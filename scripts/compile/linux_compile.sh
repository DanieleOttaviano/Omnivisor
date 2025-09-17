#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Compile the Linux kernel (and optionally modules)

Usage:
  $0 [-m] [-n] -t <target> -b <backend>

Options:
  -m, --modules        Compile kernel modules
  -n, --nfs-install    Install modules in the NFS rootfs (implies -m)
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

COMPILE_MOD="n"
INSTALL_MOD="n"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--modules) COMPILE_MOD="y"; shift ;;
    -n|--nfs-install) INSTALL_MOD="y"; COMPILE_MOD="y"; shift ;;
    -t|--target) TARGET="$2"; shift 2 ;;
    -b|--backend) BACKEND="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) error "Unknown option: $1"; usage ;;
  esac
done

# Load environment
source "$script_dir/common/set_environment.sh" "$TARGET" "$BACKEND"

# --- Compile Kernel ---
if ! yes "" | make -C "$linux_dir" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" Image -j"$(nproc)"; then
  error "The make command failed during the compilation of LINUX KERNEL."
  exit 1
fi
success "LINUX KERNEL has been successfully compiled"

# --- Compile + Install Modules ---
if [[ "$COMPILE_MOD" =~ ^y(es)?$ ]]; then
  if ! make -C "$linux_dir" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" modules -j"$(nproc)"; then
    error "The make command failed during the compilation of LINUX KERNEL MODULES."
    exit 1
  fi
  success "LINUX KERNEL MODULES have been successfully compiled"

  if [[ "$INSTALL_MOD" =~ ^y(es)?$ ]]; then
    INSTALL_MOD_PATH="$rootfs_dir/$TARGET"
  else
    INSTALL_MOD_PATH="$install_dir"
  fi

  if ! make -C "$linux_dir" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" modules_install INSTALL_MOD_PATH="$INSTALL_MOD_PATH"; then
    error "The make command failed during the INSTALLATION of LINUX KERNEL MODULES."
    exit 1
  fi
  success "LINUX KERNEL MODULES have been successfully installed"
else
  warn "Skipped compiling and installing modules."
fi

# Copy kernel Image to boot directory
cp "$image_dir/Image" "$boot_dir/"
