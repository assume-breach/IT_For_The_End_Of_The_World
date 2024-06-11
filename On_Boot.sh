# Make it executable
chmod +x /opt/IT_For_The_End_Of_The_World/CaptivePortal.sh
chmod +x /opt/IT_For_The_End_Of_The_World/Web.sh
chmod +x /opt/IT_For_The_End_Of_The_World/Music.sh
chmod +x /opt/IT_For_The_End_Of_The_World/FileShare.sh


###Captive Portal Service Install###
echo '[Unit]
Description=Captive Portal
After=network.target

[Service]
ExecStart=/opt/IT_For_The_End_Of_The_World/CaptivePortal.sh
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=default.target' > /etc/systemd/system/CaptivePortal.service

systemctl enable CaptivePortal.service
systemctl start CaptivePortal.service

###Web Service Install###
echo '[Unit]
Description=Web
After=network.target

[Service]
ExecStart=/opt/IT_For_The_End_Of_The_World/Web.sh
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=default.target' > /etc/systemd/system/Web.service

# Step 3: Enable and start the service
systemctl enable Web.service
systemctl start Web.service

# Music Service Install
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

###File Server Service Install###
echo '[Unit]
Description=File Server
After=network.target

[Service]
ExecStart=/opt/IT_For_The_End_Of_The_World/FileShare.sh
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=default.target' > /etc/systemd/system/FileShare.service

# Step 3: Enable and start the service
systemctl enable FileShare.service
systemctl start FileShare
