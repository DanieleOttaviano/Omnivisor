# Omnivisor
The Omnivisor is an experimental research project focused on enhancing the capabilities of static partitioning hypervisors (SPH) to trasparently manage virtual machines (VMs) on asymmetric cores while assuring temporal and spatial isolation between VMs.

## Repositories
[Jailhouse-Omnivisor](https://github.com/DanieleOttaviano/jailhouse): The repository containing Jailhouse hypervisor patched with Omnivisor model.

[Test_Omnivisor_Host](https://github.com/DanieleOttaviano/test_omnivisor_host): The repository containing the scripts that run on the Host PC linked to a board under test. It contains the scripts to test the Omnivisor.

[Test_Omnivisor_Guest](https://github.com/DanieleOttaviano/test_omnivisor_guest): The repository containing the scripts that run directly on the board (guest) where the Omnivisor is enabled.

[Patched-ATF](https://github.com/DanieleOttaviano/arm-trusted-firmware): The repository containing the patched version of the arm-trusted-firmware to run the Omnivisor.

## Overview

This repository provides a unified framework to build the full software stack required to run **Omnivisor** on real hardware environments.

Each environment consists of:
- **Pre-Built Components**: Board-specific firmware and dependencies that are not intended for modification (e.g., board-specific firmware).
- **To-Build Components**: Customizable software built using this repository (e.g., kernels, hypervisors, and RunPHI itself).

A dedicated configuration script (`<target>-<backend>.sh`) defines the set of components, Git repositories, commits, and compilation flags for each environment.

## Table of Contents

- [1. Supported Platforms](#1-supported-platforms)
  - [1.1 Supported Hypervisor](#11-supported-hypervisor)
  - [1.2 Supported Boards](#12-supported-board)
- [2. Dependencies](#2-dependencies)
  - [2.1 Add User to Docker Group](#21-add-user-to-docker-group)
  - [2.2 Build and Launch Docker Environment](#22-build-and-launch-docker-environment)
  - [2.3 Optional: Native Setup Without Docker](#23-optional-native-setup-without-docker-not-recommended)
- [3. Usage](#3-usage)
  - [3.1 Review Configuration](#31-review-configuration)
  - [3.2 Build the Environment](#32-build-the-environment)
  - [3.3 Setup the Target](#33-setup-the-target)
  - [3.4 (Optional) Configure SSH Access](#34-optional-configure-ssh-access)
  - [3.5 Load Components to Target](#35-load-components-to-target)
  - [3.6 Test the Environment](#36-test-the-environment)

## 1. Supported Platforms

### 1.1 Supported Hypervisor:
- [x] Jailhouse

### 1.2 Supported Board:
- [x] kria (kv260 Zynq Ultrascale +)

#### 1.2.1 Supported Cores:
- [x] Cortex-A53 (APU)
- [x] Cortex-R5F (RPU)
- [x] Pico32 on FPGA (RISC-V)


## 2. Dependencies

> [!WARNING]
> **Recommended**: Use Docker to avoid inconsistencies caused by different toolchain versions.

### 2.1 Add User to Docker Group
Be sure to add the username to the docker group

```bash
sudo usermod -aG docker <username>
newgrp docker
```

### 2.2 Build and Launch Docker Environment
To open a shell in the Docker image with all the needed dependencies, just run:

```bash
cd ~/Omnivisor
docker build -t env_builder .
docker run -it --rm --user $(id -u):$(id -g) -v /etc/passwd:/etc/passwd:ro --net=host --name env_builder_container -v ${PWD}:/home -w="/home" env_builder /bin/bash
```

### 2.3 Optional: Native Setup Without Docker (Not Recommended)

```bash
apt-get update && apt-get install -y \
  git make sed binutils diffutils python3 ninja-build build-essential \
  bzip2 tar findutils unzip cmake rsync u-boot-tools \
  gcc-arm-none-eabi gcc-aarch64-linux-gnu libglib2.0-dev \
  libpixman-1-dev wget cpio rsync bc libncurses5 flex bison \
  openssl libssl-dev kmod python3-pip file pkg-config

pip3 install Mako
```

---

## 3. Usage

### 3.1 Review Configuration

The environments configurations, including GitHub repositories, commits, patches, and more, can be found in the following file: 
```
environment_cfgs/<target>-<backend>.sh
```

More details about configurations are documented [here](documentation/environment_cfgs.md).


### 3.2 Build the Environment
Launch the following script to download, configure, and compile all the "To-Build Components" for the chosen \<target\> (e.g. kria) and \<backend\> (e.g. jailhouse):

```bash
./scripts/build_environment.sh -t <target> -b <backend>
```

The previous script set the default environment. To switch the default environment:

```bash
./scripts/change_environment.sh -t <target> -b <backend>
```

You can override the default environment in any script using `-t` and `-b` flags.


### 3.3 Setup the Target

Different environemnts have different setup steps (e.g., load the SD card with the produced artifacts).
Refer to the `SETUP.md` file specific for each target-backend in:

```
environment/<target>/<backend>/SETUP.md
```

### 3.4 (Optional) Configure SSH Access

> [!NOTE]
> All the scripts in ./scripts/remote/* can be launched outside the docker container.

Allow password-less access to the running target (only once).

**While the target is running**:

```bash
./scripts/remote/set_remote_ssh.sh
```

Then in the board copy the authorized keys in the .ssh directory if it has been saved in the dropbear directory

```bash
cd ~
mkdir .ssh
cp /etc/dropbear/authorized_keys ~/.ssh
```

### 3.5 Load Components to Target

Load/update components (e.g., Jailhouse) on the target

**While the target is running**:
```bash
./scripts/remote/load_components_to_remote.sh -j
```

[Optional] Sync the install directory (overlay directory specific to the enviornment) to the target.

**While the target is running**:
```bash
./scripts/remote/load_install_dir_to_remote.sh
```

### 3.6 Test the Environment

Follow the `DEMO.md` in the relevant environment folder.

```
environment/<target>/<backend>/DEMO.md
```

#### Sub-Modules Tests
The tests are uploaded as submodules.

To grab latest commits from server

```bash
git submodule update --recursive --remote
```

The above command will set current branch to detached HEAD. set back to main:

```bash
git submodule foreach git checkout main
```

Now do pull to fast-forward to latest commit

```bash
git submodule foreach git pull origin main
```

### 3.7 Clean the Build

Inside the Docker container:

```bash
./scripts/clean/destroy_build.sh
```

## Contact 📬 

For more information or contributions, please open an issue or contact the Omnivisor maintainers.