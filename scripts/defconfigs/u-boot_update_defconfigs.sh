#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script updates the u-boot configurations of the selected environment:\r\n \
    [-m launch menuconfig after update]\r\n \
    [-t <target>]\r\n \
    [-b <backend>]\r\n \
    [-h help]" 1>&2
  exit 1
}

# DIRECTORIES
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "${current_dir}")
source "${script_dir}"/common/common.sh

# By default no menuconfig
MENUCFG=0

while getopts "mt:b:h" o; do
  case "${o}" in
  m)
    MENUCFG=1
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

# ASK user if he really wants to update
read -r -p "Do you really want to update "${defconfig_uboot_name}" (your current configs will be lost)? (y/n): " UPDATE

# Update!
if [[ "${UPDATE,,}" =~ ^y(es)?$ ]]; then
  # UPDATE U-BOOT 
  echo "Updating U-BOOT config ..."
  echo "Updating ${defconfig_uboot_name} ..."

  # Copy custom u-boot defconfig in u-boot directory and configure it
  cp "${custom_uboot_config_dir}"/"${defconfig_uboot_name}" "${uboot_config_dir}"/"${defconfig_uboot_name}"

  # Export variables
  export ARCH="${BUILD_ARCH}"
  export CROSS_COMPILE="${CROSS_COMPILE}"

  # Configure U-BOOT
  make -C "${uboot_dir}" "${defconfig_uboot_name}" 
  if [[ $? -ne 0 ]]; then
    echo "ERROR: The make command failed in configuring U-BOOT KERNEL"
    exit 1
  fi
  echo "U-BOOT has been successfully configured"

  # Start Menuconfig
  if [[ ${MENUCFG} -eq 1 ]]; then
    make -C "${uboot_dir}" menuconfig 
  else 
    echo "Skipping Menuconfig." 
  fi

  # Unset variables
  unset ARCH
  unset CROSS_COMPILE
else
  echo "Skipping Update."
fi