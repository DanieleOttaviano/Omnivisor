#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  Start the qemu emulation for the specified <target> and <backend>:\r\n \
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

if [[ "${TARGET}" != "qemu" ]]; then
  echo "ERROR: Only qemu target is supported."
  exit 1
fi


exec "${qemu_bin_dir}"/qemu-system-aarch64 \
  -cpu cortex-a57 \
  -smp 16 \
  -m 4G \
  -machine virt,gic-version=3,virtualization=on,its=off \
  -nographic \
  -netdev type=user,id=eth0,hostfwd=tcp::5022-:22 \
  -device virtio-net-device,netdev=eth0 \
  -drive file="${rootfs_dir}"/rootfs.ext2,if=none,format=raw,id=hd0 \
  -device virtio-blk-device,drive=hd0 \
  -kernel "${boot_dir}"/Image \
  -append "rootwait root=/dev/vda console=ttyAMA0 mem=768M"

