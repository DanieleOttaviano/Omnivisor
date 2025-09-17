#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Save the Jailhouse configuration of the selected environment

Usage:
  $0 [options]

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

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target)  TARGET="$2"; shift 2 ;;
    -b|--backend) BACKEND="$2"; shift 2 ;;
    -h|--help)    usage ;;
    *) error "Unknown option: $1"; usage ;;
  esac
done

# Load environment
source "$script_dir/common/set_environment.sh" "$TARGET" "$BACKEND"

# Confirm save
read -r -p "Do you really want to save ${defconfig_jailhouse_name}? (this will overwrite existing) [y/N]: " SAVE
if [[ ! "${SAVE,,}" =~ ^y(es)?$ ]]; then
  warn "Cancelled. Jailhouse config not saved."
  exit 0
fi

# Backup old config if it exists
if [[ -f "$custom_jailhouse_config_dir/$defconfig_jailhouse_name" ]]; then
  cp "$custom_jailhouse_config_dir/$defconfig_jailhouse_name" \
     "$custom_jailhouse_config_dir/${defconfig_jailhouse_name}_old.h"
  info "Existing config backed up as ${defconfig_jailhouse_name}_old.h"
fi

# Save new config
if ! cp "$jailhouse_config_dir/config.h" "$custom_jailhouse_config_dir/$defconfig_jailhouse_name"; then
  error "config.h not found in $jailhouse_config_dir"
  exit 1
fi

success "Jailhouse config saved as $defconfig_jailhouse_name"
