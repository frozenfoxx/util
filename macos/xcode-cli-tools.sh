#!/bin/sh
# Originally pulled from https://github.com/timsutton/osx-vm-templates
# Modified by FrozenFOXX

if [[ ! "$INSTALL_XCODE_CLI_TOOLS" =~ ^(true|yes|on|1|TRUE|YES|ON])$ ]]; then
    exit
fi

# Get and install Xcode CLI tools
OSX_VERS=$(sw_vers -productVersion | awk -F "." '{print $2}')

# on 10.9+, we can leverage SUS to get the latest CLI tools
if [ "$OSX_VERS" -ge 15 ]; then
    # create the placeholder file that's checked by CLI updates' .dist code
    # in Apple's SUS catalog
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    # find the CLI Tools update
    PROD=$(softwareupdate -l | grep "\*.*Label: Command Line Tools" | tail -n 1 | awk -F"*" '{print $2}' | sed -e 's/^.*Label:.*Command/Command/' | tr -d '\n')
    # install it
    softwareupdate -i "$PROD" --verbose
else
    echo "This version is no longer supported via this script, please install manually and update"
    exit 1
fi
