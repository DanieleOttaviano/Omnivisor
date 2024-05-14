#!/bin/bash

#WARNING: configure with the right .cell
BAREMETAL_INMATE_CELL="zynqmp-kv260-RISCV-inmate-demo.cell"

jailhouse cell destroy inmate-demo-RISCV

jailhouse cell create ${JAILHOUSE_DIR}/configs/arm64/${BAREMETAL_INMATE_CELL}
jailhouse cell load inmate-demo-RISCV ${JAILHOUSE_DIR}/inmates/demos/riscv/riscv-demo.bin 
jailhouse cell start inmate-demo-RISCV