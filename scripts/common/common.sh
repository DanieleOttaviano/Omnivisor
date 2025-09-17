#!/bin/bash
# WARNING: the script needs ${script_dir} defined before sourcing

# --- Color codes ---
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
RESET='\033[0m'

# --- Print helpers ---
info()    { echo -e "${CYAN}[INFO]${RESET}    $*"; }
success() { echo -e "${GREEN}[OK]${RESET}      $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}    $*"; }
error()   { echo -e "${RED}[ERROR]${RESET}   $*" >&2; }

# --- Directories ---
project_dir=$(dirname "${script_dir:?"script_dir is not defined!"}")
environment_dir=${project_dir}/environment

# --- Variables ---
ENVIRONMENTS_LIST=${environment_dir}/environments.txt
TARGET=""
QEMU_BUILD="n"
ATF_BUILD="n"
UBOOT_BUILD="n"
BUILDROOT_BUILD="n"
LINUX_BUILD="n"
JAILHOUSE_BUILD="n"
BOOTGEN_BUILD="n"
