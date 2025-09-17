#!/bin/bash

ENV_FILE="${environment_dir}/.build_env"

if [[ -n "${TARGET:-}" && -n "${BACKEND:-}" ]]; then
  # Save both values to ENV_FILE
  cat > "$ENV_FILE" <<EOF
TARGET=$TARGET
BACKEND=$BACKEND
EOF
elif [[ -n "${TARGET:-}" || -n "${BACKEND:-}" ]]; then
  error "Both TARGET and BACKEND must be defined together!"
  error "Got: TARGET='${TARGET:-unset}', BACKEND='${BACKEND:-unset}'"
  exit 1
elif [[ -f "$ENV_FILE" ]]; then
  source "$ENV_FILE"
else
  error "TARGET and BACKEND must be set!"
  exit 1
fi

## --- CHECK SELECTED TARGET/BACKEND ---
if ! grep -qx "${TARGET}-${BACKEND}" "${ENVIRONMENTS_LIST}"; then
  error "Environment '${TARGET}-${BACKEND}' doesn't exist!"
  warn "Valid environments are:"
  cat "${ENVIRONMENTS_LIST}"
  exit 1
fi

success "Environment '${TARGET}-${BACKEND}' selected."

# Define Target Architecture (default: arm64)
ARCH="arm64"

## --- ENVIRONMENT DIRECTORIES ---
environment_cfgs_dir=${environment_dir}/../environment_cfgs
target_dir=${environment_dir}/${TARGET}
backend_dir=${target_dir}/${BACKEND}

# Boot sources & install
boot_sources_dir=${backend_dir}/boot_sources
install_dir=${backend_dir}/install

# Output directories
output_dir=${backend_dir}/output
hardware_dir=${output_dir}/hardware
boot_dir=${output_dir}/boot
rootfs_dir=${output_dir}/rootfs

# Build directories
build_dir=${backend_dir}/build
custom_build_dir=${backend_dir}/custom_build

# QEMU
qemu_dir=${build_dir}/qemu
qemu_bin_dir=${qemu_dir}/build/aarch64-softmmu

# ATF
atf_dir=${build_dir}/arm-trusted-firmware
atf_image_dir=${atf_dir}/build/zynqmp/release/bl31

# U-Boot
uboot_dir=${build_dir}/u-boot
uboot_image_dir=${uboot_dir}
uboot_config_dir=${uboot_dir}/configs
custom_uboot_dir=${custom_build_dir}/u-boot
custom_uboot_config_dir=${custom_uboot_dir}/configs
custom_uboot_patch_dir=${custom_uboot_dir}/patch

# Linux
linux_dir=${build_dir}/linux
image_dir=${linux_dir}/arch/${ARCH}/boot
linux_config_dir=${linux_dir}/arch/${ARCH}/configs
custom_linux_dir=${custom_build_dir}/linux
custom_linux_config_dir=${custom_linux_dir}/arch/${ARCH}/configs
custom_linux_patch_dir=${custom_linux_dir}/patch

# Buildroot
buildroot_dir=${build_dir}/buildroot
rootfs_image_dir=${buildroot_dir}/output/images
buildroot_config_dir=${buildroot_dir}/configs
busybox_config_dir=${buildroot_dir}/output/build/busybox-1.36.1
aarch64_buildroot_linux_gnu_dir=${buildroot_dir}/output/host/bin
custom_buildroot_dir=${custom_build_dir}/buildroot
custom_buildroot_config_dir=${custom_buildroot_dir}/configs
custom_buildroot_patch_dir=${custom_buildroot_dir}/patch
custom_busybox_config_dir=${custom_buildroot_dir}/busybox_configs

# Jailhouse
jailhouse_dir=${build_dir}/jailhouse
jailhouse_config_dir=${jailhouse_dir}/include/jailhouse
jailhouse_cell_dir=${jailhouse_dir}/configs/${ARCH}
jailhouse_inmate_demos_dir=${jailhouse_dir}/inmates/demos
custom_jailhouse_dir=${custom_build_dir}/jailhouse
custom_jailhouse_config_dir=${custom_jailhouse_dir}/include/jailhouse
custom_jailhouse_patch_dir=${custom_jailhouse_dir}/patch
custom_jailhouse_cell_dir=${custom_jailhouse_dir}/configs/${ARCH}
custom_jailhouse_inmate_demos_dir=${custom_jailhouse_dir}/inmates/demos

# Bootgen
bootgen_dir=${build_dir}/bootgen

## --- SETUP SPECIFIC TARGET ---
source "${environment_cfgs_dir}/${TARGET}-${BACKEND}.sh"

## --- Boot Sources Configurations ---
bootcmd_file=${BOOTCMD_CONFIG:+boot_${BOOTCMD_CONFIG}.cmd}
bootcmd_file=${bootcmd_file:-boot.cmd}

dts_file=${DTS_CONFIG:+system_${DTS_CONFIG}.dts}
dts_file=${dts_file:-system.dts}

## --- DEFCONFIGS ---
defconfig_buildroot_name=${BACKEND}_${TARGET}${BUILDROOT_CONFIG:+_${BUILDROOT_CONFIG}}_buildroot_defconfig
defconfig_busybox_name=${BACKEND}_${TARGET}${BUSYBOX_CONFIG:+_${BUSYBOX_CONFIG}}_busybox_defconfig
defconfig_linux_name=${BACKEND}_${TARGET}${LINUX_CONFIG:+_${LINUX_CONFIG}}_kernel_defconfig
defconfig_uboot_name=${BACKEND}_${TARGET}${UBOOT_CONFIG:+_${UBOOT_CONFIG}}_u-boot_defconfig
defconfig_jailhouse_name=${JAILHOUSE_CONFIG:+config_${JAILHOUSE_CONFIG}.h}
defconfig_jailhouse_name=${defconfig_jailhouse_name:-config.h}