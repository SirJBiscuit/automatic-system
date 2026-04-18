# Pre-Installation Guide

## Overview

The Pre-Installation Checks script ensures your system is ready for Pterodactyl installation. It checks for existing installations, verifies network configuration, and guides you through necessary setup steps.

## Quick Start

```bash
sudo ./pre-install-checks.sh
```

Or run via main script:

```bash
sudo ./pteroanyinstall.sh pre-check
```

## What Gets Checked

### 1. Existing Pterodactyl Installation

**Checks for:**
- Existing Panel at `/var/www/pterodactyl`
- Existing Wings at `/usr/local/bin/wings`
- Configuration files

**If found, you can:**
1. **Backup and migrate** (RECOMMENDED)
   - Automatic backup to external drive
   - Database export
   - Configuration backup
   - Option to wipe and start fresh

2. **Update existing installation**
   - Keep current files
   - Update in place

3. **Exit and backup manually**
   - Do it yourself first

### 2. Cloudflare Integration

**Checks if you have:**
- Cloudflare account setup
- Domain added to Cloudflare
- API credentials ready

**Benefits of Cloudflare:**
- Free DDoS protection
- Global CDN
- Automatic SSL certificates
- DNS management
- Analytics

**What you need:**
- API Token with `Zone:DNS:Edit` permission
- Zone ID from domain overview
- Get at: https://dash.cloudflare.com/profile/api-tokens

### 3. DNS Configuration

**Verifies:**
- Domain points to server IP
- DNS records are configured
- Propagation status

**Required DNS Records:**

```
Type: A
Name: panel.yourdomain.com
Value: YOUR_SERVER_PUBLIC_IP
TTL: 3600

Type: A
Name: node.yourdomain.com
Value: YOUR_SERVER_PUBLIC_IP
TTL: 3600
```

**DNS Providers:**
- Cloudflare (recommended)
- GoDaddy
- Namecheap
- Google Domains
- Your registrar's DNS

**Propagation Time:**
- Usually: 5-60 minutes
- Can take up to 24-48 hours

### 4. Port Forwarding Check

**Determines if:**
- Server is behind router/firewall
- Ports are already forwarded
- Port forwarding guide needed

**Required Ports:**

**Panel:**
- Port 80 (HTTP)
- Port 443 (HTTPS)

**Wings:**
- Port 8080 (Wings API)
- Port 2022 (SFTP)
- Port 443 (HTTPS)

**Game Servers:**
- Port 25565 (Minecraft)
- Port 27015 (Source games)
- Port 7777 (ARK, Rust)
- Ports 30000-30100 (Dynamic range)

## Backup and Migration

### Automatic Backup Process

When migrating from existing installation:

**1. Backup Location**
```
Default: /var/backups/pterodactyl-migration-YYYYMMDD-HHMMSS
Custom: /mnt/external, /backup, etc.
```

**2. What Gets Backed Up**

**Panel:**
- All Panel files (`panel-files.tar.gz`)
- Database dump (`panel-database.sql`)
- Environment file (`panel.env`)
- Nginx configuration (`nginx-panel.conf`)

**Wings:**
- Configuration (`wings/config.yml`)
- Server data (`wings-data.tar.gz`)

**3. Backup Manifest**

Created at `BACKUP_INFO.txt`:
```
Pterodactyl Backup Information
==============================
Backup Date: 2024-04-18 10:30:00
Backup Location: /var/backups/pterodactyl-migration-20240418-103000

Contents:
  - Panel files (panel-files.tar.gz)
  - Panel database (panel-database.sql)
  - Panel .env (panel.env)
  - Nginx config (nginx-panel.conf)
  - Wings config (wings/config.yml)
  - Wings data (wings-data.tar.gz)
```

**4. Wipe Option**

After backup, you can:
- **Wipe and start fresh** - Removes all existing files
- **Keep existing files** - Updates in place

### Restoring from Backup

If you need to restore:

```bash
# Extract Panel files
cd /var/www
sudo tar -xzf /backup/panel-files.tar.gz

# Restore database
mysql -u root -p
CREATE DATABASE panel;
exit
mysql -u root -p panel < /backup/panel-database.sql

# Restore .env
sudo cp /backup/panel.env /var/www/pterodactyl/.env

# Restore Nginx config
sudo cp /backup/nginx-panel.conf /etc/nginx/sites-available/pterodactyl.conf
sudo ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/

# Restore Wings
sudo cp /backup/wings/config.yml /etc/pterodactyl/config.yml

# Extract Wings data
cd /var/lib
sudo tar -xzf /backup/wings-data.tar.gz

# Restart services
sudo systemctl restart nginx
sudo systemctl restart wings
```

## Port Forwarding Walkthrough

### Step-by-Step Guide

**Step 1: Find Router IP**
```bash
# Linux
ip route | grep default

# Windows
ipconfig

# Usually: 192.168.1.1 or 192.168.0.1
```

**Step 2: Find Server Local IP**
```bash
# Linux
hostname -I

# This script shows it automatically
```

**Step 3: Access Router**
1. Open browser
2. Go to `http://192.168.1.1`
3. Login (check router label for credentials)

**Step 4: Find Port Forwarding**

Look for sections named:
- Port Forwarding
- Virtual Servers
- NAT Forwarding
- Applications & Gaming

**Step 5: Add Rules**

For each port, create a rule:

| Service | External Port | Internal Port | Internal IP | Protocol |
|---------|---------------|---------------|-------------|----------|
| HTTP | 80 | 80 | Server IP | TCP |
| HTTPS | 443 | 443 | Server IP | TCP |
| Wings | 8080 | 8080 | Server IP | TCP |
| SFTP | 2022 | 2022 | Server IP | TCP |
| Minecraft | 25565 | 25565 | Server IP | TCP/UDP |

**Step 6: Save and Test**

1. Save rules
2. Apply/Restart router
3. Wait 1-2 minutes
4. Test at: https://www.yougetsignal.com/tools/open-ports/

### Router-Specific Guides

**TP-Link:**
- Advanced → NAT Forwarding → Virtual Servers

**Netgear:**
- Advanced → Advanced Setup → Port Forwarding

**Linksys:**
- Security → Apps and Gaming → Single Port Forwarding

**ASUS:**
- WAN → Virtual Server / Port Forwarding

**D-Link:**
- Advanced → Port Forwarding

**Need Help?**
Visit: https://portforward.com (router-specific guides)

## Pre-Installation Report

After checks complete, a report is generated:

**Location:** `/tmp/pteroanyinstall-precheck-YYYYMMDD-HHMMSS.txt`

**Contains:**
- System information
- Check results
- Next steps
- Backup location (if applicable)

**Example:**
```
Pterodactyl Pre-Installation Check Report
==========================================
Generated: 2024-04-18 10:30:00

System Information:
  OS: Ubuntu 22.04.3 LTS
  Kernel: 5.15.0-91-generic
  Public IP: 203.0.113.42
  Local IP: 192.168.1.100

Checks Performed:
  Existing Installation: None
  Cloudflare Setup: Yes
  DNS Configured: Yes
  Behind Router: Yes
  Port Forwarding: Configured

Next Steps:
  1. Complete any pending configurations
  2. Run the main installation script
  3. Follow the interactive prompts
```

## Common Scenarios

### Scenario 1: Fresh Server, No Cloudflare

```
✓ No existing installation
✗ No Cloudflare
✗ DNS not configured
✓ Direct internet access

Action: Set up DNS first, then install
```

### Scenario 2: Home Server Behind Router

```
✓ No existing installation
✗ No Cloudflare
✓ DNS configured
✗ Behind router, no port forwarding

Action: Follow port forwarding guide, then install
```

### Scenario 3: Migrating Existing Installation

```
⚠ Existing Panel found
✓ Cloudflare ready
✓ DNS configured
✓ Direct internet access

Action: Backup and migrate to fresh install
```

### Scenario 4: VPS with Everything Ready

```
✓ No existing installation
✓ Cloudflare ready
✓ DNS configured
✓ Direct internet access

Action: Ready to install immediately!
```

## Troubleshooting

### DNS Not Propagating

**Check propagation:**
```bash
nslookup panel.yourdomain.com
dig panel.yourdomain.com
```

**Online tools:**
- https://www.whatsmydns.net
- https://dnschecker.org

**Solutions:**
- Wait longer (up to 48 hours)
- Clear local DNS cache
- Try different DNS server (8.8.8.8)

### Port Forwarding Not Working

**Test ports:**
```bash
# From external network
telnet YOUR_PUBLIC_IP 80
nc -zv YOUR_PUBLIC_IP 80
```

**Common issues:**
- Router firewall blocking
- ISP blocking ports (especially 80)
- Incorrect internal IP
- Router needs reboot

**Solutions:**
- Double-check all settings
- Restart router
- Contact ISP about port blocks
- Use alternative ports (8080 instead of 80)

### Cloudflare API Issues

**Common errors:**
- Invalid API token
- Insufficient permissions
- Wrong Zone ID

**Solutions:**
- Regenerate API token
- Ensure `Zone:DNS:Edit` permission
- Copy Zone ID from domain overview
- Test API token first

### Backup Failed

**Common causes:**
- Insufficient disk space
- Permission issues
- Database connection failed

**Solutions:**
```bash
# Check disk space
df -h

# Fix permissions
sudo chown -R www-data:www-data /var/www/pterodactyl

# Test database connection
mysql -u pterodactyl -p panel
```

## Best Practices

### Before Installation

1. ✅ Run pre-installation checks
2. ✅ Configure DNS and wait for propagation
3. ✅ Set up port forwarding (if needed)
4. ✅ Get Cloudflare ready (optional but recommended)
5. ✅ Backup existing installation (if applicable)
6. ✅ Have all credentials ready

### During Installation

1. ✅ Follow prompts carefully
2. ✅ Save all credentials shown
3. ✅ Don't skip optional features you might need
4. ✅ Test each component after installation

### After Installation

1. ✅ Verify all services running
2. ✅ Test panel access
3. ✅ Test Wings connection
4. ✅ Create first server
5. ✅ Set up backups
6. ✅ Enable 2FA

## Next Steps

After pre-installation checks:

```bash
# Run main installation
sudo ./pteroanyinstall.sh install-full

# Or specific components
sudo ./pteroanyinstall.sh install-panel
sudo ./pteroanyinstall.sh install-wings
```

## Support

**Issues with pre-checks:**
- Check `/tmp/pteroanyinstall-precheck-*.txt` report
- Review this guide
- Check main README.md

**Need help:**
- GitHub Issues
- Pterodactyl Discord
- Community forums

## Summary

The pre-installation checks ensure:
- ✅ System is ready
- ✅ No conflicts with existing installations
- ✅ Network properly configured
- ✅ All prerequisites met
- ✅ Smooth installation process

Run pre-checks before every installation to avoid issues!
