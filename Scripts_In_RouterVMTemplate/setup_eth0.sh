#!/bin/sh
nmcli c m eth0 ipv4.address $1 ipv4.gateway $2 ipv4.dns $3 ipv4.method manual
nmcli c down eth0
nmcli c up eth0
cp /etc/sysconfig/network-scripts/ifcfg-eth0 /root/routerVM_setup
