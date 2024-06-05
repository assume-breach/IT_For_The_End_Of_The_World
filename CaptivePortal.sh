#!/bin/bash

# Ensure wlan1 is up
ip link set wlan1 up

# Assign a static IP address to wlan1 (ignore if already assigned)
ip addr add 10.1.1.1/24 dev wlan1 2>/dev/null || true

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Install necessary packages
apt-get update
apt-get install -y hostapd dnsmasq apache2 iptables-persistent

# Unmask and enable hostapd
systemctl unmask hostapd
systemctl enable hostapd

# Configure hostapd
cat <<EOF > /etc/hostapd/hostapd.conf
interface=wlan1
driver=nl80211
ssid=CaptivePortal
hw_mode=g
channel=6
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
EOF

# Update default hostapd config
sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

# Configure dnsmasq
cat <<EOF > /etc/dnsmasq.conf
interface=wlan1
dhcp-range=10.1.1.2,10.1.1.100,255.255.255.0,24h
dhcp-option=3,10.1.1.1
dhcp-option=6,10.1.1.1
address=/#/10.1.1.1
EOF

# Restart dnsmasq
systemctl enable dnsmasq
systemctl restart dnsmasq

#Configure NameServer
cat <<EOF >> /etc/resolv.conf
nameserver 10.1.1.1
EOF

# Configure iptables for captive portal
iptables -t nat -A PREROUTING -i wlan1 -p tcp --dport 80 -j DNAT --to-destination 10.1.1.1:80
iptables -t nat -A PREROUTING -i wlan1 -p tcp --dport 443 -j DNAT --to-destination 10.1.1.1:80
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -A FORWARD -p tcp -d 10.1.1.1 --dport 80 -j ACCEPT
iptables -A FORWARD -p tcp -d 10.1.1.1 --dport 443 -j ACCEPT

# Save iptables rules
netfilter-persistent save

# Restart hostapd
systemctl restart hostapd

# Ensure Apache2 is running
systemctl enable apache2
systemctl restart apache2


# Create a simple index.html for the captive portal
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Captive Portal</title>
</head>
<body>
    <h1>Welcome to the Captive Portal</h1>
    <p>Please log in to continue.</p>
</body>
</html>
EOF

echo "Captive portal setup complete. Connect to the 'CaptivePortal' WiFi network."
