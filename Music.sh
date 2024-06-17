#!/bin/bash

# Ensure the script is executed with superuser privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Define the music directory
MUSIC_DIR="/opt/music"
WEB_DIR="/var/www/html/music"

# Create the music directory if it doesn't exist
mkdir -p $MUSIC_DIR

# Ensure the web directory exists
mkdir -p /var/www/html

# Create a symbolic link from /opt/music to /var/www/html/music
ln -s $MUSIC_DIR $WEB_DIR

# Configure Apache to serve the music directory
APACHE_CONF="/etc/apache2/sites-available/000-default.conf"

# Add the Alias and Directory directives if not already present
if ! grep -q "Alias /music" $APACHE_CONF; then
    echo "
Alias /music $WEB_DIR
<Directory $WEB_DIR>
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>" >> $APACHE_CONF
fi

# Restart Apache to apply the changes
systemctl restart apache2

# Output success message
echo "Mapping of /opt/music to http://10.1.1.1/music is complete."
