#!/bin/bash

usage() {
  echo -e "Usage: $0 \r\n \
  This script download and configure everything needed to run a <backend> in a <target> machine:\r\n \
      [-t <target>]\r\n \
      [-b <backend>]\r\n \
      [-s Skip GIT cloning]\r\n \
      [-h help]" 1>&2
    exit 1
}

# DIRECTORIES
script_dir=$(dirname -- "$(readlink -f -- "$0")")
source "${script_dir}"/common/common.sh

# Skip cloning, which means no git clone at startup and use already existing repositories is disabled by default
SKIPCLONE=0

# CREATE is used to create a new environment if it doesn't exist
CREATE="create"

while getopts "t:b:sh" o; do
  case "${o}" in
  t)
    TARGET=${OPTARG}
    ;;
  b)
    BACKEND=${OPTARG}
    ;;
  s)
    SKIPCLONE=1
    echo "GIT Cloning skip enabled"
    ;;
  h)
    echo ""
    echo "Valid targets <target>-<backend>:"
    cat "${ENVIRONMENTS_LIST}"
    echo "" 
    usage
    ;;
  *)
    usage
    ;;
  esac
done
shift $((OPTIND - 1))

# Set the environment as default
bash "${script_dir}"/change_environment.sh -t "${TARGET}" -b "${BACKEND}"

# Set the Environment
source "${script_dir}"/common/set_environment.sh "${TARGET}" "${BACKEND}" "${CREATE}"

# SKIP CLONE if requested
echo "SKIP CLONE = ${SKIPCLONE}"

