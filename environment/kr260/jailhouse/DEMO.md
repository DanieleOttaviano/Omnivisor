# Run demos

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
Copy the VM image from jailhouse to /lib/firmware directory
```sh
cp jailhouse/inmates/demos/armr5/src_rpu0-latency/rpu0-latency-demo.elf /lib/firmware/
```

Load a VM in the remote core RPU0 (the kv260 cell configs works also for the kr260):
```sh 
jailhouse cell create jailhouse/configs/arm64/zynqmp-kv260-RPU0-inmate-demo.cell

jailhouse cell load inmate-demo-RPU0 -r rpu0-latency-demo.elf 0

jailhouse cell start inmate-demo-RPU0
```

The expected output is:
```sh
[RPU-0] time(us): 83705
[RPU-0] time(us): 83709
[RPU-0] time(us): 83699
[RPU-0] time(us): 83701
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

