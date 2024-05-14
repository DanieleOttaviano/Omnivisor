#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script upload the specified directory (full path needed) from the <target> filesystem\r\n \
  and save it in the environment install directory:\r\n \
    [-d <directory_path>]\r\n \
    [-b <backend>]\r\n \
    [-t <target>]\r\n \
    [-h help]" 1>&2
  exit 1
}

# DIRECTORIES
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "${current_dir}")
source ${script_dir}/common/common.sh

while getopts "d:t:b:h" o; do
  case "${o}" in
  d)
    DIRECTORY_PATH=${OPTARG}
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

echo "REMOTE: ${USER}@${IP}:${RSYNC_REMOTE_PATH}"
echo "ARGS: ${RSYNC_ARGS} ${RSYNC_ARGS_SSH}"

if [ -z "${DIRECTORY_PATH}" ]; then
  echo "ERROR: You must specify a directory path to upload"
  usage
else
  if [ -z "${RSYNC_ARGS_SSH}" ]; then
    rsync -ruv ${RSYNC_ARGS} root@${IP}:${DIRECTORY_PATH}/* ${install_dir}${DIRECTORY_PATH}
  else
    rsync -ruv ${RSYNC_ARGS} "${RSYNC_ARGS_SSH}" root@${IP}:${DIRECTORY_PATH}/* ${install_dir}${DIRECTORY_PATH}
  fi
fi
