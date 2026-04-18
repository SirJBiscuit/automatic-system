# Enhanced Features Guide

## Overview

The pteroanyinstall script has been enhanced with advanced features to provide a complete, production-ready Pterodactyl installation with network stability, visual guides, billing integration, and automatic recovery.

## New Features

### 1. Network Configuration Wizard

**What it does:** Automatically detects and configures your network interface to prevent IP changes after reboots.

**Why it's important:** Without a static IP configuration, your server's local IP address may change after a reboot, breaking DNS records and causing service outages.

**Features:**
- Automatic detection of WiFi and Ethernet interfaces
- Visual display of available network adapters
- Auto-detection of public IP address
- Static IP configuration to prevent DHCP changes
- Configuration persistence across reboots

**How it works:**
```
1. Script detects all network interfaces (eth0, wlan0, etc.)
2. Shows you each interface with its type (WiFi/Ethernet), status, and current IP
3. You select which interface to use
4. Script auto-detects your public IP from multiple sources
5. Optionally configure static IP to prevent changes
6. Configuration is saved to /etc/pteroanyinstall/config.conf
```

**Example Output:**
```
Available Network Interfaces:
=============================
1) eth0 - Ethernet - Status: UP - IP: 192.168.1.100
2) wlan0 - WiFi - Status: DOWN - IP: Not assigned

Select network interface number: 1

Detected public IP: 203.0.113.50

Do you want to configure a static IP to prevent IP changes on reboot? (y/n): y
```

### 2. Visual Network Diagrams

**What it does:** Shows ASCII art diagrams of how Pterodactyl components connect.

**Why it's important:** Helps you understand the architecture before installation, making troubleshooting easier.

**Diagrams included:**
- Network Architecture (Internet → Cloudflare → Panel/Wings → Services)
- Installation Flow (Step-by-step process visualization)
- Port Requirements (Which ports need to be open)

**Example:**
```
                         ┌─────────────────┐
                         │   INTERNET      │
                         │  (Public IP)    │
                         └────────┬────────┘
                                  │
                         ┌────────▼────────┐
                         │   CLOUDFLARE    │
                         │  (DNS + DDoS)   │
                         └────────┬────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
           ┌────────▼────────┐         ┌───────▼────────┐
           │  PANEL SERVER   │         │  WINGS SERVER  │
           │  (Web Interface)│         │  (Game Nodes)  │
           └────────┬────────┘         └───────┬────────┘
```

### 3. Enhanced Prompts with Explanations

**What it does:** Every prompt now includes an explanation of what it's asking for and why.

**Why it's important:** Reduces confusion and helps users make informed decisions.

**Example:**
```
EXPLANATION: This email will be used for SSL certificates and admin account notifications.
Enter your email address: admin@example.com

EXPLANATION: GPU support allows game servers to use your NVIDIA graphics card.
This is useful for games that benefit from GPU acceleration.
Do you want to enable GPU support? (y/n):
```

### 4. Public IP Detection and Confirmation

**What it does:** Automatically detects your public IP and asks for confirmation.

**Why it's important:** Ensures DNS records point to the correct IP address.

**Features:**
- Tries multiple IP detection services (ifconfig.me, icanhazip.com, ipinfo.io)
- Shows detected IP and allows manual override
- Validates IP format
- Saves IP to configuration file

**How it works:**
```bash
Detecting public IP address...
Detected public IP: 203.0.113.50

EXPLANATION: Auto-detected: 203.0.113.50. Press Enter to use this, or type a different IP.
Confirm or enter your public IP [203.0.113.50]:
```

### 5. Reboot Protection

**What it does:** Ensures all Pterodactyl services automatically start after a server reboot.

**Why it's important:** Prevents downtime when your server restarts (planned or unplanned).

**What gets protected:**
- Docker daemon
- MariaDB database
- Nginx web server
- Redis cache
- Pterodactyl Wings
- Panel queue workers

