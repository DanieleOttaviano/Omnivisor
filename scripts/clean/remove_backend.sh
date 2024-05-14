#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  Delete all the files and configuration related to a speific <target>:\r\n \
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

# ASK User if he really wants to remove the environment
read -r -p "Do you really want to remove ${BACKEND} from ${TARGET}? (y/n): " REMOVE
if [[ "${REMOVE,,}" =~ ^y(es)?$ ]]; then
  # Remove Backend directory
  rm -rf "${target_dir:?}"/backend/"${BACKEND}"
  echo "Backend (${BACKEND}) directory removed from target (${TARGET})!"
  # Remove Target-Backend configuration file
  rm -rf "${environment_cfgs_dir:?}"/"${TARGET}"-"${BACKEND}".sh
  echo "Target-Backend configuration file (${TARGET}-${BACKEND}.sh) removed from target (${TARGET})!"
else
  echo "Skipping REMOVE."
fi
