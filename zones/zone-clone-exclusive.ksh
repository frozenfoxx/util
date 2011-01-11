#!/usr/bin/ksh
################################################################
# Title:        zone-clone.ksh
# Date:         08/24/2010
# Author(s):    FOXX (frozenfoxx@github.com), Gerard Charleza
# Description:  This creates a new zone based upon another
#               template zone with an exclusive IP.
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

MYMASK=255.255.255.0
MYROUTE=100.1.100.100
MYDOMAIN=somedomain.net
RPASSWORD=e1KuiW8AE9lD2 #Root password is "zones",it should be changed after installation 

echo "Please enter the desired name, IP address, Interface, DNS server, and DNS server IP for the new zone:"
echo "Example:  zone1 10.1.100.1 bge0 somedns 100.1.0.10"
echo "> \c"
read NAM MYADDRESS IMC DNS_S DNS_IP

if [ "$DNS_S" ]
  then
    SETDNS="name_service=DNS { domain_name=$MYDOMAIN name_server=$DNS_S ( $DNS_IP )}"
  else
    SETDNS="name_service=NONE"
fi

#The control file for zonecfg utility
cat > ./zonecfgfile<<-END
        create -b
        set zonepath=$DIR/${NAM}
        set autoboot=true
        set ip-type=exclusive
        add inherit-pkg-dir
        set dir=$SDIR
        end
        add net
        set physical=$IMC
        end
END
echo '*************************'

cat ./zonecfgfile
zonecfg -z ${NAM} -f ./zonecfgfile
zoneadm -z $MYZ halt
zoneadm -z ${NAM} clone $MYZ

cat > $DIR/${NAM}/root/etc/sysidcfg<<-END
        system_locale=en_US
        terminal=xterm
        timezone=US/Eastern
        timeserver=localhost
        $SETDNS
        network_interface=primary { hostname=$NAM
        default_route=$MYROUTE
        ip_address=$MYADDRESS
        netmask=$MYMASK
        protocol_ipv6=no
        }
        security_policy=NONE
        root_password=$RPASSWORD
        nfs4_domain=dynamic
        service_profile=limited_net
END
ex $DIR/${NAM}/root/etc/default/nfs<<-END
        /NFSMAPID_DOMAIN/s/^#//
        w!
        q!
END

zoneadm -z ${NAM} boot
