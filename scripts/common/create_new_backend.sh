#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
This script create a new <backend> in the project for a specific <target>:\r\n \
    [-t <target>]\r\n \
    [-b <backend>]\r\n \
    [-h help]" 1>&2
  exit 1
}

# DIRECTORIES
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "${current_dir}")
source "${script_dir}"/common/common.sh

while getopts "t:b:h" o; do
  case "${o}" in
  t)
    TARGET=${OPTARG}
    ;;
  b)
    BACKEND=${OPTARG}
    ;;
  h)
    usage
    ;;
  *)
    usage
    ;;
  esac
done
shift $((OPTIND - 1))
echo "TARGET:   ${TARGET}"
echo "BACKEND:  ${BACKEND}"

env_dir="${environment_dir}"/"${TARGET}"/"${BACKEND}"

# Create directory hierarchy
mkdir -p "${env_dir}"/build
mkdir -p "${env_dir}"/custom_build
mkdir -p "${env_dir}"/environment_cfgs
mkdir -p "${env_dir}"/install
mkdir -p "${env_dir}"/output
mkdir -p "${env_dir}"/output/boot
mkdir -p "${env_dir}"/output/hardware
mkdir -p "${env_dir}"/output/rootfs

## DEFAULT VALUES ##

#Architectures
NEW_ARCH="arm64"
NEW_CROSS_COMPILE="aarch64-linux-gnu-"
NEW_REMOTE_COMPILE="arm-none-eabi-"

#QEMU
NEW_QEMU_BUILD='n'
NEW_QEMU_COMPILE_ARGS=""
NEW_QEMU_PATCH=""
NEW_QEMU_REPOSITORY="https://github.com/Xilinx/qemu.git"
NEW_QEMU_BRANCH="xlnx_rel_v2023.1"
NEW_QEMU_COMMIT="21adc9f99e813fb24fb65421259b5b0614938376"

#ATF
NEW_ATF_BUILD='n'
NEW_ATF_COMPILE_ARGS=""
NEW_ATF_PATCH=""
NEW_ATF_REPOSITORY="https://github.com/Xilinx/arm-trusted-firmware.git"
NEW_ATF_BRANCH="master"
NEW_ATF_COMMIT="c7385e021c0b95a025f2c78384d57224e0120401"

#LINUX
NEW_LINUX_BUILD='n'
NEW_UPD_LINUX_COMPILE_ARGS="-l"
NEW_LINUX_COMPILE_ARGS="-m"
NEW_LINUX_PATCH=""
NEW_LINUX_REPOSITORY="https://github.com/Xilinx/linux-xlnx.git"
NEW_LINUX_BRANCH="xlnx_rebase_v5.15_LTS"
NEW_LINUX_COMMIT="7484228ddbb5760eac350b1b4ffe685c9da9e765"

#BUILDROOT
NEW_BUILDROOT_BUILD='n'
NEW_UPD_BUILDROOT_COMPILE_ARGS="-u"
NEW_BUILDROOT_COMPILE_ARGS="-p"
NEW_BUILDROOT_PATCH="0001-gcc-target.patch"
NEW_BUILDROOT_REPOSITORY="https://github.com/buildroot/buildroot.git"
NEW_BUILDROOT_BRANCH="2023.05.x"
NEW_BUILDROOT_COMMIT="25d59c073ac355d5b499a9db5318fb4dc14ad56c"

#JAILHOUSE
NEW_JAILHOUSE_BUILD='n'
NEW_JAILHOUSE_COMPILE_ARGS="-r all"
NEW_JAILHOUSE_PATCH="0001-Update-for-kernel-version-greater-then-5-7-and-5-15.patch"
NEW_JAILHOUSE_REPOSITORY="https://gitlab.com/minervasys/public/jailhouse.git"
NEW_JAILHOUSE_BRANCH="minerva/public"
NEW_JAILHOUSE_COMMIT="b817b436e3fdaa7fad999b47adc94180b18bff75"

# BOOTGEN
NEW_BOOTGEN_BUILD="n"
NEW_BOOTGEN_COMPILE_ARGS=""
NEW_BOOTGEN_PATCH=""
NEW_BOOTGEN_REPOSITORY="https://github.com/Xilinx/bootgen.git"
NEW_BOOTGEN_BRANCH="xlnx_rel_v2022.1"
NEW_BOOTGEN_COMMIT="c77d7998d0db56f8a19642275e061b308bc24d53"

