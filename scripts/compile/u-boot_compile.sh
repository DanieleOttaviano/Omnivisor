#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script compile the U-boot bootloader for the specified <target> and <backend>:\r\n \
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
# Export variables
export ARCH="${BUILD_ARCH}"
export CROSS_COMPILE="${CROSS_COMPILE}"

PLATFORM="xilinx_zynqmp_virt_defconfig"

# Compile U-boot 
#make -C "${uboot_dir}" ${PLATFORM} 
# IF zcu102 (sudo apt-et install libgnutls28-dev)
# export BL31=/home/environment/zcu102/jailhouse/output/boot/bl31.elf
#echo 'CONFIG_BOOTCOMMAND="if dhcp ${scriptaddr} kria/boot.scr; then source ${scriptaddr}; fi"' >> ${uboot_dir}/.config
make -C "${uboot_dir}"  -j"$(nproc)"
if [[ $? -ne 0 ]]; then
  echo "ERROR: The make command failed during the compilation of U-boot"
  exit 1
fi

# Unset variables
unset ARCH
unset CROSS_COMPILE


echo "U-boot has been successfully compiled"

# Copy U-boot elf file in the boot directory
cp "${uboot_dir}"/u-boot.elf "${boot_dir}"/
