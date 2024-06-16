#!/bin/bash

# Ensure the script is executed with superuser privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Install samba if it is not already installed
if ! dpkg -l | grep -q samba; then
    apt-get update
    apt-get install -y samba
fi

# Create the fileshare directory if it doesn't exist
SHARE_DIR="/var/www/html/fileshare"
mkdir -p $SHARE_DIR

# Set permissions for the shared directory
chmod -R 0777 $SHARE_DIR
chown -R nobody:nogroup $SHARE_DIR

# Backup the original smb.conf
cp /etc/samba/smb.conf /etc/samba/smb.conf.bak

# Configure samba to share the directory with the name "WorldEnded"
cat <<EOL >> /etc/samba/smb.conf

[WorldEnded]
   path = $SHARE_DIR
   browseable = yes
   read only = no
   guest ok = yes
   force user = nobody
   force group = nogroup
   create mask = 0777
   directory mask = 0777
EOL

# Restart samba services
systemctl restart smbd
systemctl restart nmbd

# Provide feedback to the user
echo "Samba fileshare setup complete."
echo "The directory $SHARE_DIR is now shared on the network as 'WorldEnded'."
echo "No special access is needed to add or remove files from it."
