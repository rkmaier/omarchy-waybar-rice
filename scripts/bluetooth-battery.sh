#!/bin/bash

# Get battery level of connected Bluetooth headsets
# This script checks for battery information from connected Bluetooth devices

# Method 1: Try using upower to find Bluetooth audio devices
# Look for headphones, headsets, or devices with bluez in native-path
battery_info=$(upower -d | awk '
    /^Device:.*headphones|^Device:.*headset/ { in_device=1; next }
    /^Device:/ { in_device=0 }
    in_device && /percentage:/ {
        gsub(/%/, "", $2)
        print $2
        exit
    }
')

# If not found, try looking for any device with bluez in native-path
if [ -z "$battery_info" ]; then
    battery_info=$(upower -d | awk '
        /native-path:.*bluez/ { in_device=1 }
        in_device && /^Device:/ && !/native-path/ { in_device=0 }
        in_device && /percentage:/ && !/should be ignored/ {
            gsub(/%/, "", $2)
            if ($2 > 0) {
                print $2
                exit
            }
        }
    ')
fi

# Output the result
if [ -n "$battery_info" ] && [ "$battery_info" != "0" ]; then
    echo "${battery_info}%"
else
    echo "󰂲"
fi
