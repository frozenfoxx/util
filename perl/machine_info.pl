#!/usr/bin/perl

# Script to output machine configuration.
# Has verbose mode as well as "normal" mode.
# Has the facility to allow you to choose which configuration items you want.

# v1.0

use IPC::Open3;
use Data::Dumper;

sub options
{
        use Getopt::Long;
        if ($#ARGV lt 0)
        {
                &usage;
        }
        GetOptions ("cpu|c"             => \$cpu,
                    "memory|m"          => \$memory,
                    "verbose|v"         => \$verbose,
                    "release|r"         => \$release,
                    "hostid|h"          => \$hostid,
                    "obp|o"             => \$obp,
                    "disk|d"            => \$disk,
                    "help"              => \$help);
        &usage if $help;
}

# sub routine to print out the usage if the no command line arguments are passed.
sub usage
{
        print "-cpu or -c: Display CPU information [verbose will show cpu information]\n";
        print "-memory or -m: Display memory information [verbose will show dimm information]\n";
        print "-release or -r: OS information\n";
        print "-obp or -o: Display OBP version\n";
        print "-disk or d: Display disk information\n";
        print "-v or -verbose: Verbose\n";
        print "-help help message\n";

        exit 1;
}

&options;

sub external_command(@)
{
        $cmd=shift;
        $resource=shift;
        $pid = open3(\*P_IN, \*P_OUT, \*P_ERR, $cmd );
        close(P_IN);
        @output=<P_OUT>;
        @error=<P_ERR>;
        if ( $#output == 0 )
        {
                $output=$output[0];
                $output=~ s/^\s+//;
                $output=~ s/s+$//;
                print "$resource: $output\n";
        }
        if ( @error )
        {
                print "There was an error running the command $cmd\n";
                if ( $verbose )
                {
                        print "\n@error\n";
                }
        }
}

if ( $cpu )
{
        $command='/usr/sbin/psrinfo -p';
        $resource='physical cpus';
        print "================\n";
        &external_command($command, $resource);

        if ( $verbose )
        {
                $num_cpu=`/usr/sbin/psrinfo | wc -l`;
                for ($count=0; $count <= $num_cpu-1; $count++)
                {
                        $cpuinfo[$count]=`/usr/sbin/psrinfo -v $count`;
                        ($junk,$megahertz)=split (/processor operates at /, $cpuinfo[$count]);
                        ($megahertz,$junk)=split (/,/, $megahertz);
                        print "\tCPU: $count\n";
                        print "\tCPU Speed: $megahertz\n";
                        print "\n";
                }
        }
}
if ( $memory )
{
        $command='/usr/sbin/prtconf | grep Mem | awk -F":" \'{print $2}\'';
        $resource='memory';
        print "================\n";
        &external_command($command, $resource);

        if ( $verbose )
        {
                $unamei=`uname -i`;
                chomp $unamei;
                if ( $unamei ne "i86pc" )
                {
                        @dimms=`prtfru | grep mem-module`;
                        foreach ( @dimms )
                        {
                                ($fruhandle,$junk) = split /\(container\)/, $_;
                                #print $fruhandle;
                                ($junk,$payload)=split(/system-board/, $fruhandle);
                                #print $payload;
                                ($a,$b,$c,$d,$e,$f,$g,$h)=split(/\?Label=/, $payload);
                                ($junk,$processor)=split(/\//, $a);
                                ($junk,$bank)=split(/cpu\//, $b);
                                ($junk,$dimmlocation)=split(/bank\//, $c);
                                print "Location:\n";
                                print "\tProcessor: $processor\n";
                                print "\tBank: $bank\n";
                                print "\tDimm: $dimmlocation\n";
                                $currentCapacity=`prtfru $fruhandle | grep DIMM_Capacity`;
                                ($junk,$currentCapacity)=split(/: /,$currentCapacity);
                                $currentType=`prtfru $fruhandle | grep Fundamental_Memory_Type`;
                                ($junk,$currentType)=split(/: /, $currentType);
                                $currentAccessTime=`prtfru $fruhandle | grep Access_Time`;
                                ($junk,$currentAccessTime)=split(/: /, $currentAccessTime);
                                $currentConfigType=`prtfru $fruhandle | grep DIMM_Config_Type`;
                                ($junk,$currentConfigType)=split(/: /, $currentConfigType);
                                $currentVendorName=`prtfru $fruhandle | grep Vendor_Name`;
                                ($junk,$currentVendorName)=split(/: /, $currentVendorName);
                                $currentPartNumber=`prtfru $fruhandle | grep Manufacturer_Part_No`;
                                ($junk,$currentPartNumber)=split(/: /, $currentPartNumber);
                                $currentRevCode=`prtfru $fruhandle | grep Module_Rev_Code`;
                                ($junk,$currentRevCode)=split(/: /, $currentRevCode);
                                $currentYear=`prtfru $fruhandle | grep Manufacture_Year`;
                                ($junk,$currentYear)=split(/: /, $currentYear);
                                $currentWeek=`prtfru $fruhandle | grep Manufacture_Week`;
                                ($junk,$currentWeek)=split(/: /, $currentWeek);
                                $currentSerial=`prtfru $fruhandle | grep Assembly_Serial_No`;
                                ($junk,$currentSerial)=split(/: /, $currentSerial);
                                print "\n";
                                print "\tCapacity: $currentCapacity";
                                print "\tType: $currentType";
                                print "\tConfig Type: $currentConfigType";
                                print "\tAccess Time: $currentAccessTime";
                                print "\tVendor: $currentVendorName";
                                print "\tManufacture Date: $currentYear";
                                print "\tSerial Number:$currentSerial";
                                print "\tPart Number: $currentPartNumber";
                                print "\tRev Code: $currentRevCode";
                        }
                                print "\n";
                }
                else
                {
                        print "Verbose memory mapping not available on $unamei platform\n\n";
                }
        }

}
if ( $release )
{
        $command='uname -r';
        $resource='os version';
        print "================\n";
        &external_command($command, $resource);

        $command='head -1 /etc/release';
        $resource='release';
        print "================\n";
        &external_command($command, $resource);
}

if ( $obp )
{
        $command='/usr/sbin/prtconf -V';
        $resource='obp';
        print "================\n";
        &external_command($command, $resource);
}

if ( $hostid )
{
        $command='/usr/bin/hostid';
        $resource='hostid';
        print "================\n";
        &external_command($command, $resource);
}

if ( $disk )
{
        print "================\n";
        @disks=`iostat -Ern`;
        for ($count=0; $count<=$#disks;)
        {
                ($currentdisk,$junk)=split(/,/,$disks[$count]);
                print "DEVICE: $currentdisk";
                print "\n";
                if ( $verbose )
                {
                        $count=$count+1;
                        ($diskvendor,$diskproduct,$diskrevision,$diskserial)=split(/,/,$disks[$count]);
                        print "\t$diskvendor\n";
                        print "\t$diskproduct\n";
                        print "\t$diskrevision\n";
                        print "\t$diskserial";
                        $count=$count-1;
                }
                $count=$count+2;
                $disksize=$disks[$count];
                print "\t$disksize\n";
                $count=$count-2;

                $count=$count+5;
        }
}





##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.txt
##############################################################################


