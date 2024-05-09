# Omnivisor
The Omnivisor is an experimental research project focused on enhancing 
the capabilities of static partitioning hypervisors (SPH) 
to trasparently manage virtual machines (VMs) on asymmetric cores 
while assuring temporal and spatial isolation between VMs.


## Important Repositories
[Omnivisor](https://github.com/DanieleOttaviano/jailhouse): The repository containing the features included in the Jailhouse hypervisor to manage remote cores using the Omnivisor model.

[Test_Omnivisor_Host](https://github.com/DanieleOttaviano/test_omnivisor_host): The repository containing the scripts that run on the Host PC linked to the board under test. It contains all the scripts to start the experiments and visualize the results.

[Test_Omnivisor_Guest](https://github.com/DanieleOttaviano/test_omnivisor_guest): The repository containing the scripts that run directly on board (guest).


## Overview

### Supported Hypervisor:
- [x] Jailhouse

### Supported Board:
- [x] Zynq Ultrascale +

### Supported Cores:
- [x] Cortex-a53 (APU)
- [x] Cortex-R5F (RPU)
- [x] Pico32 on FPGA (RISC-V)
