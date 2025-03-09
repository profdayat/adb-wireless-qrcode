# ADB Wireless Debugging via QR Code 

This script simplifies wireless ADB debugging by allowing seamless pairing and connection using a QR code—no manual IP or port entry required!

## Why Use This?

Tired of manually pairing and connecting your ADB device over Wi-Fi? This script streamlines the process by:

- 🔍 **QR Code-Based Pairing** – No need to enter IP addresses or ports manually. Just scan and connect!  
- ⚡ **Automatic Pairing & Connection** – Detects available ADB devices and establishes a connection effortlessly.  
- 🔄 **Smart Port Detection** – Scans for open ADB ports and attempts reconnection if needed.  
- 🛠️ **Built-in Troubleshooting** – Helps diagnose connection issues with fallback mechanisms.  

## Features

- 📷 **QR Code Generation** – Instantly generate a QR code for easy pairing.
- 🔎 **Automatic Device Detection** – Finds available ADB devices using mDNS.
- 🔗 **Auto-Pairing & Connection** – Connects to the device immediately after scanning.
- 🚀 **Smart Port Scanning** – If no port is found, it attempts alternative connection methods.
- 🛡️ **Failsafe Mechanism** – If connection fails, it suggests troubleshooting steps.

## Prerequisites

Before running this script, ensure your system has the following dependencies installed:

- `adb`
- `nmap`
- `fping`
- `qrencode`

If they are not installed, you can install them using the following command on Ubuntu 24.04:

```sh
sudo apt update && sudo apt install adb nmap fping qrencode -y
```

## Usage

1. Enable "Wireless Debugging" on your Android device:
   - Go to *Settings* > *Developer options* > *Wireless debugging*.
   - Select "Pair device with QR code".
2. Run the script in the terminal:
   ```sh
   ./adb_wireless.sh
   ```
3. Scan the QR Code displayed in the terminal using your Android device.
4. Wait for the script to detect and pair with the device automatically.
5. If pairing is successful, the script will attempt to connect to the device via ADB.
6. Once connected, you can use ADB as usual:
   ```sh
   adb devices
   ```

## Recommendation for Android 11+

For Android 11 and newer versions, ensure the following additional steps:

- 🔓 Keep the device screen **unlocked** during the pairing and connection process.
- 🔄 If the device fails to appear in `adb mdns services`, try toggling "Wireless Debugging" off and on.
- 🛠️ Some devices may require **USB debugging enabled** before enabling wireless debugging.
- 📡 Ensure both your **PC and Android device** are connected to the **same Wi-Fi network**.

## License

This script is developed by [profdayat](https://github.com/profdayat) and released under the MIT License.

