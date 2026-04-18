# 🔄 Pterodactyl Server Migration Guide

## Complete Guide to Migrate from Old to New Pterodactyl Server

---

## 📋 **Overview**

This guide will help you migrate your existing Pterodactyl installation to a new server while preserving:
- ✅ All Panel data (users, servers, nodes, settings)
- ✅ All game server files
- ✅ All databases
- ✅ All configurations
- ✅ SSL certificates
- ✅ Custom themes/branding

**Estimated Time:** 2-4 hours (depending on data size)

---

## ⚠️ **Before You Start**

### **Prerequisites:**
- Access to OLD server (SSH)
- Access to NEW server (SSH)
- Root/sudo access on both servers
- Enough disk space on NEW server
- Domain DNS can be updated
- Backup of OLD server (recommended)

### **Important Notes:**
- Plan migration during low-traffic period
- Inform users of maintenance window
- Test thoroughly before switching DNS
- Keep old server running until verified

---

# PART 1: BACKUP OLD SERVER

## Step 1: Create Backup Directory

```bash
# On OLD server
sudo mkdir -p /root/pterodactyl-migration
cd /root/pterodactyl-migration
```

## Step 2: Backup Panel Database

```bash
# Get database credentials
cd /var/www/pterodactyl
cat .env | grep DB_

# Backup database
sudo mysqldump -u panel_user -p panel_database > panel_database.sql

# Or if using root:
sudo mysqldump -u root -p panel > panel_database.sql

# Compress it
gzip panel_database.sql
```

## Step 3: Backup Panel Files

```bash
# Backup Panel directory
sudo tar -czf panel_files.tar.gz /var/www/pterodactyl

# Backup Nginx config
sudo tar -czf nginx_config.tar.gz /etc/nginx/sites-available/pterodactyl.conf

# Backup SSL certificates
sudo tar -czf ssl_certs.tar.gz /etc/letsencrypt
```

## Step 4: Backup Wings Configuration

```bash
# Backup Wings config
sudo tar -czf wings_config.tar.gz /etc/pterodactyl

# Backup Wings systemd service
sudo cp /etc/systemd/system/wings.service wings.service
```

## Step 5: Backup Game Server Files

```bash
# Check size first (this can be HUGE!)
sudo du -sh /var/lib/pterodactyl/volumes

# Backup server files (WARNING: Can take hours if large!)
sudo tar -czf server_files.tar.gz /var/lib/pterodactyl/volumes

# Alternative: Backup individual servers
cd /var/lib/pterodactyl/volumes
for dir in */; do
    echo "Backing up $dir..."
    sudo tar -czf "/root/pterodactyl-migration/server_${dir%/}.tar.gz" "$dir"
done
```

## Step 6: Create Backup Manifest

```bash
cd /root/pterodactyl-migration

cat > backup_manifest.txt <<EOF
Pterodactyl Migration Backup
============================
Date: $(date)
Old Server: $(hostname)
Old IP: $(hostname -I | awk '{print $1}')

Files:
$(ls -lh)

Panel Version: $(cd /var/www/pterodactyl && php artisan --version)
Wings Version: $(wings --version 2>/dev/null || echo "Not available")

Database Size: $(du -sh panel_database.sql.gz)
Panel Files: $(du -sh panel_files.tar.gz)
Server Files: $(du -sh server_files.tar.gz)
Total Backup Size: $(du -sh /root/pterodactyl-migration)
EOF

cat backup_manifest.txt
```

---

# PART 2: TRANSFER BACKUPS TO NEW SERVER

## Option A: Direct Transfer (Fastest)

```bash
# On OLD server - transfer to NEW server
rsync -avz --progress /root/pterodactyl-migration/ root@NEW_SERVER_IP:/root/pterodactyl-migration/

# Or using SCP
scp -r /root/pterodactyl-migration/* root@NEW_SERVER_IP:/root/pterodactyl-migration/
```

## Option B: External Drive

```bash
# On OLD server - copy to external drive
sudo mount /dev/sdb1 /mnt/backup
sudo cp -r /root/pterodactyl-migration/* /mnt/backup/
sudo umount /mnt/backup

# Then physically move drive to NEW server
# On NEW server
sudo mount /dev/sdb1 /mnt/backup
sudo cp -r /mnt/backup/* /root/pterodactyl-migration/
sudo umount /mnt/backup
```

