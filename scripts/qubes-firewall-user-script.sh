#!/bin/bash

# Block forwarding outside VPN tunnel (backup killswitch)
nft add rule qubes custom-forward oifname eth0 counter drop
nft add rule ip6 qubes custom-forward oifname eth0 counter drop

# Fix MTU issues
nft add rule ip qubes custom-forward tcp flags syn / syn,rst tcp option maxseg size set rt mtu

# Redirect DNS to Mullvad's DNS (prevents leaks)
DNS=10.64.0.1
nft add chain qubes nat { type nat hook prerouting priority dstnat\; }
nft add rule qubes nat iifname == "vif*" tcp dport 53 dnat "$DNS"
nft add rule qubes nat iifname == "vif*" udp dport 53 dnat "$DNS"
