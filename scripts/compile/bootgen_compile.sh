#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script compile the bootgen project for the specified <target> and <backend>:\r\n \
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

# Compile bootgen
make -C "${bootgen_dir}"
if [[ $? -ne 0 ]]; then
  echo "ERROR: The make command failed during the compilation of BOOTGEN"
  exit 1
fi
echo "BOOTGEN has been successfully compiled"

# Use bootgen to generate BOOT.BIN for the target
cd "${boot_dir}" || exit 1
"${bootgen_dir}"/bootgen -arch "${PLATFORM}" -image bootgen.bif -w -o BOOT.BIN