## Option C: Cloud Storage (S3, Dropbox, etc.)

```bash
# Install rclone
curl https://rclone.org/install.sh | sudo bash

# Configure rclone
rclone config

# Upload to cloud
rclone copy /root/pterodactyl-migration remote:pterodactyl-backup

# On NEW server - download
rclone copy remote:pterodactyl-backup /root/pterodactyl-migration
```

---

# PART 3: INSTALL PTERODACTYL ON NEW SERVER

## Step 1: Run Pre-Installation Checks

```bash
# On NEW server
bash <(curl -s https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/install.sh)

cd /opt/ptero
./pteroanyinstall.sh pre-check
```

## Step 2: Install Panel (DO NOT RUN INITIAL SETUP YET!)

```bash
# Install Panel
./pteroanyinstall.sh install-panel

# STOP! Don't complete the initial setup wizard
# We'll restore the database instead
```

## Step 3: Install Wings

```bash
# Install Wings
./pteroanyinstall.sh install-wings

# STOP! Don't configure the node yet
# We'll restore the configuration
```

---

# PART 4: RESTORE DATA ON NEW SERVER

## Step 1: Stop Services

```bash
# On NEW server
sudo systemctl stop wings
sudo systemctl stop nginx
sudo systemctl stop pteroctl
```

## Step 2: Restore Panel Database

```bash
cd /root/pterodactyl-migration

# Decompress database
gunzip panel_database.sql.gz

# Get NEW server database credentials
cd /var/www/pterodactyl
cat .env | grep DB_

# Drop existing database and recreate
mysql -u root -p <<EOF
DROP DATABASE panel;
CREATE DATABASE panel;
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Restore database
mysql -u root -p panel < /root/pterodactyl-migration/panel_database.sql

# Verify restoration
mysql -u root -p -e "USE panel; SHOW TABLES;"
```

## Step 3: Restore Panel Files

```bash
# Backup NEW panel files (just in case)
sudo mv /var/www/pterodactyl /var/www/pterodactyl.new

# Extract OLD panel files
cd /root/pterodactyl-migration
sudo tar -xzf panel_files.tar.gz -C /

# Update .env with NEW server database credentials
cd /var/www/pterodactyl
sudo nano .env

# Update these if needed:
# APP_URL=https://panel.yourdomain.com
# DB_HOST=127.0.0.1
# DB_PORT=3306
# DB_DATABASE=panel
# DB_USERNAME=pterodactyl
# DB_PASSWORD=<new_password>

# Clear cache
php artisan config:clear
php artisan cache:clear
php artisan view:clear

# Run migrations (in case of version differences)
php artisan migrate --force

# Fix permissions
sudo chown -R www-data:www-data /var/www/pterodactyl
sudo chmod -R 755 /var/www/pterodactyl/storage
sudo chmod -R 755 /var/www/pterodactyl/bootstrap/cache
```

## Step 4: Restore SSL Certificates

```bash
# Extract SSL certificates
cd /root/pterodactyl-migration
sudo tar -xzf ssl_certs.tar.gz -C /

# Verify certificates
sudo certbot certificates

# If domain is different, you'll need new certificates:
# sudo certbot --nginx -d panel.yourdomain.com
```

## Step 5: Restore Nginx Configuration

```bash
# Extract Nginx config
cd /root/pterodactyl-migration
sudo tar -xzf nginx_config.tar.gz -C /

# Update domain if changed
sudo nano /etc/nginx/sites-available/pterodactyl.conf

# Test Nginx config
sudo nginx -t

# If OK, reload
sudo systemctl reload nginx
```

## Step 6: Restore Wings Configuration

```bash
# Extract Wings config
cd /root/pterodactyl-migration
sudo tar -xzf wings_config.tar.gz -C /

# Update config.yml with NEW server IP if changed
sudo nano /etc/pterodactyl/config.yml

# Update these:
# api:
#   host: 0.0.0.0
#   port: 8080
#   ssl:
#     enabled: true
#     cert: /etc/letsencrypt/live/node.yourdomain.com/fullchain.pem
#     key: /etc/letsencrypt/live/node.yourdomain.com/privkey.pem

# Restore Wings service
sudo cp wings.service /etc/systemd/system/
sudo systemctl daemon-reload
```

