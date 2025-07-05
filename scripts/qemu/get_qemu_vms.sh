#!/bin/bash

qemu_process=$(ps aux|grep "qemu-system-" | grep -v "grep")
pids=$(echo ${qemu_process} | awk '{print $2}')
echo "PIDs: ${pids}"
