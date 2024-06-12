#!/bin/bash

# Ensure the script is executed with superuser privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Define directories and file paths
FILES_DIR="/opt/fileserver"
APACHE_CONF="/etc/apache2/sites-available/000-default.conf"

# Create the Samba fileshare directory
mkdir -p $FILES_DIR

# Install Samba if not already installed
apt update
apt install -y samba

# Set permissions for the shared directory to allow open access
chmod -R 777 "$FILES_DIR"

# Add a Samba share configuration
echo "
[WorldEnded]
   comment = Shared Folder
   path = $FILES_DIR
   browseable = yes
   read only = no
   guest ok = yes
   create mask = 0777
   directory mask = 0777
" | tee -a /etc/samba/smb.conf > /dev/null

# Restart Samba service to apply changes
systemctl restart smbd

# Configure Apache to serve the chat application under /live-chat and fileshare under /fileshare
cat <<EOL > $APACHE_CONF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    Alias /live-chat /opt/simple-chat/public
    <Directory /opt/simple-chat/public>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    Alias /fileshare $FILES_DIR
    <Directory $FILES_DIR>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

# Restart Apache to apply changes
systemctl restart apache2

# Print completion message
echo "Fileshare setup is complete."
echo "Access the fileshare at http://<Your_Server_IP>/fileshare"
