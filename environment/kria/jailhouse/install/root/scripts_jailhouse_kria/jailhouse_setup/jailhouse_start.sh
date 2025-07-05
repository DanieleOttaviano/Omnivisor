#!/bin/bash

# Default cell configuration
PLATFORM="zynqmp-kv260"

# Check for input parameter
if [ "$1" == "-o" ] || [ "$1" == "--omnv" ]; then
       ROOT_CELL="${PLATFORM}-omnv.cell"
elif [ "$1" == "-c"] || [ "$1" == "--clean" ]; then
       ROOT_CELL="${PLATFORM}.cell"
elif [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
       echo "Usage: $0 [-o | --omnv] [-h | --help]"
       echo "Options:"
       echo "  -o, --omnv    Use the OMNV cell configuration"
       echo "  -c, --clean   Use the clean cell configuration"
       echo "  -h, --help    Display this help message"
       echo "Default: ${PLATFORM}-omnv.cell"
       exit 0
else
       ROOT_CELL="${PLATFORM}-omnv.cell" # Default to OMNV cell if no parameter is provided
fi

echo "Using root cell configuration: ${ROOT_CELL}"

# Check if the firmware directory exists
if [ -d "/lib/firmware" ]; then
       echo "firmware directory exists!"
else
       mkdir /lib/firmware
fi

# Clean up
jailhouse disable
rmmod jailhouse

# Copy the hypervisor image in the firmware directory
cp ${JAILHOUSE_DIR}/hypervisor/jailhouse.bin /lib/firmware/

# Insert the jailhouse module
insmod ${JAILHOUSE_DIR}/driver/jailhouse.ko

# Start the hypervisor
jailhouse enable ${JAILHOUSE_DIR}/configs/arm64/${ROOT_CELL}