## CLONE PHASE ##
if [[ ${SKIPCLONE} -eq 0 ]]; then
  #Clone QEMU
  {
    if [[ ${QEMU_BUILD,,} =~ ^y(es)?$ ]]; then
      echo "QEMU repository = ${QEMU_REPOSITORY}"

      # Use the specific COMMIT if defined
      if [[ -n "${QEMU_COMMIT}" ]]; then
        echo "QEMU commit:${QEMU_COMMIT}"
        git clone "${QEMU_REPOSITORY}" "${qemu_dir}"
        cd "${qemu_dir}" || exit 1
        git reset --hard "${QEMU_COMMIT}"

      # If COMMIT not defined, use BRANCH
      elif [ -n "${QEMU_BRANCH}" ]; then
        echo "QEMU commit not specified, using QEMU branch  = ${QEMU_BRANCH}"
        git clone --depth 1 "${QEMU_REPOSITORY}" --branch "${QEMU_BRANCH}" "${qemu_dir}"

      # if both COMMIT and BRANCH are not defined use master
      else
        echo "QEMU commit and branch not specified, cloning master"
        git clone "${QEMU_REPOSITORY}" "${qemu_dir}"
      fi

    else
      echo "Skipping QEMU cloning"
    fi
  } &
  pidQEMU=$!

  #Clone ATF
  {
    if [[ ${ATF_BUILD,,} =~ ^y(es)?$ ]]; then
      echo "ATF repository = ${ATF_REPOSITORY}"

      # Use the specific COMMIT if defined
      if [[ -n "${ATF_COMMIT}" ]]; then
        echo "ATF commit:${ATF_COMMIT}"
        git clone "${ATF_REPOSITORY}" "${atf_dir}"
        cd "${atf_dir}" || exit 1
        git reset --hard "${ATF_COMMIT}"

      # If COMMIT not defined, use BRANCH
      elif [ -n "${ATF_BRANCH}" ]; then
        echo "ATF commit not specified, using ATF branch  = ${ATF_BRANCH}"
        git clone --depth 1 "${ATF_REPOSITORY}" --branch "${ATF_BRANCH}" "${atf_dir}"

      # if both COMMIT and BRANCH are not defined use master
      else
        echo "ATF commit and branch not specified, cloning master"
        git clone "${ATF_REPOSITORY}" "${atf_dir}"
      fi

    else
      echo "Skipping ATF cloning"
    fi
  } &
  pidATF=$!

  #Clone LINUX
  {
    if [[ ${LINUX_BUILD,,} =~ ^y(es)?$ ]]; then
      echo "LINUX repository = ${LINUX_REPOSITORY}"

      # Use the specific COMMIT if defined
      if [[ -n "${LINUX_COMMIT}" ]]; then
        echo "LINUX commit:${LINUX_COMMIT}"
        git clone "${LINUX_REPOSITORY}" ${linux_dir}
        cd "${linux_dir}" || exit 1
        git reset --hard "${LINUX_COMMIT}"

      # If COMMIT not defined, use BRANCH
      elif [[ -n "${LINUX_BRANCH}" ]]; then
        echo "LINUX commit not specified, using LINUX branch  = ${LINUX_BRANCH}"
        git clone --depth 1 "${LINUX_REPOSITORY}" --branch "${LINUX_BRANCH}" "${linux_dir}"

      # if both COMMIT and BRANCH are not defined use master
      else
        echo "LINUX commit and branch not specified, cloning master"
        git clone "${LINUX_REPOSITORY}" "${linux_dir}"
      fi

    else
      echo "Skipping LINUX cloning"
    fi
  } &
  pidLINUX=$!

  #Clone BUILDROOT
  {
    if [[ ${BUILDROOT_BUILD,,} =~ ^y(es)?$ ]]; then
      echo "BUILDROOT repository = ${BUILDROOT_REPOSITORY}"

      # Use the specific COMMIT if defined
      if [[ -n "${BUILDROOT_COMMIT}" ]]; then
        echo "BUILDROOT commit:${BUILDROOT_COMMIT}"
        git clone "${BUILDROOT_REPOSITORY}" "${buildroot_dir}"
        cd "${buildroot_dir}" || exit 1
        git reset --hard "${BUILDROOT_COMMIT}"

      # If COMMIT not defined, use BRANCH
      elif [[ -n "${BUILDROOT_BRANCH}" ]]; then
        echo "BUILDROOT commit not specified, using BUILDROOT branch  = ${BUILDROOT_BRANCH}"
        git clone --depth 1 "${BUILDROOT_REPOSITORY}" --branch "${BUILDROOT_BRANCH}" "${buildroot_dir}"

      # if both COMMIT and BRANCH are not defined use master
      else
        echo "BUILDROOT commit and branch not specified, cloning master"
        git clone "${BUILDROOT_REPOSITORY}" "${buildroot_dir}"
      fi

    else
      echo "Skipping BUILDROOT cloning"
    fi

  } &
  pidBUILDROOT=$!

  #Clone JAILHOUSE
  {
    if [[ ${JAILHOUSE_BUILD,,} =~ ^y(es)?$ ]]; then
      echo "JAILHOUSE repository = ${JAILHOUSE_REPOSITORY}"

      # Use the specific COMMIT if defined
      if [[ -n "${JAILHOUSE_COMMIT}" ]]; then
        echo "JAILHOUSE commit:${JAILHOUSE_COMMIT}"
        git clone "${JAILHOUSE_REPOSITORY}" "${jailhouse_dir}"
        cd "${jailhouse_dir}" || exit 1
        git reset --hard "${JAILHOUSE_COMMIT}"

      # If COMMIT not defined, use BRANCH
      elif [[ -n "${JAILHOUSE_BRANCH}" ]]; then
        echo "JAILHOUSE commit not specified, using QEMU branch  = ${JAILHOUSE_BRANCH}"
        git clone --depth 1 "${JAILHOUSE_REPOSITORY}" --branch "${JAILHOUSE_BRANCH}" "${jailhouse_dir}"

      # if both COMMIT and BRANCH are not defined use master
      else
        echo "JAILHOUSE commit and branch not specified, cloning master"
        git clone "${JAILHOUSE_REPOSITORY}" "${jailhouse_dir}"
      fi

    else
      echo "Skipping JAILHUSE cloning"
    fi
  } &
  pidJAILHOUSE=$!

  #Clone BOOTGEN
  {
    if [[ ${BOOTGEN_BUILD,,} =~ ^y(es)?$ ]]; then
      echo "BOOTGEN repository = ${BOOTGEN_REPOSITORY}"

      # Use the specific COMMIT if defined
      if [[ -n "${BOOTGEN_COMMIT}" ]]; then
        echo "BOOTGEN commit:${BOOTGEN_COMMIT}"
        git clone "${BOOTGEN_REPOSITORY}" "${bootgen_dir}"
        cd "${bootgen_dir}" || exit 1
        git reset --hard "${BOOTGEN_COMMIT}"

      # If COMMIT not defined, use BRANCH
      elif [[ -n "${BOOTGEN_BRANCH}" ]]; then
        echo "BOOTGEN commit not specified, using BOOTGEN branch  = ${BOOTGEN_BRANCH}"
        git clone --depth 1 "${BOOTGEN_REPOSITORY}" --branch "${BOOTGEN_BRANCH}" "${bootgen_dir}"

      # if both COMMIT and BRANCH are not defined use master
      else
        echo "BOOTGEN commit and branch not specified, cloning master"
        git clone "${BOOTGEN_REPOSITORY}" "${bootgen_dir}"
      fi

    else
      echo "Skipping BOOTGEN cloning"
    fi
  } &
  pidBOOTGEN=$!

  echo "Waiting for GIT to complete ..."
  #Wait for all the clones to complete
  wait ${pidQEMU}
  wait ${pidATF}
  wait ${pidLINUX}
  wait ${pidBUILDROOT}
  wait ${pidJAILHOUSE}
  wait ${pidBOOTGEN}

