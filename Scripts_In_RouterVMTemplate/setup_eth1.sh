#!/bin/sh
nmcli c m eth1 ipv4.address $1 ipv4.method manual
nmcli c down eth1
nmcli c up eth1
cp /etc/sysconfig/network-scripts/ifcfg-eth1 /root/routerVM_setup
