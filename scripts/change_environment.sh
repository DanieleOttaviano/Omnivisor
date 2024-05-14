#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script change the environment to the one with specified <target> and <backend>:\r\n \
    [-t <target>]\r\n \
    [-b <backend>]\r\n \
    [-h help]" 1>&2
  exit 1
}

script_dir=$(dirname -- "$(readlink -f -- "$0")")
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

if [[ -z ${TARGET} ]] || [[ -z ${BACKEND} ]]; then
  echo "ERROR: Target or Backend not defined!"
  usage
fi

if [[ ! -f ${script_dir}/common/current_environment.sh ]]; then
  printf "#!/bin/bash\nTARGET=\"\"\nBACKEND=\"\"" >${script_dir}/common/current_environment.sh
fi

sed -i "s/TARGET=\"[^\"]*\"/TARGET=\"${TARGET}\"/;s/BACKEND=\"[^\"]*\"/BACKEND=\"${BACKEND}\"/" "${script_dir}"/common/current_environment.sh

echo "Environment changed to:"
echo "TARGET: ${TARGET}"
echo "BACKEND: ${BACKEND}"
echo "All the scrip will use them as default."
