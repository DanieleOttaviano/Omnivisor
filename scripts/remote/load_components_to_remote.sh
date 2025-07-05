#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script loads the selected components into the target filesystem:\r\n \
    [-a load all]\r\n \
    [-j load jailhouse]\r\n \
    [-t <target>]\r\n \
    [-b <backend>]\r\n \
    [-h help]" 1>&2
  exit 1
}

# DIRECTORIES
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "${current_dir}")
source ${script_dir}/common/common.sh

J=0
R=0

while getopts "jat:b:h" o; do
  case "${o}" in
  j)
    J=1
    ;;
  a)
    J=1
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

# Validate input
if [ "${J}" -eq 0 ]; then
  echo "ERROR: Select a project to sync!"
  usage
fi

# Set the Environment
source ${script_dir}/common/set_environment.sh ${TARGET} ${BACKEND}

echo "REMOTE: ${USER}@${IP}:${RSYNC_REMOTE_PATH}"
echo "ARGS: ${RSYNC_ARGS} ${RSYNC_ARGS_SSH}"

ssh ${USER}@${IP} "date -u -s '$(date -u +'%Y-%m-%d %H:%M:%S')'"

if [ -z "${RSYNC_ARGS_SSH}" ]; then
  [ ${J} -eq 1 ] && rsync -ruv --modify-window=1 ${RSYNC_ARGS} ${jailhouse_dir} ${USER}@${IP}:${RSYNC_REMOTE_PATH}
else
  [ ${J} -eq 1 ] && rsync -ruv --modify-window=1 ${RSYNC_ARGS} "${RSYNC_ARGS_SSH}" ${jailhouse_dir} ${USER}@${IP}:${RSYNC_REMOTE_PATH}
fi
