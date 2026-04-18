# Quick Start Guide

## What This Script Does

The **pteroanyinstall** script provides a complete, production-ready Pterodactyl installation with:

✅ **Network Stability** - Prevents IP changes after reboots  
✅ **Visual Guides** - Shows you how everything connects  
✅ **Explained Prompts** - Every question tells you what it's for  
✅ **Auto-Recovery** - Services restart automatically after reboot  
✅ **Billing Ready** - Optional WHMCS/Blesta integration  
✅ **Monitoring** - Built-in server health monitoring  
✅ **Backups** - Automatic daily backups  
✅ **Security** - Firewall auto-configuration  

## Installation in 3 Steps

### Step 1: Download the Script

```bash
wget https://raw.githubusercontent.com/yourusername/pteroanyinstall/main/pteroanyinstall.sh
chmod +x pteroanyinstall.sh
```

### Step 2: Run the Script

```bash
sudo ./pteroanyinstall.sh
```

### Step 3: Follow the Prompts

The script will:
1. Show you a network diagram
2. Ask if you want to scan existing installations
3. Present installation options
4. Guide you through each step with explanations

## What to Expect

### Network Configuration (NEW!)

```
Available Network Interfaces:
=============================
1) eth0 - Ethernet - Status: UP - IP: 192.168.1.100
2) wlan0 - WiFi - Status: DOWN - IP: Not assigned

Select network interface number: 1

Detected public IP: 203.0.113.50

Do you want to configure a static IP to prevent IP changes on reboot? (y/n): y
```

**What this does:** Ensures your server's IP address doesn't change when it reboots, which would break DNS and cause downtime.

### Visual Diagrams (NEW!)

The script shows you ASCII art diagrams:
- How Pterodactyl components connect
- Installation flow step-by-step
- Which ports need to be open

### Explained Prompts (NEW!)

Every question includes an explanation:

```
EXPLANATION: This email will be used for SSL certificates and admin account notifications.
Enter your email address: admin@example.com

EXPLANATION: GPU support allows game servers to use your NVIDIA graphics card.
This is useful for games that benefit from GPU acceleration.
Do you want to enable GPU support? (y/n): y
```

### Optional Features (NEW!)

At the end, you'll be asked about extras:

```
Do you want to install server monitoring tools? (y/n): y
Do you want to setup automatic backups? (y/n): y
Do you want to setup a billing system integration? (y/n): n
Do you want to configure firewall rules automatically? (y/n): y
```

## After Installation

### Verify Everything Works

```bash
# Check service status
./pteroanyinstall.sh health-check

# View server monitor
ptero-monitor

# Check reboot protection
systemctl status pterodactyl-startup

# View network configuration
cat /etc/pteroanyinstall/config.conf
```

### Test Reboot Protection (NEW!)

```bash
# Reboot your server
sudo reboot

# After reboot, check if services auto-started
systemctl status docker
systemctl status mariadb
systemctl status nginx
systemctl status wings

# Check startup logs
cat /var/log/pterodactyl-startup.log
```

### Access Your Panel

```
Panel URL: https://panel.example.com
Admin credentials: /root/panel_credentials.txt
```

**Important:** Copy credentials to a safe place, then delete the file:
```bash
cat /root/panel_credentials.txt
rm /root/panel_credentials.txt
```

## Common Questions

### Q: What if my network interface isn't listed?

**A:** Run `ip link show` to see all interfaces. If yours isn't showing up, it may be down. Bring it up with:
```bash
ip link set [interface] up
```

### Q: What if public IP detection fails?

**A:** The script will ask you to enter it manually. Find your public IP:
```bash
curl ifconfig.me
```

### Q: Do I need a static IP?

**A:** **YES!** Without static IP configuration, your server's local IP may change after DHCP lease expires or after reboots. This breaks DNS records and causes service outages.

### Q: What is reboot protection?

**A:** It ensures all Pterodactyl services (Docker, MariaDB, Nginx, Redis, Wings) automatically start when your server reboots. Without this, your game servers would stay offline until you manually start services.

### Q: Should I enable automatic backups?

**A:** **YES!** Backups protect against:
- Hardware failures
- Accidental deletions
- Database corruption
- Hacking attempts

### Q: Do I need a billing system?

