#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  Delete builds and output for the specified target:\r\n \
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

# ASK User if he really wants to delete the build
read -r -p "Do you really want to delete ${TARGET}/${BACKEND} builds? (y/n): " DELETE
if [[ "${DELETE,,}" =~ ^y(es)?$ ]]; then
  # Clean build
  rm -rf "${build_dir:?}"/*
else
  echo "Skipping DELETE."
fi
