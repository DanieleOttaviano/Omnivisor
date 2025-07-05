#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script updates the jailhouse configurations of the selected environment:\r\n \
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
read -r -p "Do you really want to update "${defconfig_jailhouse_name}" (your current configs will be lost)? (y/n): " UPDATE

# Update!
if [[ "${UPDATE,,}" =~ ^y(es)?$ ]]; then
  # UPDATE JAILHOUSE
  echo "Updating JAILHOUSE config ..."
  # Copy custom jailhouse config.h in jailhouse and configure it
  cp "${custom_jailhouse_config_dir}"/"${defconfig_jailhouse_name}" "${jailhouse_config_dir}"/config.h
  echo "JAILHOUSE "${defconfig_jailhouse_name}"-> config.h has been successfully updated"

  # Start Menuconfig
  if [[ ${MENUCFG} -eq 1 ]]; then
    echo "menuconfig is not available for jailhouse."
  else
    echo "Skipping Menuconfig."
  fi
else
  echo "Skipping Update."
fi