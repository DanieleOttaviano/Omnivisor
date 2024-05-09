# Omnivisor
The Omnivisor is an experimental research project focused on enhancing 
the capabilities of static partitioning hypervisors (SPH) 
to trasparently manage virtual machines (VMs) on asymmetric cores 
while assuring temporal and spatial isolation between VMs.


## Important Repositories
[Jailhouse-Omnivisor](https://github.com/DanieleOttaviano/jailhouse): The repository containing Jailhouse hypervisor patched with Omnivisor model.

[Test_Omnivisor_Host](https://github.com/DanieleOttaviano/test_omnivisor_host): The repository containing the scripts that run on the Host PC linked to a board under test. It contains the scripts to test the Omnivisor.

[Test_Omnivisor_Guest](https://github.com/DanieleOttaviano/test_omnivisor_guest): The repository containing the scripts that run directly on the board (guest) where the Omnivisor is enabled.


## Overview

### Supported Hypervisor:
- [x] Jailhouse

### Supported Board:
- [x] Zynq Ultrascale +

### Supported Cores:
- [x] Cortex-a53 (APU)
- [x] Cortex-R5F (RPU)
- [x] Pico32 on FPGA (RISC-V)
