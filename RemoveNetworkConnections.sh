#!/bin/bash

# Ensure the script is run as root
if [[ "$EUID" -ne 0 ]]; then
  echo "Please run as root"
  exit 1
fi

# List all NetworkManager connection profiles
connections=$(nmcli -t -f NAME connection show)

# Loop through each connection profile and delete it
IFS=$'\n' # Change IFS to newline to handle spaces in connection names
for conn in $connections; do
  echo "Deleting connection: $conn"
  nmcli connection delete "$conn"
done

echo "All Wi-Fi connections have been removed."