## Step 7: Restore Game Server Files

```bash
# Extract server files
cd /root/pterodactyl-migration
sudo tar -xzf server_files.tar.gz -C /

# Or restore individual servers:
for file in server_*.tar.gz; do
    echo "Restoring $file..."
    sudo tar -xzf "$file" -C /var/lib/pterodactyl/volumes/
done

# Fix permissions
sudo chown -R pterodactyl:pterodactyl /var/lib/pterodactyl/volumes
sudo chmod -R 755 /var/lib/pterodactyl/volumes
```

---

# PART 5: UPDATE PANEL CONFIGURATION

## Step 1: Update Node Configuration in Panel

```bash
# Log into Panel web interface
# Go to: Admin Panel → Nodes → Your Node

# Update these settings:
# - FQDN: node.yourdomain.com (NEW server)
# - Daemon Server File Directory: /var/lib/pterodactyl/volumes
# - Memory: (NEW server RAM)
# - Disk: (NEW server disk space)
```

## Step 2: Update Application Settings

```bash
# In Panel: Admin Panel → Settings → General

# Update:
# - Panel URL: https://panel.yourdomain.com
# - Company Name: (if changed)
```

## Step 3: Regenerate Wings Token (if needed)

```bash
# In Panel: Admin Panel → Nodes → Your Node → Configuration

# Copy the configuration command
# Run it on NEW server:
cd /etc/pterodactyl
sudo wings configure --panel-url https://panel.yourdomain.com --token YOUR_TOKEN --node YOUR_NODE_ID
```

---

# PART 6: START SERVICES & TEST

## Step 1: Start Services

```bash
# On NEW server
sudo systemctl start nginx
sudo systemctl start wings
sudo systemctl start pteroctl

# Check status
sudo systemctl status nginx
sudo systemctl status wings
sudo systemctl status pteroctl
```

## Step 2: Test Panel Access

```bash
# Access Panel
https://panel.yourdomain.com

# Login with your admin credentials
# Verify:
# - All users are present
# - All servers are listed
# - All settings are correct
```

## Step 3: Test Wings Connection

```bash
# Check Wings logs
sudo journalctl -u wings -f

# In Panel, check node status:
# Admin Panel → Nodes → Your Node
# Should show: Online (green)
```

## Step 4: Test Server Startup

```bash
# Try starting a test server from Panel
# Verify:
# - Server starts successfully
# - Console works
# - File manager works
# - SFTP works
```

---

# PART 7: UPDATE DNS & GO LIVE

## Step 1: Update DNS Records

```bash
# Update A records to point to NEW server IP:
# panel.yourdomain.com → NEW_SERVER_IP
# node.yourdomain.com → NEW_SERVER_IP

# Wait for DNS propagation (5-30 minutes)
# Check with:
nslookup panel.yourdomain.com
nslookup node.yourdomain.com
```

## Step 2: Test from External Network

```bash
# From a different computer/network:
# Access: https://panel.yourdomain.com
# Verify everything works
```

## Step 3: Monitor for Issues

```bash
# On NEW server, monitor logs:
sudo tail -f /var/log/nginx/error.log
sudo journalctl -u wings -f
sudo tail -f /var/www/pterodactyl/storage/logs/laravel-$(date +%Y-%m-%d).log
```

---

# PART 8: POST-MIGRATION TASKS

## Step 1: Install P.R.I.S.M AI (Recommended)

```bash
cd /opt/ptero
./pteroanyinstall.sh ai-assistant

# Follow the interactive tutorial
# Set up Discord notifications
# Configure API integration
```

## Step 2: Set Up Automated Backups

```bash
./pteroanyinstall.sh backup

# Or set up automatic backups:
./pteroanyinstall.sh quick-setup
```

## Step 3: Run System Optimization

```bash
# If P.R.I.S.M is installed:
chatbot detect

# Follow optimization recommendations
```

## Step 4: Update User Documentation

```bash
# Inform users of:
# - New server IP (if changed)
# - New SFTP host (if changed)
# - Any downtime that occurred
```

## Step 5: Keep Old Server Running (Temporarily)

```bash
# Keep OLD server running for 1-2 weeks
# Monitor for any missed data
# Once verified, decommission old server
```

