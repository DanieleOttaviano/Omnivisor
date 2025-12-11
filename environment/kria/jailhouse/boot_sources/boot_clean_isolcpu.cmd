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
# setenv bootargs "isolcpus=3 rcu_nocbs=3 nohz_full=3 rcu_nocb_poll skew_tick=1 nosoftlockup nowatchdog processor.max_cstate=0 processor_idle.max_cstate=0 earlycon clk_ignore_unused earlyprintk root=/dev/mmcblk1p2 rw rootwait console=ttyPS1,115200 loglevel=8"
setenv bootargs "isolcpus=3 rcu_nocbs=3 rcu_nocb_poll skew_tick=1 nosoftlockup nowatchdog processor.max_cstate=0 processor_idle.max_cstate=0 earlycon clk_ignore_unused earlyprintk root=/dev/mmcblk1p2 rw rootwait console=ttyPS1,115200 loglevel=8"
fatload mmc 1 0x3000000 Image
fatload mmc 1 0x2A00000 system.dtb
booti 0x3000000 - 0x2A00000

