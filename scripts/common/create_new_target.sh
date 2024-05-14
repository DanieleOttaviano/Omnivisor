#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script create a new <target> in the project:\r\n \
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

# Verifty if TARGET already exist
while IFS= read -r line; do
  if [[ "${TARGET}-${BACKEND}" == "${line}" ]]; then
    found="true"
    break
  fi
done <"${ENVIRONMENTS_LIST}"
if [ "${found}" == "true" ]; then
  echo "ERROR: Environment exist!"
  exit 1
fi
echo "TARGET: ${TARGET}"
echo "BACKEND: ${BACKEND}"

## Add new environment to list (/environment/environments.txt)##
echo "${TARGET}-${BACKEND}" >>"${environment_dir}"/environments.txt
echo "New environment added!"
echo "existing environments ..."
cat "${environment_dir}"/environments.txt

## Create new target directory hiearchy ##
echo "Creating directory hierarchy for the new environment ..."
mkdir -p "${environment_dir}"/"${TARGET}"
mkdir -p "${environment_dir}"/"${TARGET}"/"${BACKEND}"

bash "${script_dir}"/common/create_new_backend.sh -t "${TARGET}" -b "${BACKEND}"
