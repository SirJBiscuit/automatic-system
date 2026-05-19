# Enhanced SSH Terminal - Deployment Guide

## 🚀 Quick Deployment

### Prerequisites
- Ubuntu/Debian server with root access
- Nginx installed
- Port 8095 available
- ttyd running on port 7681 (for terminal functionality)

### One-Command Deployment

```bash
sudo bash deploy.sh
```

This will:
1. ✅ Create backup of existing installation
2. ✅ Deploy new version
3. ✅ Configure Nginx with security headers
4. ✅ Set up firewall rules
5. ✅ Verify deployment
6. ✅ Auto-rollback on failure

---

## 🔒 Security Features

### Built-in Security
- **Password Authentication**: SHA-256 hashed passwords
- **Session Management**: Secure sessionStorage
- **CSP Headers**: Content Security Policy enabled
- **XSS Protection**: X-XSS-Protection header
- **Frame Protection**: X-Frame-Options set to SAMEORIGIN
- **MIME Sniffing**: X-Content-Type-Options nosniff
- **Rate Limiting**: 5 login attempts per minute
- **No Server Tokens**: Nginx version hidden

### Nginx Security Configuration
```nginx
# Security Headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;

# Content Security Policy
add_header Content-Security-Policy "default-src 'self'; ..." always;

# Rate Limiting
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
```

---

## 📦 Manual Deployment

### Step 1: Backup Current Installation
```bash
sudo mkdir -p /var/backups/ssh-terminal
sudo tar -czf /var/backups/ssh-terminal/backup_$(date +%Y%m%d_%H%M%S).tar.gz \
    -C /var/www ssh-terminal
```

### Step 2: Deploy Files
```bash
sudo mkdir -p /var/www/ssh-terminal
sudo cp index.html /var/www/ssh-terminal/
sudo cp ai-context.json /var/www/ssh-terminal/
sudo chown -R www-data:www-data /var/www/ssh-terminal
sudo chmod -R 755 /var/www/ssh-terminal
```

### Step 3: Configure Nginx
```bash
sudo nano /etc/nginx/sites-available/ssh-terminal
```

Paste the configuration from `deploy.sh` (lines 76-131)

### Step 4: Enable Site
```bash
sudo ln -s /etc/nginx/sites-available/ssh-terminal \
    /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Step 5: Configure Firewall
```bash
sudo ufw allow 8095/tcp comment 'SSH Terminal'
```

---

## 🔄 Rollback Procedure

### Automatic Rollback
The deployment script automatically rolls back on failure.

### Manual Rollback
```bash
# List available backups
ls -lh /var/backups/ssh-terminal/

# Restore specific backup
sudo rm -rf /var/www/ssh-terminal
sudo tar -xzf /var/backups/ssh-terminal/backup_TIMESTAMP.tar.gz \
    -C /var/www
sudo systemctl reload nginx
```

---

## 🌐 Access & First Login

### Access URL
```
http://YOUR_SERVER_IP:8095
```

### First Time Setup
1. Navigate to the URL
2. You'll see "First Time Setup"
3. Create a strong admin password (min 6 characters)
4. Password is hashed with SHA-256 and stored securely
5. You're automatically logged in

### Subsequent Logins
1. Enter your password
2. Session persists until browser tab closes
3. Use Settings → Logout to manually logout

---

## 🔐 Security Best Practices

### 1. Strong Password
```
✅ Use 12+ characters
✅ Mix uppercase, lowercase, numbers, symbols
✅ Don't reuse passwords
✅ Change periodically
```

### 2. HTTPS Setup (Recommended)
```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal
sudo systemctl enable certbot.timer
```

### 3. Firewall Configuration
```bash
# Allow only specific IPs (optional)
sudo ufw delete allow 8095/tcp
sudo ufw allow from YOUR_IP to any port 8095

# Or use IP whitelist in Nginx
```

### 4. Regular Backups
```bash
# Add to crontab
0 2 * * * tar -czf /var/backups/ssh-terminal/backup_$(date +\%Y\%m\%d).tar.gz \
    -C /var/www ssh-terminal
