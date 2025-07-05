#!/bin/bash
#WARNING: the script need a defined ${script_dir}

## Printing preferences
info='\033[0;33m'
warn='\033[0;31m'
norm='\033[0m'

## DIRECTORIES ##
# PROJECT
project_dir=$(dirname "${script_dir:?"script_dir is not defined!"}")
# ENVIRONMENT
environment_dir=${project_dir}/environment
# runPHI
#runPHI_dir=${project_dir}/runPHI/target
## VARIABLES ##
ENVIRONMENTS_LIST=${environment_dir}/environments.txt
TARGET=""
# To Build (Default="n") to remove ...
QEMU_BUILD="n"
ATF_BUILD="n"
UBOOT_BUILD="n"
BUILDROOT_BUILD="n"
LINUX_BUILD="n"
JAILHOUSE_BUILD="n"
BOOTGEN_BUILD="n"