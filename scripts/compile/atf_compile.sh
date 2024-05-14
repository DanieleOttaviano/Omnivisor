#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script compile the arm trust firmware for the specified <target> and <backend>:\r\n \
    [-t <target>]\r\n \
    [-b <backend>]\r\n \
    [-h help]" 1>&2
  exit 1
}

# DIRECTORIES
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "${current_dir}")
source "${script_dir}"/common/common.sh

PLATFORM="zynqmp"

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

# Compile atf
make -C "${atf_dir}" CROSS_COMPILE="${CROSS_COMPILE}" PLAT="${PLATFORM}" bl31 -j"$(nproc)"
if [[ $? -ne 0 ]]; then
  echo "ERROR: The make command failed during the compilation of ATF"
  exit 1
fi
echo "ATF has been successfully compiled"

# Copy atf in the boot directory
cp "${atf_image_dir}"/bl31.elf "${boot_dir}"/
