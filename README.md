# Qubes OS Mullvad WireGuard ProxyVM

A minimal, secure WireGuard VPN gateway for Qubes OS that:
- Random server selection on boot
- Desktop notifications for connect/disconnect
- Automatic reconnection on drop
- Full killswitch protection

## Requirements

- Qubes OS 4.2+
- Debian 12/13 minimal template
- Wireguard VPN account (Mullvad)

## Step 1: Prepare the Template

In your `debian-13-minimal` template:

```bash
sudo apt update
sudo apt install -y qubes-core-agent-network-manager wireguard wireguard-tools libnotify-bin dunst

# Disable nm-applet (optional - removes tray icon)
sudo bash -c 'echo -e "#!/bin/bash\nexit 0" > /usr/lib/qubes/show-hide-nm-applet.sh'

sudo shutdown -h now
```

## Step 2: Create the VPN Qube
Menu → Qubes Tools → Create Qubes VM

Setting	Value
| Setting    | Value             |
|:-----------|:------------------|
| Name       | sys-vpn-mullvad   |
| Type       | AppVM             |
| Template   | debian-13-minimal |
| Networking | sys-firewall      |

In Settings:

Advanced tab → ☑️ Provides network access to other qubes
Services tab → Add network-manager and qubes-firewall

## Step 3: Download Mullvad Configs
In a different qube:

1. Go to https://mullvad.net/en/account/wireguard-config
2. Generate a key → Select servers → Download .conf files
3. Right-click → Copy To Other AppVM → sys-vpn-mullvad

## Step 4: Set Up the VPN Qube
In sys-vpn-mullvad:

```bash
# Create config directory
mkdir -p /rw/config/vpn-configs

# Move configs
mv ~/QubesIncoming/*/*.conf /rw/config/vpn-configs/

# Copy scripts from this repo
cp scripts/rc.local /rw/config/rc.local
cp scripts/vpn-monitor.sh /rw/config/vpn-monitor.sh
cp scripts/qubes-firewall-user-script.sh /rw/config/qubes-firewall-user-script

# Make executable
chmod +x /rw/config/rc.local
chmod +x /rw/config/vpn-monitor.sh
chmod +x /rw/config/qubes-firewall-user-script
```

## Step 5: Set Up Killswitch (dom0)
In dom0:

```bash
# Copy the firewall script
qvm-run --pass-io sys-vpn-mullvad 'cat /path/to/update-vpn-firewall.sh' > ~/update-vpn-firewall.sh
chmod +x ~/update-vpn-firewall.sh

# Run it
~/update-vpn-firewall.sh
```

## Step 6: Route Qubes Through VPN
For any qube you want to use the VPN:

Qube Settings → Set Net qube to sys-vpn-mullvad

## Step 7: Test
Restart sys-vpn-mullvad. You should see notifications.

From a connected qube:

```bash
curl https://am.i.mullvad.net/connected
```

### Adding New Servers

- Download new configs from Mullvad
- Copy to `sys-vpn-mullvad:/rw/config/vpn-configs/`
- Run `~/update-vpn-firewall.sh` in dom0

### File Reference

| File                         | Location    | Purpose                 |
|:------------------------------|:-------------|:-------------------------:|
| rc.local                     | /rw/config/ | Random server + connect |
| vpn-monitor.sh               | /rw/config/ | Disconnect watcher      |
| qubes-firewall-user-script   | /rw/config/ | nftables killswitch     |
| update-vpn-firewall.sh       | dom0 ~/     | dom0 firewall rules     |

### Security Notes
- Never commit your .conf files as they contain private keys!
- The killswitch blocks ALL traffic if VPN drops.
- DNS is forced through the Mullvad DNS server at the 10.64.0.1 internal IP address.
