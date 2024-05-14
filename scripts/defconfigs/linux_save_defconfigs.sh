#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script saves the linux configuration of the selected environment:\r\n \ 
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

read -r -p "Do you really want to save (your current config will be saved as default)? (y/n): " SAVE

# Save!
if [[ "${SAVE,,}" =~ ^y(es)?$ ]]; then
  echo "Saving LINUX config ..."
  echo "saving ${defconfig_linux_name} ..."

  # Save old
  cp "${custom_linux_config_dir}"/"${defconfig_linux_name}" "${custom_linux_config_dir}"/"${defconfig_linux_name}"_old

  # Save Linux defconfig
  make -C "${linux_dir}" ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" savedefconfig
  if [[ $? -ne 0 ]]; then
    echo "ERROR: The make command failed during the savedefconfig of LINUX"
    exit 1
  fi
  echo "LINUX defconfig has been successfully saved"

  cp "${linux_dir}"/defconfig "${linux_config_dir}"/"${defconfig_linux_name}"
  cp "${linux_config_dir}"/"${defconfig_linux_name}" "${custom_linux_config_dir}"/
fi