#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script load the selected components in the target filesystem:\r\n \
    [-a load all]\r\n \
    [-j load jailhouse]\r\n \
    [-r load runPHI]\r\n \
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

while getopts "jrat:b:h" o; do
  case "${o}" in
  j)
    J=1
    ;;
  r)
    R=1
    ;;
  a)
    J=1
    R=1
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
if [ "${J}" -eq 0 ] && [ "${R}" -eq 0 ]; then
  echo "ERROR: Select a project to sync!"
  usage
fi

echo "REMOTE: ${USER}@${IP}:${RSYNC_REMOTE_PATH}"
echo "ARGS: ${RSYNC_ARGS} ${RSYNC_ARGS_SSH}"

if [ -z "${RSYNC_ARGS_SSH}" ]; then
  [ ${J} -eq 1 ] && rsync -ruv ${RSYNC_ARGS} ${jailhouse_dir} ${USER}@${IP}:${RSYNC_REMOTE_PATH}
  [ ${R} -eq 1 ] && rsync -ruv ${RSYNC_ARGS} ${runPHI_dir} ${USER}@${IP}:${RSYNC_REMOTE_PATH}
else
  [ ${J} -eq 1 ] && rsync -ruv ${RSYNC_ARGS} "${RSYNC_ARGS_SSH}" ${jailhouse_dir} ${USER}@${IP}:${RSYNC_REMOTE_PATH}
  [ ${R} -eq 1 ] && rsync -ruv ${RSYNC_ARGS} "${RSYNC_ARGS_SSH}" ${runPHI_dir} ${USER}@${IP}:${RSYNC_REMOTE_PATH}
fi
