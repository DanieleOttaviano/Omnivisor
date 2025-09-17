#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Compile and install the Jailhouse hypervisor

Usage:
  $0 [options]

Options:
  -r, --rcpu <core>       Compile RCPU demo (all, armr5, riscv32)
  -B, --bench <name>      Benchmark name for Taclebench demo
  -n, --nfs-install       Install Jailhouse in the NFS directory
  -i, --overlay-install   Install Jailhouse in the overlay directory
  -t, --target <val>      Target board/platform
  -b, --backend <val>     Backend (e.g. jailhouse)
  -h, --help              Show this help message
EOF
  exit 1
}

# Directories & helpers
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "$current_dir")
source "$script_dir/common/common.sh"

# Defaults
INSTALL_OVERLAY="n"
INSTALL_NFS="n"
RCPU_COMPILE="n"
REMOTE_COMPILE_R5="arm-none-eabi-"
REMOTE_COMPILE_RV32="riscv32-unknown-elf-"
BENCHNAME=""
RCPUs=""
CORE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--rcpu)    RCPU_COMPILE="y"; RCPUs="$2"; shift 2 ;;
    -B|--bench)   BENCHNAME="$2"; shift 2 ;;
    -n|--nfs-install) INSTALL_NFS="y"; shift ;;
    -i|--overlay-install) INSTALL_OVERLAY="y"; shift ;;
    -t|--target)  TARGET="$2"; shift 2 ;;
    -b|--backend) BACKEND="$2"; shift 2 ;;
    -h|--help)    usage ;;
    *) error "Unknown option: $1"; usage ;;
  esac
done

# Load environment
source "$script_dir/common/set_environment.sh" "$TARGET" "$BACKEND"

# Always copy configs and inmates before building
cp -r "$custom_jailhouse_cell_dir"/* "$jailhouse_cell_dir"
cp -r "$custom_jailhouse_inmate_demos_dir"/* "$jailhouse_inmate_demos_dir"

# Compile Jailhouse
if ! make -C "$jailhouse_dir" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" KDIR="$linux_dir"; then
  error "Failed to compile Jailhouse"
  exit 1
fi
success "Jailhouse compiled successfully."

# Compile RCPU demo
if [[ "$RCPU_COMPILE" == "y" ]]; then
  case "$RCPUs" in
    all) CORE="" ;;
    armr5) CORE="_armr5" ;;
    riscv32) CORE="_riscv32" ;;
    *) error "Invalid remote core: $RCPUs (use: all, armr5, riscv32)"; exit 1 ;;
  esac

  make -C "$jailhouse_dir" clean-remote$CORE REMOTE_COMPILE="$REMOTE_COMPILE_R5"
  if ! make -C "$jailhouse_dir" remote$CORE REMOTE_COMPILE="$REMOTE_COMPILE_R5" BENCH="$BENCHNAME"; then
    error "Failed to compile Jailhouse RCPU demo ($RCPUs)"
    exit 1
  fi
  success "Jailhouse RCPU demo ($RCPUs) compiled successfully."
else
  info "Skipping RCPU demo compilation."
fi

# Install Jailhouse in NFS root
if [[ "$INSTALL_NFS" == "y" ]]; then
  if ! make -C "$jailhouse_dir" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" \
    KDIR="$linux_dir" DESTDIR="$rootfs_dir/$TARGET" install; then
    error "Failed to install Jailhouse in NFS directory"
    exit 1
  fi

  cp -rf "$jailhouse_dir" "$rootfs_dir/$TARGET/root/" >/dev/null 2>&1

  [[ "$RCPUs" == "all" || "$RCPUs" == "armr5" ]] && \
    cp "$jailhouse_dir"/inmates/demos/armr5/src*/*.elf "$rootfs_dir/$TARGET/lib/firmware/"
  [[ "$RCPUs" == "all" || "$RCPUs" == "riscv32" ]] && \
    cp "$jailhouse_dir"/inmates/demos/riscv/src*/*.elf "$rootfs_dir/$TARGET/lib/firmware/"

  # Fix pyjailhouse install path
  info "Relocating pyjailhouse..."
  pyjailhouse_path=$(find "$rootfs_dir/$TARGET/usr/local/lib" -type d -name "pyjailhouse")
  cp -r "$pyjailhouse_path" "$rootfs_dir/$TARGET/usr/local/libexec/jailhouse"

  success "Jailhouse installed in NFS directory."
else
  info "Skipping NFS installation."
fi

# Install Jailhouse in overlay
if [[ "$INSTALL_OVERLAY" == "y" ]]; then
  if ! make -C "$jailhouse_dir" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" \
    KDIR="$linux_dir" DESTDIR="$project_dir/install" install; then
    error "Failed to install Jailhouse in overlay"
    exit 1
  fi

  # Remote core demos
  [[ "$RCPUs" == "all" || "$RCPUs" == "armr5" ]] && \
    cp "$jailhouse_dir"/inmates/demos/armr5/src*/*.elf "$install_dir/lib/firmware/"
  [[ "$RCPUs" == "all" || "$RCPUs" == "riscv32" ]] && \
    cp "$jailhouse_dir"/inmates/demos/riscv/src*/*.elf "$install_dir/lib/firmware/"

  # Overlay structure
  mkdir -p "$install_dir/root/inmates/demos/linux"
  mkdir -p "$install_dir/root/configs/dts"
  cp "$jailhouse_dir"/configs/arm64/*.cell "$install_dir/root/configs"
  cp "$jailhouse_dir"/configs/arm64/dts/*.dtb "$install_dir/root/configs/dts"
  cp "$jailhouse_dir"/inmates/demos/arm64/*.bin "$install_dir/root/inmates/demos"

  # Fix pyjailhouse
  if [[ -d "$install_dir/usr/local/libexec/jailhouse/pyjailhouse" ]]; then
    success "pyjailhouse already in place."
  else
    info "Relocating pyjailhouse..."
    pyjailhouse_path=$(find "$install_dir" -type d -name "pyjailhouse")
    mv "$pyjailhouse_path" "$install_dir/usr/local/libexec/jailhouse"
  fi

  success "Jailhouse installed in overlay directory."
else
  info "Skipping overlay installation."
fi