**Implementation:**
- Creates systemd service: `pterodactyl-startup.service`
- Creates startup script: `/usr/local/bin/pterodactyl-startup.sh`
- Logs all startup activities to: `/var/log/pterodactyl-startup.log`
- Waits for network to be online before starting services
- Includes 10-second delay to ensure dependencies are ready

**Startup Sequence:**
```
1. Wait for network-online.target
2. Wait 10 seconds for system stability
3. Start Docker
4. Start MariaDB
5. Start Nginx
6. Start Redis
7. Start Wings (if installed)
8. Restart Panel queue workers
9. Log all activities
```

**Verify it's working:**
```bash
systemctl status pterodactyl-startup
cat /var/log/pterodactyl-startup.log
```

### 6. Billing System Integration

**What it does:** Optionally installs and configures billing system modules.

**Why it's important:** If you're running a game hosting business, you need to charge customers.

**Supported Systems:**
1. **WHMCS** (Most Popular)
   - Automatic module installation
   - Configuration file generation
   - API integration setup

2. **Blesta**
   - Installation instructions
   - Module download links

3. **HostBill**
   - Integration guidance
   - Configuration help

**WHMCS Setup Process:**
```
1. Script asks for WHMCS URL
2. Requests API credentials
3. Clones official WHMCS module
4. Generates configuration file
5. Provides next steps for WHMCS admin panel
```

