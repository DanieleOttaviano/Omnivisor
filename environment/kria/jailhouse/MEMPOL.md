# MEMPOL Regulation Guide
 
The install directory contains the binaries to run mempol on the kria board as a Jailhouse-Omnivisor cell.
- install/lib/firmware/mempol_reg_r5_0.elf  ->  The regulator program that runs on the Cortex-R5 core.
- install/bin/membw_ctrl                    ->  Linux userspace program to control the regulator (runs on Cortex-A53)
- install/bin/bench                         ->  Linux Userspace program to benchmark the memory utilization

To run mempol as a cell you need the Omnivisor version of jailouse enabled on the kria.
To launch the mempol regulator use the following commands:
```sh
jailhouse cell create ${JAILHOUSE_DIR}/configs/arm64/zynqmp-kv260-RPU0-mempol.cell
jailhouse cell load inmate-mempol-RPU0 -r mempol_reg_r5_0.elf 0
jailhouse cell start inmate-mempol-RPU0
```

You should see on the serial (UART-1) somthing like this:
```
Regulator on R5 core
version: 5, 4 CPUs, 128 history, 2 samples, mode: sliding-window, token-bucket
buildid: dottavia@theia 2025-02-28 17:16:23 RELEASE TRACING VERBOSE WCET_STATS
TSC running at 533333333 Hz
waiting for start signal from main cores
```

Then you can use the userspace program to control the regulation.
As an example this commands apply a regulation of 250Mib/s to each core:
```sh
membw_ctrl --platform kria_k26 init
membw_ctrl --platform kria_k26 start 250 250 250 250 0
```
the outputs wuold be something like:
```
info: cpuidle for all 4 CPUs disabled
OK
controller: ready
```
```
info: cpuidle for all 4 CPUs disabled
controller: start
- mode: sliding-window
- control loop period: 3333 cycles
- weight factors: 1000, 1000
- global budget: 0/8
- core budgets: 24414/8, 24414/8, 24414/8, 24414/8
```


You can test the maximum benchmark on the cores by using the bench application:
```sh
bench -s 8 -c 3 read
```

the expected output is:
```
linear read bandwidth over 8192 KiB (8 MiB) block
242.8 MiB/s, 254.6 MB/s
243.0 MiB/s, 254.8 MB/s
243.0 MiB/s, 254.8 MB/s
243.1 MiB/s, 254.9 MB/s
243.1 MiB/s, 254.9 MB/s
243.0 MiB/s, 254.8 MB/s
243.0 MiB/s, 254.8 MB/s
243.0 MiB/s, 254.8 MB/s
242.9 MiB/s, 254.7 MB/s
243.0 MiB/s, 254.8 MB/s
243.0 MiB/s, 254.8 MB/s
240.4 MiB/s, 252.1 MB/s
242.3 MiB/s, 254.1 MB/s
242.4 MiB/s, 254.2 MB/s
242.4 MiB/s, 254.2 MB/s
242.5 MiB/s, 254.2 MB/s`