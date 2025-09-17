#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Update Buildroot (and optionally BusyBox) configuration

Usage:
  $0 [options]

Options:
  -t, --target <val>    Target board/platform
  -b, --backend <val>   Backend (e.g. jailhouse)
  -m, --menuconfig      Launch menuconfig after update
  -x, --busybox         Update BusyBox config as well
  -h, --help            Show this help message
EOF
  exit 1
}

# Directories & helpers
curr_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "$curr_dir")
source "$script_dir/common/common.sh"

MENUCFG=0
UPDATE_BUSYBOX="n"

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target)   TARGET="$2"; shift 2 ;;
    -b|--backend)  BACKEND="$2"; shift 2 ;;
    -m|--menuconfig) MENUCFG=1; shift ;;
    -x|--busybox)  UPDATE_BUSYBOX="y"; shift ;;
    -h|--help)     usage ;;
    *) error "Unknown option: $1"; usage ;;
  esac
done

# Load environment
source "$script_dir/common/set_environment.sh" "$TARGET" "$BACKEND"

# Confirm update
read -r -p "Do you really want to update ${defconfig_buildroot_name}? (your current configs will be lost) (y/n): " UPDATE

if [[ "${UPDATE,,}" =~ ^y(es)?$ ]]; then
  info "Updating Buildroot config: ${defconfig_buildroot_name}"

  # Adjust overlay directory in config
  if [[ -f "$custom_buildroot_config_dir/$defconfig_buildroot_name" ]]; then
    sed -i "/^BR2_ROOTFS_OVERLAY=/cBR2_ROOTFS_OVERLAY=\"${install_dir}\"" \
      "$custom_buildroot_config_dir/$defconfig_buildroot_name"
  else
    error "Custom Buildroot config $custom_buildroot_config_dir/$defconfig_buildroot_name not found."
    exit 1
  fi

  # Copy config into buildroot tree
  cp "$custom_buildroot_config_dir/$defconfig_buildroot_name" \
     "$buildroot_config_dir/$defconfig_buildroot_name"

  # Run defconfig
  if make -C "$buildroot_dir" "$defconfig_buildroot_name"; then
    success "Buildroot has been successfully configured."
  else
    error "Buildroot configuration failed."
    exit 1
  fi

  # Update BusyBox if requested
  if [[ "${UPDATE_BUSYBOX,,}" =~ ^y(es)?$ ]]; then
    info "Updating BusyBox config: ${defconfig_busybox_name}"

    if [[ -f "$custom_busybox_config_dir/$defconfig_busybox_name" ]]; then
      cp "$custom_busybox_config_dir/$defconfig_busybox_name" "$busybox_config_dir/.config"
      cp "$custom_busybox_config_dir/$defconfig_busybox_name" "$buildroot_dir/package/busybox/busybox.config"
      success "BusyBox has been successfully configured."
    else
      error "Custom BusyBox config $custom_busybox_config_dir/$defconfig_busybox_name not found."
    fi
  fi

  # Optionally launch menuconfig
  if [[ $MENUCFG -eq 1 ]]; then
    make -C "$buildroot_dir" menuconfig
  else
    info "Skipping menuconfig."
  fi
else
  info "Skipping update."
fi
