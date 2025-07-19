#!/bin/bash
if bluetoothctl show | grep -q "Powered: yes"; then
    bluetoothctl power off
    notify-send "Bluetooth" "Disabled"
else
    bluetoothctl power on
    notify-send "Bluetooth" "Enabled"
fi
