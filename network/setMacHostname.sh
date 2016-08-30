#!/bin/sh
tr -d ':' < /sys/class/net/eth0/address | xargs hostnamectl set-hostname
