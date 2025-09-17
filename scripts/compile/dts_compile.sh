#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Compile device tree for the specified target/backend

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
curr_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "$curr_dir")
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

# Ensure dtc is available
if ! command -v dtc >/dev/null 2>&1; then
  error "dtc not found. Please install device-tree-compiler."
  exit 1
fi

# Compile device tree
info "Compiling device tree: $dts_file -> $boot_dir/system.dtb"
dtc -O dtb -o "$boot_dir/system.dtb" "$boot_sources_dir/$dts_file"

if [[ $? -eq 0 ]]; then
  success "Device tree compiled successfully."
else
  error "Device tree compilation failed."
  exit 1
fi
