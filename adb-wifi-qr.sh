#!/bin/bash

# Function to Generate NanoID-like Name
generate_name() {
    local charset="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local name=""

    for _ in {1..14}; do
        name+="${charset:RANDOM%${#charset}:1}"
    done

    name+="-"

    for _ in {1..6}; do
        name+="${charset:RANDOM%${#charset}:1}"
    done

    echo "$name"
}

# Function to Generate NanoID-like Password
generate_password() {
    local charset="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local password=""
    
    for _ in {1..21}; do
        password+="${charset:RANDOM%${#charset}:1}"
    done

    echo "$password"
}

# Generate Random Name & Password
name="ADB_WIFI_$(generate_name)"
password="$(generate_password)"

# Function to Show QR Code
function showQR() {
    qr_text="WIFI:T:ADB;S:${name};P:${password};;"
    qrencode -t ANSIUTF8 "$qr_text"
}

function startDiscover() {
    echo "🔍 Searching for ADB devices and waiting for scan qrcode..."
    
    prev_num_lines=0  
    
    while true; do        
        device_nearby=$(adb mdns services)
        num_lines=$(echo "$device_nearby" | wc -l)

        for ((i=0; i<=prev_num_lines; i++)); do 
            tput cuu 1 && tput el
        done

        echo "device_nearby:"
        echo "$device_nearby"
        prev_num_lines=$num_lines

        result=$(echo "$device_nearby" | grep "_adb-tls-pairing._tcp" | awk '{print $3, $4}' | head -n 1)
        
        if [ -n "$result" ]; then
            ip=$(echo "$result" | cut -d':' -f1)
            pair_port=$(echo "$result" | cut -d':' -f2)
            echo "✅ Found Device: $ip:$pair_port"
            
            break
        fi

        sleep 1
    done
}

# Function to pair to Device (Dengan Error Handling)
function pair() {
    local address="$1"
    local pair_port="$2"
    echo "🔗 Pairing with ADB Device: $address:$pair_port $password"

    output=$(adb pair "$address:$pair_port" "$password" 2>&1)
    exit_status=$?

    if [ $exit_status -ne 0 ]; then
        echo "❌ Error: $output"
        return
    fi

    echo "✅ Pairing Success: $output"
}

# Function to connect to Device
function connect() {
    local address="$1"
    adb kill-server
    echo "🔗 Connecting to ADB Device: $address"
    
    for attempt in {1..3}; do
        connect_port=$(nmap $address -p 30000-50000 | awk "/\/tcp/" | cut -d/ -f1)
        adb connect "$address:$connect_port" 2>&1

        if [ $? -eq 0 ]; then
            echo "✅ Connected to $address:$connect_port"
            return
        fi

        if [ -z "$connect_port" ]; then
            echo "⚠️ No open port found, checking previous connections..."
            adb devices | grep "$address" > /dev/null
            if [ $? -eq 0 ]; then
                echo "✅ Device already connected"
                return
            fi

            fping -c1 $address
            echo "🔄 Retrying port scan after ping..."
            adb kill-server
        fi
        sleep 2
        fping -c1 $address
        echo "🔄 Retrying port scan after ping..."
    done
    
    if [ -n "$connect_port" ]; then
        echo "✅ Connecting to $address:$connect_port"
        adb_connect_output=$(adb connect "$address:$connect_port" 2>&1)
        echo "$adb_connect_output"
    else
        echo "❌ Unable to find open port for ADB connection"
    fi
}

# Main Function
function main() {
    echo "📱 ADB Wireless Debugging by https://github.com/profdayat"
    echo "Go to setting [Developer options] -> [Wireless debugging] -> [Pair device with QR code]"
    showQR
    
    startDiscover
    
    if [ -n "$ip" ]; then
        pair "$ip" "$pair_port"
        connect "$ip"
    fi
}

main