## Create new environment configuration file ##
env_cfgs="${env_dir}"/environment_cfgs
ENV_CFG_FILE="${TARGET}-${BACKEND}.sh"
echo "Creating configuration file for the new target ..."
touch "${env_cfgs}"/"${ENV_CFG_FILE}"
echo "#!/bin/bash" > "${env_cfgs}"/"${ENV_CFG_FILE}"
echo "" >> "${env_cfgs}"/"${ENV_CFG_FILE}"

## Connection configuration
# User Interaction
echo "Insert the IP of the target machine:"
read -r NEW_IP
echo "Insert the user name of the target machine:"
read -r NEW_USER
echo "Insert the remote path of the target machine if different from /home/${NEW_USER}/ (otherwise just press enter):"
read -r NEW_RSYNC_REMOTE_PATH
echo "Insert the port of the target machine if different from 22 (otherwise just press enter):"
read -r NEW_SSH_PORT
# Write Configuration
echo "## Connection" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
echo "IP=\"${NEW_IP}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
echo "USER=\"${NEW_USER}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
if [[ -n "${NEW_SSH_PORT}" ]]; then
  echo "SSH_ARGS=\"-p ${NEW_SSH_PORT}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "RSYNC_ARGS_SSH=\"ssh -p ${NEW_SSH_PORT}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo 'RSYNC_ARGS="-e"' >>"${env_cfgs}"/"${ENV_CFG_FILE}"
else
  echo 'SSH_ARGS=""' >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo 'RSYNC_ARGS_SSH=""' >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo 'RSYNC_ARGS=""' >>"${env_cfgs}"/"${ENV_CFG_FILE}"
fi
echo "RSYNC_REMOTE_PATH=\"${NEW_RSYNC_REMOTE_PATH}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
echo "" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
echo "" >>"${env_cfgs}"/"${ENV_CFG_FILE}"

## Cross compiling architectures configuration
# User Interaction
echo "Which architecture do you want to use for cross compiling? (default: arm64)"
read -r user_input
if [[ -n "${user_input}" ]]; then
  NEW_ARCH="${user_input}"
fi
echo "Which cross compiler do you want to use for cross compiling? (default: aarch64-linux-gnu-)"
read -r user_input
if [[ -n "${user_input}" ]]; then
  NEW_CROSS_COMPILE="${user_input}"
fi
echo "Which remote compiler do you want to use for remote processor cross compiling? (default: arm-none-eabi-)"
read -r user_input
if [[ -n "${user_input}" ]]; then
  NEW_REMOTE_COMPILE="${user_input}"
fi
# Write Configuration
echo "## CROSS COMPILING ARCHITECTURES" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
echo "ARCH=\"${NEW_ARCH}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
echo "CROSS_COMPILE=\"${NEW_CROSS_COMPILE}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
echo "REMOTE_COMPILE=\"${NEW_REMOTE_COMPILE}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
echo "" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
echo "" >>"${env_cfgs}"/"${ENV_CFG_FILE}"

## Components configuration
echo "## COMPONENTS ##" >>"${env_cfgs}"/"${ENV_CFG_FILE}"

# QEMU
echo "Do you want to build QEMU? (y/n)"
read -r NEW_QEMU_BUILD
if ! [[ "${NEW_QEMU_BUILD,,}" =~ ^y(es)?$ ]]; then
  NEW_QEMU_BUILD='n'
