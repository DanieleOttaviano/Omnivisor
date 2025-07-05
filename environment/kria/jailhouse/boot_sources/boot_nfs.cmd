# boot.cmd --U-boot script for Kria boards
#
# 2024-03-23, azuepke: initial
# 2024-10-07, dottavia: nfs
#
# Generate boot.scr:
#   mkimage -c none -A arm -T script -d boot.cmd boot.scr
#
# Start network download from U-boot:
#   dhcp ; tftpboot ${scriptaddr} kria/boot.scr ; source ${scriptaddr}
# 
# Start Ubuntu from SD:
# run distro_bootcmd
#
# Extract the files from the Ubuntu image.fit
#   dumpimage -T flat_dt -l image.fit
#   dumpimage -T flat_dt -p 0 image.fit -o kernel.gz
#   dumpimage -T flat_dt -p 1 image.fit -o initrd
#   ...
#
# Kria DTB files:
# - fdt-smk-k26-revA-sck-kr-g-revA.dtb
# - fdt-smk-k26-revA-sck-kr-g-revB.dtb  # <--- our KR260 boards
# - fdt-smk-k26-revA-sck-kv-g-revA.dtb
#  -fdt-smk-k26-revA-sck-kv-g-revB.dtb  # <--- our KV260 boards

# Setup for KR260
k=kria/Image
i=kria/initrd
d=kria/system.dtb

# NFS bootargs
setenv bootargs "earlycon clk_ignore_unused earlyprintk root=/dev/nfs nfsroot=/tftpboot/%s,vers=3,sec=sys ip=dhcp rw rootwait nfsrootdebug console=ttyPS1,115200 loglevel=8"

# download kernel
tftpboot 200000 ${k}

# download and activate DTB
tftpboot 20000000 ${d}
fdt addr 20000000
fdt resize 0x10000

# Start Linux with NFS
booti 200000 - 20000000