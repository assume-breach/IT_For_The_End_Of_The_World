#!/bin/bash

# Ensure the script is executed with superuser privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Define the paths to your scripts
REMOVE_NETWORK_CONNECTIONS_SCRIPT="/opt/IT_For_The_End_Of_The_World/RemoveNetworkConnections>
CAPTIVE_SCRIPT="/opt/IT_For_The_End_Of_The_World/Captive.sh"
FILE_SHARE_SCRIPT="/opt/IT_For_The_End_Of_The_World/FileShare.sh"
WEB_SCRIPT="/opt/IT_For_The_End_Of_The_World/Web.sh"

# Make sure all scripts are executable
chmod +x $REMOVE_NETWORK_CONNECTIONS_SCRIPT
chmod +x $CAPTIVE_SCRIPT
chmod +x $FILE_SHARE_SCRIPT
chmod +x $WEB_SCRIPT

# Create a temporary cron file
CRON_TEMP_FILE=$(mktemp)

# Add the current cron jobs to the temporary file
crontab -l > $CRON_TEMP_FILE

# Append the new cron jobs to the temporary file with a 5-second delay
echo "@reboot sleep 45 && $REMOVE_NETWORK_CONNECTIONS_SCRIPT" >> $CRON_TEMP_FILE
echo "@reboot sleep 45 && $CAPTIVE_SCRIPT" >> $CRON_TEMP_FILE
echo "@reboot sleep 45 && $FILE_SHARE_SCRIPT" >> $CRON_TEMP_FILE
echo "@reboot sleep 45 && $WEB_SCRIPT" >> $CRON_TEMP_FILE

# Install the new cron file
crontab $CRON_TEMP_FILE

# Remove the temporary file
rm $CRON_TEMP_FILE

echo "Cron jobs have been set up successfully to run at boot with a 45-second delay."
