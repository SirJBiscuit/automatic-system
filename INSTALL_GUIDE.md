# Pterodactyl Installation Guide

## Pre-Installation Checklist

Before running the installation script, ensure you have:

- [ ] Fresh Linux server (Ubuntu 20.04+, Debian 11+, CentOS 8+, Rocky/Alma 8+)
- [ ] Root/sudo access
- [ ] Public IP address
- [ ] Domain name(s) purchased
- [ ] DNS records configured (see below)
- [ ] Minimum 2GB RAM (4GB+ recommended)
- [ ] Minimum 10GB disk space
- [ ] Firewall ports opened (see below)

## DNS Configuration

### Before Installation

Configure your DNS records to point to your server's public IP:

#### For Panel Installation
```
Type: A
Name: panel (or your subdomain)
Value: YOUR_SERVER_IP
TTL: Auto or 300
```

Example: `panel.example.com` → `123.45.67.89`

#### For Wings Installation
```
Type: A
Name: node (or your subdomain)
Value: YOUR_SERVER_IP
TTL: Auto or 300
```

Example: `node.example.com` → `123.45.67.89`

### Verify DNS Propagation

Before running the script, verify DNS is working:

```bash
dig +short panel.example.com
dig +short node.example.com
```

Both should return your server's IP address.

## Firewall Configuration

### Panel Server Ports

Open these ports on your Panel server:

```bash
# Ubuntu/Debian
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable

# CentOS/RHEL/Rocky/Alma
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### Wings Server Ports

Open these ports on your Wings server:

```bash
# Ubuntu/Debian
sudo ufw allow 22/tcp     # SSH
sudo ufw allow 80/tcp     # HTTP (for SSL)
sudo ufw allow 443/tcp    # HTTPS
sudo ufw allow 8080/tcp   # Wings API
sudo ufw allow 2022/tcp   # SFTP
sudo ufw allow 25565/tcp  # Minecraft (example)
sudo ufw enable

# CentOS/RHEL/Rocky/Alma
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=2022/tcp
sudo firewall-cmd --permanent --add-port=25565/tcp
sudo firewall-cmd --reload
```

## Installation Steps

### Step 1: Download the Script

```bash
wget https://raw.githubusercontent.com/yourusername/pteroanyinstall/main/pteroanyinstall.sh
chmod +x pteroanyinstall.sh
```

Or use curl:

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/pteroanyinstall/main/pteroanyinstall.sh -o pteroanyinstall.sh
chmod +x pteroanyinstall.sh
```

### Step 2: Run the Script

#### Interactive Mode (Recommended for First-Time Users)

```bash
sudo ./pteroanyinstall.sh
```

The script will:
1. Ask if you want to scan for existing installations
2. Present installation options
3. Guide you through the process

#### Direct Installation

**Panel Only:**
```bash
sudo ./pteroanyinstall.sh install-panel
```

**Wings Only:**
```bash
sudo ./pteroanyinstall.sh install-wings
```

**Full Installation (Panel + Wings on same server):**
```bash
sudo ./pteroanyinstall.sh install-full
```

### Step 3: Follow the Prompts

The script will ask for:

#### For Panel Installation:
- Panel FQDN (e.g., `panel.example.com`)
- Public IP address
- Email address (for SSL certificates)
- Admin password (or auto-generate)
- SSL setup preference (yes/no)
- Cloudflare integration (yes/no)

#### For Wings Installation:
- Wings FQDN (e.g., `node.example.com`)
- Public IP address
- Email address (for SSL certificates)
- GPU support (yes/no)
- Node configuration from Panel

### Step 4: Post-Installation

#### Panel Post-Installation

1. **Save Credentials:**
   ```bash
   cat /root/panel_credentials.txt
   ```
   Copy these credentials to a secure location, then delete the file:
   ```bash
   rm /root/panel_credentials.txt
   ```

2. **Access Panel:**
   - Navigate to `https://panel.example.com`
   - Log in with admin credentials
   - Complete initial setup

3. **Create First Location:**
   - Go to Admin → Locations
   - Click "Create New"
   - Enter location details

