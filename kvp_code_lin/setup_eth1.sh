#!/bin/sh
nmcli c m eth1 ipv4.address $1 ipv4.method manual
nmcli c down eth1
nmcli c up eth1
