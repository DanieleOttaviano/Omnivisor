#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Compile bootgen and generate BOOT.BIN

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

PLATFORM="zynqmp"

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

# Compile bootgen
info "Compiling BOOTGEN..."
if make -C "$bootgen_dir"; then
  success "BOOTGEN compiled successfully."
else
  error "BOOTGEN compilation failed."
  exit 1
fi

# Generate BOOT.BIN
info "Generating BOOT.BIN for platform: $PLATFORM"
if cd "$boot_dir"; then
  if "$bootgen_dir/bootgen" -arch "$PLATFORM" -image bootgen.bif -w -o BOOT.BIN; then
    success "BOOT.BIN generated successfully in $boot_dir"
  else
    error "Failed to generate BOOT.BIN"
    exit 1
  fi
else
  error "Cannot access boot directory: $boot_dir"
  exit 1
fi