fi
echo "# QEMU" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
echo "QEMU_BUILD=\"${NEW_QEMU_BUILD}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
if [[ ${NEW_QEMU_BUILD} == 'y' ]]; then
  # User Interaction
  echo "Insert the repository of QEMU if different from default -> ${NEW_QEMU_REPOSITORY} (otherwise just press enter):"
  read -r user_input
  if [[ -n "${user_input}" ]]; then
    NEW_QEMU_REPOSITORY="${user_input}"
  fi
  echo "Insert the branch of QEMU if different from default -> ${NEW_QEMU_BRANCH} (otherwise just press enter):"
  read -r user_input
  if [[ -n "${user_input}" ]]; then
    NEW_QEMU_BRANCH="${user_input}"
  fi
  echo "Insert the commit of QEMU if different from default -> ${NEW_QEMU_COMMIT} (otherwise just press enter):"
  read -r user_input
  if [[ -n "${user_input}" ]]; then
    NEW_QEMU_COMMIT="${user_input}"
  fi

  # Write Configuration
  echo "QEMU_COMPILE_ARGS=\"${NEW_QEMU_COMPILE_ARGS}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "QEMU_PATCH=\"${NEW_QEMU_PATCH}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "QEMU_REPOSITORY=\"${NEW_QEMU_REPOSITORY}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "QEMU_BRANCH=\"${NEW_QEMU_BRANCH}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "QEMU_COMMIT=\"${NEW_QEMU_COMMIT}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
fi
echo "" >>"${env_cfgs}"/"${ENV_CFG_FILE}"

# ATF
echo "Do you want to build ATF? (y/n)"
read -r NEW_ATF_BUILD
if [[ "${NEW_ATF_BUILD}" != 'y' ]]; then
  NEW_ATF_BUILD='n'
fi
echo "# ATF" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
echo "ATF_BUILD=\"${NEW_ATF_BUILD}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
if [[ ${NEW_ATF_BUILD} == 'y' ]]; then
  # User Interaction
  echo "Insert the repository of ATF if different from default -> ${NEW_ATF_REPOSITORY} (otherwise just press enter):"
  read -r user_input
  if [[ -n "${user_input}" ]]; then
    NEW_ATF_REPOSITORY="${user_input}"
  fi
  echo "Insert the branch of ATF if different from default -> ${NEW_ATF_BRANCH} (otherwise just press enter):"
  read -r user_input
  if [[ -n "${user_input}" ]]; then
    NEW_ATF_BRANCH="${user_input}"
  fi
  echo "Insert the commit of ATF if different from default -> ${NEW_ATF_COMMIT} (otherwise just press enter):"
  read -r user_input
  if [[ -n "${user_input}" ]]; then
    NEW_ATF_COMMIT="${user_input}"
  fi

  # Write Configuration
  echo "ATF_COMPILE_ARGS=\"${NEW_ATF_COMPILE_ARGS}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "ATF_PATCH=\"${NEW_ATF_PATCH}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "ATF_REPOSITORY=\"${NEW_ATF_REPOSITORY}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "ATF_BRANCH=\"${NEW_ATF_BRANCH}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "ATF_COMMIT=\"${NEW_ATF_COMMIT}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
fi
echo "" >>"${env_cfgs}"/"${ENV_CFG_FILE}"

# LINUX
echo "Do you want to build Linux? (y/n)"
read -r NEW_LINUX_BUILD
if [[ ${NEW_LINUX_BUILD} != 'y' ]]; then
  NEW_LINUX_BUILD='n'
fi
echo "# LINUX" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
echo "LINUX_BUILD=\"${NEW_LINUX_BUILD}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
if [[ ${NEW_LINUX_BUILD} == 'y' ]]; then
  # User Interaction
  echo "Insert the repository of Linux if different from default -> ${NEW_LINUX_REPOSITORY} (otherwise just press enter):"
  read -r user_input
  if [[ -n "${user_input}" ]]; then
    NEW_LINUX_REPOSITORY="${user_input}"
  fi
  echo "Insert the branch of Linux if different from default -> ${NEW_LINUX_BRANCH} (otherwise just press enter):"
  read -r user_input
  if [[ -n "${user_input}" ]]; then
    NEW_LINUX_BRANCH="${user_input}"
  fi
  echo "Insert the commit of Linux if different from default -> ${NEW_LINUX_COMMIT} (otherwise just press enter):"
  read -r user_input
  if [[ -n "${user_input}" ]]; then
    NEW_LINUX_COMMIT="${user_input}"
  fi

  # Write Configuration
  echo "UPD_LINUX_COMPILE_ARGS=\"${NEW_UPD_LINUX_COMPILE_ARGS}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "LINUX_COMPILE_ARGS=\"${NEW_LINUX_COMPILE_ARGS}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "LINUX_PATCH=\"${NEW_LINUX_PATCH}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "LINUX_REPOSITORY=\"${NEW_LINUX_REPOSITORY}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "LINUX_BRANCH=\"${NEW_LINUX_BRANCH}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "LINUX_COMMIT=\"${NEW_LINUX_COMMIT}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
