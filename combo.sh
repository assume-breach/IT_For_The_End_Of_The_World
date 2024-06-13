#!/bin/bash

# Ensure the script is executed with superuser privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Define directories and file paths
FILES_DIR="/opt/fileserver"
MUSIC_DIR="/opt/music"
APACHE_CONF_8000="/etc/apache2/sites-available/fileshare.conf"
APACHE_CONF_8001="/etc/apache2/sites-available/music.conf"

# Create the fileshare and music directories
mkdir -p $FILES_DIR
mkdir -p $MUSIC_DIR

# Create a sample music file
echo "This is a sample music file" > $MUSIC_DIR/sample-music.txt

# Install necessary packages
apt update
apt install -y samba apache2

# Set permissions for the shared directory to allow open access
chmod -R 777 "$FILES_DIR"
chmod -R 755 "$MUSIC_DIR"

# Add a Samba share configuration for fileshare
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

# Configure Apache to serve the fileshare on port 8000
cat <<EOL > $APACHE_CONF_8000
<VirtualHost *:8000>
    ServerAdmin webmaster@localhost
    DocumentRoot $FILES_DIR

    <Directory $FILES_DIR>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/fileshare_error.log
    CustomLog \${APACHE_LOG_DIR}/fileshare_access.log combined
</VirtualHost>
EOL

# Configure Apache to serve the music directory on port 8001
cat <<EOL > $APACHE_CONF_8001
<VirtualHost *:8001>
    ServerAdmin webmaster@localhost
    DocumentRoot $MUSIC_DIR

    <Directory $MUSIC_DIR>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/music_error.log
    CustomLog \${APACHE_LOG_DIR}/music_access.log combined
</VirtualHost>
EOL

# Enable the new Apache configurations
a2ensite fileshare.conf
a2ensite music.conf

# Restart Apache to apply changes
systemctl restart apache2

# Enable Apache to start on boot
systemctl enable apache2

# Print completion message
echo "Fileshare and music setup is complete."
echo "Access the fileshare at http://<Your_Server_IP>:8000"
echo "Access the music at http://<Your_Server_IP>:8001"