#### Wings Post-Installation

1. **Create Node in Panel:**
   - Log in to Panel admin
   - Go to Admin → Nodes
   - Click "Create New"
   - Fill in details:
     - Name: Your node name
     - FQDN: `node.example.com`
     - Communicate Over SSL: Yes
     - Behind Proxy: No (unless using Cloudflare proxy)
     - Memory: Your server's RAM
     - Disk: Your server's disk space
   - Click "Create Node"

2. **Get Configuration:**
   - Click on your newly created node
   - Go to "Configuration" tab
   - Copy the entire configuration

3. **Apply Configuration:**
   - SSH into your Wings server
   - Create config file:
     ```bash
     nano /etc/pterodactyl/config.yml
     ```
   - Paste the configuration
   - Save and exit (Ctrl+X, Y, Enter)

4. **Start Wings:**
   ```bash
   systemctl enable --now wings
   systemctl status wings
   ```

## GPU Support Setup

If you enabled GPU support during installation:

### Verify NVIDIA Drivers

```bash
nvidia-smi
```

### Test GPU in Docker

```bash
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
```

### Configure in Panel

When creating a server that needs GPU:
1. Go to Admin → Nests → Minecraft (or your game)
2. Edit the Egg
3. Add environment variable: `NVIDIA_VISIBLE_DEVICES=all`

## Cloudflare Setup

If you're using Cloudflare:

### Get API Token

1. Log in to Cloudflare
2. Go to My Profile → API Tokens
3. Click "Create Token"
4. Use "Edit zone DNS" template
5. Select your domain
6. Create token and copy it

### Get Zone ID

1. Go to your domain overview in Cloudflare
2. Scroll down to "API" section
3. Copy the Zone ID

### SSL/TLS Settings

For Pterodactyl to work with Cloudflare:

1. Go to SSL/TLS → Overview
2. Set encryption mode to "Full (strict)"
3. Go to SSL/TLS → Edge Certificates
4. Enable "Always Use HTTPS"
5. Enable "Automatic HTTPS Rewrites"

### Proxy Settings

**Panel:** Can be proxied (orange cloud)
**Wings:** Must NOT be proxied (gray cloud) - Wings needs direct connection

## Troubleshooting Installation

### DNS Not Resolving

**Problem:** Script says DNS doesn't point to correct IP

**Solution:**
```bash
# Check current DNS
dig +short panel.example.com

# If wrong, update DNS and wait for propagation (up to 24 hours)
# You can continue anyway, but SSL won't work until DNS is correct
```

### SSL Certificate Failed

**Problem:** Certbot fails to issue certificate

**Solution:**
```bash
# Ensure DNS is correct
dig +short panel.example.com

# Ensure port 80 is open
sudo ufw status

# Try manual certificate
sudo certbot certonly --nginx -d panel.example.com
```

### Database Connection Failed

**Problem:** Panel can't connect to database

**Solution:**
```bash
# Check MariaDB is running
systemctl status mariadb

# Test connection
mysql -u pterodactyl -p panel

# Reset database password if needed
mysql -u root
ALTER USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY 'new_password';
FLUSH PRIVILEGES;

# Update .env file
nano /var/www/pterodactyl/.env
# Update DB_PASSWORD
php artisan config:clear
```

### Wings Not Connecting

**Problem:** Wings shows as offline in Panel

**Solution:**
```bash
# Check Wings status
systemctl status wings

# Check logs
journalctl -u wings -n 100 --no-pager

# Verify config
cat /etc/pterodactyl/config.yml

# Restart Wings
systemctl restart wings
```

### Permission Errors

**Problem:** Panel shows 500 errors or permission denied

**Solution:**
```bash
cd /var/www/pterodactyl
chown -R www-data:www-data /var/www/pterodactyl/*
chmod -R 755 storage/* bootstrap/cache/
php artisan config:clear
php artisan cache:clear
```

## Updating Pterodactyl

### Automatic Update

```bash
sudo ./pteroanyinstall.sh update
```

This updates:
- System packages
- Pterodactyl Panel
- Pterodactyl Wings
- Runs health checks