fi
echo "" >>"${env_cfgs}"/"${ENV_CFG_FILE}"

# BUILDROOT
echo "Do you want to build Buildroot? (y/n)"
read -r NEW_BUILDROOT_BUILD
if [[ ${NEW_BUILDROOT_BUILD} != 'y' ]]; then
  NEW_BUILDROOT_BUILD='n'
fi
echo "# BUILDROOT" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
echo "BUILDROOT_BUILD=\"${NEW_BUILDROOT_BUILD}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
if [[ ${NEW_BUILDROOT_BUILD} == 'y' ]]; then
  # User Interaction
  echo "Insert the repository of Buildroot if different from default -> ${NEW_BUILDROOT_REPOSITORY} (otherwise just press enter):"
  read -r user_input
  if [[ -n "${user_input}" ]]; then
    NEW_BUILDROOT_REPOSITORY="${user_input}"
  fi
  echo "Insert the branch of Buildroot if different from default -> ${NEW_BUILDROOT_BRANCH} (otherwise just press enter):"
  read -r user_input
  if [[ -n "${user_input}" ]]; then
    NEW_BUILDROOT_BRANCH="${user_input}"
  fi
  echo "Insert the commit of Buildroot if different from default -> ${NEW_BUILDROOT_COMMIT} (otherwise just press enter):"
  read -r user_input
  if [[ -n "${user_input}" ]]; then
    NEW_BUILDROOT_COMMIT="${user_input}"
  fi

  # Write Configuration
  echo "UPD_BUILDROOT_COMPILE_ARGS=\"${NEW_UPD_BUILDROOT_COMPILE_ARGS}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "BUILDROOT_COMPILE_ARGS=\"${NEW_BUILDROOT_COMPILE_ARGS}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "BUILDROOT_PATCH=\"${NEW_BUILDROOT_PATCH}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "BUILDROOT_REPOSITORY=\"${NEW_BUILDROOT_REPOSITORY}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "BUILDROOT_BRANCH=\"${NEW_BUILDROOT_BRANCH}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "BUILDROOT_COMMIT=\"${NEW_BUILDROOT_COMMIT}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
fi
echo "" >>"${env_cfgs}"/"${ENV_CFG_FILE}"

# JAILHOUSE
echo "Do you want to build Jailhouse? (y/n)"
read -r NEW_JAILHOUSE_BUILD
if [[ ${NEW_JAILHOUSE_BUILD} != 'y' ]]; then
  NEW_JAILHOUSE_BUILD='n'
fi
echo "# JAILHOUSE" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
echo "JAILHOUSE_BUILD=\"${NEW_JAILHOUSE_BUILD}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
if [[ ${NEW_JAILHOUSE_BUILD} == 'y' ]]; then
  # User Interaction
  echo "Insert the repository of Jailhouse if different from default -> ${NEW_JAILHOUSE_REPOSITORY} (otherwise just press enter):"
  read -r user_input
  if [[ -n "${user_input}" ]]; then
    NEW_JAILHOUSE_REPOSITORY="${user_input}"
  fi
  echo "Insert the branch of Jailhouse if different from default -> ${NEW_JAILHOUSE_BRANCH} (otherwise just press enter):"
  read -r user_input
  if [[ -n "${user_input}" ]]; then
    NEW_JAILHOUSE_BRANCH="${user_input}"
  fi
  echo "Insert the commit of Jailhouse if different from default -> ${NEW_JAILHOUSE_COMMIT} (otherwise just press enter):"
  read -r user_input
  if [[ -n "${user_input}" ]]; then
    NEW_JAILHOUSE_COMMIT="${user_input}"
  fi

  # Write Configuration
  echo "JAILHOUSE_COMPILE_ARGS=\"${NEW_JAILHOUSE_COMPILE_ARGS}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "JAILHOUSE_PATCH=\"${NEW_JAILHOUSE_PATCH}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "JAILHOUSE_REPOSITORY=\"${NEW_JAILHOUSE_REPOSITORY}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "JAILHOUSE_BRANCH=\"${NEW_JAILHOUSE_BRANCH}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "JAILHOUSE_COMMIT=\"${NEW_JAILHOUSE_COMMIT}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
