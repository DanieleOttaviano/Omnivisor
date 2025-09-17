# Kria Board Environment Setup Guide

The kria boars doesn't boot the firmware from SD but it uses the pre-defined BOOT.BIN in the QSPI memory which contains: 
- zynqmp_fsbl.elf
- pmufw.elf
- system.bit
- bl31.elf
- u-boot.elf

To update the firmware with the new one produced in this repo, the easiest way is to use the xilinx utilities present in the ubuntu stable version for the board available online.
Only after that we can rewrite the sd card with the other artifacts produced within this repo (e.g., Image, filesystem)

## Loading a Stable Ubuntu on the SD Card

### 1. Download Ubuntu Image:
- Visit the official Ubuntu website and download the Image (22.04): https://ubuntu.com/download/amd

### 2. Prepare the SD Card:
  - Insert the SD card into your computer.
  - Discover the internal storage device name: This is usually /dev/sda but it’s important to first make sure. 
    One of the easiest ways is to open GPartEd and use the drop-down menu in the top-right to select the correct
    device. You’ll see storage space and layout below. Make a note of the device name.
  - Use `dd` to write the Ubuntu image to the SD card:
  - Open the terminal application and enter the following command, adjusting the paths to the Ubuntu Core download and the internal storage device accordingly:
    ```sh 
    xzcat ~/Downloads/<ubuntu_image>.img.xz | \
    sudo dd of=/dev/<target disk device> bs=32M status=progress; sync
    ```

### 3. Boot the Kria Board:
  - Insert the SD card into the Kria board.
  - Connect the board to a power source and to the PC using the uart.
  - Power on the board.
  - Connect to the uart using picocom (or minicom).
    ```sh
    sudo picocom -b 115200 /dev/ttyUSB1
    ```

## Build The Environment
Launch the build_environment.sh script to generate the needed artifacts.

  - Enter the docker container.
```sh
  make run
```
  - Launch the build.
```sh 
  ./scripts/build_environment.sh -t kr260 -b jailhouse
```

## Load BOOT.BIN into QSPI

To chage the BOOT.BIN into the QSPI memory, we can use the xmutil applicaiton in the Ubuntu image we loaded 
(see [Kria_SOM_Boot_Firmware_Update](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/3020685316/Kria+SOM+Boot+Firmware+Update) for further information).

Copy the BOOT.BIN generated in the target platform:
```sh
scp environment/kr260/jailhouse/output/boot/BOOT.BIN ubuntu@<IP>:~/
```

In the platform launch the following command after coping the correct BOOT.BIN generated through this repo:
```sh
sudo xmutil bootfw_update -i <path to boot.bin>
```

The system has a backup firmware management with two separated system called A and B. 
Using the following command you should see that the loaded firmware will be the next to be booted: 
```sh
sudo xmutil bootfw_status
```

Then reboot the board:
```sh
sudo reboot
```

If the atf and u-boot are correctly loaded you need to save it before the next reboot.
Login into the Ubuntu image of the kria again and launch the following command to do it:
```sh
sudo xmutil bootfw_update -v
```

## Load the other artifacts
The other produced images can be loaded on the SD card to be tested.

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

The boot images from the directory "environment/\<target\>/\<backend\>/output/boot" must be transfered to the boot partition of the SD card ($SD\_BOOT\_PARTITION).

```bash
cp ./environment/kria/jailhouse/output/boot/Image $SD_BOOT_PARTITION
cp ./environment/kria/jailhouse/output/boot/BOOT.BIN $SD_BOOT_PARTITION
cp ./environment/kria/jailhouse/output/boot/boot.scr $SD_BOOT_PARTITION
cp ./environment/kria/jailhouse/output/boot/system.dtb $SD_BOOT_PARTITION
```

the generated rootfs from the directory "environment/\<target\>/\<backend\>/output/rootfs" must be transfered to the root partition of the SD card ($SD\_ROOT\_PARTITION).

```bash
tar xf ./environment/kria/jailhouse/output/rootfs/rootfs.tar -C $SD_ROOT_PARTITION
```

Insert the SD-card in the board, start it, and insert the following User and Password:

```bash
login:    root
Password: root
```
