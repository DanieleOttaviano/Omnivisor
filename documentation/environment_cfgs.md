
# Environment Configuration Files

This document explains how to use and customize the environment configuration files located in: 

`environment_builder/environment_cfgs/`

Each configuration script follows the naming convention: 

`<target>_<backend>.sh`

These configuration files define environment variables and build parameters necessary to set up the environment for specific hardware platforms (targets) and software stacks (backends). They are primarily used to automate building, compiling, and deploying system components.


## Table of Contents

- [1. Configuration Structure](#1-configuration-structure)
  - [1.1 Connection](#11-connection)
  - [1.2 Cross-Compiling Architectures](#12-cross-compiling-architectures)
  - [1.3 Components](#13-components)
- [2. Using *_CONFIG to Select Configurations](#2-using-_config-to-select-configurations)
  - [2.1 Component Configuration](#21-component-configuration)
  - [2.2 Boot Sources Configurations](#22-boot-sources-configurations)


## 1. Configuration Structure

Each file is a shell script (`.sh`) that initializes a set of environment variables, which are used by build and deployment scripts.

### 1.1 Connection

These variables define how the build system connects to the target device.

```bash
IP="192.168.100.46"
USER="root"
SSH_ARGS="-p 5022"
RSYNC_ARGS_SSH="ssh -p 5022"
RSYNC_ARGS="-e"
RSYNC_REMOTE_PATH="/home/user"
```

* IP, USER
    > used for SSH and file transfers.
* SSH_ARGS, RSYNC_ARGS, etc.
    > allow you to customize communication with the target. (e.g., by changing the port):
* RSYNC_REMOTE_PATH
    > target path for rsync.

### 1.2 Cross-Compiling Architectures
These variables define the toolchains used for local and remote builds.
For now only arm64 is supported (arm32 for remote processors with Omnivisor).
```bash
ARCH="arm64"
BUILD_ARCH="aarch64" # u-boot needs it
CROSS_COMPILE="aarch64-linux-gnu-"
REMOTE_COMPILE="arm-none-eabi-" # Cortex-R5 co-processor (Omnivisor)
```

### 1.3 Components
The configuration file describes the environment though a series of components to build, the repository where to download the component, and the branch/commit. 

- `<component>_BUILD = "[y/n]"` 
    > if the BUILD variable is "y" then the component will be downloaded and compiled, in "n" it will not.
- `<component>_COMPILE_ARGS = ""`
    > Additional argument to add during the compilation of the component.
- `<component>_PATCH_ARGS = "[-d <patch_directory>] [-p <patch_name>]"` 
    > The patches to apply to the component from 'environment_builder/environment/\<target\>/\<backend\>/custom_build/\<component\>/patch'. Using the [-d] flag, all the patches in a directory will be applied. Using the [-p] only one single patch will be applied.
- `<component>_REPOSITORY = ""`
    > The name of the repository from which to download the component.
- `<component>_BRANCH = ""`
    > The exact branch of the repository.
- `<component>_COMMIT = ""`
    > The exact commit of the repository.
- `<component>_CONFIG = ""`
    > the configuration to use while compiling the component.


## 2. Using <*>_CONFIG to Select Configurations

Each buildable component can use a configuration variant specified by the <*>_CONFIG variable.
If this variable is empty, a default configuration is used.

Below is an explanation of how these settings work and how to use them effectively.

### 2.1 Component Configuration
As an example, lets consider Linux as the component:
- If `LINUX_CONFIG=""` (empty), the default configuration `<target>_<backend>_kernel_defconfig` will be used.
- If `LINUX_CONFIG="isolcpu"`, the configuration `<target>_<backend>_isolcpu_kernel_defconfig` will be used.

#### Saving a New Configuration
After modifying and testing a Linux configuration, you can save it under a new name. For example:
1. Set `LINUX_CONFIG="test"`.
2. Run the script `linux_save_defconfig.sh`.

This will save the configuration as `<target>_<backend>_test_kernel_defconfig`.

### 2.2 Boot Sources Configurations
The same approach applies to boot sources, such as `boot.cmd` and `system.dts`. 
The relevant compile scripts will use the specified configuration:

#### Boot Command (`bootcmd`)
- If `BOOTCMD_CONFIG=""` (empty), the default `config.h` will be compiled.
- If `BOOTCMD_CONFIG="nfs"`, the script will compile `config_nfs.h`.

To compile the boot command, use the script `bootcmd_compile.sh`.

#### Device Tree (`devicetree`)
The same logic applies to device tree configurations. Use the script `dts_compile.sh` to compile the specified configuration.