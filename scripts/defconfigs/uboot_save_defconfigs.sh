#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Save the U-Boot configuration

Usage:
  $0 -t <target> -b <backend>

Options:
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

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target) TARGET="$2"; shift 2 ;;
    -b|--backend) BACKEND="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) error "Unknown option: $1"; usage ;;
  esac
done

# Load environment
source "$script_dir/common/set_environment.sh" "$TARGET" "$BACKEND"

read -r -p "Do you really want to save ${defconfig_uboot_name}? (it will overwrite if it exists) [y/N]: " SAVE

if [[ "${SAVE,,}" =~ ^y(es)?$ ]]; then
  warn "Overwriting existing U-Boot defconfig: ${defconfig_uboot_name}"

  # Backup old defconfig if present
  if [[ -f "$custom_uboot_config_dir/$defconfig_uboot_name" ]]; then
    cp "$custom_uboot_config_dir/$defconfig_uboot_name" \
       "$custom_uboot_config_dir/${defconfig_uboot_name}_old"
  fi

  # Export variables for U-Boot build
  [[ "$ARCH" == "arm64" ]] && export ARCH="aarch64"
  export CROSS_COMPILE="$CROSS_COMPILE"

  # Save U-Boot defconfig
  if ! make -C "$uboot_dir" savedefconfig; then
    error "The make command failed during the savedefconfig of U-Boot."
    exit 1
  fi

  # Clean up environment
  unset ARCH CROSS_COMPILE

  success "U-Boot defconfig has been successfully saved"

  cp "$uboot_dir/defconfig" "$uboot_config_dir/$defconfig_uboot_name"
  cp "$uboot_config_dir/$defconfig_uboot_name" "$custom_uboot_config_dir/"
else
  warn "Save operation canceled."
fi
