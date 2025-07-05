#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script copy the pub key to the remote target:\r\n \
    [-t <target>]\r\n \
    [-b <backend>]\r\n \
    [-h help]" 1>&2
  exit 1
}

# DIRECTORIES
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "${current_dir}")
source ${script_dir}/common/common.sh

if [ -z "${HOME_DIR}" ]; then
  HOME_DIR="${HOME}"
fi

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

echo "REMOTE: ${USER}@${IP}"
echo "ARGS: ${SSH_ARGS}"

if [ -e "${HOME_DIR}/.ssh/id_rsa" ] && [ -e "${HOME_DIR}/.ssh/id_rsa.pub" ]; then
  echo "rsa key pair exists."
else
  ssh-keygen -t rsa
fi

# Remove known host every time the emulation restart
if [ ${TARGET} == "qemu" ]; then
  #ssh-keygen -f "${HOME_DIR}/.ssh/known_hosts" -R "[localhost]:5022"
  ssh-keygen -f "/root/.ssh/known_hosts" -R "${IP}"
fi

cat ${HOME_DIR}/.ssh/id_rsa.pub | ssh ${SSH_ARGS} ${USER}@${IP} "mkdir -p /root/.ssh && cat >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys"

ssh ${SSH_ARGS} ${USER}@${IP} "[ -d /root/.ssh ] || mkdir -p /root/.ssh; [ -f /etc/dropbear/authorized_keys ] && cat /etc/dropbear/authorized_keys >> /root/.ssh/authorized_keys"
