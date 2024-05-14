#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script saves the jailhouse configuration of the selected environment:\r\n \ 
    [-h help]\r\n \
    [-t <target>]\r\n \
    [-b <backend>]" 1>&2
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
  echo "Saving JAILHOUSE config ..."

  # Save old
  cp "${custom_jailhouse_config_dir}"/config.h "${custom_jailhouse_config_dir}"/config_old.h

  # Save Jailhouse config.h
  cp "${jailhouse_config_dir}"/config.h "${custom_jailhouse_config_dir}"/
  if [[ $? -ne 0 ]]; then
    echo "ERROR: config.h not found"
    exit 1
  fi
  echo "JAILHOUSE config.h has been successfully saved"
fi