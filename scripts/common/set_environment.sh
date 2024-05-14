#!/bin/bash

if [[ "$#" -eq 0 ]]; then
  # Use default environment if neither TARGET and BACKEND are specified
  echo "Default environment"
  source "${script_dir}"/common/current_environment.sh
elif [[ "$#" -eq 1 ]]; then
  ## Only one argument is passed (TARGET or BACKEND)
  echo "ERROR: Target or Backend not defined! (leave both void to use the default environment)"
  bash "$0" -h
  exit 1
elif [[ "$#" -eq 2 ]]; then
  TARGET="$1"
  BACKEND="$2"
elif [[ "$#" -eq 3 ]]; then
  TARGET="$1"
  BACKEND="$2"
  CREATE="$3"
fi

# If TARGET and BACKEND are not set, set them to a default value
if [[ -z "${TARGET}" ]] && [[ -z "${BACKEND}" ]]; then
  echo "Default environment"
  source "${script_dir}"/common/current_environment.sh
fi

# Check if CREATE is not set and set it to a default value
if [[ -z "$CREATE" ]]; then
  CREATE="no"
fi

## CHECK ON INSERTED TARGET ##
while IFS= read -r line; do
  if [[ "${TARGET}-${BACKEND}" == "${line}" ]]; then
    found="true"
    break
  fi
done <"${ENVIRONMENTS_LIST}"
if [ "${found}" != "true" ]; then
  echo "ERROR: Environment doesn't exist!"
  echo "Valid environments:"
  cat "${environment_dir}"/environments.txt
  echo "You can change default environment using /scripts/change_environment.sh script"
  echo "You can specify a new target using -t <target> -b <backend> options"
  if [ "${CREATE}" == "create" ]; then
    echo "Do you want to add ${TARGET}-${BACKEND} as a new environment? (y/n)"
    read -r ANSWER
    if [[ ${ANSWER} == "y" ]]; then
      bash "${script_dir}"/common/create_new_target.sh -t "${TARGET}" -b "${BACKEND}"
      echo "Please check the newly created environment configuration and run again the script."
    else
      echo "Skipping target creation."
    fi
  fi
  exit 1
fi
echo "TARGET: ${TARGET}"
echo "BACKEND: ${BACKEND}"

# Define Target Architecture (to generalize ...)
ARCH="arm64"

## Environment DIRECTORIES ##
target_dir=${environment_dir}/${TARGET}
backend_dir=${target_dir}/${BACKEND}
# INSTALL
install_dir=${backend_dir}/install
# OUTPUT
output_dir=${backend_dir}/output
hardware_dir=${output_dir}/hardware
boot_dir=${output_dir}/boot
boot_sources_dir=${boot_dir}/sources
rootfs_dir=${output_dir}/rootfs
# BUILD
build_dir=${backend_dir}/build
# CUSTOM BUILD
custom_build_dir=${backend_dir}/custom_build
# CONFIGURATIONS
environment_cfgs_dir=${backend_dir}/environment_cfgs


#### COMPONENTS DIRECTORIES ####
# QEMU
qemu_dir=${build_dir}/qemu
qemu_bin_dir=${qemu_dir}/build/aarch64-softmmu
# ATF
atf_dir=${build_dir}/arm-trusted-firmware
atf_image_dir=${atf_dir}/build/zynqmp/release/bl31
# LINUX
linux_dir=${build_dir}/linux
image_dir=${linux_dir}/arch/${ARCH}/boot
linux_config_dir=${linux_dir}/arch/${ARCH}/configs
custom_linux_dir=${custom_build_dir}/linux
custom_linux_config_dir=${custom_linux_dir}/arch/${ARCH}/configs
custom_linux_patch_dir=${custom_linux_dir}/patch
# BUILDROOT
buildroot_dir=${build_dir}/buildroot
rootfs_image_dir=${buildroot_dir}/output/images
buildroot_config_dir=${buildroot_dir}/configs
aarch64_buildroot_linux_gnu_dir=${buildroot_dir}/output/host/bin
custom_buildroot_dir=${custom_build_dir}/buildroot
custom_buildroot_config_dir=${custom_buildroot_dir}/configs
custom_buildroot_patch_dir=${custom_buildroot_dir}/patch
# JAILHOUSE
jailhouse_dir=${build_dir}/jailhouse
jailhouse_config_dir=${jailhouse_dir}/include/jailhouse
jailhouse_cell_dir=${jailhouse_dir}/configs/${ARCH}
custom_jailhouse_dir=${custom_build_dir}/jailhouse
custom_jailhouse_config_dir=${custom_jailhouse_dir}/include/jailhouse
custom_jailhouse_patch_dir=${custom_jailhouse_dir}/patch
custom_jailhouse_cell_dir=${custom_jailhouse_dir}/configs/${ARCH}
# BOOTGEN
bootgen_dir=${build_dir}/bootgen

## DEFCONFIGS ##
# JAILHOUSE
defconfig_buildroot_name=${BACKEND}_${TARGET}_buildroot_defconfig
defconfig_linux_name=${BACKEND}_${TARGET}_kernel_defconfig

## SETUP THE SPECIFIC TARGET ##
source ${environment_cfgs_dir}/${TARGET}-${BACKEND}.sh
