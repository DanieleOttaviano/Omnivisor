#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script load the <backend> specific install directory in the root of the <target> filesystem:\r\n \
    [-t <target>]\r\n \
    [-b <backend>]\r\n \
    [-h help]" 1>&2
  exit 1
}

# DIRECTORIES
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "${current_dir}")
source ${script_dir}/common/common.sh

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
source ${script_dir}/common/set_environment.sh ${TARGET} ${BACKEND}

echo "REMOTE: ${USER}@${IP}:${RSYNC_REMOTE_PATH}"
echo "ARGS: ${RSYNC_ARGS} ${RSYNC_ARGS_SSH}"

if [ -z "${RSYNC_ARGS_SSH}" ]; then
  rsync -ruv ${RSYNC_ARGS} ${install_dir}/* root@${IP}:/
else
  rsync -ruv ${RSYNC_ARGS} "${RSYNC_ARGS_SSH}" ${install_dir}/* root@${IP}:/
fi
