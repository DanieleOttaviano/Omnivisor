#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Compile QEMU for a target/backend

Usage:
  $0 -t <target> -b <backend>

Options:
  -t, --target <target>     Target board/platform
  -b, --backend <backend>   Backend (e.g. jailhouse)
  -h, --help                Show this help message
EOF
  exit 1
}

current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "$current_dir")
source "$script_dir/common/common.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target) TARGET="$2"; shift 2 ;;
    -b|--backend) BACKEND="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) error "Unknown option: $1"; usage ;;
  esac
done

source "$script_dir/common/set_environment.sh" "$TARGET" "$BACKEND"

cd "$qemu_dir" || { error "QEMU directory not found: $qemu_dir"; exit 1; }

# -------------------
# Configure & Build
# -------------------
CONFIG_FLAGS=(
  --target-list="aarch64-softmmu,microblazeel-softmmu,riscv32-softmmu"
  --enable-fdt
  --enable-slirp
  --disable-kvm
  --disable-xen
  --enable-gcrypt
)

echo "Configuring QEMU with:"
printf '  %s\n' "${CONFIG_FLAGS[@]}"

if ! ./configure "${CONFIG_FLAGS[@]}"; then
  error "QEMU configure failed."
  exit 1
fi

if ! make -j"$(nproc)"; then
  error "The make command failed during QEMU compilation."
  exit 1
fi

success "QEMU has been successfully compiled"
