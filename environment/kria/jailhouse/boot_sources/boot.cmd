# This is a boot script for U-Boot
# Generate boot.scr:
# mkimage -c none -A arm -T script -d boot.cmd.default boot.scr
#
################
## Please change the kernel_offset and kernel_size if the kernel image size more than
## the 100MB and BOOT.BIN size more than the 30MB
## kernel_offset --> is the address of qspi which you want load the kernel image
## kernel_size --> size of the kernel image in hex
###############
imageub_addr=0x10000000
#fdt_addr=0x2A00000
#kernel_addr=0x3000000
kernel_addr=0x00200000
fdt_addr=0x00100000


for boot_target in ${boot_targets};
do
	if test "${boot_target}" = "mmc0" || test "${boot_target}" = "mmc1" ; then
		if test -e ${devtype} ${devnum}:${distro_bootpart} /image.ub; then
			fatload ${devtype} ${devnum}:${distro_bootpart} ${imageub_addr} image.ub;
			bootm ${imageub_addr};
			exit;
		fi
		if test -e ${devtype} ${devnum}:${distro_bootpart} /Image; then
			setenv bootargs "earlycon clk_ignore_unused earlyprintk root=/dev/mmcblk1p2 rw rootwait"
			setenv uenvcmd "fatload mmc 0 0x3000000 Image && fatload mmc 0 0x2A00000 system.dtb && booti 0x3000000 - 0x2A00000"
			setenv bootcmd "run uenvcmd"
			fatload ${devtype} ${devnum}:${distro_bootpart} ${kernel_addr} Image;
			fatload ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr} system.dtb;
			booti ${kernel_addr} - ${fdt_addr};
			exit;
		fi
		booti ${kernel_addr} - ${fdt_addr};
		exit;
	fi
done
