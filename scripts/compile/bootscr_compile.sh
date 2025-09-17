#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Compile bootscr for the specified target/backend

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

# Compile boot script
if [[ "${UBUNTU_ROOTFS}" == "y" ]]; then
  info "Compiling boot.scr.uimg (Ubuntu rootfs detected)..."
  mkimage -c none -A arm64 -T script \
    -d "$boot_sources_dir/boot.script" \
    "$boot_dir/boot.scr.uimg"
else
  info "Compiling boot.scr using $bootcmd_file..."
  mkimage -c none -A arm64 -T script \
    -d "$boot_sources_dir/$bootcmd_file" \
    "$boot_dir/boot.scr"
fi

if [[ $? -eq 0 ]]; then
  success "Boot script compiled successfully."
else
  error "Boot script compilation failed."
  exit 1
fi
