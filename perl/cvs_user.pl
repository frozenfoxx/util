#!/usr/bin/perl
########################################################
# Name:		cvs_user.pl
# Author:	FOXX (frozenfoxx@github.com)
# Date:		08/01/2010
# Description:	this script is a simple way to add
#		users to CVS.
########################################################

# VARIABLES
$cvsroot="/path_to_cvs_root";
@chars = ('A'..'Z', 'a'..'z', '0'..'9');

# Verify that you have received the "user" as input
$user = shift @ARGV || die "cvs_user.pl <user>\n";

# Request a password for the user
print "Enter password for $user: ";

# Do not show the password for said user on the screen
system "stty -echo";

# Receive input for the password and remove the trailing \n
chomp ($plain = <>);

# Turn terminal output back on
system "stty echo";

print "\n";

# Set up the salt
$salt = $chars[rand(@chars)] . $chars[rand(@chars)];

# Encrypt the plaintext
$passwd = crypt($plain, $salt);

# Write user to the end of the file
open(PASSWD,">>$cvsroot/CVSROOT/passwd") || die("Cannot open password file!");
print PASSWD "$user:$passwd:cvs\n";
close PASSWD;

print "Password file updated."
