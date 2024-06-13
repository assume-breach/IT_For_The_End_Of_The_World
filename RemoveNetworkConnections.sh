#!/bin/bash

# Ensure the script is run as root
if [[ "$EUID" -ne 0 ]]; then
  echo "Please run as root"
  exit 1
fi

# List all NetworkManager connection profiles
connections=$(nmcli connection show | awk 'NR>1 {print $1}')

# Loop through each connection profile and delete it
for conn in $connections; do
  echo "Deleting connection: $conn"
  nmcli connection delete "$conn"
done

echo "All Wi-Fi connections have been removed."
