#!/usr/bin/ksh
################################################################
# Title:	zone-clone.ksh
# Date:		08/20/2010
# Author(s):	FOXX (frozenfoxx@github.com), Gerard Charleza
# Description:	This creates a new zone based upon another
#		template zone.
#
# The "template" zone must have already been created.
# It assumes there is only one network interface configured.                              
# You will be prompted for IP and hostname.
################################################################
                                                                                          
# The name of your template zone                                                          
MYZ=template                                                                              
# The directory under which zones will be created                                         
DIR=/zones_pool                                                                           
# Shared directory. This directory will be shared between global zone                     
# and all zones.                                                                          
SDIR=/admin_tools                                                                         

echo "Please enter the desired name and IP address of the new zone:"
echo "> \c"
read NAM MYADDRESS

# Find the main network interface
ifconfig -a | grep flags | grep -v lo0 | tr \: ' ' | read IMC rest > /dev/null 2>&1

#The control file for zonecfg utility
cat > ./zonecfgfile<<-END
        create -b
        set zonepath=$DIR/${NAM}
        set autoboot=true
        set ip-type=shared
        add inherit-pkg-dir
        set dir=$SDIR
        end
        add net
        set address=$MYADDRESS
        set physical=$IMC
        end
        set cpu-shares=10
END

echo '*************************'

cat ./zonecfgfile
zonecfg -z ${NAM} -f ./zonecfgfile
zoneadm -z $MYZ halt
zoneadm -z ${NAM} clone $MYZ

# cat > $DIR/${NAM}/root/etc/sysidcfg<<-END
# Default root password hash:  n0password
cat > $DIR/${NAM}/root/etc/sysidcfg<<-END
        system_locale=en_US
        terminal=xterm
        timezone=US/Eastern
        timeserver=localhost
        name_service=NONE
        network_interface=PRIMARY { hostname=${NAM} }
        security_policy=NONE
        root_password=xxxxxxxxxxx
        nfs4_domain=dynamic
        service_profile=limited_net
END
ex $DIR/${NAM}/root/etc/default/nfs<<-END
        /NFSMAPID_DOMAIN/s/^#//
        w!
        q!
END

zoneadm -z ${NAM} boot
