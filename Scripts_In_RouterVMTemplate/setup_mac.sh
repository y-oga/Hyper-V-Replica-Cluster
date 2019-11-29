#!/bin/sh
systemctl stop network
rm -f /etc/sysconfig/network-scripts/ifcfg-eth0
rm -f /etc/sysconfig/network-scripts/ifcfg-eth1
cp /root/routerVM_setup/ifcfg-eth0.bak /etc/sysconfig/network-scripts/ifcfg-eth0
cp /root/routerVM_setup/ifcfg-eth1.bak /etc/sysconfig/network-scripts/ifcfg-eth1
chmod 600 /etc/sysconfig/network-scripts/ifcfg-eth0
chmod 600 /etc/sysconfig/network-scripts/ifcfg-eth1
systemctl start network
