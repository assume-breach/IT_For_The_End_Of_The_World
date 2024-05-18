#!/bin/bash

# Define directories and file paths
BASE_DIR="/opt/simple-chat"
SERVER_JS="$BASE_DIR/server.js"
INDEX_HTML="$BASE_DIR/public/index.html"
PACKAGE_JSON="$BASE_DIR/package.json"

# Create the base directory and public directory
mkdir -p $BASE_DIR/public

# Create package.json
cat <<EOL > $PACKAGE_JSON
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

# Create server.js
cat <<EOL > $SERVER_JS
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
        socket.broadcast.emit('user connected', \`\${username} has joined the chat\`);
    });

    socket.on('disconnect', () => {
        console.log('user disconnected');
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

# Create index.html
cat <<EOL > $INDEX_HTML
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

# Install necessary npm packages
npm install

# Print completion message
echo "Simple chat server setup is complete. You can start the server by running 'node server.js' in the /opt/simple-chat directory."
