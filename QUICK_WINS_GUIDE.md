# Quick Wins Guide - Essential Post-Installation Features

## Overview

The Quick Wins setup provides **5 essential features** that every Pterodactyl installation should have. These features enhance security, reliability, and maintainability with minimal configuration.

## Installation

```bash
sudo ./quick-setup.sh
```

Or via main script:

```bash
sudo ./pteroanyinstall.sh quick-setup
```

## Features Included

### 1. 🔐 SSL Certificate Monitoring

**What it does:**
- Checks SSL certificate expiry daily
- Sends email alerts 30 days before expiration
- Automatically attempts renewal with certbot
- Prevents unexpected certificate expiration

**Configuration:**
- Script: `/usr/local/bin/check-ssl-expiry.sh`
- Cron: `/etc/cron.daily/ssl-check`
- Alert threshold: 30 days

**Manual check:**
```bash
/usr/local/bin/check-ssl-expiry.sh panel.yourdomain.com admin@yourdomain.com
```

**Output example:**
```
SSL Certificate Status for panel.example.com
========================================
Expires: Dec 15 23:59:59 2024 GMT
Days until expiry: 45
Certificate is valid for 45 more days
```

### 2. 🛡️ Fail2ban Security

**What it does:**
- Protects against brute-force attacks
- Monitors Pterodactyl Panel login attempts
- Protects SSH, Nginx, and other services
- Automatically bans malicious IPs

**Protected services:**
- Pterodactyl Panel (5 failed attempts = 1 hour ban)
- Nginx rate limiting (10 attempts = 2 hour ban)
- SSH (3 failed attempts = 24 hour ban)

**Configuration:**
- Filter: `/etc/fail2ban/filter.d/pterodactyl.conf`
- Jail: `/etc/fail2ban/jail.d/pterodactyl.conf`

**Useful commands:**
```bash
# View status
fail2ban-client status

# View banned IPs
fail2ban-client status pterodactyl

# Unban an IP
fail2ban-client set pterodactyl unbanip 192.168.1.100

# View logs
tail -f /var/log/fail2ban.log
```

### 3. 💾 Automated Backup System

**What it does:**
- Automatically backs up Panel files
- Exports database daily
- Backs up Wings configuration
- Maintains backup retention policy
- Cleans up old backups automatically

**Backup schedule options:**
1. Daily at 2 AM
2. Daily at 3 AM
3. Twice daily (2 AM and 2 PM)
4. Custom schedule

**What gets backed up:**
- Panel files: `/var/www/pterodactyl` → `panel-YYYYMMDD-HHMMSS.tar.gz`
- Database: MySQL dump → `database-YYYYMMDD-HHMMSS.sql.gz`
- Wings config: `/etc/pterodactyl/config.yml` → `wings-config-YYYYMMDD-HHMMSS.yml`

**Backup location:**
```
/var/backups/pterodactyl/
```

**Manual backup:**
```bash
/usr/local/bin/pterodactyl-backup.sh
```

**Restore example:**
```bash
# Extract Panel files
cd /var/www
sudo tar -xzf /var/backups/pterodactyl/panel-20240418-020000.tar.gz

# Restore database
gunzip < /var/backups/pterodactyl/database-20240418-020000.sql.gz | mysql -u pterodactyl -p panel

# Restore Wings config
sudo cp /var/backups/pterodactyl/wings-config-20240418-020000.yml /etc/pterodactyl/config.yml
```

**Retention policy:**
- Default: 7 days
- Configurable during setup
- Automatic cleanup via cron

### 4. 📊 Health Dashboard

**What it does:**
- Real-time system resource monitoring
- Service status checks
- SSL certificate status
- Recent backup information
- Fail2ban security status
- Docker container overview

**Access:**
```bash
ptero-health
```

