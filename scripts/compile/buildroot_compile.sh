#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Compile Buildroot root filesystem for target/backend

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

# Check tools
for tool in make tar; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    error "Required tool '$tool' not found in PATH."
    exit 1
  fi
done

# Compile buildroot
info "Compiling Buildroot in $buildroot_dir ..."
if make -C "$buildroot_dir" -j"$(nproc)"; then
  success "BUILDROOT has been successfully compiled."
else
  error "Buildroot compilation failed."
  exit 1
fi

# Copy rootfs image into rootfs directory
info "Copying rootfs images ..."
cp "$rootfs_image_dir"/* "$rootfs_dir"/

# Export rootfs.tar into target directory
target_rootfs_dir="$rootfs_dir/$TARGET"
mkdir -p "$target_rootfs_dir"

if [[ -z "$(ls -A "$target_rootfs_dir")" ]]; then
  info "Extracting rootfs.tar into $target_rootfs_dir"
  tar -xf "$rootfs_dir/rootfs.tar" -C "$target_rootfs_dir"
else
  warn "Directory $target_rootfs_dir is not empty."
  backup_dir="$rootfs_dir/OLD_${TARGET}_$(date +%Y%m%d_%H%M%S)"
  warn "Moving existing content to $backup_dir"
  mv "$target_rootfs_dir" "$backup_dir"
  mkdir -p "$target_rootfs_dir"
  info "Extracting rootfs.tar into fresh $target_rootfs_dir"
  tar -xf "$rootfs_dir/rootfs.tar" -C "$target_rootfs_dir"
fi

success "Buildroot rootfs prepared for target: $TARGET"