```

### 5. Monitor Logs
```bash
# Nginx access log
sudo tail -f /var/log/nginx/access.log | grep 8095

# Nginx error log
sudo tail -f /var/log/nginx/error.log
```

---

## 🛠️ Troubleshooting

### Port Already in Use
```bash
# Check what's using port 8095
sudo lsof -i :8095

# Kill the process
sudo kill -9 PID
```

### Nginx Configuration Error
```bash
# Test configuration
sudo nginx -t

# Check error details
sudo journalctl -u nginx -n 50
```

### Permission Denied
```bash
# Fix permissions
sudo chown -R www-data:www-data /var/www/ssh-terminal
sudo chmod -R 755 /var/www/ssh-terminal
```

### Can't Access from Browser
```bash
# Check if Nginx is running
sudo systemctl status nginx

# Check firewall
sudo ufw status

# Check if port is listening
sudo netstat -tlnp | grep 8095
```

### ttyd Not Working
```bash
# Check if ttyd is running
ps aux | grep ttyd

# Start ttyd
ttyd -p 7681 bash

# Or use systemd service
sudo systemctl start ttyd
```

---

## 📊 Monitoring

### Check Deployment Status
```bash
# Service status
sudo systemctl status nginx

# Test endpoint
curl -I http://localhost:8095

# Check logs
sudo tail -f /var/log/nginx/access.log
```

### Performance Monitoring
```bash
# Nginx connections
sudo nginx -V 2>&1 | grep -o with-http_stub_status_module

# Add to Nginx config
location /nginx_status {
    stub_status on;
    access_log off;
    allow 127.0.0.1;
    deny all;
}
```

---

## 🔄 Update Procedure

### Update to New Version
```bash
# 1. Pull latest code
cd /path/to/repo
git pull origin main

# 2. Run deployment script
cd web-terminal
sudo bash deploy.sh

# 3. Verify
curl -I http://localhost:8095
```

### Zero-Downtime Update
```bash
# Use blue-green deployment
sudo cp -r /var/www/ssh-terminal /var/www/ssh-terminal-new
# Update files in ssh-terminal-new
# Test thoroughly
# Swap symlinks
sudo ln -sfn /var/www/ssh-terminal-new /var/www/ssh-terminal
sudo systemctl reload nginx
```

---

## 📝 Maintenance

### Clean Old Backups
```bash
# Keep only last 10 backups
cd /var/backups/ssh-terminal
ls -t backup_*.tar.gz | tail -n +11 | xargs -r rm
```

### Clear Browser Cache
Users should clear cache after updates:
```
Ctrl + Shift + R (Windows/Linux)
Cmd + Shift + R (Mac)
```

### Database Cleanup
```bash
# Clear old localStorage data (client-side)
# Users can do this in browser console:
localStorage.clear()
```

---

## 🆘 Support

### Logs Location
- Nginx Access: `/var/log/nginx/access.log`
- Nginx Error: `/var/log/nginx/error.log`
- Backups: `/var/backups/ssh-terminal/`

### Common Issues
1. **Login not working**: Clear browser cache and localStorage
2. **Widgets not showing**: Check browser console for errors
3. **AI not responding**: Verify Open WebUI is accessible
4. **Terminal not connecting**: Check ttyd service status

---

## ✅ Post-Deployment Checklist

- [ ] Deployment successful (HTTP 200 response)
- [ ] Login screen appears
- [ ] Admin password set
- [ ] Can login successfully
- [ ] Firewall rules configured
- [ ] Backups directory created
- [ ] Nginx security headers verified
- [ ] SSL certificate installed (if using HTTPS)
- [ ] ttyd service running
- [ ] AI assistant accessible
- [ ] Widgets working
- [ ] Context menus functional
- [ ] Mobile responsive

---

## 🎉 You're All Set!

Your Enhanced SSH Terminal is now deployed securely and ready for production use!

**Access it at:** `http://YOUR_SERVER_IP:8095`

**Remember:**
- Set a strong password
- Enable HTTPS for production
- Regular backups
- Monitor logs
- Keep system updated