**Dashboard output:**
```
╔════════════════════════════════════════════════════════════════════════╗
║              PTERODACTYL HEALTH DASHBOARD                              ║
╚════════════════════════════════════════════════════════════════════════╝

System Resources:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CPU Usage: 15.3%
Memory: 2.1G/4.0G (52%)
Disk: 8.5G/50G (17%)
Load Average: 0.45, 0.52, 0.48

Service Status:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
nginx: ● Running
mysql: ● Running
redis-server: ● Running
wings: ● Running
docker: ● Running

SSL Certificate:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Expires: Dec 15 23:59:59 2024 GMT (45 days)

Recent Backups:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
panel-20240418-020000.tar.gz - 125M - Apr 18 02:00
database-20240418-020000.sql.gz - 15M - Apr 18 02:00
wings-config-20240418-020000.yml - 2.1K - Apr 18 02:00

Security (Fail2ban):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Status: Active
Active jails: 3
Jail list: pterodactyl, nginx-limit-req, sshd

Docker Containers:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Running: 5 / 5 containers

Last updated: 2024-04-18 10:30:00
Run 'ptero-health' anytime to view this dashboard
```

### 5. 🔔 Update Notifications

**What it does:**
- Checks for Pterodactyl Panel updates weekly
- Checks for Wings updates
- Compares installed vs latest versions
- Sends email notifications (optional)
- Provides update instructions

**Schedule:**
- Weekly checks every Monday at 9 AM
- Configurable via cron

**Manual check:**
```bash
check-ptero-updates.sh
```

**Output example:**
```
Pterodactyl Update Check
========================
Current Panel Version: 1.11.5
Latest Panel Version: 1.11.7

⚠️  UPDATE AVAILABLE!
A new version of Pterodactyl Panel is available: v1.11.7

To update, run:
  cd /var/www/pterodactyl
  php artisan p:upgrade

Or use pteroanyinstall:
  ./pteroanyinstall.sh update

Current Wings Version: 1.11.5
Latest Wings Version: 1.11.7
⚠️  Wings update available: v1.11.7
```

## Post-Setup Commands

After running quick setup, these commands are available:

| Command | Description |
|---------|-------------|
| `ptero-health` | View system health dashboard |
| `check-ptero-updates.sh` | Check for updates |
| `pterodactyl-backup.sh` | Create manual backup |
| `fail2ban-client status` | View security status |
| `/usr/local/bin/check-ssl-expiry.sh DOMAIN EMAIL` | Check SSL certificate |

## Cron Jobs Created

The quick setup creates these automated tasks:

```bash
# Daily SSL check
0 2 * * * /etc/cron.daily/ssl-check

# Automated backups (example: daily at 2 AM)
0 2 * * * /usr/local/bin/pterodactyl-backup.sh >> /var/log/pterodactyl-backup.log 2>&1

# Weekly update check (Monday at 9 AM)
0 9 * * 1 /usr/local/bin/check-ptero-updates.sh
```

## Configuration Files

| File | Purpose |
|------|---------|
| `/usr/local/bin/check-ssl-expiry.sh` | SSL monitoring script |
| `/usr/local/bin/pterodactyl-backup.sh` | Backup automation script |
| `/usr/local/bin/check-ptero-updates.sh` | Update checker script |
| `/usr/local/bin/ptero-health.sh` | Health dashboard script |
| `/etc/fail2ban/filter.d/pterodactyl.conf` | Fail2ban filter |
| `/etc/fail2ban/jail.d/pterodactyl.conf` | Fail2ban jail config |
| `/etc/cron.daily/ssl-check` | Daily SSL check cron |

## Customization

### Change Backup Schedule

Edit the cron job:
```bash
crontab -e
```

Change the schedule (examples):
```bash
# Every 6 hours
0 */6 * * * /usr/local/bin/pterodactyl-backup.sh

# Every day at 3 AM
0 3 * * * /usr/local/bin/pterodactyl-backup.sh

# Twice daily (2 AM and 2 PM)
0 2,14 * * * /usr/local/bin/pterodactyl-backup.sh
```

### Change Backup Retention

Edit the backup script:
```bash
nano /usr/local/bin/pterodactyl-backup.sh
```

Change `RETENTION_DAYS`:
```bash
RETENTION_DAYS=14  # Keep backups for 14 days
```

### Change SSL Alert Threshold

Edit the SSL check script:
```bash
nano /usr/local/bin/check-ssl-expiry.sh
```

