#!/bin/sh
rm -f /etc/quagga/ospfd.conf
cp /etc/quagga/ospfd.conf.bak2 /etc/quagga/ospfd.conf
chown quagga:quagga /etc/quagga/ospfd.conf
systemctl restart ospfd
rm -f /etc/quagga/ospfd.conf.bak1
rm -f /etc/quagga/ospfd.conf.bak2
