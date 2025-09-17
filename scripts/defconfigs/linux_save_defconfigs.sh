#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Save the Linux kernel configuration

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

read -r -p "Do you really want to save ${defconfig_linux_name}? (it will overwrite if it exists) [y/N]: " SAVE

if [[ "${SAVE,,}" =~ ^y(es)?$ ]]; then
  warn "Overwriting existing Linux defconfig: ${defconfig_linux_name}"

  # Backup old defconfig if present
  if [[ -f "$custom_linux_config_dir/$defconfig_linux_name" ]]; then
    cp "$custom_linux_config_dir/$defconfig_linux_name" \
       "$custom_linux_config_dir/${defconfig_linux_name}_old"
  fi

  # Save Linux defconfig
  if ! make -C "$linux_dir" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" savedefconfig; then
    error "The make command failed during the savedefconfig of Linux."
    exit 1
  fi

  success "Linux defconfig has been successfully saved"

  cp "$linux_dir/defconfig" "$linux_config_dir/$defconfig_linux_name"
  cp "$linux_config_dir/$defconfig_linux_name" "$custom_linux_config_dir/"
else
  warn "Save operation canceled."
fi
