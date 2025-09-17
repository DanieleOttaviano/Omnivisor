#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Compile ARM Trusted Firmware for a target/backend

Usage:
  $0 -t <target> -b <backend>

Options:
  -t, --target <target>     Target board/platform
  -b, --backend <backend>   Backend (e.g. jailhouse)
  -h, --help                Show this help message
EOF
  exit 1
}

# Directories & helpers
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "$current_dir")
source "$script_dir/common/common.sh"

PLATFORM="zynqmp"

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

# Compile ATF
if ! make -C "$atf_dir" CROSS_COMPILE="$CROSS_COMPILE" PLAT="$PLATFORM" bl31 -j"$(nproc)"; then
  error "The make command failed during the compilation of ATF."
  exit 1
fi

success "ATF has been successfully compiled"

# Copy output to boot directory
cp "$atf_image_dir/bl31.elf" "$boot_dir/"
