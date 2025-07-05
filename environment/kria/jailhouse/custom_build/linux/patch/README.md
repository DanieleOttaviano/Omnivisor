
- jailhouse_enable: A collection of patches from the jailhouse mantainer Kizka. The patches are necessary to run jailhouse the kernel with all its features.

- preempt-rt: The patch enable the fully preemption mode in the kernel (https://wiki.linuxfoundation.org/realtime/start).

- omnvisor: The patches modifies the remoteproc driver to make it compatible with jailhouse-omnivisor. N.B. remoteproc doesn't work standalone with this patch