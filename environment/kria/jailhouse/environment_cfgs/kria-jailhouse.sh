#!/bin/bash

## Connection
IP="10.210.1.228"
USER="root"
SSH_ARGS=""
RSYNC_ARGS_SSH=""
RSYNC_ARGS=""
RSYNC_REMOTE_PATH=""

## CROSS COMPILING ARCHITECTURES
ARCH="arm64"
CROSS_COMPILE="/tools/Xilinx/SDK/2019.1/gnu/aarch64/lin/aarch64-linux/bin/aarch64-linux-gnu-" ##"aarch64-linux-gnu-"
REMOTE_COMPILE="arm-none-eabi-"


## COMPONENTS ##
# QEMU
QEMU_BUILD="n"

# ATF
ATF_BUILD="y"
ATF_COMPILE_ARGS=""
ATF_PATCH_ARGS=""
ATF_REPOSITORY="https://github.com/DanieleOttaviano/arm-trusted-firmware.git"
ATF_BRANCH="master"
ATF_COMMIT=""

# LINUX
LINUX_BUILD="y"
UPD_LINUX_COMPILE_ARGS=""
LINUX_COMPILE_ARGS="-m"
LINUX_PATCH_ARGS=""
LINUX_REPOSITORY="https://github.com/Xilinx/linux-xlnx.git"
LINUX_BRANCH="xlnx_rebase_v5.15_LTS"
LINUX_COMMIT="7484228ddbb5760eac350b1b4ffe685c9da9e765"

# BUILDROOT
BUILDROOT_BUILD="y"
UPD_BUILDROOT_COMPILE_ARGS=""
BUILDROOT_COMPILE_ARGS=""
BUILDROOT_PATCH_ARGS="-p 0001-gcc-target.patch"
BUILDROOT_REPOSITORY="https://github.com/buildroot/buildroot.git"
BUILDROOT_BRANCH="2023.05.x"
BUILDROOT_COMMIT="25d59c073ac355d5b499a9db5318fb4dc14ad56c"

# JAILHOUSE
JAILHOUSE_BUILD="y"
UPD_JAILHOUSE_COMPILE_ARGS=""
JAILHOUSE_COMPILE_ARGS="-r all"
JAILHOUSE_PATCH_ARGS="-p 0001-Update-for-kernel-version-greater-then-5-7-and-5-15.patch"
JAILHOUSE_REPOSITORY="git@github.com:DanieleOttaviano/jailhouse.git"
JAILHOUSE_BRANCH="master"
JAILHOUSE_COMMIT=""

# BOOTGEN
BOOTGEN_BUILD="y"
BOOTGEN_COMPILE_ARGS=""
BOOTGEN_PATCH_ARGS=""
BOOTGEN_REPOSITORY="https://github.com/Xilinx/bootgen.git"
BOOTGEN_BRANCH="xlnx_rel_v2022.1"
BOOTGEN_COMMIT="c77d7998d0db56f8a19642275e061b308bc24d53"