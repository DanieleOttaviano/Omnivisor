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

# ASK User if he really wants to remove the environment
read -r -p "Do you really want to remove Environment:${TARGET}-${BACKEND}? (y/n): " REMOVE
if [[ "${REMOVE,,}" =~ ^y(es)?$ ]]; then
  # Remove Environment from file
  grep -v "${TARGET}-${BACKEND}" "${ENVIRONMENTS_LIST}" >temp_file && mv temp_file "${ENVIRONMENTS_LIST}"
  echo "Removed Environment:${TARGET}-${BACKEND} from ${ENVIRONMENTS_LIST}"

  # Remove Target directory
  rm -rf "${environment_dir:?}"/"${TARGET}"
  echo "Removed ${environment_dir}/${TARGET}"

else
  echo "Skipping REMOVE."
fi
