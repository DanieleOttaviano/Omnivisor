#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script saves the buildroot configuration of the selected environment:\r\n \ 
    [-t <target>]\r\n \
    [-b <backend>]\r\n \
    [-x save also busybox config]\r\n \
    [-h help]" 1>&2
  exit 1
}

# DIRECTORIES
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "${current_dir}")
source "${script_dir}"/common/common.sh

SAVE_BUSYBOX=n

while getopts "t:b:xh" o; do
  case "${o}" in
  t)
    TARGET=${OPTARG}
    ;;
  b)
    BACKEND=${OPTARG}
    ;;
  x)
    SAVE_BUSYBOX=y
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

read -r -p "Do you really want to save "${defconfig_builroot_name}" (if already exist it will be overwritten)? (y/n): " SAVE

# Save!
if [[ "${SAVE,,}" =~ ^y(es)?$ ]]; then
  echo "Saving BUILDROOT config ..."
  echo "saving ${defconfig_buildroot_name} ..."

  # Save old
  cp "${custom_buildroot_config_dir}"/"${defconfig_buildroot_name}" "${custom_buildroot_config_dir}"/"${defconfig_buildroot_name}"_old

  # Save buildroot defconfig
  make -C ${buildroot_dir} savedefconfig BR2_DEFCONFIG="${buildroot_config_dir}"/"${defconfig_buildroot_name}"
  if [[ $? -ne 0 ]]; then
    echo "ERROR: The make command failed during the savedefconfig of BUILDROOT"
    exit 1
  fi
  echo "BUILDROOT defconfig has been successfully saved"

  cp "${buildroot_config_dir}"/"${defconfig_buildroot_name}" "${custom_buildroot_config_dir}"/
fi

if [[ "${SAVE_BUSYBOX,,}" =~ ^y(es)?$ ]]; then
  echo "Saving BUSYBOX config ..."
  echo "saving ${defconfig_busybox_name} ..."

  # Save old
  cp "${custom_busybox_config_dir}"/"${defconfig_busybox_name}" "${custom_busybox_config_dir}"/"${defconfig_busybox_name}"_old

  # Save busybox defconfig
  cp "${busybox_config_dir}"/.config "${custom_busybox_config_dir}"/"${defconfig_busybox_name}"
fi