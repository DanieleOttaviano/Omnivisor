## Main Directories

- Dockerfile
  > Dockerfile to build the build container
- documentation
  > Project Documentation
- scripts
  > Utility scripts (Core of Environment Builder)
- environment
  > List of Target/Backend
- environment_cfgs
  > Configuration files describing all the components of each environment 

## Target/Backend Directories

- boot_sources
  > Directory with all the boot files, which can be modified and compiled. (Device Tree Source, Boot Script, ...)
- build
  > Directory with all the "To Build Components" (U-Boot, Buildroot, Linux, Qemu, Jailhouse, ...)
- custom_build
  > Builds mirror directory with custom files (defconfig files, default_dts, cell_configs, ...)
- install
  > It is used as an overlay directory for the rootfs. Anything that you want to add to the target filesystem should be here (e.g., kernel modules, scripts, network configuration)
- output
  > Artifacts produced by compilations (To-Build Components artifact) + Pre-Built Components artifacts.

## Scripts

- clean
  - destroy_build.sh
    > Delete build and outputs of the \<target\>
- common
  > Scripts used by other scripts to set the environmental variables (Users should not use them).
- compile
  > Scripts to compile "To-Build Components" individually
- defconfigs
  > Scripts to Save and Update the configurations of the configurable "To-Build Components"
- orchestration
  > Setup for orchestration
- patch
  > Utility to apply custom patches to components
- qemu
  > Script to launch the QEMU emulation (the target is QEMU).
- remote
  > Scripts to update and load components, images, and utilities on the running environment.
- build_environment.sh
  > Download and compile all the "To-Build Components" for a given environment (\<target\>+\<backend\>) with a single script (it may take a while...).

