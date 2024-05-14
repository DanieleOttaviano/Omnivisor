#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script patch linux with the <patch>:\r\n \
    [-p <patch>]\r\n \
    [-h help]" 1>&2
  exit 1
}

# DIRECTORIES
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "${current_dir}")
source "${script_dir}"/common/common.sh

while getopts "p:h" o; do
  case "${o}" in
  p)
    PATCH=${OPTARG}
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

# Apply Patch if ${PATCH} exists
if [[ -z "${PATCH}" ]]; then
    echo "Skipping patch application."
elif [[ -f "${custom_linux_patch_dir}/${PATCH}" ]]; then
    patch -p1 -d "${linux_dir}" < "${custom_linux_patch_dir}"/"${PATCH}"
    echo "Patch applied!"
else
    echo "Patch not found!"
    echo "The available patches are:"
    ls ${custom_linux_patch_dir}
    exit 1
fi
