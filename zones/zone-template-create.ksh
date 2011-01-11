#!/usr/bin/ksh
################################################################
# Title:	zone-template-create.ksh
# Date:		08/20/2010
# Author(s):	FOXX (frozenfoxx@github.com), Gerard Charleza
# Description:	This will create a Solaris full-root zone as a
#		template.  This means it will be cloned to create
#		other zones on the machine.
#
# Prerequisites:
# -Only one network interface is configured
# -Zone IP address is already chosen
# -Hostname is not required, it will be "template"
# -Global/root zone network is already configured
# -Only one network interface is configured
################################################################

# The directory prefix for all operations with the zones.
DIR=/zones_pool

# Shared directory. This directory will be shared between global zone
# and all zones.
SDIR=/admin_tools
mkdir $SDIR

# Check to see if the arch is SPARC.  If so, set the locale specifically.
# We do not set the locale for Solaris x86 because it kills the system.
if [ `uname -p` = sparc ]
        then
        locale='system_locale=en_US'
fi

# Pick the first configured network port.
ifconfig -a | grep flags | grep -v lo0 | tr \: ' ' | read IMC rest > /dev/null 2>&1

# Prompt for the IP
echo "Please enter the  IP address for the template zone:"
echo "> \c"
read MYADDRESS
NAM=template

# The following is the configuration skeleton for the zonecfgfile that will be
# used to build the template zone.
cat > ./zonecfgfile<<-END
        create -b
        set zonepath=$DIR/${NAM}
        set autoboot=false
        set ip-type=shared
        add inherit-pkg-dir
        set dir=$SDIR
        end
        add net
        set address=$MYADDRESS
        set physical=$IMC
        end
END
echo '*************************'

# Show us the output of the created file for sanity checking.
cat ./zonecfgfile

# Configure the new template zone from the above-created configuration file.
zonecfg -z ${NAM} -f ./zonecfgfile

# Install the template zone now that it has a configuration.
zoneadm -z  ${NAM} install

# Copy relevant information into the zone's configuration
# Default root password hash:  n0password
cat > ${DIR}/${NAM}/root/etc/sysidcfg<<-END
        $locale
        terminal=vt100
        timezone=US/Eastern
        timeserver=localhost
        name_service=NONE
        network_interface=PRIMARY { hostname=${NAM} }
        security_policy=NONE
        root_password=CLr.m1qoVn3mg
        nfs4_domain=dynamic
        service_profile=limited_net
END

# With this we set the NFSv4 name to be dynamic derived
ex ${DIR}/${NAM}/root/etc/default/nfs<<-END
        /NFSMAPID_DOMAIN/s/^#//
        w!
        q!
END

# Finally boot the zone
zoneadm -z ${NAM} boot
