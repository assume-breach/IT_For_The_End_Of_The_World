#!/bin/bash
mkdir /opt/fileserver
# Install Samba if not already installed
sudo apt update
sudo apt install samba

# Define the shared directory
SHARED_DIR="/opt/fileserver"
SHARE_NAME="WorldEnded"
SHARE_COMMENT="Shared Folder"

# Create the shared directory if it doesn't exist
sudo mkdir -p "$SHARED_DIR"

# Set permissions for the shared directory to allow open access
sudo chmod -R 777 "$SHARED_DIR"

# Add a Samba share configuration
echo "
[$SHARE_NAME]
   comment = $SHARE_COMMENT
   path = $SHARED_DIR
   browseable = yes
   read only = no
   guest ok = yes
   create mask = 0777
   directory mask = 0777
" | sudo tee -a /etc/samba/smb.conf > /dev/null

# Restart Samba service to apply changes
sudo systemctl restart smbd

# Display confirmation message
echo "Samba server configured to share $SHARED_DIR without authentication"
