# Kernel & DTB filenames
k=Image
d=system.dtb

# Bootargs for rootfs on MMC
# setenv bootargs "earlycon clk_ignore_unused earlyprintk root=/dev/mmcblk0 rw rootwait"
# Bootargs for 9p rootfs
setenv bootargs "earlycon clk_ignore_unused earlyprintk root=root rootfstype=9p rootflags=trans=virtio,version=9p2000.L,msize=512000,cache=loose rw"

# IP config for TFTP if needed
setenv ipaddr 10.0.2.15
setenv serverip 10.0.2.2

# Load kernel and DTB over TFTP (optional)
tftpboot 0x200000 ${k}
tftpboot 0x20000000 ${d}

# Set FDT
fdt addr 0x20000000
fdt resize 0x10000

# Boot kernel with DTB (no initrd needed)
booti 0x200000 - 0x20000000
