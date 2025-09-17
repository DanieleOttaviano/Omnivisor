#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Compile U-Boot for a target/backend

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

[[ -z "$TARGET" || -z "$BACKEND" ]] && { error "Both target and backend required."; usage; }

source "$script_dir/common/set_environment.sh" "$TARGET" "$BACKEND"

# Adjust environment
[[ "$ARCH" == "arm64" ]] && export ARCH="aarch64"
export CROSS_COMPILE="${CROSS_COMPILE}"

PLATFORM="xilinx_zynqmp_virt_defconfig"

#make -C "${uboot_dir}" ${PLATFORM} 
# IF zcu102 (sudo apt-et install libgnutls28-dev)
# export BL31=/home/environment/zcu102/jailhouse/output/boot/bl31.elf
#echo 'CONFIG_BOOTCOMMAND="if dhcp ${scriptaddr} kria/boot.scr; then source ${scriptaddr}; fi"' >> ${uboot_dir}/.config
if ! make -C "$uboot_dir" -j"$(nproc)"; then
  error "The make command failed during U-Boot compilation."
  exit 1
fi

unset ARCH CROSS_COMPILE

success "U-Boot has been successfully compiled"
cp "$uboot_dir/u-boot.elf" "$boot_dir/"