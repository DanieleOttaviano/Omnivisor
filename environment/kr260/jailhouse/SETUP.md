# Kria kr260 Board Environment with UBUNTU Setup Guide
To have a stable setup, the idea is to load a certfied ubuntu on the sd card of the board. 
Then update the arm-trusted-firmware, the Kernel Image and the device tree to enable Jailhouse and Omnivisor. 

## Loading a Stable Ubuntu on the SD Card

1. **Download Ubuntu Image:**
    - Visit the official Ubuntu website and download the Image (24.04) for the kr260 baord: https://ubuntu.com/download/amd

2. **Prepare the SD Card:**
    - Insert the SD card into your computer.
    - Discover the internal storage device name: This is usually /dev/sda but it’s important to first make sure. 
      One of the easiest ways is to open GParted (sudo apt install gparted) and use the drop-down menu in the top-right to select the correct
      device. You’ll see storage space and layout below. Make a note of the device name. Make sure to remove all partition and clean the sd.
    - Use `dd` to write the Ubuntu image to the SD card:
    - Open the terminal application and enter the following command, adjusting the paths to the Ubuntu Core download and the internal storage device accordingly:
      ```sh 
      xzcat ~/Downloads/<ubuntu_image>.img.xz | \
      sudo dd of=/dev/<target disk device> bs=32M status=progress; sync
      ```

3. **Boot the Kria Board:**
    - Insert the SD card into the Kria board.
    - Connect the board to you PC using the uart
    - Connect to the uart using picocom (or minicom).
      ```sh
      picocom -b 115800 /dev/ttyUSB1
      ```
    - Connect the ethernet port (the up-right one) to the network.
    - Connect the board to a power source to power on the board.

4. **Setup new password**
    - Check that the boot complete succesfully.
    - Setup new Password

## Build The Environment
Launch the build_environment.sh script to generate the needed Kernel Image and jailhouse/omnivisor.
  - Enter the docker container.
```sh
  make run
```
  - Launch the build.
```sh 
  ./scripts/build_environment.sh -t kr260 -b jailhouse
```

## Update arm trusted firmware
The kria boars doesn't boot from SD but it uses the pre-defined BOOT.BIN in the QSPI memory which contains: 
- zynqmp_fsbl.elf
- pmufw.elf
- system.bit
- bl31.elf
- u-boot.elf

We need to change it since for 2 reasons: 
- We need to change the bl31.elf for using the Omnivisor and Memguard.
- we may need to change the bitstream loaded at boot time. 

To chage the BOOT.BIN into the QSPI memory, we can use the xmutil applicaiton in the Ubuntu image we loaded 
(see https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/3020685316/Kria+SOM+Boot+Firmware+Update).

Copy the BOOT.BIN produced during the build of the environment into the board: 
```sh
scp environment_builder/environment/kr260/jailhouse/output/boot/BOOT.BIN ubuntu@<IP>:~/
```
In the board launch the following command after coping the correct BOOT.BIN:
```sh
sudo xmutil bootfw_update -i <path to boot.bin>
```
The system has a backup firmware management with two separated system called A and B. 
Using the following command you should see that the loaded firmware will be the next to be booted: 
```sh
sudo xmutil bootfw_status
```

Then reboot the board, if the atf and u-boot are correctly loaded you need to save it before the next reboot.
Login into the Ubuntu image of the kria again and launch the following command to do it:
```sh
sudo xmutil bootfw_update -v
```


## Load new Kernel Image and the DTB overlay
Now we need to update the kernel with the one we compiled in this repo during the building of the environment,
and we need to upload the device tree overlay for seeing the remotecore, and for reserving memory for jailhouse.
N.B. to use ssh on the root you need to setup the "/etc/ssh/sshd_config" file: 

```sh
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
```
then we can copy the artifacts:
```sh
scp environment/kr260/jailhouse/output/boot/Image root@<IP>:/boot/firmware/Image
scp environment/kr260/jailhouse/output/boot/system.dtb root@<IP>:/boot/firmware/user-override.dtb
```
then reboot the board and stop the boot before u-boot autobooting.


## Load Jailhouse
Now you just need to load jailhouse on the board. We can load all the jailhouse directory 
```sh
scp environment/kr260/jailhouse/build/jailhouse root@<IP>:/root
```

## Load the install directory
To have the demo, the scripts and so on you can load the install directory:
```sh
scp -r environment/kr260/jailhouse/install/* root@<IP>:/
```