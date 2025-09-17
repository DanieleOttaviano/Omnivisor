#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Update the Linux kernel configuration

Usage:
  $0 -t <target> -b <backend> [-c <config_file>] [-m]

Options:
  -t, --target <val>     Target board/platform
  -b, --backend <val>    Backend (e.g. jailhouse)
  -c, --config <file>    Use this config file instead of the default
  -m, --menuconfig       Launch menuconfig after update
  -h, --help             Show this help message
EOF
  exit 1
}

# Directories & helpers
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "$current_dir")
source "$script_dir/common/common.sh"

# Defaults
MENUCFG=0
CONFIG_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--menuconfig) MENUCFG=1; shift ;;
    -t|--target) TARGET="$2"; shift 2 ;;
    -b|--backend) BACKEND="$2"; shift 2 ;;
    -c|--config) CONFIG_FILE="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) error "Unknown option: $1"; usage ;;
  esac
done

echo TARGET="$TARGET"
echo BACKEND="$BACKEND"

# Load environment
source "$script_dir/common/set_environment.sh" "$TARGET" "$BACKEND"

# Confirm with user
read -r -p "Do you really want to update ${defconfig_linux_name}? (your current configs will be lost) [y/N]: " UPDATE

if [[ "${UPDATE,,}" =~ ^y(es)?$ ]]; then
  # Select config file
  CONFIG_TO_COPY="${CONFIG_FILE:-$defconfig_linux_name}"

  if [[ ! -f "$custom_linux_config_dir/$CONFIG_TO_COPY" ]]; then
    error "Specified config file '$CONFIG_TO_COPY' not found in '$custom_linux_config_dir'"
    exit 1
  fi

  warn "Overwriting Linux config with: $CONFIG_TO_COPY"

  # Copy config into kernel source
  cp "$custom_linux_config_dir/$CONFIG_TO_COPY" "$linux_config_dir/$defconfig_linux_name"

  # Configure Linux
  if ! make -C "$linux_dir" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" "$defconfig_linux_name"; then
    error "The make command failed while configuring the Linux kernel."
    exit 1
  fi
  success "Linux kernel has been successfully configured."

  # Launch menuconfig if requested
  if [[ $MENUCFG -eq 1 ]]; then
    make -C "$linux_dir" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" menuconfig
  else
    warn "Skipping menuconfig."
  fi
else
  warn "Skipping update."
fi