Change `ALERT_DAYS`:
```bash
ALERT_DAYS=14  # Alert 14 days before expiry
```

### Customize Fail2ban Rules

Edit the jail configuration:
```bash
nano /etc/fail2ban/jail.d/pterodactyl.conf
```

Adjust settings:
```ini
[pterodactyl]
maxretry = 3     # Number of attempts before ban
bantime = 7200   # Ban duration in seconds (2 hours)
findtime = 600   # Time window for attempts (10 minutes)
```

Restart Fail2ban:
```bash
systemctl restart fail2ban
```

## Troubleshooting

### SSL Check Failing

**Problem:** Cannot retrieve SSL certificate

**Solutions:**
```bash
# Check if domain is accessible
curl -I https://panel.yourdomain.com

# Check DNS
nslookup panel.yourdomain.com

# Check Nginx
systemctl status nginx

# Check certificate files
ls -la /etc/letsencrypt/live/panel.yourdomain.com/
```

### Backups Not Running

**Problem:** No backups being created

**Solutions:**
```bash
# Check cron is running
systemctl status cron

# View cron logs
grep CRON /var/log/syslog

# Test backup manually
/usr/local/bin/pterodactyl-backup.sh

# Check permissions
ls -la /var/backups/pterodactyl
```

### Fail2ban Not Banning

**Problem:** IPs not being banned

**Solutions:**
```bash
# Check Fail2ban status
systemctl status fail2ban

# Check logs
tail -f /var/log/fail2ban.log

# Test filter
fail2ban-regex /var/www/pterodactyl/storage/logs/laravel-*.log /etc/fail2ban/filter.d/pterodactyl.conf

# Restart Fail2ban
systemctl restart fail2ban
```

### Health Dashboard Not Working

**Problem:** `ptero-health` command not found

**Solutions:**
```bash
# Check if script exists
ls -la /usr/local/bin/ptero-health.sh

# Reinstall
bash quick-setup.sh

# Run directly
/usr/local/bin/ptero-health.sh
```

## Best Practices

### Security
1. ✅ Enable all Fail2ban jails
2. ✅ Monitor banned IPs regularly
3. ✅ Keep SSL certificates valid
4. ✅ Review security logs weekly

### Backups
1. ✅ Test restore process monthly
2. ✅ Store backups off-site
3. ✅ Verify backup integrity
4. ✅ Document restore procedures

### Monitoring
1. ✅ Check health dashboard daily
2. ✅ Review update notifications
3. ✅ Monitor disk space
4. ✅ Track resource usage trends

### Maintenance
1. ✅ Apply updates promptly
2. ✅ Clean old backups
3. ✅ Review logs regularly
4. ✅ Test disaster recovery plan

## Integration with Admin Panel

All quick wins features are accessible through the Admin Control Panel:

```bash
sudo ./ptero-admin.sh
```

From the admin panel you can:
- View health dashboard
- Manage backups
- Check security status
- View SSL certificate status
- Check for updates

## Uninstallation

To remove quick wins features:

```bash
# Remove cron jobs
crontab -e
# Delete the pterodactyl-backup and ssl-check lines

# Remove Fail2ban
apt-get remove --purge fail2ban  # Debian/Ubuntu
yum remove fail2ban              # CentOS/RHEL

# Remove scripts
rm /usr/local/bin/check-ssl-expiry.sh
rm /usr/local/bin/pterodactyl-backup.sh
rm /usr/local/bin/check-ptero-updates.sh
rm /usr/local/bin/ptero-health.sh
rm /usr/local/bin/ptero-health
```

## Summary

The Quick Wins setup provides:
- ✅ **Security**: Fail2ban protection against attacks
- ✅ **Reliability**: SSL monitoring prevents expiration
- ✅ **Safety**: Automated backups protect your data
- ✅ **Visibility**: Health dashboard shows system status
- ✅ **Maintenance**: Update notifications keep you informed

**Total setup time:** 5-10 minutes  
**Ongoing maintenance:** Minimal (automated)  
**Value:** Essential for production environments

Run quick setup on every Pterodactyl installation!
