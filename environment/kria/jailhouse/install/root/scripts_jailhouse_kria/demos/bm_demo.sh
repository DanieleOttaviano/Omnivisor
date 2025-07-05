#!/bin/bash

PLATFORM="zynqmp-kv260"

CPUs=( "RPU0" "RPU1" "APU" "RISCV" )

echo "Platform: ${PLATFORM}"

# Check if the first argument is provided, otherwise prompt the user
if [ -z "$1" ]; then
    echo "Please choose the CPU where to launch the inmate cell(RPU0, RPU1, APU, RISCV):"
    read CELL_CHOICE
else
    CELL_CHOICE=$1
fi

# CPU choice validation
if [[ ! " ${CPUs[@]} " =~ " ${CELL_CHOICE} " ]]; then
    echo "Invalid CPU choice (RPU0, RPU1, APU, RISCV)."
    exit 1
fi
# Map the user input to the corresponding cell file
BAREMETAL_INMATE_CELL="${PLATFORM}-${CELL_CHOICE}-inmate-demo.cell"
INMATE="inmate-demo-${CELL_CHOICE}"
ARCH=$(case $CELL_CHOICE in
    APU) echo "arm64" ;;
    RPU0) echo "armr5" ;;
    RPU1) echo "armr5" ;;
    RISCV) echo "riscv" ;;
esac)
RCPU_NUM=$(case $CELL_CHOICE in
    APU) echo "" ;;
    RPU0) echo "0" ;;
    RPU1) echo "1" ;;
    RISCV) echo "2" ;;
esac)

# Check if the second argument is provided, otherwise prompt the user
if [ -z "$2" ]; then
    echo "Please choose the demo to launch from the following options:"
    if [ "$ARCH" == "arm64" ]; then
        for demo_file in ${JAILHOUSE_DIR}/inmates/demos/${ARCH}/*-demo.bin; do
            demo_name=$(basename "$demo_file" | sed 's/-demo\.bin//')
            echo "$demo_name"
        done
    else
        for demo_file in ${JAILHOUSE_DIR}/inmates/demos/${ARCH}/src*/${CELL_CHOICE,,}-*-demo.elf; do
            demo_name=$(basename "$demo_file" | sed -E "s/^${CELL_CHOICE,,}-(.*)-demo\.elf$/\1/")
            echo "$demo_name"
        done
    fi
    read DEMO_CHOICE
else
    DEMO_CHOICE=$2
fi
# Check if the demo choice is valid
DEMO_VALID=false
if [ "$ARCH" == "arm64" ]; then
    for demo_file in ${JAILHOUSE_DIR}/inmates/demos/${ARCH}/*-demo.bin; do
        demo_name=$(basename "$demo_file" | sed 's/-demo\.bin//')
        if [ "$demo_name" == "$DEMO_CHOICE" ]; then
            DEMO_VALID=true
            DEMO_BIN="${demo_name}-demo.bin"
            break
        fi
    done
else
    for demo_file in ${JAILHOUSE_DIR}/inmates/demos/${ARCH}/src*/${CELL_CHOICE,,}-*.elf; do
        demo_name=$(basename "$demo_file" | sed -E "s/^${CELL_CHOICE,,}-(.*)-demo\.elf$/\1/")
        if [ "$demo_name" == "$DEMO_CHOICE" ]; then
            DEMO_VALID=true
            DEMO_BIN="${CELL_CHOICE,,}-${demo_name}-demo.elf"
            break
        fi
    done
fi

if [ "$DEMO_VALID" == false ]; then
    echo "Invalid demo choice. Exiting."
    exit 1
fi

jailhouse cell create ${JAILHOUSE_DIR}/configs/arm64/${BAREMETAL_INMATE_CELL}
if [ "$CELL_CHOICE" == "APU" ]; then
    jailhouse cell load ${INMATE} ${JAILHOUSE_DIR}/inmates/demos/${ARCH}/${DEMO_BIN}
else
    jailhouse cell load ${INMATE} -r ${DEMO_BIN} ${RCPU_NUM}
fi
jailhouse cell start ${INMATE}