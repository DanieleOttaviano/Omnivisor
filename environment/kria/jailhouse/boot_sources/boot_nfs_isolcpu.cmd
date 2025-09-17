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
k=kria_3/Image
i=kria_3/initrd
d=kria_3/system.dtb

# NFS bootargs

# isolcpus=nohz,domain,managed_irq,3: Isolates CPU 3 from the general scheduler. This means CPU 3 will not handle any tasks except those explicitly assigned to it. The additional flags (nohz, domain, managed_irq) further refine the isolation behavior.
# skew_tick=1: Enables skewed tick handling, which can help reduce power consumption by staggering timer interrupts across CPUs.
# nosoftlockup: Disables the kernel's soft lockup detector, which is used to detect long-running tasks that could indicate a problem.
# nowatchdog: Disables the kernel's watchdog timer, which is used to detect and recover from system hangs.
# rcu_nocbs=3: Offloads RCU (Read-Copy-Update) callback processing from CPU 3 to other CPUs, reducing the load on CPU 3.
# nohz_full=3: Enables full dynamic tick mode on CPU 3, reducing the frequency of timer interrupts to improve performance for real-time tasks.
# rcu_nocb_poll: Forces RCU callback threads to poll for work instead of being woken up by interrupts, which can reduce latency.
# processor.max_cstate=0: Limits the processor to C0 state (active state), preventing it from entering any power-saving states.
# processor_idle.max_cstate=0: Similar to processor.max_cstate=0, this limits the processor idle state to C0, ensuring the processor remains fully active.
# isolcpus=nohz,domain,managed_irq,3 skew_tick=1 nosoftlockup nowatchdog rcu_nocbs=3 nohz_full=3 rcu_nocb_poll processor.max_cstate=0 processor_idle.max_cstate=0 
setenv bootargs "isolcpus=3 rcu_nocbs=3 rcu_nocb_pol skew_tick=1 nosoftlockup nowatchdog processor.max_cstate=0 processor_idle.max_cstate=0 earlycon clk_ignore_unused earlyprintk root=/dev/nfs nfsroot=/tftpboot/%s,vers=3,sec=sys ip=dhcp rw rootwait nfsrootdebug console=ttyPS1,115200 loglevel=8"

# download kernel
tftpboot 200000 ${k}

# download and activate DTB
tftpboot 20000000 ${d}
fdt addr 20000000
fdt resize 0x10000

# Start Linux with NFS
booti 200000 - 20000000
