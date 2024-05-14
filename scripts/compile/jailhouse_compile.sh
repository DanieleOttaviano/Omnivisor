#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script compile the jailhouse hypervisor:\r\n \
    [-c add custom cells/dts from custom_build]\r\n \
    [-r <remote core> compile rCPU code demo and libraries (all, armr5, riscv32)]\r\n \
    [-B <benchmark name> for Taclebench demo]\r\n \
    [-i install jailhouse in the install directory]\r\n \
    [-t <target>]\r\n \
    [-b <backend>]\r\n \
    [-h help]" 1>&2
  exit 1
}

# DIRECTORIES
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "${current_dir}")
source "${script_dir}"/common/common.sh

INSTALL_OVERLAY="n"
CUSTOM_CONFIGS="n"
RCPU_COMPILE="n"

#Benchmark name
BENCHNAME=""
RCPUs=""
CORE=""

while getopts "cr:B:it:b:h" o; do
  case "${o}" in
  c)
    CUSTOM_CONFIGS="Y"
    ;;
  i)
    INSTALL_OVERLAY="Y"
    ;;
  r)
    RCPU_COMPILE="Y"  
    RCPUs=${OPTARG}
    ;;
  B)
    BENCHNAME=${OPTARG}
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
source "${script_dir}"/common/set_environment.sh "${TARGET}" "${BACKEND}"

# Copy config, custom dts and custom cells before make
if [[ "${CUSTOM_CONFIGS,,}" =~ ^y(es)?$ ]]; then
  cp "${custom_jailhouse_cell_dir}"/dts/*.dts "${jailhouse_cell_dir}"/dts/
  cp "${custom_jailhouse_cell_dir}"/*.c "${jailhouse_cell_dir}"
else
  echo "Skipping adding custom dts/cells."
fi

# Compile jailhouse (INPUT: kernel directory, installation directory)
make -C "${jailhouse_dir}" ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" KDIR="${linux_dir}" #ARCH=arm64 CROSS_COMPILE=${aarch64_buildroot_linux_gnu_dir}/aarch64-buildroot-linux-gnu-
if [[ $? -ne 0 ]]; then
  echo "ERROR: The make command failed during the compilation of JAILHOUSE"
  exit 1
else
  echo "JAILHOUSE has been successfully compiled"
fi

# Compile RCPU demo
if [[ "${RCPU_COMPILE,,}" =~ ^y(es)?$ ]]; then
  # Check remote core
  if [[ "${RCPUs}" == "all" ]]; then
    CORE=""
  elif [[ "${RCPUs}" == "armr5" ]]; then
    CORE="_armr5"
  elif [[ "${RCPUs}" == "riscv32" ]]; then
    CORE="_riscv32"
  else
    echo "ERROR: Invalid remote core specified. try 'all', 'armr5' or 'riscv32'"
    exit 1
  fi
  # clean and compile
  make -C "${jailhouse_dir}" clean-remote${CORE} REMOTE_COMPILE="${REMOTE_COMPILE}" 
  make -C "${jailhouse_dir}" remote${CORE} REMOTE_COMPILE="${REMOTE_COMPILE}" BENCH=${BENCHNAME} 
  
  if [[ $? -ne 0 ]]; then
    echo "ERROR: The make command failed during the compilation of JAILHOUSE RPU demo"
    exit 1
  else
    echo "JAILHOUSE ${RCPUs} DEMO has been successfully compiled"
  fi
else
  echo "Skipping compiling JAILHOUSE RCPUs DEMO"
fi

# Install Jailhouse in the overlay filesystem
if [[ "${INSTALL_OVERLAY,,}" =~ ^y(es)?$ ]]; then
  make -C "${jailhouse_dir}" ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" KDIR="${linux_dir}" DESTDIR="${project_dir}"/install install #ARCH=arm64 CROSS_COMPILE=${aarch64_buildroot_linux_gnu_dir}/aarch64-buildroot-linux-gnu-
  if [[ $? -ne 0 ]]; then
    echo "ERROR: The make command failed during the installation of JAILHOUSE"
    exit 1
  fi
  echo "JAILHOUSE has been successfully installed!"

  # Create overlay directory structure
  mkdir -p "${install_dir}"/root/inmates/demos/linux
  mkdir -p "${install_dir}"/root/configs/dts

  # Copy compiled cell, compiled device tree, demos bin, in the final rootfs
  cp "${jailhouse_dir}"/configs/arm64/*.cell "${install_dir}"/root/configs
  cp "${jailhouse_dir}"/configs/arm64/dts/*.dtb "${install_dir}"/root/configs/dts
  cp "${jailhouse_dir}"/inmates/demos/arm64/*.bin "${install_dir}"/root/inmates/demos

  # Jailhouse should install pyjailhouse in the libexec/jailhouse directory but it dosn't. So lets do it manually
  if [ -d "${install_dir}/usr/local/libexec/jailhouse/pyjailhouse" ]; then
    echo "pyjailhouse is already in the right directory"
  else
    echo "moving pyjailhouse in the right directory..."
    pyjailhouse_path=$(find "${install_dir}" -type d -name "pyjailhouse")
    mv "${pyjailhouse_path}" "${install_dir}"/usr/local/libexec/jailhouse
  fi

else
  echo "Skipping installation ..."
fi