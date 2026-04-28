# File Sharing Panel Setup

Complete automated installation for a secure file sharing/storage panel with Cloudflare tunnel access.

## 🚀 What This Does

Installs and configures:

- **Filebrowser** - Modern, beautiful web-based file manager
- **Cloudflared** - Secure HTTPS tunnel (no port forwarding needed)
- **Systemd Services** - Auto-start on boot
- **User Management** - Multi-user support with permissions

## ✨ Features

✅ **Web-Based Interface** - Access files from any browser  
✅ **Secure HTTPS** - Automatic SSL via Cloudflare  
✅ **File Upload/Download** - Drag & drop support  
✅ **File Sharing** - Generate shareable links  
✅ **File Preview** - Images, videos, PDFs, code  
✅ **Search** - Find files quickly  
✅ **Mobile Responsive** - Works on phones/tablets  
✅ **User Management** - Multiple users with permissions  
✅ **No Port Forwarding** - Works behind NAT/firewall  

## 📋 Prerequisites

- Debian 12 (or Ubuntu 20.04+)
- Root/sudo access
- Cloudflare account (free)
- Domain managed by Cloudflare
- Minimum 1GB RAM
- Minimum 10GB disk space (more for file storage)

## 🎯 Quick Start

### 1. Download the Script

```bash
wget https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/file-share-setup.sh
```

Or create manually:

```bash
nano file-share-setup.sh
# Paste the script content
chmod +x file-share-setup.sh
```

### 2. Run the Script

```bash
sudo ./file-share-setup.sh
```

### 3. Follow the Prompts

The script will ask for:
- Domain name (default: cloudmc.online)
- Subdomain (default: share)
- Storage path (default: /var/filebrowser)
- Admin username (default: admin)
- Admin password

### 4. Authenticate with Cloudflare

A browser will open for Cloudflare authentication:
1. Log in to your Cloudflare account
2. Select your domain
3. Authorize the tunnel

### 5. Done!

Access your file share at: **https://share.cloudmc.online**

## 🎨 What You'll Get

After installation:

```
Access Points:
  🌐 External URL:  https://share.cloudmc.online
  🏠 Local URL:     http://your-mini-pc-ip:8080

Storage:
  📁 Files stored in: /var/filebrowser

Services:
  ✅ Filebrowser (systemd)
  ✅ Cloudflared tunnel (systemd)
```

## 📁 Using Filebrowser

### Upload Files

1. Click **Upload** button
2. Drag & drop files or click to browse
3. Files are uploaded to your storage directory

### Create Folders

1. Click **New** → **Folder**
2. Enter folder name
3. Click **Create**

### Share Files

1. Select a file
2. Click **Share** button
3. Copy the generated link
4. Share with anyone!

### Download Files

1. Select file(s)
2. Click **Download** button
3. Files download to your device

### File Preview

- **Images**: Click to view full-size
- **Videos**: Built-in player
- **PDFs**: In-browser viewer
- **Code**: Syntax highlighting
- **Text**: Direct editing

## 👥 User Management

### Add Users

1. Log in as admin
2. Go to **Settings** → **User Management**
3. Click **New User**
4. Set username, password, and permissions
5. Click **Save**

### User Permissions

- **Admin**: Full access, can manage users
- **User**: Upload, download, create folders
- **View Only**: Can only view and download

### Scope Permissions

Set which folders each user can access:
1. Edit user
2. Set **Scope** to specific folder path
3. User only sees that folder

## 🔧 Management Commands

### Check Status

```bash
# Check Filebrowser
sudo systemctl status filebrowser

# Check Cloudflared tunnel
sudo systemctl status cloudflared
```

### Restart Services

```bash
# Restart Filebrowser
sudo systemctl restart filebrowser

# Restart Cloudflared
sudo systemctl restart cloudflared
```

### View Logs

```bash
# Filebrowser logs
sudo journalctl -u filebrowser -f

# Cloudflared logs
sudo journalctl -u cloudflared -f
```

### Stop Services

```bash
# Stop Filebrowser
sudo systemctl stop filebrowser

# Stop Cloudflared
sudo systemctl stop cloudflared
```

## ⚙️ Configuration

### Change Storage Location

1. Edit Filebrowser config:
```bash
sudo nano /etc/filebrowser/filebrowser.json
```

2. Update `root` path:
```json
{
  "root": "/new/storage/path"
}
```

3. Restart:
```bash
sudo systemctl restart filebrowser
```

### Change Port

1. Edit config:
```bash
sudo nano /etc/filebrowser/filebrowser.json
```

2. Update `port`:
```json
{
  "port": 9090
}
```

3. Update Cloudflared config:
```bash
sudo nano ~/.cloudflared/config.yml
```

4. Update service URL:
```yaml
service: http://127.0.0.1:9090
```

5. Restart both services:
```bash
sudo systemctl restart filebrowser
sudo systemctl restart cloudflared
```

### Reset Admin Password

