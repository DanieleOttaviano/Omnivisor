#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script saves the u-boot configuration of the selected environment:\r\n \ 
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

read -r -p "Do you really want to save "${defconfig_uboot_name}" (if already exist it will be overwritten)? (y/n): " SAVE

# Save!
if [[ "${SAVE,,}" =~ ^y(es)?$ ]]; then
  echo "Saving U-BOOT config ..."
  echo "saving ${defconfig_uboot_name} ..."

  # Save old
  cp "${custom_uboot_config_dir}"/"${defconfig_uboot_name}" "${custom_uboot_config_dir}"/"${defconfig_uboot_name}"_old

  # Export variables
  export ARCH="${BUILD_ARCH}"
  export CROSS_COMPILE="${CROSS_COMPILE}"
  
  # Save U-BOOT defconfig
  make -C "${uboot_dir}" savedefconfig
  if [[ $? -ne 0 ]]; then
    echo "ERROR: The make command failed during the savedefconfig of U-BOOT"
    exit 1
  fi

  # Unset variables
  unset ARCH
  unset CROSS_COMPILE

  echo "U-BOOT defconfig has been successfully saved"

  cp "${uboot_dir}"/defconfig "${uboot_config_dir}"/"${defconfig_uboot_name}"
  cp "${uboot_config_dir}"/"${defconfig_uboot_name}" "${custom_uboot_config_dir}"/
fi