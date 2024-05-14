# Omnivisor
The Omnivisor is an experimental research project focused on enhancing the capabilities of static partitioning hypervisors (SPH) to trasparently manage virtual machines (VMs) on asymmetric cores while assuring temporal and spatial isolation between VMs.


## Building System

**The purpose of this repository is to automate the building of a working environmet (Target + Backend) to use/test Omnivisor.**

An environment is composed by:
- Target: The board (e.g,  kria kv260 Zynq Ultrascale +)
- Backend: The hypervisor patched with Omnivisor extension (e.g, Jailhouse)

To build a working environment we are going to use Pre-Built Components and To-Build Components.

- Pre-Built Components: all the pre-compiled software for the target. This is software that we are not interested in changing or modifying but is needed to have a complete working environment (e.g. board specific firmware).
- To-Build Components: all the software that is compiled using the scripts of this repository. This is the software that we are interested in changing and modifying dynamically.

Each environment (target + backend) is characterized by a configuration file (\<target\>-\<backend\>.sh) that specifies a set of "To-Build Components" that are characterized by specific compilation flags and specific GitHub repository/commit.
Each target "Pre-Built components" are instead stored in the \<target\>/\<backend\> directory

The configure_everything.sh -t \<target\> -b \<backend\> script downloads each "To-Build component" from their GitHub repository, compiles them and puts the result artifacts with the "Pre-Built Components" in the right environment directory.
The backend directory of the specified target will then store all the files needed to boot and run our system.

While the system is running the "remote" scripts (scripts/remote/) give you a simple way to load/update software components in the environment (e.g. update Kernel, load Jailhouse, ...).

## Status of the Project

### Supported Hypervisor:
- [x] Jailhouse

### Supported Board:
- [x] kria (kv260 Zynq Ultrascale +)

#### Supported Cores:
- [x] Cortex-A53 (APU)
- [x] Cortex-R5F (RPU)
- [x] Pico32 on FPGA (RISC-V)