### Manual Panel Update

```bash
cd /var/www/pterodactyl
php artisan down

curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv
chmod -R 755 storage/* bootstrap/cache

composer install --no-dev --optimize-autoloader

php artisan view:clear
php artisan config:clear
php artisan migrate --seed --force

chown -R www-data:www-data /var/www/pterodactyl/*

php artisan queue:restart
php artisan up
```

### Manual Wings Update

```bash
systemctl stop wings

curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"
chmod u+x /usr/local/bin/wings

systemctl start wings
```

## Security Hardening

### 1. Change Default Passwords

Immediately after installation:
- Change admin password in Panel
- Change database password
- Change any default credentials

### 2. Enable Two-Factor Authentication

1. Log in to Panel
2. Go to Account Settings
3. Enable 2FA
4. Scan QR code with authenticator app

### 3. Configure SSH Key Authentication

```bash
# On your local machine
ssh-keygen -t ed25519

# Copy to server
ssh-copy-id root@your-server-ip

# On server, disable password auth
nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
systemctl restart sshd
```

### 4. Install Fail2Ban

```bash
# Ubuntu/Debian
apt install fail2ban

# CentOS/RHEL/Rocky/Alma
yum install fail2ban

systemctl enable --now fail2ban
```

### 5. Regular Updates

```bash
# Set up automatic security updates
# Ubuntu/Debian
apt install unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades
```

## Backup Strategy

### Panel Backup Script

Create `/root/backup-panel.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/root/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup database
mysqldump -u pterodactyl -p'YOUR_DB_PASSWORD' panel > $BACKUP_DIR/panel_db_$DATE.sql

# Backup files
tar -czf $BACKUP_DIR/panel_files_$DATE.tar.gz /var/www/pterodactyl

# Keep only last 7 days
find $BACKUP_DIR -name "panel_*" -mtime +7 -delete

echo "Backup completed: $DATE"
```

Make executable and run:
```bash
chmod +x /root/backup-panel.sh
./root/backup-panel.sh
```

### Automated Backups with Cron

```bash
crontab -e

# Add this line for daily backups at 2 AM
0 2 * * * /root/backup-panel.sh
```

## Next Steps

After successful installation:

1. **Create Your First Server:**
   - Go to Servers → Create New
   - Select location and node
   - Choose egg (Minecraft, etc.)
   - Allocate resources
   - Create server

2. **Configure Eggs:**
   - Go to Admin → Nests
   - Review and customize eggs
   - Add custom eggs if needed

3. **Set Up Backups:**
   - Configure backup storage (S3, local, etc.)
   - Set backup schedules

4. **Monitor Resources:**
   - Check node resource usage
   - Monitor server performance
   - Set up alerts

5. **Join Community:**
   - [Pterodactyl Discord](https://discord.gg/pterodactyl)
   - [Documentation](https://pterodactyl.io/project/introduction.html)
   - [Community Forums](https://community.pterodactyl.io/)

## Getting Help

If you encounter issues:

1. **Check Logs:**
   ```bash
   # Panel logs
   tail -f /var/www/pterodactyl/storage/logs/laravel-$(date +%Y-%m-%d).log
   
   # Wings logs
   journalctl -u wings -f
   
   # Nginx logs
   tail -f /var/log/nginx/error.log
   ```

2. **Run Health Check:**
   ```bash
   sudo ./pteroanyinstall.sh health-check
   ```

3. **Run Scan and Fix:**
   ```bash
   sudo ./pteroanyinstall.sh scan
   ```

4. **Community Support:**
   - Discord: https://discord.gg/pterodactyl
   - Documentation: https://pterodactyl.io
   - GitHub Issues: https://github.com/pterodactyl/panel/issues

## Additional Resources

- [Official Documentation](https://pterodactyl.io/project/introduction.html)
- [Community Guides](https://pterodactyl.io/community/about.html)
- [API Documentation](https://dashflo.net/docs/api/pterodactyl/v1/)
- [Egg Repository](https://github.com/parkervcp/eggs)
