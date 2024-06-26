#!/bin/bash

# Ensure the script is executed with superuser privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Define directories and file paths
BASE_DIR="/opt/simple-chat"
CHAT_SERVER_JS="$BASE_DIR/server.js"
CHAT_INDEX_HTML="$BASE_DIR/public/index.html"
CHAT_PACKAGE_JSON="$BASE_DIR/package.json"
SYSTEMD_SERVICE="/etc/systemd/system/worldended-chat.service"
APACHE_CONF="/etc/apache2/sites-available/000-default.conf"
MUSIC_DIR="/var/www/html/music"
INDEX_HTML="/var/www/html/index.html"
FILESHARE_DIR="/var/www/html/fileshare"


# Ensure wlan1 is up
ip link set wlan1 up

# Assign a static IP address to wlan1 (ignore if already assigned)
ip addr add 10.1.1.1/24 dev wlan1 2>/dev/null || true

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Install necessary packages
apt-get update
apt-get install -y apache2 nodejs npm hostapd dnsmasq iptables-persistent

# Copy frowny.png to the web directory
cp frowny.png /var/www/html/

# Create necessary directories
mkdir -p $BASE_DIR/public
mkdir -p $MUSIC_DIR
mkdir -p $FILESHARE_DIR

# Create package.json for chat server
cat <<EOL > $CHAT_PACKAGE_JSON
{
  "name": "simple-chat",
  "version": "1.0.0",
  "description": "A simple chat application",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "socket.io": "^4.4.1"
  },
  "author": "",
  "license": "ISC"
}
EOL

# Create server.js for chat
cat <<EOL > $CHAT_SERVER_JS
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');
const app = express();
const server = http.createServer(app);
const io = socketIo(server);

// Serve static files from the "public" directory
app.use(express.static(path.join(__dirname, 'public')));

io.on('connection', (socket) => {
    let username = '';
    console.log('a user connected');
    
    socket.on('set username', (name) => {
        username = name;
        console.log(\`User connected: \${username}\`);
        socket.broadcast.emit('user connected', \`\${username} has joined the chat\`);
    });

    socket.on('disconnect', () => {
        console.log(\`User disconnected: \${username}\`);
        socket.broadcast.emit('user disconnected', \`\${username} has left the chat\`);
    });

    socket.on('chat message', (msg) => {
        io.emit('chat message', { user: username, message: msg });
    });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(\`Server is running on port \${PORT}\`);
});
EOL

# Create index.html for chat
cat <<EOL > $CHAT_INDEX_HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Simple Chat</title>
    <style>
        body { font-family: Arial, sans-serif; }
        #banner { text-align: center; padding: 10px; background-color: #222; color: #fff; }
        #messages { list-style-type: none; padding: 0; }
        #messages li { padding: 8px; margin-bottom: 8px; background-color: #f4f4f4; border-radius: 4px; }
        #message-form { display: flex; }
        #message-form input { flex: 1; padding: 8px; }
        #message-form button { padding: 8px; }
    </style>
</head>
<body>
    <div id="banner">Welcome To The End Of The World Chat</div>
    <ul id="messages"></ul>
    <form id="username-form">
        <input id="username-input" autocomplete="off" placeholder="Enter your username..." />
        <button>Set Username</button>
    </form>
    <form id="message-form" style="display:none;">
        <input id="message-input" autocomplete="off" placeholder="Type your message here..." />
        <button>Send</button>
    </form>
    <script src="/socket.io/socket.io.js"></script>
    <script>
        const socket = io();
        const usernameForm = document.getElementById('username-form');
        const usernameInput = document.getElementById('username-input');
        const messageForm = document.getElementById('message-form');
        const messageInput = document.getElementById('message-input');
        const messages = document.getElementById('messages');
        let username = '';
        usernameForm.addEventListener('submit', (e) => {
            e.preventDefault();
            if (usernameInput.value) {
                username = usernameInput.value;
                socket.emit('set username', username);
                usernameForm.style.display = 'none';
                messageForm.style.display = 'flex';
            }
        });
        messageForm.addEventListener('submit', (e) => {
            e.preventDefault();
            if (messageInput.value) {
                socket.emit('chat message', messageInput.value);
                messageInput.value = '';
            }
        });
        socket.on('chat message', (data) => {
            const item = document.createElement('li');
            item.textContent = \`\${data.user}: \${data.message}\`;
            messages.appendChild(item);
            window.scrollTo(0, document.body.scrollHeight);
        });
        socket.on('user connected', (msg) => {
            const item = document.createElement('li');
            item.textContent = msg;
            messages.appendChild(item);
            window.scrollTo(0, document.body.scrollHeight);
        });
        socket.on('user disconnected', (msg) => {
            const item = document.createElement('li');
            item.textContent = msg;
            messages.appendChild(item);
            window.scrollTo(0, document.body.scrollHeight);
        });
    </script>
</body>
</html>
EOL

# Change to the base directory
cd $BASE_DIR

# Install necessary npm packages for chat server
npm install

# Create a systemd service file for the chat server
cat <<EOL > $SYSTEMD_SERVICE
[Unit]
Description=Worldended Chat Server
After=network.target

[Service]
ExecStart=/usr/bin/node $CHAT_SERVER_JS
WorkingDirectory=$BASE_DIR
Restart=always
User=nobody
Group=nogroup
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd manager configuration
systemctl daemon-reload

# Enable the chat server service to start at boot
systemctl enable worldended-chat.service

# Start the chat server service
systemctl start worldended-chat.service

# Create sample music file
echo "This is a sample music file" > $MUSIC_DIR/sample-music.txt

# Create the main index.html file
cat <<EOL > $INDEX_HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome To The End Of The World!</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin: 0; padding: 0; }
        #banner { padding: 20px; background-color: #222; color: #fff; }
        #content { margin: 20px; }
        img { max-width: 100%; height: auto; }
    </style>
</head>
<body>
    <div id="banner">Welcome To The End Of The World!</div>
    <div id="content">
        <img src="frowny.png" alt="Welcome Image">
        <h2>Choose An Option</h2>
        <ul>
            <li><a href="http://10.1.1.1:3000">Live Chat</a></li>
            <li><a href="http://10.1.1.1/fileshare">Knowledge Base Documents</a></li>
            <li><a href="http://10.1.1.1/music">Listen To Music</a></li>
        </ul>
    </div>
</body>
</html>
EOL

# Configure Apache to serve the chat application under /live-chat and fileshare under /fileshare and music under /music
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

    <Directory /opt/simple-chat/public>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
    
    Alias /fileshare /var/www/html/fileshare
    <Directory /var/www/html/fileshare>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
    
    Alias /music /var/www/html/music
    <Directory /var/www/html/music>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

# Restart Apache service to apply changes
systemctl restart apache2

# Provide final instructions to user
echo "Setup complete."
echo "Wireless network 'WorldendedNetwork' configured with password 'worldendedpass'."
echo "Connect to 'WorldendedNetwork' from your devices to access:"
echo "- Live Chat at http://10.1.1.1:3000"
echo "- Knowledge Base Documents at http://10.1.1.1/fileshare"
echo "- Music at http://10.1.1.1/music"
echo "Enjoy!"

