#!/usr/bin/ksh
################################################################
# Title:        zone-post-install.ksh
# Date:         08/23/2010
# Author(s):    FOXX (frozenfoxx@github.com), Gerard Charleza
# Description:  This modifies a new zone after its installation.
#
# The "template" zone must have already been created.
# The zone should have been built with zone-clone.ksh
# Must provide a single argument, the name of the zone to be
#  configured.
# A directory containing files to copy in place must exist and
#  be specified by ZONECFG.
################################################################

ROOT=/zones_pool/$1/root
ZONECFG=/usr/local/zonecfg

EXPORT_HOME=/export/home
SHADOW=/etc/shadow
PASSWD=/etc/passwd
GROUP=/etc/group
CLUSTERS=/etc/clusters

# Create directories nonexistant by default.
echo "\n############################"
echo "Creating non-default directories..."
mkdir -p ${ROOT}/${EXPORT_HOME}
mkdir -p ${ROOT}/usr/local/bin
mkdir -p ${ROOT}/usr/local/etc

# Copy configuration files from the global zone into appropriate
#  areas of the zone.
echo "\n############################"
echo "Copying configuration files..."
cat ${ZONECFG}/lib/cshrc.SUN > ${ROOT}/etc/skel/.cshrc
cat ${ZONECFG}/lib/skel_profile.SUN > ${ROOT}/etc/skel/.profile
cat ${ZONECFG}/lib/etc_profile.SUN >> ${ROOT}/etc/profile 
cat ${ZONECFG}/lib/root_profile.SUN >> ${ROOT}/root/.profile

#cp -rp ${ZONECFG}/lib/root ${ROOT}

# Insert accounts at the end of the passwd file.  Please note
#  that the names MUST be empty.
echo "\n############################"
echo "Modifying passwd file..."
cat << ENDOFPASSWD >> ${ROOT}/${PASSWD}
user1:x:256:10::/export/home/user1:/bin/bash
ENDOFPASSWD

# Insert groups at the end of the group file.
echo "\n############################"
echo "Modifying group file..."
cat << ENDOFGROUP >> ${ROOT}/${GROUP}
usergroup::256:
ENDOFGROUP

# Insert shadow passwords at the end of the shadow file.
echo "\n############################"
echo "Modifying shadow file..."
cat << ENDOFSHADOW >> ${ROOT}/${SHADOW}
user1:somepasswordhash:14008::::::
ENDOFSHADOW

# Modify user accounts.
#ex ${ROOT}/${PASSWD}<<END
#/root/
#s/\//\/root/
#wq
#END

# Append domain to the defaultdomain file.
echo "\n############################"
echo "Creating defaultdomain..."
echo 'somedomain.net' > ${ROOT}/etc/defaultdomain

# Set up home directories for users in the staff group (GID == 10)
echo "\n############################"
echo "Creating user directories..."
cat ${ROOT}/${PASSWD} | sed 's/:/ /g' |
while read USER v1 USERUID gid HOMEDIR USERSHELL
do
        if [  ! -d "$USERUID" -a "$gid" -eq 10 -a "$USER" != nobody ]
        then
        echo USER=$USER USERUID=$USERUID gid=$gid HOMEDIR=$HOMEDIR 
        mkdir -p ${ROOT}${HOMEDIR}
        echo mkdir -p ${ROOT}${HOMEDIR}
        cp ${ROOT}/etc/skel/.profile ${ROOT}${HOMEDIR}
        echo cp ${ROOT}/etc/skel/.profile ${ROOT}${HOMEDIR}
        cp ${ROOT}/etc/skel/.cshrc ${ROOT}${HOMEDIR}
        echo cp ${ROOT}/etc/skel/.cshrc ${ROOT}${HOMEDIR}
        chown -R ${USERUID}:$gid ${ROOT}${HOMEDIR}
        echo chown -R ${USERUID}:$gid ${ROOT}${HOMEDIR}
        fi
done

# Change permissions/ownership on critical files
echo "\n############################"
echo "Changing perms on critical files..."
chmod 400 ${ROOT}/${PASSWD}
chmod 400 ${ROOT}/${SHADOW}
