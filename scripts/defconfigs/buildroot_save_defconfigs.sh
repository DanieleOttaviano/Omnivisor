#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Save Buildroot (and optionally BusyBox) configuration

Usage:
  $0 [options]

Options:
  -t, --target <val>    Target board/platform
  -b, --backend <val>   Backend (e.g. jailhouse)
  -x, --busybox         Save BusyBox config as well
  -h, --help            Show this help message
EOF
  exit 1
}

# Directories & helpers
curr_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "$curr_dir")
source "$script_dir/common/common.sh"

SAVE_BUSYBOX="n"

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target)  TARGET="$2"; shift 2 ;;
    -b|--backend) BACKEND="$2"; shift 2 ;;
    -x|--busybox) SAVE_BUSYBOX="y"; shift ;;
    -h|--help)    usage ;;
    *) error "Unknown option: $1"; usage ;;
  esac
done

# Load environment
source "$script_dir/common/set_environment.sh" "$TARGET" "$BACKEND"

# Confirm save
read -r -p "Do you really want to save ${defconfig_buildroot_name}? (existing file will be overwritten) (y/n): " SAVE

if [[ "${SAVE,,}" =~ ^y(es)?$ ]]; then
  info "Saving Buildroot config: ${defconfig_buildroot_name}"

  # Save old if exists
  if [[ -f "$custom_buildroot_config_dir/$defconfig_buildroot_name" ]]; then
    cp "$custom_buildroot_config_dir/$defconfig_buildroot_name" \
       "$custom_buildroot_config_dir/${defconfig_buildroot_name}_old"
    warn "Previous Buildroot config saved as ${defconfig_buildroot_name}_old"
  fi

  # Check tool
  if ! command -v make >/dev/null 2>&1; then
    error "make not found in PATH"
    exit 1
  fi

  # Save buildroot defconfig
  if make -C "$buildroot_dir" savedefconfig BR2_DEFCONFIG="$buildroot_config_dir/$defconfig_buildroot_name"; then
    cp "$buildroot_config_dir/$defconfig_buildroot_name" "$custom_buildroot_config_dir/"
    success "Buildroot defconfig saved successfully."
  else
    error "Failed to save Buildroot defconfig."
    exit 1
  fi
else
  info "Skipping Buildroot config save."
fi

# Optionally save BusyBox config
if [[ "${SAVE_BUSYBOX,,}" =~ ^y(es)?$ ]]; then
  info "Saving BusyBox config: ${defconfig_busybox_name}"

  if [[ -f "$custom_busybox_config_dir/$defconfig_busybox_name" ]]; then
    cp "$custom_busybox_config_dir/$defconfig_busybox_name" \
       "$custom_busybox_config_dir/${defconfig_busybox_name}_old"
    warn "Previous BusyBox config saved as ${defconfig_busybox_name}_old"
  fi

  if [[ -f "$busybox_config_dir/.config" ]]; then
    cp "$busybox_config_dir/.config" "$custom_busybox_config_dir/$defconfig_busybox_name"
    success "BusyBox config saved successfully."
  else
    error "BusyBox .config not found in $busybox_config_dir"
  fi
fi
