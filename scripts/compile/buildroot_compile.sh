#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script compile the root file system for the specified <target> and <backend>:\r\n \
    [-t <target>]\r\n \
    [-b <backend>]\r\n \
    [-h help]" 1>&2
  exit 1
}

# DIRECTORIES
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "${current_dir}")
source "${script_dir}"/common/common.sh

while getopts "t:b:h" o; do
  case "${o}" in
  t)
    TARGET=${OPTARG}
    ;;
  b)
    BACKEND=${OPTARG}
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

# Compile buildroot
make -C "${buildroot_dir}" -j"$(nproc)"
if [[ $? -ne 0 ]]; then
  echo "ERROR: The make command failed during the compilation of BUILDROOT"
  exit 1
fi
echo "BUILDROOT has been successfully compiled"

# Copy rootfs in rootcell
cp ${rootfs_image_dir}/* ${rootfs_dir}/
