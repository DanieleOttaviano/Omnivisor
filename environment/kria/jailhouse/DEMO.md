# Run demos

After loaded the overlay directory update the PATH by logging again:

```bash
exit
```

```bash
login:  root
Password: root
```

Verify that the jailhouse PATH have been exported correctly by printing the version:

```bash
jailhouse --version
```

### Start the Jailhouse hypervisor (with Omnivisor)
Run the script available in the the /root directory
```sh
./scripts_jailhouse_kria/jailhouse_setup/jailhouse_start.sh -o
```

Verify the resouces available to the rootcell:
```sh
jailhouse cell list
```

The expected output is:
```sh
ID      Name                    State             Assigned CPUs           Assigned rCPUs          Assigned FPGA regions   Failed CPUs             
0       ZynqMP-KV260            running           0-3                     0-1                     0-2                                             
```


### Start VM (cell) on a remote core (RPU0)

> [!WARNING]
> The remote core demo elf files need to be in the /lib/firmware directory.

Load a VM in the remote core RPU0:
```sh 
jailhouse cell create jailhouse/configs/arm64/zynqmp-kv260-RPU0-inmate-demo.cell

jailhouse cell load inmate-demo-RPU0 -r rpu0-latency-demo.elf 0

jailhouse cell start inmate-demo-RPU0
```

The expected output is:
```sh
[RPU-0] time(us): 83701
[RPU-0] time(us): 83693
[RPU-0] time(us): 83708
[RPU-0] time(us): 83689
[RPU-0] time(us): 83698
[RPU-0] time(us): 83702
[RPU-0] time(us): 83696
[RPU-0] time(us): 83699
[RPU-0] time(us): 83701
[RPU-0] time(us): 83693
...
```


To stop the VM: 
```sh
jailhouse cell destroy inmate-demo-RPU0
```

### Start VM (cell) on a soft-core on FPGA using dfx

> [!WARNING]
> The bitstream files need to be in the /lib/firmware directory.


The create load the bitstream in the FPGA, then the procedure remain the same:
```sh
jailhouse cell create jailhouse/configs/arm64/zynqmp-kv260-RISCV-inmate-demo.cell

jailhouse cell load inmate-demo-RISCV -r riscv-latency-demo.elf 2

jailhouse cell start inmate-demo-RISCV
```

Since the RISCV core on FPGA is not connected to the UART, the results are written in the shared memory.To read the shared memory use the provided linux app:
```sh 
latency_shm_reader
```

The expected output is: 
```sh
[RISCV-PICO32] time(us):  75182
[RISCV-PICO32] time(us):  75180
[RISCV-PICO32] time(us):  75176
[RISCV-PICO32] time(us):  75183
[RISCV-PICO32] time(us):  75181
[RISCV-PICO32] time(us):  75181
[RISCV-PICO32] time(us):  75182
[RISCV-PICO32] time(us):  75178
[RISCV-PICO32] time(us):  75179
[RISCV-PICO32] time(us):  75180
...
```

### Baremetal Demos script
To test the other baremetal applications uses the provided demo script on the platform: 
```sh
/root/scripts_jailhouse_kria/demos/bm_demo.sh
```
```sh
Platform: zynqmp-kv260
Please choose the CPU where to launch the inmate cell(RPU0, RPU1, APU, RISCV):
```
Choose the CPU (e.g., RPU1)
```sh
RPU1

Please choose the demo to launch from the following options:
bench
bm
latency
membomb
```
Choose the demo (e.g., bench)
```sh
bench
```

The expected output is:
```sh
[RPU-1]     209.9 MiB/s,     220.1 MB/s
[RPU-1]     209.9 MiB/s,     220.1 MB/s
[RPU-1]     209.9 MiB/s,     220.1 MB/s
[RPU-1]     209.9 MiB/s,     220.1 MB/s
[RPU-1]     209.9 MiB/s,     220.1 MB/s
[RPU-1]     209.9 MiB/s,     220.1 MB/s
[RPU-1]     209.9 MiB/s,     220.1 MB/s
[RPU-1]     209.9 MiB/s,     220.1 MB/s
[RPU-1]     209.9 MiB/s,     220.1 MB/s
[RPU-1]     209.9 MiB/s,     220.1 MB/s
...
```


### MEMPOL Regulation Demo

official mempol code: https://gitlab.com/azuepke/mempol
 
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