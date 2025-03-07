#!/bin/bash

# Function to check and install missing dependencies
check_install_dependency() {
    package=$1
    if ! command -v "$package" &> /dev/null; then
        echo "$package is not installed. Installing..."
        sudo apt update && sudo apt install -y "$package"
    fi
}

# Check and install required tools
check_install_dependency "nmap"
check_install_dependency "fping"
check_install_dependency "adb"

echo "Initializing ADB..."
adb devices  # Run adb devices first

echo "Scanning devices in the network..."

# Get the subnet mask
subnet_mask=$(ip route | awk '/proto kernel/ {print $1}')

# Scan the network and collect results
device_list=()
while read -r ip; do
    hostname=$(host "$ip" 2>/dev/null | awk '{print $NF}')
    device_list+=("$ip -> $hostname")
done < <(fping -aqg "$subnet_mask" 2>/dev/null)

# Display the list of detected devices
echo "Available devices:"
for i in "${!device_list[@]}"; do
    echo "$((i+1)). ${device_list[i]}"
done

echo "Enter a number to select a device (e.g., 1, 2, 3) or 'x' to exit:"
read -r choice

# Check if user wants to exit
if [[ "$choice" == "x" ]]; then
    echo "Exiting script."
    exit 0
fi

# Validate selection
if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#device_list[@]} )); then
    echo "Invalid selection. Exiting..."
    exit 1
fi

# Extract selected IP and hostname
selected_ip=$(echo "${device_list[choice-1]}" | awk '{print $1}')
selected_hostname=$(echo "${device_list[choice-1]}" | awk '{print $3}')

# Check if selected IP is already connected to ADB and get its port
adb_connected_info=$(adb devices | awk 'NR>1 && $2=="device" {print $1}')
selected_device_entry=$(echo "$adb_connected_info" | grep "^$selected_ip:")

if [[ -n "$selected_device_entry" ]]; then
    # Extract port from connected device
    connected_port=$(echo "$selected_device_entry" | awk -F: '{print $2}')
    
    echo "Device $selected_ip --> $selected_hostname is already connected."
    echo "Press [R] to reconnect and rescan ports, or [X] to exit:"
    read -r reconnect_choice

    if [[ "$reconnect_choice" == "R" || "$reconnect_choice" == "r" ]]; then
        adb disconnect "$selected_ip:$connected_port"  # Properly disconnect ADB
        echo "Reconnecting to $selected_ip --> $selected_hostname..."
        echo "Rescanning ports..."
    else
        echo "Exiting script."
        exit 0
    fi
fi

# Retry counter for port scanning
scan_attempts=0
max_attempts=3

while :; do
    echo "Scanning ports for $selected_ip --> $selected_hostname (Attempt $((scan_attempts + 1))/$max_attempts)..."

    # Scan for open ports
    open_ports=$(sudo nmap "$selected_ip" -p 37000-44000 --defeat-rst-ratelimit | awk '/open/{gsub("/tcp", "", $1); print $1}')

    if [[ -n "$open_ports" ]]; then
        # Get the first open port
        first_port=$(echo "$open_ports" | head -n1)

        echo "First open port found: $first_port for $selected_ip --> $selected_hostname"
        echo "Open ports detected:"
        while read -r port; do
            echo "$selected_ip:$port"
        done <<< "$open_ports"

        # Check ADB devices before offering connection
        echo "Checking ADB status for $selected_ip:$first_port --> $selected_hostname..."
        adb_connected=$(adb devices | awk 'NR>1 && $2=="device" {print $1}')

        if echo "$adb_connected" | grep -q "$selected_ip:$first_port"; then
            echo "Device already connected at $selected_ip:$first_port --> $selected_hostname."
            exit 0
        fi

        # ADB is not connected, proceed to connect automatically
        echo "Connecting to ADB at $selected_ip:$first_port --> $selected_hostname..."
        adb connect "$selected_ip:$first_port"
        exit 0
    else
        echo "No open ports found."
        scan_attempts=$((scan_attempts + 1))
        
        # Jika sudah 3 kali scan & masih tidak ada open port, lakukan ping
        if (( scan_attempts >= max_attempts )); then
            echo "Max scan attempts reached. Pinging $selected_ip ($selected_hostname)..."

            if fping -c1 -t100 "$selected_ip" &>/dev/null; then
                echo "Ping successful. Restarting port scan..."
                scan_attempts=0  # Reset scan attempt counter
            else
                echo "Ping failed! Retrying in 2 seconds..."
                sleep 2
            fi
        fi
    fi
done
