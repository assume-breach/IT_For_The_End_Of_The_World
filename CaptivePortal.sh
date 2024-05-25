#!/bin/bash

# Ensure the script is executed with superuser privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Install necessary packages
apt-get update
apt-get install -y dnsmasq hostapd apache2 bridge-utils iptables iptables-persistent

# Stop NetworkManager and wpa_supplicant if they are running
systemctl stop NetworkManager
systemctl stop wpa_supplicant
systemctl unmask hostapd 

# Bring up wlan1 interface
ip link set wlan1 up

# Create bridge interface br0 and add wlan1 to it
ip link add name br0 type bridge
ip link set dev wlan1 master br0
ip link set br0 up
ip addr add 10.1.1.1/24 dev br0

# Configure dnsmasq
cat <<EOL > /etc/dnsmasq.conf
interface=br0
listen-address=10.1.1.1
no-hosts
dhcp-range=10.1.1.2,10.1.1.254,10m
dhcp-option=option:router,10.1.1.1
dhcp-authoritative

address=/.*/10.1.1.1
EOL

# Configure hostapd
cat <<EOL > /etc/hostapd/hostapd.conf
interface=wlan1
driver=nl80211
channel=6
hw_mode=g
ssid=End Of The World
bridge=br0
auth_algs=1
wmm_enabled=0
EOL

# Ensure Apache is using the existing index.html
# Assuming the existing index.html is already in the default DocumentRoot /var/www/html

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Persist IP forwarding across reboots
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Flush existing iptables rules
iptables --flush
iptables -t nat --flush

# Set up iptables rules for DNS redirection
iptables -t nat -A PREROUTING -i wlan1 -p udp --dport 53 -j DNAT --to-destination 10.1.1.1:53

# Set up iptables rules for HTTP redirection
iptables -t nat -A PREROUTING -i wlan1 -p tcp --dport 80 -j DNAT --to-destination 10.1.1.1:80

# Set up iptables rules for HTTPS redirection (redirect to port 80 as captive portals usually don't use HTTPS)
iptables -t nat -A PREROUTING -i wlan1 -p tcp --dport 443 -j DNAT --to-destination 10.1.1.1:80

# Set up iptables rules for masquerading
iptables -t nat -A POSTROUTING -j MASQUERADE

# Ensure the /etc/iptables directory exists
mkdir -p /etc/iptables

# Save iptables rules to be persistent across reboots
iptables-save > /etc/iptables/rules.v4

# Restart services
systemctl restart dnsmasq
systemctl restart hostapd
systemctl restart apache2
systemctl restart NetworkManager

# Check if hostapd is running
if ! pgrep hostapd >/dev/null; then
    echo "hostapd is not running. Please check hostapd configuration and try again."
else
    echo "Configuration files updated, IP forwarding enabled, and services restarted."
fi
