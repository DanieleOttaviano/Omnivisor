#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Update U-Boot configuration for a target/backend

Usage:
  $0 -t <target> -b <backend> [-m]

Options:
  -t, --target <target>     Target board/platform
  -b, --backend <backend>   Backend (e.g. jailhouse)
  -m, --menuconfig          Launch menuconfig after update
  -h, --help                Show this help message
EOF
  exit 1
}

current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "$current_dir")
source "$script_dir/common/common.sh"

MENUCFG=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--menuconfig) MENUCFG=1; shift ;;
    -t|--target) TARGET="$2"; shift 2 ;;
    -b|--backend) BACKEND="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) error "Unknown option: $1"; usage ;;
  esac
done

source "$script_dir/common/set_environment.sh" "$TARGET" "$BACKEND"

read -r -p "Do you really want to update ${defconfig_uboot_name}? (your current configs will be lost) (y/N): " REPLY
if [[ "${REPLY,,}" =~ ^y(es)?$ ]]; then
  cp "$custom_uboot_config_dir/$defconfig_uboot_name" "$uboot_config_dir/$defconfig_uboot_name"

  [[ "$ARCH" == "arm64" ]] && export ARCH="aarch64"
  export CROSS_COMPILE="$CROSS_COMPILE"

  if ! make -C "$uboot_dir" "$defconfig_uboot_name"; then
    error "The make command failed in configuring U-Boot."
    exit 1
  fi

  success "U-Boot has been successfully configured"

  [[ $MENUCFG -eq 1 ]] && make -C "$uboot_dir" menuconfig

  unset ARCH CROSS_COMPILE
else
  warn "Skipping Update."
fi
