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

# Export the rootfs.tar into the target directory
if [ ! -d "${rootfs_dir}/${TARGET}/" ]; then
  mkdir -p "${rootfs_dir}/${TARGET}/"
fi

# Check if the directory is empty
if [ -z "$(ls -A "${rootfs_dir}/${TARGET}/")" ]; then
  tar -xvf "${rootfs_dir}/rootfs.tar" -C "${rootfs_dir}/${TARGET}/"
else
  echo "The directory ${rootfs_dir}/${TARGET}/ is not empty. Moving content to ${rootfs_dir}/OLD_${TARGET} and extracting."
  if [ -d "${rootfs_dir}/OLD_${TARGET}" ]; then
    echo "The directory ${rootfs_dir}/OLD_${TARGET} already exists. Removing it..."
    rm -rf "${rootfs_dir}/OLD_${TARGET}"
  fi
  mv "${rootfs_dir}/${TARGET}/" "${rootfs_dir}/OLD_${TARGET}" 
  mkdir -p "${rootfs_dir}/${TARGET}/"
  tar -xvf "${rootfs_dir}/rootfs.tar" -C "${rootfs_dir}/${TARGET}/"
fi
