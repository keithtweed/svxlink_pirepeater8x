#!/bin/bash

############################################
# Script to load the configuration files
# for SVXLink into the appropriate places on
# the system.
############################################

# Check if the user is root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Get the directory of the script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Get the current date and time
DATE=$(date +'%Y%m%d-%H%M%S')

# Backup current RepeaterLogics
echo -n "Backing up current configuration files..."
(cd /usr/share/svxlink/events.d && tar -czf ~/backup_events-$DATE.tar.gz RepeaterLogic?.tcl)
(cd /etc/svxlink && tar -czf ~/backup_svxlink-$DATE.tar.gz $(ls -A /etc/svxlink))
echo " Done"

# Copy the configuration files
echo -n "Copying configuration files..."
cp -r $SCRIPT_DIR/svxlink/* /etc/svxlink/
cp -r $SCRIPT_DIR/events/* /usr/share/svxlink/events.d/
echo " Done"

# Restart the svxlink service
echo -n "Restarting svxlink service..."
systemctl restart svxlink
echo " Done"