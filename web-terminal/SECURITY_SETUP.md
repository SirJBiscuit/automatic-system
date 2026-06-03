# Security Configuration Guide

## Overview
This guide covers securing the Enhanced SSH Terminal with:
1. Disabling Termux tunnel
2. Password protecting term.cloudmc.online
3. Fixing wireless access for ssh.cloudmc.online

## Quick Setup

```bash
# Upload and run the security configuration script
cd /tmp/automatic-system/web-terminal
sudo bash security-config.sh
```

## Manual Steps

### 1. Disable Termux Tunnel

```bash
# Kill Termux tunnel processes
pkill -f "termux.*tunnel"
pkill -f "cloudflared.*termux"

# Block ports in firewall
sudo ufw delete allow 8022
sudo ufw delete allow 8023
sudo ufw reload

# List and delete Cloudflare tunnels
cloudflared tunnel list
cloudflared tunnel delete <tunnel-name>
```

### 2. Password Protect term.cloudmc.online

```bash
# Install htpasswd utility
sudo apt-get install apache2-utils

# Create password file
sudo mkdir -p /etc/nginx/auth
sudo htpasswd -c /etc/nginx/auth/term.htpasswd admin

# Update Nginx config to require authentication
sudo nano /etc/nginx/sites-available/ssh-terminal
```

Add these lines inside the `server` block:
```nginx
# Basic Authentication
auth_basic "Restricted Access - Admin Only";
auth_basic_user_file /etc/nginx/auth/term.htpasswd;
```

```bash
# Reload Nginx
sudo nginx -t
sudo systemctl reload nginx
```

### 3. Fix Wireless Access (Insecure Connection)

The "insecure connection" error occurs because:
- HTTP is being used instead of HTTPS
- No SSL certificate is configured

**Solution A: Use Cloudflare Tunnel (Recommended)**

```bash
# Install cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# Login to Cloudflare
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create ssh-terminal

# Create config file
sudo nano ~/.cloudflared/config.yml
```

Add:
```yaml
tunnel: <tunnel-id>
credentials-file: /root/.cloudflared/<tunnel-id>.json

ingress:
  - hostname: ssh.cloudmc.online
    service: http://localhost:80
  - hostname: term.cloudmc.online
    service: http://localhost:8095
  - service: http_status:404
```

```bash
# Route DNS
cloudflared tunnel route dns ssh-terminal ssh.cloudmc.online
cloudflared tunnel route dns ssh-terminal term.cloudmc.online

# Run tunnel as service
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
```

**Solution B: Use Let's Encrypt (Alternative)**

```bash
# Install certbot
sudo apt-get install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d ssh.cloudmc.online -d term.cloudmc.online

# Auto-renewal is configured automatically
```

### 4. Configure Firewall for Admin Access

```bash
# Allow SSH from anywhere
sudo ufw allow 22/tcp comment 'SSH - Admin access'

# Allow HTTPS
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw allow 80/tcp comment 'HTTP redirect'

# Allow term.cloudmc.online (password protected)
sudo ufw allow 8095/tcp comment 'term.cloudmc.online'

# Reload firewall
sudo ufw reload
sudo ufw status
```

## Testing

### Test Password Protection
```bash
# Should prompt for username/password
curl -I http://term.cloudmc.online:8095

# With credentials
curl -u admin:password http://term.cloudmc.online:8095
```

### Test HTTPS Access
```bash
# Should redirect to HTTPS
curl -I http://ssh.cloudmc.online

# Should work without "insecure" warning
curl -I https://ssh.cloudmc.online
```

### Test Wireless Access
1. Connect to WiFi (not ethernet)
2. Open browser
3. Navigate to `https://ssh.cloudmc.online`
4. Should load without security warnings

## Troubleshooting

### "Insecure Connection" Error
**Cause**: No SSL certificate or using HTTP instead of HTTPS

**Fix**:
1. Ensure Cloudflare tunnel is running: `systemctl status cloudflared`
2. Or install SSL certificate: `sudo certbot --nginx -d ssh.cloudmc.online`
3. Force HTTPS redirect in Nginx config

### Password Not Working
**Cause**: htpasswd file not found or incorrect permissions

**Fix**:
```bash
# Check file exists
ls -la /etc/nginx/auth/term.htpasswd

# Fix permissions
sudo chown www-data:www-data /etc/nginx/auth/term.htpasswd
sudo chmod 640 /etc/nginx/auth/term.htpasswd

# Recreate password
sudo htpasswd -c /etc/nginx/auth/term.htpasswd admin
```

### Can't Connect Wirelessly
**Cause**: Firewall blocking or DNS not resolving

**Fix**:
```bash
# Check firewall
sudo ufw status

# Check DNS resolution
nslookup ssh.cloudmc.online

# Check Nginx is listening
sudo netstat -tlnp | grep nginx

# Check Cloudflare tunnel
cloudflared tunnel info ssh-terminal
```

## Security Best Practices

1. **Use Strong Passwords**
   - Minimum 16 characters
   - Use password manager
   - Rotate every 90 days

2. **Enable 2FA** (if using Cloudflare)
   - Cloudflare Access with 2FA
   - Add additional authentication layer

3. **Monitor Access Logs**
   ```bash
   sudo tail -f /var/log/nginx/access.log
   sudo tail -f /var/log/nginx/error.log
   ```

4. **Rate Limiting**
   - Already configured in Nginx (5 requests/minute)
   - Prevents brute force attacks

5. **Regular Updates**
   ```bash
   sudo apt-get update
   sudo apt-get upgrade
   ```

## Credentials Storage

**term.cloudmc.online Password**
- Location: `/etc/nginx/auth/term.htpasswd`
- Username: `admin`
- Password: Generated during setup (save it!)

**Change Password**:
```bash
sudo htpasswd /etc/nginx/auth/term.htpasswd admin
sudo systemctl reload nginx
```

## Emergency Access

If locked out:
```bash
# SSH into server
ssh user@server-ip

# Temporarily disable auth
sudo nano /etc/nginx/sites-available/ssh-terminal
# Comment out auth_basic lines

# Reload Nginx
sudo systemctl reload nginx

# Access site and fix issue

# Re-enable auth
sudo nano /etc/nginx/sites-available/ssh-terminal
# Uncomment auth_basic lines
sudo systemctl reload nginx
```