## Repositories
[Jailhouse-Omnivisor](https://github.com/DanieleOttaviano/jailhouse): The repository containing Jailhouse hypervisor patched with Omnivisor model.

[Test_Omnivisor_Host](https://github.com/DanieleOttaviano/test_omnivisor_host): The repository containing the scripts that run on the Host PC linked to a board under test. It contains the scripts to test the Omnivisor.

[Test_Omnivisor_Guest](https://github.com/DanieleOttaviano/test_omnivisor_guest): The repository containing the scripts that run directly on the board (guest) where the Omnivisor is enabled.

[Patched-ATF](https://github.com/DanieleOttaviano/arm-trusted-firmware): The repository containing the patched version of the arm-trusted-firmware to run the Omnivisor.


## Dependencies

> [!WARNING]
> We strongly recommend you run the compiling scripts in a docker image to avoid unexpected errors due to different software versions (e.g., compilers version).

To open a shell in the Docker image with all the needed dependencies just run:

```bash
cd docker/
docker build -t omnvdocker .
cd ../../
docker run -it --rm --user $(id -u):$(id -g) -v /etc/passwd:/etc/passwd:ro --net=host --name jhomnv -v ./Omnivisor:/home omnvdocker /bin/bash
```

> [!NOTE]
> You may need to specify the entire absolute path to Omnivisor: change ./Omnivisor with \<your path\>/Omnivisor

Once in the docker container, move to the home directory

```bash
cd ~
```

It is possible to run the scripts without docker but you will need the following packages (we don't recommend it):

```bash
apt-get update
apt-get install -y git make sed binutils diffutils python3 ninja-build build-essential bzip2 tar findutils unzip cmake rsync u-boot-tools gcc-arm-none-eabi gcc-aarch64-linux-gnu libglib2.0-dev libpixman-1-dev wget cpio rsync bc libncurses5 flex bison openssl libssl-dev kmod python3-pip file pkg-config
pip3 install Mako
```


## How to use the repository

> [!NOTE]
> For each script you can use the flag _-h_ (help) to understand the behavior of the script and the accepted flags.

### 1. Download, configure, and compile everything

Launch the following script to download, configure and compile all the "To-Build Components" for the chosen \<target\> (e.g. kria) and \<backend\> (e.g. jailhouse):

```bash
./scripts/configure_everything.sh -t kria -b jailhouse
```

From now on the chosen target and backend will be the default ones. If you need to change for some reason the default target and backend, we provide the script "change_environment":

```bash
./scripts/change_environment.sh -t <target> -b <backend>
```

Otherwhise if you need to change the target and backend just for a single script you can always add the flags -t \<target\> -b \<backend\>.

### 2. Test the Board

After the "configure_everything" script, the produced images can be loaded on the SD card to be tested.

Format an sd card (at least 8GB) with a boot (1GB fat) and root (rest of space, ext4) partitions:

```bash
sudo fdisk /dev/sdcard
# Command (m for help): d # and accept all prompts, until there are no more partitions
# Command (m for help): w
sudo fdisk /dev/sdcard
# Command (m for help): n # all default, except size (last sector) +1GB
# Command (m for help): a # to make it bootable
# Command (m for help): n # all default
# Command (m for help): w
sudo mkfs.fat /dev/sdcardpart1 -n boot
sudo mkfs.ext4 -L root /dev/sdcardpart2 
```

The boot images from the directory "Omnivisor/environment/\<target\>/\<backend\>/output/boot" must be transfered to the boot partition of the SD card ($SD\_BOOT\_PARTITION).

```bash
cp ./Omnivisor/environment/kria/jailhouse/output/boot/Image $SD_BOOT_PARTITION
cp ./Omnivisor/environment/kria/jailhouse/output/boot/BOOT.BIN $SD_BOOT_PARTITION
cp ./Omnivisor/environment/kria/jailhouse/output/boot/boot.scr $SD_BOOT_PARTITION
cp ./Omnivisor/environment/kria/jailhouse/output/boot/system.dtb $SD_BOOT_PARTITION
```

the generated rootfs from the directory "Omnivisor/environment/\<target\>/\<backend\>/output/rootfs" must be transfered to the root partition of the SD card ($SD\_ROOT\_PARTITION). 

```bash
tar xf ./Omnivisor/environment/kria/jailhouse/output/rootfs/rootfs.tar -C $SD_ROOT_PARTITION
```

Insert the SD-card in the board, start it, and insert the following User and Password:

```bash
login:    root
Password: root
```

### 3. Configure ssh [OPTIONAL]

While the board is running, use the following script on the host machine to create a local key pair for the user (if it doesn't exist) and send the pub key to the target to authorize the host to exchange data without requiring any password

```bash
./scripts/remote/set_remote_ssh.sh
```

Then in the board copy the authorized keys in the .ssh directory if it has been saved in the dropbear directory

```bash
cd ~
mkdir .ssh
cp /etc/dropbear/authorized_keys ~/.ssh
```


### 4. Load projects

Use the following script to sync the install directory (as an overlay filesystem) in the target file system:

```bash
./scripts/remote/load_install_dir_to_remote.sh
```

Use the following script to load (or update if already loaded) Jailhouse in the board filesystem (run with -h flag for help).

```bash
./scripts/remote/load_components_to_remote.sh -j
```

Verify in the /root directory if the files have been loaded correctly.

### 5. Test the Omnivisor

Update the PATH by logging again:

```bash
exit
```

```bash
login:  root
Password: root
```

Verify that the jailhouse PATH have been exported correctly by printing the version:

```bash
jailhouse --version
```

Load the jailhouse hypervisor, using the previously loaded script:

```bash
cd scripts_jailhouse_<target>/
sh jailhouse_start.sh
```

Verify that the rootcell is running:

```bash
jailhouse cell list
```

Try to create baremetal cell:

```bash
sh gic_demo.sh
```

Stop the baremetal cell:

```bash
jailhouse cell destroy inmate-demo
```


You can open an ssh connection to take control of the rootcell while the non-rootcell is running.
To do it, open another shell and in the runphi directory launch:

```bash
./scripts/remote/ssh_connection.sh 
```

## Warnings

> [!WARNING]
> In order to run Jailhouse, the Linux kernel needs to be configured enabling CONFIG_OF_OVERLAY, CONFIG_KALLSYMS_ALL, and CONFIG_KPROBES.