**A:** Only if you're running a game hosting business and charging customers. For personal use, skip this.

### Q: What monitoring tools are installed?

**A:** 
- **htop** - Interactive process viewer
- **iotop** - Disk I/O monitor
- **nethogs** - Network bandwidth per process
- **vnstat** - Network traffic statistics
- **ptero-monitor** - Custom Pterodactyl status command

### Q: How do backups work?

**A:**
- Run daily at 2 AM automatically
- Backup Panel database, files, and Wings config
- Keep backups for configurable days (default: 7)
- Stored in `/var/backups/pterodactyl/`
- Can be run manually: `/usr/local/bin/pterodactyl-backup.sh`

### Q: What firewall ports are opened?

**A:**
- **22** - SSH
- **80** - HTTP
- **443** - HTTPS
- **8080** - Wings API
- **2022** - Wings SFTP
- **25565** - Minecraft (example)

## Troubleshooting

### Services not starting after reboot

```bash
# Check startup service
systemctl status pterodactyl-startup

# View logs
cat /var/log/pterodactyl-startup.log

# Manually run startup script
/usr/local/bin/pterodactyl-startup.sh
```

### IP address changed after reboot

```bash
# Check if static IP is configured
cat /etc/netplan/01-netcfg.yaml  # Ubuntu
cat /etc/network/interfaces.d/*  # Debian
cat /etc/sysconfig/network-scripts/ifcfg-*  # CentOS

# Reapply configuration
netplan apply  # Ubuntu
systemctl restart networking  # Debian
systemctl restart network  # CentOS
```

### Backups not running

```bash
# Check cron job
crontab -l

# View backup logs
cat /var/log/pterodactyl-backup.log

# Test backup manually
/usr/local/bin/pterodactyl-backup.sh
```

### Can't access monitoring command

```bash
# Make sure it's executable
chmod +x /usr/local/bin/ptero-monitor

# Run it
ptero-monitor
```

## Next Steps

1. **Configure DNS** - Point your domain to the public IP
2. **Create First Server** - Log into Panel and create a game server
3. **Test Reboot** - Reboot server and verify auto-start works
4. **Setup Backups** - Verify backups are running daily
5. **Monitor Resources** - Run `ptero-monitor` to check health

## Getting Help

- **Documentation:** See `ENHANCED_FEATURES.md` for detailed feature explanations
- **Installation Guide:** See `INSTALL_GUIDE.md` for step-by-step instructions
- **Examples:** See `EXAMPLES.md` for real-world scenarios
- **Health Check:** Run `./pteroanyinstall.sh health-check`
- **Scan & Fix:** Run `./pteroanyinstall.sh scan`

## Key Files and Locations

```
/etc/pteroanyinstall/config.conf           # Network configuration
/etc/systemd/system/pterodactyl-startup.service  # Reboot protection service
/usr/local/bin/pterodactyl-startup.sh      # Startup script
/usr/local/bin/pterodactyl-backup.sh       # Backup script
/usr/local/bin/ptero-monitor               # Monitoring command
/var/log/pterodactyl-startup.log           # Startup logs
/var/log/pterodactyl-backup.log            # Backup logs
/var/backups/pterodactyl/                  # Backup storage
/root/panel_credentials.txt                # Admin credentials (delete after copying)
```

## Advanced Usage

### Update Everything

```bash
./pteroanyinstall.sh update
```

### Run Health Check

```bash
./pteroanyinstall.sh health-check
```

### Scan and Fix Issues

```bash
./pteroanyinstall.sh scan
```

### Manual Backup

```bash
/usr/local/bin/pterodactyl-backup.sh
```

### View Server Status

```bash
ptero-monitor
```

## Security Reminders

✅ Change default passwords immediately  
✅ Enable 2FA in Panel settings  
✅ Use SSH keys instead of passwords  
✅ Keep system updated regularly  
✅ Monitor logs for suspicious activity  
✅ Restrict SSH access to specific IPs  
✅ Backup encryption keys securely  

## Support

For issues:
1. Check logs in `/var/log/`
2. Run `./pteroanyinstall.sh health-check`
3. Run `./pteroanyinstall.sh scan`
4. Review `ENHANCED_FEATURES.md`
5. Check Pterodactyl Discord: https://discord.gg/pterodactyl
