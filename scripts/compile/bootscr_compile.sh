#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script compile the bootscr for the specified <target> and <backend>:\r\n \
    [-t <target>]\r\n \
    [-b <backend>]\r\n \
    [-h help]" 1>&2
  exit 1
}

curr_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "${curr_dir}")
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
    exit 1
    ;;
  *)
    usage
    ;;
  esac
done
shift $((OPTIND - 1))

# Set the Environment
source "${script_dir}"/common/set_environment.sh "${TARGET}" "${BACKEND}"

if [ "${UBUNTU_ROOTFS}" == "y" ]; then
  echo "UBUNTU_ROOTFS"
  mkimage -c none -A arm64 -T script -d "${boot_sources_dir}"/boot.script "${boot_dir}"/boot.scr.uimg
else
  mkimage -c none -A arm64 -T script -d "${boot_sources_dir}"/boot.cmd "${boot_dir}"/boot.scr
fi
