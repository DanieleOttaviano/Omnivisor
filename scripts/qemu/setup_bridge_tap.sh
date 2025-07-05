#!/bin/bash

### This script setup host bridge (by defualt br0) and tap device on QEMU VM (tap0 by default) to allows networking between
### root cell and non-root cells 
### Ref: https://gist.github.com/extremecoders-re/e8fd8a67a515fee0c873dcafc81d811c?permalink_comment_id=4540628#gistcomment-4540628

### TODO: brdige network (now 192.0.3.0 is hardcoded) should be a param, as well as netmask and gateway

BRIDGE_NAME="br0"
DEFAULT_HOST_NIC=$(ip route|grep default|awk '{print $5}') # get main NIC by getting default route device
BRIDGE_NETWORK=192.0.3.0
BRIDGE_NETMASK=255.255.255.0
BRIDGE_GATEWAY=192.0.3.1
# BRIDGE_DHCPRANGE=192.0.3.2,192.0.3.100 ### use in the future
TAP_NAME="tap0"

### Install pre-requisites packages

apt-get install iproute2 iptables

ip link add ${BRIDGE_NAME} type bridge
ip link set dev ${BRIDGE_NAME} up
ip addr add dev ${BRIDGE_NAME} ${BRIDGE_GATEWAY}/${BRIDGE_NETMASK}

sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1

#iptables --flush
#iptables -t nat -F
#iptables -X
#iptables -Z
#iptables -P PREROUTING ACCEPT
#iptables -P POSTROUTING ACCEPT
#iptables -P OUTPUT ACCEPT
#iptables -P INPUT ACCEPT
#iptables -P FORWARD ACCEPT
#iptables -A INPUT -i ${BRIDGE_NAME} -p tcp -m tcp --dport 67 -j ACCEPT
#iptables -A INPUT -i ${BRIDGE_NAME} -p udp -m udp --dport 67 -j ACCEPT
#iptables -A INPUT -i ${BRIDGE_NAME} -p tcp -m tcp --dport 53 -j ACCEPT
#iptables -A INPUT -i ${BRIDGE_NAME} -p udp -m udp --dport 53 -j ACCEPT

iptables -A FORWARD -i ${BRIDGE_NAME} -o ${BRIDGE_NAME} -j ACCEPT
iptables -A FORWARD -s ${BRIDGE_NETWORK}/${BRIDGE_NETMASK} -i ${BRIDGE_NAME} -j ACCEPT
iptables -A FORWARD -d ${BRIDGE_NETWORK}/${BRIDGE_NETMASK} -o ${BRIDGE_NAME} -m state --state RELATED,ESTABLISHED -j ACCEPT
# make a distinction between the bridge packets and routed packets, don't want the
# bridged frames/packets to be masqueraded.
iptables -t nat -A POSTROUTING -s ${BRIDGE_NETWORK}/${BRIDGE_NETMASK} -d ${BRIDGE_NETWORK}/${BRIDGE_NETMASK} -j ACCEPT
iptables -t nat -A POSTROUTING -s ${BRIDGE_NETWORK}/${BRIDGE_NETMASK} -j MASQUERADE

ip tuntap add dev ${TAP_NAME} mode tap user $(whoami)
ip link set ${TAP_NAME} master ${BRIDGE_NAME}
ip link set dev ${TAP_NAME} up

# set the traffic get through the wireless
iptables -A FORWARD -i ${BRIDGE_NAME} -o ${DEFAULT_HOST_NIC} -j ACCEPT
iptables -t nat -A POSTROUTING -o ${DEFAULT_HOST_NIC} -j MASQUERADE
# let the known traffic get back at bridge
iptables -A FORWARD -i ${DEFAULT_HOST_NIC} -o ${BRIDGE_NAME} -m state --state RELATED,ESTABLISHED -j ACCEPT
