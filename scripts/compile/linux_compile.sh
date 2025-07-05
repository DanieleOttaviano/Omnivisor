#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script compile the Linux kernel Image (optionally the modules):\r\n \
    [-m compile kernel modules]\r\n \
    [-n install modules in the NFS rootfs]\r\n \
    [-t <target>]\r\n \
    [-b <backend>]\r\n \
    [-h help]" 1>&2
  exit 1
}

# DIRECTORIES
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "${current_dir}")
source "${script_dir}"/common/common.sh

INSTALL_MOD="n"
COMPILE_MOD="n"

while getopts "mnt:b:h" o; do
  case "${o}" in
  m)
    COMPILE_MOD="Y"
    ;;
  n)
    INSTALL_MOD="Y"
    ;;
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

# Compile the Kernel
yes "" | make -C "${linux_dir}" ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" Image -j"$(nproc)"
if [[ $? -ne 0 ]]; then
  echo "ERROR: The make command failed during the compilation of LINUX KERNEL"
  exit 1
fi
echo "LINUX KERNEL has been successfully compiled"

# Compile the Modules
if [[ "${COMPILE_MOD,,}" =~ ^y(es)?$ ]]; then
  make -C "${linux_dir}" ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" modules -j"$(nproc)"
  if [[ $? -ne 0 ]]; then
    echo "ERROR: The make command failed during the compilation of LINUX KERNEL MODULES"
    exit 1
  fi
  echo "LINUX KERNEL MODULES have been successfully compiled"

  # Install modules
  if [[ "${INSTALL_MOD,,}" =~ ^y(es)?$ ]]; then
    INSTALL_MOD_PATH="${rootfs_dir}/${TARGET}" make -C "${linux_dir}" ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" modules_install
  else
    INSTALL_MOD_PATH="${install_dir}" make -C "${linux_dir}" ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" modules_install
  fi
  if [[ $? -ne 0 ]]; then
    echo "ERROR: The make command failed during the INSTALLATION of LINUX KERNEL MODULES"
    exit 1
  fi
  echo "LINUX KERNEL MODULES have been successfully INSTALLED"
else
  echo "Skipped compiling and installing modules."
fi

# Copy Image in the boot directory
cp "${image_dir}"/Image "${boot_dir}"/