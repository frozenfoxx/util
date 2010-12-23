#!/bin/sh

# NOTE:  This file rebuilds the cfengine configuration directory in the event it
# becomes irreperably damaged using a backup directory tree.

mkdir /var/cfengine
cp -pr /var/cf-failsafe/* /var/cfengine
/var/cfengine/bin/cf-agent && /var/cfengine/bin/cf-agent