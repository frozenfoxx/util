#!/bin/sh
#######################################################
# Name:		beaglebone_wakeup.sh
# Author:	FOXX (frozenfoxx@github.com)
# Date:		09/26/2013
# Description:	this trick wakes up the Beaglebone
#		Black from HDMI sleep mode.
#######################################################
echo 0 > /sys/class/graphics/fb0/blank
