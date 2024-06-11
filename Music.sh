#!/bin/bash

# Define directories and file paths
MUSIC_DIR="/opt/music"
APACHE_CONF="/etc/apache2/sites-available/000-default.conf"

# Create the music directory
mkdir -p $MUSIC_DIR

# Create a sample music file
echo "This is a sample music file" > $MUSIC_DIR/sample-music.txt

# Configure Apache to serve the music directory under /music
cat <<EOL > $APACHE_CONF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    Alias /music $MUSIC_DIR
    <Directory $MUSIC_DIR>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

# Restart Apache to apply changes
#systemctl restart apache2

# Print completion message
echo "Music mapping setup is complete."
echo "Access the music at http://<Your_Server_IP>/music"
