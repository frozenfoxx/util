#!/usr/bin/ksh
################################################################
# Title:        zone-remove.ksh
# Date:         08/24/2010
# Author(s):    FOXX (frozenfoxx@github.com), Gerard Charleza
# Description:  This destroys a zone.
#
# Must provide a single argument, the name of the zone to be
#  destroyed.
################################################################

ROOT=/zones_pool/

# Ensure proper usage
if [ $# -ne 1 ]; then
  echo "Usage: $0 <zone to remove>"
  exit 1
fi

DOOMEDZONE=$1

# Wait for the zone to stop
echo "\n###############################"
echo "Halting the zone..."
zlogin $DOOMEDZONE halt -q 
sleep 10

echo "\n###############################"
echo "Uninstalling the zone..."
/usr/sbin/zoneadm  -z $DOOMEDZONE uninstall -F

echo "\n###############################"
echo "Deleting the zone..."
/usr/sbin/zonecfg  -z $DOOMEDZONE delete -F

echo "\n###############################"
echo "Zone removal complete."
echo "For safety reasons the file system"
echo "has NOT been removed.  It is found"
echo "at:  $ROOT$DOOMEDZONE"
