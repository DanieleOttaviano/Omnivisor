#!/bin/bash

#echo "Loading bin ..."
jailhouse cell load inmate-demo-RPU  ${JAILHOUSE_DIR}/inmates/demos/armr5/baremetal-demo_tcm.bin -a 0xffe00000  ${JAILHOUSE_DIR}/inmates/demos/armr5/baremetal-demo.bin
