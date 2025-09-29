# QEMU Environment Setup Guide

### Build The Environment
Launch the build_environment.sh script to generate the artifacts.

  - Enter the docker container.
```sh
  make run
```
  - Launch the build.
```sh 
  ./scripts/build_environment.sh -t qemu -b jailhouse
```

### Start the emulation
To start the emulation just run the following script:
```sh
  ./scripts/start_qemu.sh
```
Insert User and Password:

```bash
login:    root
Password: root
```

### Connect with ssh
Connect to the emulated board with the following command: 
```sh 
  ssh -p 2222 root@localhost
```
or using the script
```sh
  ./scripts/remote/ssh_connection.sh
```

### Connect to second uart (needed to visualize RPU cells output)
To connect to the second serial open a new terminal and connect to the docker container
```sh
  make connect
```

Then use telnet to connect to the second uart: 
```sh
  telnet localhost 4321
```