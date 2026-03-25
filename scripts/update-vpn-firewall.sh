#!/bin/bash

QUBE="sys-vpn-mullvad"
CONFIG_DIR="/rw/config/vpn-configs"

# Reset firewall
qvm-firewall "$QUBE" reset

# Get all endpoint IPs from configs and add firewall rules
qvm-run -p "$QUBE" "grep -h '^Endpoint' $CONFIG_DIR/*.conf | cut -d'=' -f2 | cut -d':' -f1 | sort -u" | while read -r ip; do
    echo "Allowing $ip"
    qvm-firewall "$QUBE" add accept dsthost="$ip"
done

# Remove default allow-all rule (activates killswitch)
qvm-firewall "$QUBE" del --rule-no 0

echo "Done. Current rules:"
qvm-firewall "$QUBE"
