#!/usr/bin/env bash
#######################################################
# Name:         jekyll-deploy.sh
# Date:         04/10/2017
# Author(s):    FOXX (frozenfoxx@github)
# Description:  this script deploys a site with Jekyll
#######################################################

# Verify number of arguments
if [ $# -lt 2 ] ; then
  # Print usage and exit
  echo 'Incorrect number of arguments.'
  echo 'Usage:'
  echo 'jekyll-deploy.sh [path to repo] [path to docroot]'

  exit
fi

# VARIABLES
REPOROOT=$1
DOCROOT=$2

cd ${REPOROOT}
git pull --rebase
jekyll build
sudo rm -Rf "${DOCROOT}/*"
sudo rsync -avP _site/* "${DOCROOT}/"
sudo chown -R www-data:www-data "${DOCROOT}/*"
