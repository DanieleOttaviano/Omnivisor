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
