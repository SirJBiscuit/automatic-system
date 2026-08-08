# Troubleshooting Guide

Quick reference for common issues and their automatic fixes.

## Automatic Diagnostics

The `panel-diagnostics.sh` script now includes **automatic issue detection and fixes**!

```bash
sudo ~/CascadeProjects/pteroanyinstall/scripts/panel-diagnostics.sh
```

## Common Issues & Automatic Fixes

### 1. Port 8080 Conflict (Filebrowser blocking Nginx)

**Symptoms:**
- Nginx fails to start
- Error: `bind() to 0.0.0.0:8080 failed (98: Address already in use)`
- Panel web console not accessible

**Automatic Fix:**
The script will detect filebrowser on port 8080 and offer to move it to port 8090.

**Manual Fix:**
```bash
# Option 9 in the menu: Fix port conflicts
# Option 10 in the menu: Move filebrowser to different port
```

---

### 2. Nginx Not Running

**Symptoms:**
- Panel not accessible
- Port 8082 not listening
- 502 Bad Gateway errors

**Automatic Fix:**
The script will restart nginx automatically.

**Manual Fix:**
```bash
sudo systemctl restart nginx
sudo systemctl status nginx
```

---

### 3. Cloudflare Tunnel Down

**Symptoms:**
- Panel accessible locally but not via `panel.cloudmc.online`
- Tunnel service not running

**Automatic Fix:**
The script will restart the tunnel service.

**Manual Fix:**
```bash
sudo systemctl restart cloudflared-webconsole
sudo systemctl status cloudflared-webconsole
```

---

### 4. PHP-FPM Not Running

**Symptoms:**
- Panel shows blank page or PHP errors
- 502/504 errors

**Automatic Fix:**
The script will restart PHP-FPM.

**Manual Fix:**
```bash
sudo systemctl restart php8.2-fpm
sudo systemctl status php8.2-fpm
```

---

### 5. Port Conflicts (General)

**Symptoms:**
- Services fail to start
- "Address already in use" errors

**Automatic Fix:**
The script will identify conflicting processes and offer to kill them.

**Manual Fix:**
```bash
# Find what's using a port
sudo lsof -i :8080

# Kill the process
sudo kill -9 <PID>

# Restart the service
sudo systemctl restart nginx
```

---

## Quick Commands

### Check All Services
```bash
sudo systemctl status nginx php8.2-fpm cloudflared-webconsole wings
```

### Check All Ports
```bash
sudo netstat -tlnp | grep -E '(443|8080|8082|8083)'
```

### View Logs
```bash
# Nginx errors
sudo tail -50 /var/log/nginx/pterodactyl.app-error.log

# Tunnel logs
sudo journalctl -u cloudflared-webconsole -n 50

# Wings logs
sudo journalctl -u wings -n 50

# PHP-FPM logs
sudo tail -50 /var/log/php8.2-fpm.log
```

### Test Connectivity
```bash
# Local panel
curl -I http://localhost:8082

# Public panel
curl -I https://panel.cloudmc.online

# Web console
curl -I http://localhost:8080
```

---

## Menu Options

When you run the diagnostics script, you'll see these options:

1. **Restart all services** - Restarts nginx, PHP-FPM, and tunnel
2. **Edit tunnel configuration** - Opens Cloudflare tunnel config
3. **Edit panel nginx config** - Opens nginx configuration
4. **View tunnel logs** - Shows recent tunnel activity
5. **View nginx error logs** - Shows nginx errors
6. **Test panel connectivity** - Tests all endpoints
7. **Change panel tunnel port** - Modify tunnel port
8. **Show tunnel status** - Detailed tunnel status
9. **Fix port conflicts manually** - Interactive port conflict resolver
10. **Move filebrowser to different port** - Change filebrowser port
11. **Exit** - Close the script

---

## Automatic Fix Flow

1. Script runs diagnostics
2. Detects issues automatically:
   - Port conflicts
   - Service failures
   - Configuration problems
3. Offers to fix automatically
4. You confirm with `y`
5. Script applies fixes:
   - Moves filebrowser if blocking port 8080
   - Kills conflicting processes
   - Restarts failed services
   - Tests connectivity
6. Reports results

---

## Prevention

### Startup Check Script
Run on boot to ensure all services start correctly:
```bash
sudo ~/CascadeProjects/pteroanyinstall/scripts/server-startup-check.sh
```

### Dynamic DNS
Automatically updates DNS when IP changes:
```bash
sudo systemctl status cloudflare-ddns.timer
```

---

## Emergency Recovery

If everything is broken:

```bash
# 1. Stop all services
sudo systemctl stop nginx php8.2-fpm cloudflared-webconsole

# 2. Kill any stuck processes
sudo pkill nginx
sudo pkill php-fpm

# 3. Check for port conflicts
sudo netstat -tlnp | grep -E '(443|8080|8082)'

# 4. Start services one by one
sudo systemctl start php8.2-fpm
sudo systemctl start nginx
sudo systemctl start cloudflared-webconsole

# 5. Check status
sudo systemctl status nginx php8.2-fpm cloudflared-webconsole
```

---

## Getting Help

If automatic fixes don't work:

1. Run diagnostics and save output:
   ```bash
   sudo ~/CascadeProjects/pteroanyinstall/scripts/panel-diagnostics.sh > ~/diagnostics.log 2>&1
   ```

2. Check the logs:
   ```bash
   cat ~/diagnostics.log
   ```

3. Look for specific error messages in service logs

4. Check the troubleshooting guide for your specific error

---

## Port Reference

| Port | Service | Purpose |
|------|---------|---------|
| 443 | Nginx | HTTPS (Main panel) |
| 8080 | Nginx | Web console proxy |
| 8081 | Python | Web console app |
| 8082 | Nginx | Panel tunnel (Cloudflare) |
| 8083 | Wings | Wings API |
| 8090 | Filebrowser | File manager (moved from 8080) |
| 3000 | Open WebUI | AI interface |
| 5050 | Pingvin Share | File sharing |
| 5051 | Nextcloud | Cloud storage |
| 25565-25575 | Game Servers | Minecraft/game servers |

---

## File Locations

### Configurations
- Panel: `/var/www/pterodactyl/.env`
- Nginx: `/etc/nginx/sites-enabled/`
- Tunnel: `/root/.cloudflared/config.yml`
- Filebrowser: `/etc/systemd/system/filebrowser.service`

### Logs
- Nginx: `/var/log/nginx/`
- PHP-FPM: `/var/log/php8.2-fpm.log`
- Systemd: `journalctl -u <service-name>`

### Scripts
- Diagnostics: `~/CascadeProjects/pteroanyinstall/scripts/panel-diagnostics.sh`
- Startup Check: `~/CascadeProjects/pteroanyinstall/scripts/server-startup-check.sh`
- DDNS: `~/CascadeProjects/pteroanyinstall/scripts/cloudflare-ddns.sh`
- Git Sync: `~/CascadeProjects/pteroanyinstall/scripts/git-sync.sh`
