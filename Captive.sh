#!/bin/bash

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# Variables
#WLAN_IF="wlan1"
#AP_SSID="Go To 10.1.1.1 In Browser!"
#CaptivePortalIP="10.1.1.1"
#APACHE_CONF="/etc/apache2/sites-available/captiveportal.conf"

# Update and install necessary packages
apt-get update
apt-get install -y apache2 hostapd dnsmasq iptables-persistent

sudo ip link set wlan1 up
sudo ip addr add 10.1.1.1/24 dev wlan1

# Configure hostapd
cat <<EOL > /etc/hostapd/hostapd.conf
interface=wlan1
driver=nl80211
ssid="Go To 10.1.1.1 In Browser!"
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
EOL

# Update hostapd default configuration file
sed -i 's/#DAEMON_CONF=""/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/g' /etc/default/hostapd

# Configure dnsmasq
cat <<EOL > /etc/dnsmasq.conf
interface=wlan1
dhcp-range=10.1.1.2,10.1.1.20,12h
dhcp-option=3,10.1.1.1
address=/#/10.1.1.1
dhcp-authoritative

log-queries
log-dhcp
EOL

# Enable IP forwarding
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p

# Configure iptables for transparent proxy
iptables -t nat -A PREROUTING -i wlan1 -p tcp --dport 80 -j DNAT --to-destination 10.1.1.1:80
iptables -t nat -A PREROUTING -i wlan1 -p tcp --dport 443 -j DNAT --to-destination 10.1.1.1:80
iptables -t nat -A POSTROUTING -o wlan1 -j MASQUERADE

# Save iptables rules
iptables-save > /etc/iptables/rules.v4

# Create the captive portal site
mkdir -p /var/www/html/captiveportal
cat <<EOL > $APACHE_CONF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/captiveportal
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

# Enable the captive portal site
a2ensite captiveportal
systemctl reload apache2

# Restart services
systemctl unmask hostapd
systemctl enable hostapd
systemctl restart hostapd
systemctl restart dnsmasq

# Final instructions to user
echo Done