**What you need:**
- WHMCS URL (e.g., https://billing.example.com)
- WHMCS API Identifier
- WHMCS API Secret

### 7. Automatic Backups

**What it does:** Sets up daily automatic backups of your Panel and Wings.

**Why it's important:** Protects against data loss from hardware failures, accidents, or attacks.

**What gets backed up:**
- Panel database (MySQL dump)
- Panel files (/var/www/pterodactyl)
- Wings configuration (/etc/pterodactyl)
- Nginx configurations

**Features:**
- Configurable backup directory
- Configurable retention period (default: 7 days)
- Automatic old backup cleanup
- Cron job for daily execution (2 AM)
- Detailed logging

**Configuration:**
```bash
Enter backup directory [/var/backups/pterodactyl]: /backups
How many days to keep backups? [7]: 14
```

**Backup files:**
```
/var/backups/pterodactyl/
├── panel_db_20260418_020000.sql
├── panel_files_20260418_020000.tar.gz
├── wings_config_20260418_020000.tar.gz
└── ...
```

**Manual backup:**
```bash
/usr/local/bin/pterodactyl-backup.sh
```

### 8. Server Monitoring Tools

**What it does:** Installs tools to monitor server performance and resource usage.

**Why it's important:** Helps you identify performance issues before they affect customers.

**Tools installed:**
- **htop** - Interactive process viewer
- **iotop** - Disk I/O monitor
- **nethogs** - Network bandwidth monitor per process
- **vnstat** - Network traffic statistics

**Custom monitoring command:**
```bash
ptero-monitor
```

**Output includes:**
```
=== Pterodactyl Server Monitor ===

=== System Resources ===
Memory usage
Disk usage

=== Service Status ===
✓ Docker: Running
✓ MariaDB: Running
✓ Nginx: Running
✓ Redis: Running
✓ Wings: Running

=== Network Usage ===
Daily network statistics
```

### 9. Automatic Firewall Configuration

**What it does:** Automatically configures firewall rules for Pterodactyl.

**Why it's important:** Protects your server from unauthorized access while allowing necessary traffic.

**Ports opened:**
- **22** - SSH (Server management)
- **80** - HTTP (Web traffic, SSL verification)
- **443** - HTTPS (Secure web traffic)
- **8080** - Wings API (Panel-to-Wings communication)
- **2022** - Wings SFTP (File uploads)
- **25565** - Minecraft (Example game port)

**Firewall systems supported:**
- **UFW** (Ubuntu/Debian)
- **firewalld** (CentOS/RHEL/Rocky/Alma)

**Default policy:**
- Deny all incoming connections
- Allow all outgoing connections
- Allow only specified ports

### 10. Static IP Configuration

**What it does:** Configures your network interface to use a static IP address.

**Why it's important:** Prevents your server's IP from changing when DHCP lease expires or after reboots.

**Supports:**
- **Netplan** (Modern Ubuntu/Debian)
- **interfaces.d** (Legacy Debian)
- **network-scripts** (CentOS/RHEL)

**What gets configured:**
- Static IP address
- Gateway
- DNS servers (primary + Google DNS 8.8.8.8)
- Auto-start on boot

**Configuration saved to:**
- Ubuntu (Netplan): `/etc/netplan/01-netcfg.yaml`
- Debian: `/etc/network/interfaces.d/[interface]`
- CentOS/RHEL: `/etc/sysconfig/network-scripts/ifcfg-[interface]`

### 11. Optional Features Menu

**What it does:** Presents a menu of optional features to install.

**Why it's important:** Allows customization without overwhelming users with questions.

**Options:**
1. Server monitoring tools
2. Automatic backups
3. Billing system integration
4. Firewall configuration

**Each option:**
- Includes explanation of what it does
- Can be skipped
- Configured independently

## Usage Examples

### Example 1: Full Installation with All Features

```bash
sudo ./pteroanyinstall.sh install-full
```

**What happens:**
1. Shows installation flow diagram
2. Runs network configuration wizard
   - Detects interfaces
   - Auto-detects public IP
   - Optionally configures static IP
3. Installs all dependencies
4. Asks about GPU support (with explanation)
5. Prompts for email and password (with explanations)
6. Installs Panel
7. Asks about Wings installation
8. Asks about Cloudflare integration
9. Configures reboot protection
10. Presents optional features menu:
    - Monitoring tools?
    - Automatic backups?
    - Billing system?
    - Firewall?
11. Runs health check
12. Shows completion message

### Example 2: Panel Only with Monitoring

```bash
sudo ./pteroanyinstall.sh install-panel
```

**Answers during installation:**
```
Select network interface: 1 (eth0)
Public IP: 203.0.113.50
Configure static IP: yes
Email: admin@example.com
Admin password: [auto-generated]
Cloudflare: no
Monitoring tools: yes
Automatic backups: yes
Billing system: no
Firewall: yes
```

### Example 3: Wings Only with GPU

```bash
sudo ./pteroanyinstall.sh install-wings
```

**Answers during installation:**
```
Select network interface: 1 (eth0)
Public IP: 203.0.113.51
Configure static IP: yes
GPU support: yes
Email: admin@example.com
Monitoring tools: yes
Automatic backups: no
Billing system: no
Firewall: yes
```

## Configuration Files

### Network Configuration
**Location:** `/etc/pteroanyinstall/config.conf`

**Contents:**
```bash
INTERFACE=eth0
STATIC_IP=192.168.1.100
PUBLIC_IP=203.0.113.50
GATEWAY=192.168.1.1
DNS=8.8.8.8
CONFIGURED_DATE=Fri Apr 18 10:30:00 EDT 2026
```

### Reboot Protection Service
**Location:** `/etc/systemd/system/pterodactyl-startup.service`

**Startup Script:** `/usr/local/bin/pterodactyl-startup.sh`

**Log File:** `/var/log/pterodactyl-startup.log`

### Backup Script
**Location:** `/usr/local/bin/pterodactyl-backup.sh`

**Cron Job:** Daily at 2 AM

**Log File:** `/var/log/pterodactyl-backup.log`

### Monitoring Script
**Location:** `/usr/local/bin/ptero-monitor`

**Usage:** `ptero-monitor`

## Troubleshooting

### Network Interface Not Detected

**Problem:** Script doesn't show your network interface

**Solution:**
```bash
# List all interfaces manually
ip link show

# Check if interface is up
ip link set [interface] up
```

### Public IP Detection Fails

**Problem:** Script can't auto-detect public IP

**Solution:**
- Manually check your public IP: `curl ifconfig.me`
- Enter it when prompted
- Check firewall isn't blocking outbound connections

### Static IP Not Working After Reboot

**Problem:** IP address changes after reboot

**Solution:**
```bash
# Check configuration
cat /etc/netplan/01-netcfg.yaml  # Ubuntu
cat /etc/network/interfaces.d/*  # Debian
cat /etc/sysconfig/network-scripts/ifcfg-*  # CentOS

# Reapply configuration
netplan apply  # Ubuntu
systemctl restart networking  # Debian
systemctl restart network  # CentOS
```

### Services Not Starting on Reboot

**Problem:** Pterodactyl services don't auto-start

**Solution:**
```bash
# Check startup service status
systemctl status pterodactyl-startup

# Check logs
cat /var/log/pterodactyl-startup.log

# Manually enable
systemctl enable pterodactyl-startup

# Test startup script
/usr/local/bin/pterodactyl-startup.sh
```

### Backups Not Running

**Problem:** Automatic backups aren't being created

**Solution:**
```bash
# Check cron job
crontab -l

# Check backup log
cat /var/log/pterodactyl-backup.log

# Test backup script manually
/usr/local/bin/pterodactyl-backup.sh

# Re-add cron job
(crontab -l; echo "0 2 * * * /usr/local/bin/pterodactyl-backup.sh") | crontab -
```

## Security Considerations

### Firewall Rules
- Only necessary ports are opened
- Default deny policy for incoming connections
- SSH access should be restricted to key-based authentication

### Backup Security
- Backups contain sensitive data
- Store backups in secure location
- Consider encrypting backups
- Restrict access to backup directory

### Static IP Configuration
- Ensure static IP doesn't conflict with DHCP range
- Document IP assignments
- Update DNS records if IP changes

### Reboot Protection
- Startup script runs as root
- Logs may contain sensitive information
- Restrict access to log files

## Advanced Configuration

### Custom Backup Schedule

Edit cron job:
```bash
crontab -e

# Change from daily at 2 AM to every 6 hours
0 */6 * * * /usr/local/bin/pterodactyl-backup.sh
```

### Custom Monitoring

Edit monitoring script:
```bash
nano /usr/local/bin/ptero-monitor

# Add custom checks, alerts, etc.
```

### Additional Firewall Rules

```bash
# Ubuntu/Debian
ufw allow 27015/tcp comment 'Source Engine'

# CentOS/RHEL
firewall-cmd --permanent --add-port=27015/tcp
firewall-cmd --reload
```

### Network Interface Bonding

For redundancy, bond multiple interfaces:
```bash
# This is advanced - consult your OS documentation
# Example for Ubuntu with Netplan
nano /etc/netplan/01-netcfg.yaml
```

## Benefits Summary

✅ **Network Stability** - Static IP prevents service disruptions
✅ **Visual Guidance** - Diagrams help understand architecture
✅ **User-Friendly** - Explanations for every prompt
✅ **Automatic Recovery** - Services auto-start after reboot
✅ **Data Protection** - Automatic backups prevent data loss
✅ **Performance Monitoring** - Track server health
✅ **Business Ready** - Billing system integration
✅ **Security** - Automatic firewall configuration
✅ **Production Ready** - All features for running a hosting business

## Next Steps

After installation:

1. **Verify Network Configuration**
   ```bash
   cat /etc/pteroanyinstall/config.conf
   ip addr show
   ```

2. **Test Reboot Protection**
   ```bash
   reboot
   # After reboot
   systemctl status pterodactyl-startup
   cat /var/log/pterodactyl-startup.log
   ```

3. **Check Backup System**
   ```bash
   ls -lh /var/backups/pterodactyl/
   cat /var/log/pterodactyl-backup.log
   ```

4. **Monitor Server**
   ```bash
   ptero-monitor
   ```

5. **Review Firewall**
   ```bash
   ufw status  # Ubuntu/Debian
   firewall-cmd --list-all  # CentOS/RHEL
   ```

## Support

For issues with enhanced features:
- Check log files in `/var/log/`
- Review configuration in `/etc/pteroanyinstall/`
- Run health check: `./pteroanyinstall.sh health-check`
- Run scan and fix: `./pteroanyinstall.sh scan`
