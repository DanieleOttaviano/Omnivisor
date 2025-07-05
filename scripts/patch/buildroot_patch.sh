#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
This script patches Buildroot with the following options:\r\n \
  [-p <patch>]         (single patch)\r\n \
  [-d <dir1,dir2,...>]  (directories containing patches)\r\n \
  [-h help]" 1>&2
  exit 1
}

# Directories
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "${current_dir}")
source "${script_dir}/common/common.sh"

ERROR=0
PATCH=""
PATCH_DIRS=()

# Process arguments
while getopts "p:d:h" o; do
  case "${o}" in
    p)
      PATCH=${OPTARG}
      ;;
    d)
      IFS=',' read -r -a PATCH_DIRS <<< "${OPTARG}"  # Split comma-separated list into an array
      ;;
    h)
      usage
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND - 1))

# Set the environment (expects TARGET and BACKEND to be defined)
source "${script_dir}/common/set_environment.sh" "${TARGET}" "${BACKEND}"

# Function to apply patches in a given directory
apply_patches_in_dir() {
  local patch_dir="$1"
  local full_patch_dir="${custom_buildroot_patch_dir}/${patch_dir}"
  if [[ -d "${full_patch_dir}" ]]; then
    echo "Processing patches from directory: ${full_patch_dir}"
    
    # Find and sort patch files (assuming numeric ordering, e.g. 001_patch.patch)
    patches=$(find "${full_patch_dir}" -type f -name "*.patch" | sort)
    
    if [[ -z "${patches}" ]]; then
      echo "No patches found in directory: ${full_patch_dir}"
    else
      for patch_file in ${patches}; do
        echo "Applying patch: $(basename "${patch_file}")"
        patch -p1 -d "${buildroot_dir}" < "${patch_file}"
        if [[ $? -ne 0 ]]; then
          echo "Failed to apply patch: $(basename "${patch_file}")"
          ERROR=1
        fi
      done
      if [[ ${ERROR} -eq 0 ]]; then
        echo "All patches from ${full_patch_dir} applied successfully."
      else
        echo "One or more patches in ${full_patch_dir} failed to apply."
      fi
    fi
  else
    echo "Directory not found: ${full_patch_dir}"
    exit 1
  fi
}

# Apply a single patch if specified
if [[ -n "${PATCH}" ]]; then
  local patch_file="${custom_buildroot_patch_dir}/${PATCH}"
  if [[ -f "${patch_file}" ]]; then
    echo "Applying single patch: ${PATCH}"
    patch -p1 -d "${buildroot_dir}" < "${patch_file}"
    if [[ $? -eq 0 ]]; then
      echo "Patch ${PATCH} applied successfully!"
    else
      echo "Failed to apply patch: ${PATCH}"
      ERROR=1
    fi
  else
    echo "Patch not found: ${patch_file}"
    echo "The available patches are:"
    ls "${custom_buildroot_patch_dir}"
    exit 1
  fi
fi

# Apply patches from directories if specified
if [[ ${#PATCH_DIRS[@]} -gt 0 ]]; then
  for dir in "${PATCH_DIRS[@]}"; do
    apply_patches_in_dir "${dir}"
  done
fi

# If neither a patch nor directories were specified, skip patching.
if [[ -z "${PATCH}" && ${#PATCH_DIRS[@]} -eq 0 ]]; then
  echo "Skipping patch application as no patch or directories were specified."
fi

exit ${ERROR}
