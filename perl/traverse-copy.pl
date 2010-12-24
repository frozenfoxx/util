#!/usr/bin/perl
########################################################
# Name:		traverse-copy.pl
# Author:	FOXX (frozenfoxx@github.com)
# Date:		11/12/2010
# Description:	this script is purposebuilt to traverse
#  a complex tree in the file system and retrieve the
#  files at its location given a file of case numbers.
########################################################
use strict;

# Variable declaration
my $inputLocation = "/home/user/traverse-copy-input/";
my $outputLocation = "/home/user/traverse-copy-output/";

# Read in the file name from the invocation
open(INPUTDATA, "<$ARGV[0]") || die "Error opening $ARGV[0].";
my @caseArray = <INPUTDATA>;
close(INPUTDATA); 

# Remove '\n' from the end of each line in the array
chomp(@caseArray);

# Iterate over the the list of case numbers
foreach my $caseNum (@caseArray) {
  my @nextDir = split( '', $caseNum);
  system("cd", "$inputLocation");

  # Iterate over the characters in the case number
  foreach my $i (@nextDir) {
    system( "cd", "$i" );
  }

  # Copy file elsewhere
  system("cp", "\*", "$outputLocation");
}

print "File copying complete.";
