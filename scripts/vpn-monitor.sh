#!/bin/bash

CONNECTION_NAME="mullvad"
CHECK_INTERVAL=10

notify() {
    sudo -u user DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus notify-send "$@"
}

while true; do
    sleep "$CHECK_INTERVAL"

    if ! nmcli -t -f NAME connection show --active | grep -q "^${CONNECTION_NAME}$"; then
        notify -u critical "VPN" "⚠ Connection dropped! Reconnecting..."

        if nmcli connection up "$CONNECTION_NAME"; then
            notify -u normal "VPN" "✓ Reconnected"
        else
            notify -u critical "VPN" "✗ Reconnect failed!"
        fi
    fi
done
