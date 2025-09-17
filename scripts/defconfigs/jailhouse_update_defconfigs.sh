#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Update Jailhouse configuration for the selected environment

Usage:
  $0 [options]

Options:
  -m, --menuconfig     Attempt to launch menuconfig after update (not supported)
  -t, --target <val>   Target board/platform
  -b, --backend <val>  Backend (e.g. jailhouse)
  -h, --help           Show this help message
EOF
  exit 1
}

# Directories & helpers
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "$current_dir")
source "$script_dir/common/common.sh"

MENUCFG=0

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--menuconfig) MENUCFG=1; shift ;;
    -t|--target)     TARGET="$2"; shift 2 ;;
    -b|--backend)    BACKEND="$2"; shift 2 ;;
    -h|--help)       usage ;;
    *) error "Unknown option: $1"; usage ;;
  esac
done

# Load environment
source "$script_dir/common/set_environment.sh" "$TARGET" "$BACKEND"

# Confirm update
read -r -p "Do you really want to update ${defconfig_jailhouse_name}? (your current configs will be lost) [y/N]: " UPDATE
if [[ ! "${UPDATE,,}" =~ ^y(es)?$ ]]; then
  warn "Cancelled. Jailhouse config not updated."
  exit 0
fi

# Perform update
if [[ -f "$custom_jailhouse_config_dir/$defconfig_jailhouse_name" ]]; then
  cp "$custom_jailhouse_config_dir/$defconfig_jailhouse_name" "$jailhouse_config_dir/config.h"
  success "Jailhouse config updated: ${defconfig_jailhouse_name} -> config.h"
else
  error "Custom config not found: $custom_jailhouse_config_dir/$defconfig_jailhouse_name"
  exit 1
fi

# Menuconfig handling
if [[ $MENUCFG -eq 1 ]]; then
  warn "menuconfig is not available for Jailhouse."
else
  info "Skipping menuconfig."
fi