---

# TROUBLESHOOTING

## Panel Won't Load

```bash
# Check Nginx
sudo systemctl status nginx
sudo nginx -t

# Check PHP-FPM
sudo systemctl status php8.1-fpm

# Check logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/www/pterodactyl/storage/logs/laravel-*.log

# Clear cache
cd /var/www/pterodactyl
php artisan config:clear
php artisan cache:clear
```

## Wings Won't Connect

```bash
# Check Wings status
sudo systemctl status wings

# Check Wings logs
sudo journalctl -u wings -n 100

# Verify config
sudo cat /etc/pterodactyl/config.yml

# Regenerate token from Panel
# Run configuration command again
```

## Servers Won't Start

```bash
# Check Wings logs
sudo journalctl -u wings -f

# Check Docker
sudo docker ps
sudo docker logs <container_id>

# Check permissions
sudo chown -R pterodactyl:pterodactyl /var/lib/pterodactyl/volumes
```

## Database Connection Failed

```bash
# Check .env file
cd /var/www/pterodactyl
cat .env | grep DB_

# Test database connection
mysql -u pterodactyl -p -h 127.0.0.1 panel

# Check MySQL status
sudo systemctl status mysql

# Check MySQL logs
sudo tail -f /var/log/mysql/error.log
```

## SSL Certificate Issues

```bash
# Check certificates
sudo certbot certificates

# Renew if needed
sudo certbot renew

# Or get new certificates
sudo certbot --nginx -d panel.yourdomain.com -d node.yourdomain.com
```

---

# MIGRATION CHECKLIST

## Pre-Migration:
- [ ] Backup OLD server completely
- [ ] Test backups are valid
- [ ] Document OLD server configuration
- [ ] Prepare NEW server
- [ ] Schedule maintenance window
- [ ] Notify users

## During Migration:
- [ ] Stop services on OLD server
- [ ] Transfer all data
- [ ] Install Pterodactyl on NEW server
- [ ] Restore database
- [ ] Restore Panel files
- [ ] Restore Wings config
- [ ] Restore game server files
- [ ] Update configurations
- [ ] Test thoroughly

## Post-Migration:
- [ ] Update DNS records
- [ ] Test from external network
- [ ] Monitor for 24-48 hours
- [ ] Install P.R.I.S.M AI
- [ ] Set up automated backups
- [ ] Update documentation
- [ ] Inform users of completion
- [ ] Keep OLD server as backup (1-2 weeks)
- [ ] Decommission OLD server

---

# QUICK MIGRATION SCRIPT

For experienced users, here's a quick script:

```bash
#!/bin/bash
# Quick Pterodactyl Migration Script
# Run on OLD server

echo "Starting Pterodactyl migration backup..."

# Create backup directory
mkdir -p /root/pterodactyl-migration
cd /root/pterodactyl-migration

# Backup database
mysqldump -u root -p panel | gzip > panel_database.sql.gz

# Backup files
tar -czf panel_files.tar.gz /var/www/pterodactyl
tar -czf wings_config.tar.gz /etc/pterodactyl
tar -czf nginx_config.tar.gz /etc/nginx/sites-available/pterodactyl.conf
tar -czf ssl_certs.tar.gz /etc/letsencrypt

# Backup server files (optional - can be huge!)
read -p "Backup game server files? (y/n): " backup_servers
if [[ "$backup_servers" =~ ^[Yy]$ ]]; then
    tar -czf server_files.tar.gz /var/lib/pterodactyl/volumes
fi

# Create manifest
ls -lh > backup_manifest.txt
du -sh . >> backup_manifest.txt

echo "Backup complete! Files in: /root/pterodactyl-migration"
echo "Total size: $(du -sh /root/pterodactyl-migration | cut -f1)"
```

---

# ALTERNATIVE: USING PTERODACTYL BACKUP ADDON

If you have the Pterodactyl Backup addon installed:

```bash
# Use built-in backup
php artisan p:backup:run

# Export to external storage
php artisan p:backup:export
```

---

**Your Pterodactyl server is now successfully migrated!** 🎉

For ongoing monitoring and automation, install P.R.I.S.M AI:
```bash
cd /opt/ptero
./pteroanyinstall.sh ai-assistant
```
