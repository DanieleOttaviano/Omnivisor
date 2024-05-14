#!/bin/bash

#WARNING: The hipotesys is that the board target has the boot partition mounted in /boot/firmware

usage() {
  echo -e "Usage: $0 \r\n \
  This script copy the selected <backend> images files in the <target> boot/firmware directory for the next boot:\r\n \
    [-s load boot script]\r\n \
    [-d load device tree blob]\r\n \
    [-i load Image>]\r\n \
    [-o load BOOT.BIN>]\r\n \
    [-t <target>]\r\n \
    [-b <backend>]\r\n \
    [-h help]" 1>&2
  exit 1
}

curr_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "${curr_dir}")
source ${script_dir}/common/common.sh

S=0
D=0
I=0
O=0

while getopts "sdiot:b:h" o; do
  case "${o}" in
  s)
    S=1
    ;;
  d)
    D=1
    ;;
  i)
    I=1
    ;;
  o)
    O=1
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
source ${script_dir}/common/set_environment.sh ${TARGET} ${BACKEND}

# Check input
if [ "${S}" -eq 0 ] && [ "${D}" -eq 0 ] && [ "${I}" -eq 0 ] && [ "${O}" -eq 0 ]; then
  echo "ERROR: Select a project to sync!"
  usage
fi

[ ${S} -eq 1 ] && scp ${boot_dir}/boot.scr* root@${IP}:/boot/firmware/
[ ${D} -eq 1 ] && scp ${boot_dir}/*.dtb root@${IP}:/boot/firmware/
[ ${I} -eq 1 ] && scp ${boot_dir}/Image root@${IP}:/boot/firmware/
[ ${O} -eq 1 ] && scp ${boot_dir}/BOOT.BIN root@${IP}:/boot/firmware/
