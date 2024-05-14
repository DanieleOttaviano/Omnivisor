#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script updates the buildroot configurations of the selected environment:\r\n \
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
read -r -p "Do you really want to update (your current configs will be lost)? (y/n): " UPDATE

# Update!
if [[ "${UPDATE,,}" =~ ^y(es)?$ ]]; then
  # UPDATE BUILDROOT
  echo "Updating BUILDROOT config ..."
  echo "Updating ${defconfig_buildroot_name} ..."

  # Modify Overlay directory according to the target
  sed -i "/^BR2_ROOTFS_OVERLAY=/cBR2_ROOTFS_OVERLAY=\"${install_dir}\"" "${custom_buildroot_config_dir}"/"${defconfig_buildroot_name}"

  # Copy custom buildroot defconfig in buildroot and configure it
  cp "${custom_buildroot_config_dir}"/"${defconfig_buildroot_name}" "${buildroot_config_dir}"/"${defconfig_buildroot_name}"

  # Configure Buildroot
  make -C "${buildroot_dir}" "${defconfig_buildroot_name}"
  if [[ $? -ne 0 ]]; then
    echo "ERROR: The make command failed in configuring BUILDROOT"
    exit 1
  fi
  echo "BUILDROOT has been successfully configured"

  # Start Menuconfig
  if [[ ${MENUCFG} -eq 1 ]]; then
    make -C "${buildroot_dir}" menuconfig 
  else
    echo "Skipping Menuconfig."
  fi
else
  echo "Skipping Update."
fi