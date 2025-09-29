# Run demos

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
0       ZynqMP-KV260            running           0-3                     0-1                                                                  
```


### Start VM (cell) on a remote core (RPU0)

> [!WARNING]
> The remote core demo elf files need to be in the /lib/firmware directory.

Connect to Telnet on a different terminal as explained in SETUP.md to visualize the output.
```sh
  telnet localhost 4321
```

Load a VM in the remote core RPU0 (the kv260 demo works for the qemu-zcu102 emulation):
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

### Baremetal Demos script
To test the other baremetal applications uses the provided demo script on the platform: 
```sh
/root/scripts_jailhouse_zcu102/demos/bm_demo.sh
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