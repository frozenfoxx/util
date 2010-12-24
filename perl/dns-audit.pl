#!/usr/bin/perl 

###
### This perl script will go out and check any given name server for 
### any given block of reverse IP addresses.
### 
### It will: 
###    1) Query the name server for every single IP address within the block 
###       that you give it and record the forward names.
###    2) Then go and query the forward names and make sure that they match 
###       the reverse.
###    3) Spit out a warning error if any do not match.
###
### Features:
###   Takes network blocks in CIDR notation.
###   Can turn on full list of forward / reverse names or just see errors.
###
### Uses CPAN modules:
###
###    Net::DNS::Resolver
###    NetAddr::IP
###
### Submitted by: Scott van Kalken
###

use Net::DNS::Resolver;
use NetAddr::IP;
use Getopt::Long;

use vars qw/ %opt /;

#############################################################################
#                                                                           #
# Sub to perform DNS lookup                                                 #
# Too lazy to write one sub with var for fw/rev so did two instead          #
#                                                                           #
#############################################################################
sub revlookup {
    my $res = Net::DNS::Resolver->new;
    $res->nameservers($server);
    my $search = $res->search($input);

    if ($search) {
        foreach $rr ($search->answer) {
            my $type = $rr->type;
            if ($type eq "A") {
                $host = $rr->address;
            }
            
            if ($type eq "PTR") {
                $host = $rr->ptrdname;
            } else {
                print "$input\t$rr->type\n";
            }
            
            if ($pr) {
                print "$input\t$host\n";
            }

            push(@reverseip,$input);
            push (@reversename, $host);
        }
    }
}

sub fwlookup {
    my $res = Net::DNS::Resolver->new;
    $res->nameservers($server);
    my $search = $res->search($input);

    if ($search) {
        foreach $rr ($search->answer) {
            my $type = $rr->type;
            if ($type eq "A") {
                $host = $rr->address;
            }
            
            if ($type eq "PTR") {
                $host = $rr->ptrdname;
            }
            
            if ($type eq "CNAME") {
                $host = $rr->cname;
            } else {
                #print "$input\t$rr->type\n";
            }
            
            if ($pf) {
                print "$input\t$host\n";
            }

            push(@forwardip,$host);
            push (@forwardname, $input);
        }
    } else {
        push (@forwardip, $res->errorstring);
        push (@forwardname, $input);
    }
}

#############################################################################
#                                                                           #
# sub to check command line options passed to program for validity          #
#                                                                           #
#############################################################################
sub options {
    
    if ($#ARGV lt 0) {
        &usage;
    }

    GetOptions ("r:s" => \$cidr,
        "h" => \$help,
        "s:s" => \$server,
        "pr" => \$pr,
        "pf" => \$pf);
        
    &usage if $help;
    &usage if not $cidr;
    &usage if not $server;
}


#############################################################################
#                                                                           #
# sub to display a usage message                                            #
#                                                                           #
#############################################################################
sub usage {
    print "-h help message\n";
    print "-r [range] to search in CIDR format: 128.0/8\n";
    print "-s [server] to direct queries to\n";
    print "-pf print forward names as they are looked up\n";
    print "-pr print reverse names as they are looked up\n";
    
    exit 1;
}


#############################################################################
#                                                                           #
# Main program                                                              #
# Too lazy to write sub to do check so just shoved it in here               #
#                                                                           #
#############################################################################

&options;

my $ip = new NetAddr::IP($cidr);
$range = $ip->range();
$bcast = $ip->broadcast();

print "Searching range: $range: Broadcast $bcast\n";
while ($ip < $ip->broadcast) {
    ($iponly,$mask) = split /\//, $ip;
    $input = $iponly;
    &revlookup;
    $ip++;
}

foreach (@reversename) {
   $input = $_;
   &fwlookup;
}

for ($count = 0; $count ne $#reversename; $count++) {
    $revip = $reverseip[$count];
    $revname = $reversename[$count];
    $fwip = $forwardip[$count];
    $fwname = $forwardname[$count];

    if ($revip ne $fwip) {
        print "\n\n";
        print "REVERSE: $revip\t$revname\n";
        print "FORWARD: $fwname\t$fwip\n";
    }
    
    if ($fwname ne $revname) {
        print "\n\n";
        print "WARNING: $revname\t$fwname\n";
    }
} 



##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
###  Copyright Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.jsp
##############################################################################


