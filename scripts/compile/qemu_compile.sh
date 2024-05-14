#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script build QEMU for the specified <target> and <backend>:\r\n \
    [-t <target>]\r\n \
    [-b <backend>]\r\n \
    [-h help]" 1>&2
  exit 1
}

# DIRECTORIES
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
    ;;
  *)
    usage
    ;;
  esac
done
shift $((OPTIND - 1))

# Set the Environment
source "${script_dir}"/common/set_environment.sh "${TARGET}" "${BACKEND}"

cd "${qemu_dir}" || exit 1
./configure --target-list=aarch64-softmmu
make -j"$(nproc)"
if [[ $? -ne 0 ]]; then
  echo "Error: The make command failed during the compilation of QEMU."
  exit 1
fi
echo "QEMU has been successfully compiled"