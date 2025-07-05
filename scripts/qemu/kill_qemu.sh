#!/bin/bash

ps aux|grep "qemu-system-" | grep -v "grep"|grep -v "kill_qemu.sh"| awk '{print $2}' |xargs kill -9