fi
echo "" >>"${env_cfgs}"/"${ENV_CFG_FILE}"

# BOOTGEN
echo "Do you want to build BOOTGEN? (y/n)"
read -r NEW_BOOTGEN_BUILD
if [[ ${NEW_BOOTGEN_BUILD} != 'y' ]]; then
  NEW_BOOTGEN_BUILD='n'
fi
echo "# BOOTGEN" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
echo "BOOTGEN_BUILD=\"${NEW_BOOTGEN_BUILD}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
if [[ ${NEW_BOOTGEN_BUILD} == 'y' ]]; then
  # User Interaction
  echo "Insert the repository of BOOTGEN if different from default -> ${NEW_BOOTGEN_REPOSITORY} (otherwise just press enter):"
  read -r user_input
  if [[ -n "${user_input}" ]]; then
    NEW_BOOTGEN_REPOSITORY="${user_input}"
  fi
  echo "Insert the branch of BOOTGEN if different from default -> ${NEW_BOOTGEN_BRANCH} (otherwise just press enter):"
  read -r user_input
  if [[ -n "${user_input}" ]]; then
    NEW_BOOTGEN_BRANCH="${user_input}"
  fi
  echo "Insert the commit of BOOTGEN if different from default -> ${NEW_BOOTGEN_COMMIT} (otherwise just press enter):"
  read -r user_input
  if [[ -n "${user_input}" ]]; then
    NEW_BOOTGEN_COMMIT="${user_input}"
  fi

  # Write Configuration
  echo "BOOTGEN_COMPILE_ARGS=\"${NEW_BOOTGEN_COMPILE_ARGS}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "BOOTGEN_PATCH=\"${NEW_BOOTGEN_PATCH}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "BOOTGEN_REPOSITORY=\"${NEW_BOOTGEN_REPOSITORY}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "BOOTGEN_BRANCH=\"${NEW_BOOTGEN_BRANCH}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
  echo "BOOTGEN_COMMIT=\"${NEW_BOOTGEN_COMMIT}\"" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
fi
echo "" >>"${env_cfgs}"/"${ENV_CFG_FILE}"

echo "" >>"${env_cfgs}"/"${ENV_CFG_FILE}"
echo "New target created!"
echo ""
echo "Remember to add the board specific files (Pre-Build Components) in the directory of the target (e.g. Ultrascale):"
echo "  - add boot.scr                          in ${environment_dir}/${TARGET}/${BACKEND}/boot/sources/"
echo "  - add system.dts (device tree source)   in ${environment_dir}/${TARGET}/${BACKEND}/boot/sources/"
echo "  - add bootgen.bif                       in ${environment_dir}/${TARGET}/${BACKEND}/boot/"
echo "  - add zynqmp-fsbl.elf                   in ${environment_dir}/${TARGET}/${BACKEND}/boot/"
echo "  - add pmufw.elf                         in ${environment_dir}/${TARGET}/${BACKEND}/boot/"
echo "  - add system.bit                        in ${environment_dir}/${TARGET}/${BACKEND}/boot/"
echo "  - add u-boot.elf                        in ${environment_dir}/${TARGET}/${BACKEND}/boot/"
echo "  - add hardware specification (.xsa)     in ${environment_dir}/${TARGET}/${BACKEND}/hardware/"
echo ""
echo "Remember to add configurations for all the configurable components:"
echo "  - add ${BACKEND}_${TARGET}_buildroot_defconfig   in ${environment_dir}/${TARGET}/${BACKEND}/custom_build/buildroot/configs/"
echo "  - add ${BACKEND}_${TARGET}_kernel_defconfig   	 in ${environment_dir}/${TARGET}/${BACKEND}/custom_build/linux/arch/arm64/configs/"
echo "	- ..."
echo ""
echo "Remember to add the PATCH if needed:"
echo "  - add <name_of the patch>.patch   in ${environment_dir}/${TARGET}/${BACKEND}/custom_build/<component>/patch/"
echo ""