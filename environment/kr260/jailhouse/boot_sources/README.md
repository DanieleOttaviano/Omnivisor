## Device Tree Source

* system_clean.dts: clean device tree from the kr260 official repository
* system_omnv.dts: device tree with additional information for Omnivisor: 
  * reserved memory for jailhouse
  * reserved memory for cells
  * reserved memory for remote processors (RPU0, RPU1, RISCV core)
  * RPU0 & RPU1

## Boot Script