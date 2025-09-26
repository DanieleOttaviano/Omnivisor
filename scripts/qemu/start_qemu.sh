#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Start QEMU emulation for a target/backend

Usage:
  $0 -t <target> -b <backend>

Options:
  -t, --target <target>     Target board/platform (only 'qemu' supported)
  -b, --backend <backend>   Backend (e.g. zcu102)
  -h, --help                Show this help message
EOF
  exit 1
}

current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "$current_dir")
source "$script_dir/common/common.sh"

# -------------------
# Parse arguments
# -------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target) TARGET="$2"; shift 2 ;;
    -b|--backend) BACKEND="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) error "Unknown option: $1"; usage ;;
  esac
done

source "$script_dir/common/set_environment.sh" "$TARGET" "$BACKEND"

if [[ "$TARGET" != "qemu" ]]; then
  error "Only 'qemu' target is supported."
  exit 1
fi


TMPDIR=$(mktemp -d /tmp/tmpXXXXXXX)

echo "Launching QEMU for ZCU102..."
echo "  Temp dir: $TMPDIR"

# -------------------
# Start PMU (MicroBlaze)
# -------------------
"$qemu_build/microblazeel-softmmu/qemu-system-microblazeel" \
  -M microblaze-fdt \
  -serial mon:stdio \
  -serial /dev/null \
  -display none \
  -kernel "$boot_dir/pmu_rom_qemu_sha3.elf" \
  -device loader,file="$boot_dir/pmufw.elf" \
  -hw-dtb "$boot_dir/zynqmp-qemu-multiarch-pmu.dtb" \
  -machine-path "$TMPDIR" \
  -device loader,addr=0xfd1a0074,data=0x1011003,data-len=4 \
  -device loader,addr=0xfd1a007C,data=0x1010f03,data-len=4 &


# -------------------
# Start ARM system
# -------------------
exec "$qemu_build/aarch64-softmmu/qemu-system-aarch64" \
  -M arm-generic-fdt \
  -serial mon:stdio \
  -serial tcp:localhost:4321,server,nowait \
  -display none \
  -device loader,file="$boot_dir/u-boot.elf" \
  -device loader,file="$boot_dir/bl31.elf",cpu-num=0 \
  -device loader,file="$boot_dir/boot.scr",addr=0x20000000,force-raw=on \
  -device loader,file="$boot_dir/system.dtb",addr=0x100000,force-raw=on \
  -drive if=sd,format=raw,index=1,file="$rootfs_dir/rootfs.ext4" \
  -global xlnx,zynqmp-boot.cpu-num=0 \
  -global xlnx,zynqmp-boot.use-pmufw=true \
  -global xlnx,zynqmp-boot.drive=pmu-cfg \
  -blockdev node-name=pmu-cfg,filename="$boot_dir/pmu-conf.bin",driver=file \
  -hw-dtb "$boot_dir/zynqmp-qemu-multiarch-arm.dtb" \
  -gdb tcp:localhost:9000 \
  -netdev user,id=eth3,tftp=$boot_dir,hostfwd=tcp::2222-:22 \
  -net nic -net nic -net nic -net nic,netdev=eth3 \
  -machine-path "$TMPDIR" \
  -m 4G