else
  echo "Skipping clone from repositories"
  sleep 1
fi

# Create the target directories
mkdir -p "${build_dir}"
mkdir -p "${install_dir}"
mkdir -p "${output_dir}"
mkdir -p "${boot_dir}"
mkdir -p "${boot_sources_dir}"
mkdir -p "${hardware_dir}"
mkdir -p "${rootfs_dir}"

## COMPILING PHASE ##

# Compile QEMU
if [[ ${QEMU_BUILD,,} =~ ^y(es)?$ ]]; then
  echo "Compiling QEMU ..."
  yes "y" | bash "${script_dir}"/compile/qemu_compile.sh ${QEMU_COMPILE_ARGS}
  if [[ $? -eq 1 ]]; then
    echo "QEMU compilation failed. Exiting..."
    exit 1
  fi
else
  echo "Skipping QEMU compile"
fi

# Compile ATF
if [[ ${ATF_BUILD,,} =~ ^y(es)?$ ]]; then
  echo "Compiling ATF ..."
  yes "y" | bash "${script_dir}"/compile/atf_compile.sh ${ATF_COMPILE_ARGS}
  if [[ $? -eq 1 ]]; then
    echo "ATF compilation failed. Exiting..."
    exit 1
  fi
else
  echo "Skipping ATF compile"
fi

# Compile the LINUX kernel
if [[ ${LINUX_BUILD,,} =~ ^y(es)?$ ]]; then 
  echo "Patching LINUX ..."
  yes "n" | bash "${script_dir}"/patch/linux_patch.sh ${LINUX_PATCH_ARGS}
  echo "Updating LINUX configuration ..."
  yes "y" | bash "${script_dir}"/defconfigs/linux_update_defconfigs.sh ${UPD_LINUX_COMPILE_ARGS}
  echo "Compiling the LINUX kernel ..."
  yes "y" | bash "${script_dir}"/compile/linux_compile.sh ${LINUX_COMPILE_ARGS}
  if [[ $? -eq 1 ]]; then
    echo "LINUX compilation failed. Exiting..."
    exit 1
  fi
else
  echo "Skipping LINUX compile"
fi

# Compile the rootfs using BUILDROOT (Linux modules loaded from overlay-fs)
if [[ ${BUILDROOT_BUILD,,} =~ ^y(es)?$ ]]; then
  echo "Patching BUILDROOT ..."
  yes "n" | bash "${script_dir}"/patch/buildroot_patch.sh ${BUILDROOT_PATCH_ARGS}
  echo "Updating BUILDROOT configuration ..."
  yes "y" | bash "${script_dir}"/defconfigs/buildroot_update_defconfigs.sh ${UPD_BUILDROOT_COMPILE_ARGS}
  echo "Compiling the rootfs with BUILDROOT ..."
  yes "y" | bash "${script_dir}"/compile/buildroot_compile.sh ${BUILDROOT_COMPILE_ARGS}
  if [[ $? -eq 1 ]]; then
    echo "BUILDROOT compilation failed. Exiting..."
    exit 1
  fi
else
  echo "Skipping BUILDROOT compile"
fi

# Compile JAILHOUSE
if [[ ${JAILHOUSE_BUILD,,} =~ ^y(es)?$ ]]; then
  echo "Patching JAILHOUSE ..."
  yes "n" | bash "${script_dir}"/patch/jailhouse_patch.sh ${JAILHOUSE_PATCH_ARGS}
  echo "Updating JAILHOUSE configuration ..."
  yes "y" | bash "${script_dir}"/defconfigs/jailhouse_update_defconfigs.sh ${UPD_JAILHOUSE_COMPILE_ARGS}
  echo "Compiling JAILHOUSE ..."
  yes "y" | bash "${script_dir}"/compile/jailhouse_compile.sh ${JAILHOUSE_COMPILE_ARGS}
  if [[ $? -eq 1 ]]; then
    echo "JAILHOUSE compilation failed. Exiting..."
    exit 1
  fi
else
  echo "Skipping JAILHOUSE compile"
fi

# Compile BOOTGEN
if [[ ${BOOTGEN_BUILD,,} =~ ^y(es)?$ ]]; then
  echo "Compile BOOTGEN"
  yes "y" | bash "${script_dir}"/compile/bootgen_compile.sh ${BOOTGEN_COMPILE_ARGS}
  if [[ $? -eq 1 ]]; then
    echo "BOOTGEN compilation failed. Exiting..."
    exit 1
  fi
else
  echo "Skipping BOOTGEN compile"
fi

echo "Finish!"
