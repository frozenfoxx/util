#!/usr/bin/perl
########################################################
# Name:		cpuhog.pl
# Author:	FOXX (frozenfoxx@github.com)
# Date:		06/20/2009
# Description:	this script is a quick test way to eat
#		CPU resources, useful for determining
#		if FSS/CFM processor scheduling in
#		Solaris/Linux is properly working.
########################################################

print "Chewing CPU resources..."

foreach $i (1..16) {
	$pid = fork();
	last if $pid == 0;
	print "Created PID $pid\n";
}

while (1) {
	$x++;
}
