#!/bin/bash

# Ensure the directory exists
if [ ! -d "/opt/IT_For_The_End_Of_The_World/" ]; then
  echo "Directory /opt/IT_For_The_End_Of_The_World/ does not exist."
  exit 1
fi

# Make scripts executable
chmod +x /opt/IT_For_The_End_Of_The_World/CaptivePortal.sh
chmod +x /opt/IT_For_The_End_Of_The_World/Web.sh
chmod +x /opt/IT_For_The_End_Of_The_World/FileShare.sh

### Captive Portal Service Install ###
cat <<EOF > /etc/systemd/system/CaptivePortal.service
[Unit]
Description=Captive Portal
After=network.target

[Service]
ExecStart=/opt/IT_For_The_End_Of_The_World/CaptivePortal.sh
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable CaptivePortal.service
systemctl start CaptivePortal.service

### Web Service Install ###
cat <<EOF > /etc/systemd/system/Web.service
[Unit]
Description=Web
After=network.target

[Service]
ExecStart=/opt/IT_For_The_End_Of_The_World/Web.sh
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable Web.service
systemctl start Web.service

### Music Service Install ###
cat <<EOF > /etc/systemd/system/Music.service
[Unit]
Description=Music Service
After=network.target

[Service]
ExecStart=/opt/IT_For_The_End_Of_The_World/Music.sh
Type=simple
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable Music.service
systemctl start Music.service

### File Server Service Install ###
cat <<EOF > /etc/systemd/system/FileShare.service
[Unit]
Description=File Server
After=network.target

[Service]
ExecStart=/opt/IT_For_The_End_Of_The_World/FileShare.sh
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable FileShare.service
systemctl start FileShare.service
