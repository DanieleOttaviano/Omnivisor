#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script updates the Linux configurations of the selected environment:\r\n \
    [-m launch menuconfig after update]\r\n \
    [-t <target>]\r\n \
    [-b <backend>]\r\n \
    [-c <config_file>]\r\n \
    [-h help]" 1>&2
  exit 1
}

# DIRECTORIES
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "${current_dir}")
source "${script_dir}"/common/common.sh

# By default no menuconfig
MENUCFG=0
CONFIG_FILE=""

while getopts "mt:b:c:h" o; do
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
  c)
    CONFIG_FILE=${OPTARG}
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
read -r -p "Do you really want to update "${defconfig_linux_name}" (your current configs will be lost)? (y/n): " UPDATE

# Update!
if [[ "${UPDATE,,}" =~ ^y(es)?$ ]]; then
  # UPDATE LINUX 
  echo "Updating LINUX config ..."
  
  # Determine which config file to use
  CONFIG_TO_COPY="${defconfig_linux_name}"
  if [[ -n "${CONFIG_FILE}" ]]; then
    CONFIG_TO_COPY="${CONFIG_FILE}"
  fi
  
  if [[ ! -f "${custom_linux_config_dir}/${CONFIG_TO_COPY}" ]]; then
    echo "ERROR: Specified config file '${CONFIG_TO_COPY}' not found in '${custom_linux_config_dir}'"
    exit 1
  fi
  
  echo "Updating ${CONFIG_TO_COPY} ..."

  # Copy custom linux kernel defconfig in linux kernel and configure it
  cp "${custom_linux_config_dir}/${CONFIG_TO_COPY}" "${linux_config_dir}/${defconfig_linux_name}"

  # Configure Linux
  make -C "${linux_dir}" ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" "${defconfig_linux_name}"
  if [[ $? -ne 0 ]]; then
    echo "ERROR: The make command failed in configuring LINUX KERNEL"
    exit 1
  fi
  echo "LINUX KERNEL has been successfully configured"

  # Start Menuconfig
  if [[ ${MENUCFG} -eq 1 ]]; then
    make -C "${linux_dir}" ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" menuconfig
  else 
    echo "Skipping Menuconfig." 
  fi
else
  echo "Skipping Update."
fi
