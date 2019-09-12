#!/bin/sh
nmcli c m $1 $2 $3
nmcli c m $1 ipv4.method manual
nmcli c down $1
nmcli c up $1
