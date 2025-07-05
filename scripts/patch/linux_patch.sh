#!/bin/bash
 
usage() {
  echo -e "Usage: $0 \r\n \
  This script patches Linux with the following options:\r\n \
    [-p <patch>] (single patch)\r\n \
    [-d <dir1,dir2,...>] (directories containing patches)\r\n \
    [-r] remove the patches\r\n \
    [-h help]" 1>&2
  exit 1
}
 
# DIRECTORIES
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "${current_dir}")
source "${script_dir}"/common/common.sh

ERROR=0
REMOVE=""
PATCH=""
PATCH_DIRS=()

# Process arguments
while getopts "p:d:rh" o; do
  case "${o}" in
  p)
    PATCH=${OPTARG}
    ;;
  d)
    IFS=',' read -r -a PATCH_DIRS <<< "${OPTARG}"  # Read directories into an array
    ;;
  r)
    REMOVE="-R"
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
 
# Set the Environment
source "${script_dir}"/common/set_environment.sh "${TARGET}" "${BACKEND}"

# Define operation based on the REMOVE flag (-r)
if [[ -n "${REMOVE}" ]]; then
  OPERATION="removing"
  OPERATION2="removed"
else
  OPERATION="applying"
  OPERATION2="applied"
fi

# Function to apply/remove patches in a given directory
apply_patches_in_dir() {
  local patch_dir="$1"
  if [[ -d "${custom_linux_patch_dir}/$patch_dir" ]]; then
    echo "Processing patches from directory: ${custom_linux_patch_dir}/$patch_dir"
    
    # Find and sort patches numerically (assuming patches are prefixed with numbers like 001, 002)
    patches=$(find "${custom_linux_patch_dir}/$patch_dir/" -type f -name "*.patch" | sort)
    
    if [[ -z "$patches" ]]; then
      echo "No patches found in directory: ${custom_linux_patch_dir}/$patch_dir"
    else
      for patch_file in $patches; do
        echo "${OPERATION^} patch: $(basename "$patch_file")"  # Capitalize first letter
        patch ${REMOVE} -p1 -d "${linux_dir}" < "$patch_file"
        if [[ $? -ne 0 ]]; then
          echo "Failed to complete ${OPERATION} for patch: $(basename "$patch_file")"
          ERROR=1
        fi
      done
      if [[ ${ERROR} -ne 0 ]]; then
         echo "Failed to complete ${OPERATION} for patches in directory: ${custom_linux_patch_dir}/$patch_dir"
      else
         echo "All patches from ${custom_linux_patch_dir}/$patch_dir ${OPERATION2} successfully."
      fi
    fi
  else
    echo "Directory not found: ${custom_linux_patch_dir}/$patch_dir"
    exit 1
  fi
}

# Apply or remove a single patch if provided
if [[ -n "${PATCH}" ]]; then
  if [[ -f "${custom_linux_patch_dir}/${PATCH}" ]]; then
    echo "${OPERATION^} single patch: ${PATCH}"
    patch ${REMOVE} -p1 -d "${linux_dir}" < "${custom_linux_patch_dir}/${PATCH}"
    if [[ $? -eq 0 ]]; then
      echo "Patch ${PATCH} ${OPERATION2} successfully!"
    else
      echo "Failed to complete ${OPERATION} for patch: ${PATCH}"
    fi
  else
    echo "Patch not found!"
    echo "The available patches are:"
    ls "${custom_linux_patch_dir}"
    exit 1
  fi
fi

# Apply or remove patches from directories if provided
if [[ ${#PATCH_DIRS[@]} -gt 0 ]]; then
  for dir in "${PATCH_DIRS[@]}"; do
    apply_patches_in_dir "$dir"
  done
fi
 
# If neither a patch nor directories are specified, skip patching
if [[ -z "${PATCH}" && ${#PATCH_DIRS[@]} -eq 0 ]]; then
  echo "Skipping patch operation as no patch or directories were specified."
fi