```bash
# Using Filebrowser CLI
filebrowser users update admin --password="newpassword" --database=/etc/filebrowser/filebrowser.db
```

## 🔒 Security Best Practices

1. **Use Strong Passwords** - Minimum 12 characters
2. **Enable 2FA** - In Cloudflare dashboard
3. **Regular Backups** - Backup your files regularly
4. **User Permissions** - Give users minimum required access
5. **Monitor Access** - Check logs regularly
6. **Update Regularly** - Keep Filebrowser updated

## 💾 Backup

### Backup Files

```bash
# Backup storage directory
sudo tar -czf filebrowser-backup-$(date +%Y%m%d).tar.gz /var/filebrowser

# Copy to safe location
sudo cp filebrowser-backup-*.tar.gz /path/to/backup/
```

### Backup Configuration

```bash
# Backup config and database
sudo tar -czf filebrowser-config-$(date +%Y%m%d).tar.gz /etc/filebrowser ~/.cloudflared
```

### Restore from Backup

```bash
# Restore files
sudo tar -xzf filebrowser-backup-YYYYMMDD.tar.gz -C /

# Restore config
sudo tar -xzf filebrowser-config-YYYYMMDD.tar.gz -C /

# Restart services
sudo systemctl restart filebrowser cloudflared
```

## 🔄 Updates

### Update Filebrowser

```bash
# Download latest version
curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | sudo bash

# Restart service
sudo systemctl restart filebrowser
```

### Update Cloudflared

```bash
# Update package
sudo apt-get update
sudo apt-get install --only-upgrade cloudflared

# Restart service
sudo systemctl restart cloudflared
```

## 🐛 Troubleshooting

### Can't Access Website

**Check DNS propagation:**
```bash
nslookup share.cloudmc.online
```

**Check Cloudflared:**
```bash
sudo systemctl status cloudflared
sudo journalctl -u cloudflared -n 50
```

**Verify in Cloudflare Dashboard:**
- Go to Zero Trust → Networks → Tunnels
- Check tunnel status

### Filebrowser Not Starting

**Check logs:**
```bash
sudo journalctl -u filebrowser -n 50
```

**Check port availability:**
```bash
sudo netstat -tulpn | grep 8080
```

**Verify permissions:**
```bash
sudo ls -la /var/filebrowser
sudo ls -la /etc/filebrowser
```

### Upload Fails

**Check disk space:**
```bash
df -h
```

**Check permissions:**
```bash
sudo chmod 755 /var/filebrowser
```

**Check Filebrowser logs:**
```bash
sudo journalctl -u filebrowser -f
```

### Slow Performance

**Check system resources:**
```bash
htop
```

**Check disk I/O:**
```bash
iostat -x 1
```

**Optimize storage:**
```bash
# Move to faster disk if available
sudo systemctl stop filebrowser
sudo mv /var/filebrowser /path/to/faster/disk/
sudo ln -s /path/to/faster/disk/filebrowser /var/filebrowser
sudo systemctl start filebrowser
```

## 📊 System Requirements

### Minimum:
- 1 CPU core
- 1GB RAM
- 10GB disk space
- Debian 12 or Ubuntu 20.04+

### Recommended:
- 2+ CPU cores
- 2GB+ RAM
- 100GB+ disk space (for file storage)
- SSD for better performance

## 🌟 Advanced Features

### Custom Branding

Edit Filebrowser config to add custom branding:

```bash
sudo nano /etc/filebrowser/filebrowser.json
```

Add:
```json
{
  "branding": {
    "name": "My File Share",
    "disableExternal": true
  }
}
```

### Command Execution

Enable command execution (use with caution):

```bash
filebrowser config set --commands "ls,cat,grep" --database=/etc/filebrowser/filebrowser.db
```

### Custom Rules

Create rules for file handling in the web interface.

## 📚 Additional Resources

- [Filebrowser Documentation](https://filebrowser.org/configuration)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Debian Documentation](https://www.debian.org/doc/)

## 🆘 Support

If you encounter issues:

1. Check the setup log: `/tmp/file-share-setup-*.log`
2. Review service status: `sudo systemctl status filebrowser cloudflared`
3. Check logs: `sudo journalctl -u filebrowser -u cloudflared`
4. Verify Cloudflare tunnel in dashboard

## 📝 Configuration Files

- **Filebrowser config:** `/etc/filebrowser/filebrowser.json`
- **Filebrowser database:** `/etc/filebrowser/filebrowser.db`
- **Cloudflared config:** `~/.cloudflared/config.yml`
- **Systemd service:** `/etc/systemd/system/filebrowser.service`

## 🎉 What's Next?

After setup:

1. **Upload files** - Start adding your files
2. **Create users** - Add family/team members
3. **Set permissions** - Control who sees what
4. **Share files** - Generate links for sharing
5. **Mobile access** - Install as PWA on phone
6. **Backup regularly** - Protect your data

Enjoy your personal cloud storage! ☁️
