# Unified Server Admin Panel

Complete control center for managing your entire server from one beautiful interface.

## Features

### 🔐 Security
- Secure login with username/password
- Password hashing (SHA256)
- Session management
- Change username and password from settings

### 📊 System Monitoring
- Real-time server uptime
- CPU load average
- Memory usage
- Disk usage
- Auto-refresh every 30 seconds

### ⚙️ Service Management
- View status of all services
- Restart individual services
- Restart all services at once
- Supports:
  - Filebrowser
  - Cloudflared
  - Wings (Pterodactyl)
  - Docker
  - Pingvin Share
  - Nextcloud

### 👤 User Management
- Add/delete Filebrowser users
- Set admin permissions
- Password management

### 🚀 Quick Actions
- Restart all services
- Fix corrupted database
- Health check
- View service logs

### 🔗 Quick Shortcuts
- Direct links to:
  - Pingvin Share
  - Nextcloud
  - Filebrowser
  - Pterodactyl Panel

### 💾 Storage Management
- View disk information
- Configure storage paths for services
- Monitor disk usage

### 🖥️ System Control
- Safe server reboot
- Safe server shutdown
- Graceful service stopping

### 📋 Logs
- View logs for any service
- Real-time log viewing
- Configurable line count

## Installation

```bash
cd /tmp
git clone https://github.com/SirJBiscuit/automatic-system.git
cd automatic-system/unified-admin

chmod +x install.sh
sudo ./install.sh
```

## Configure Cloudflare Tunnel

Edit `/root/.cloudflared/config.yml`:

```yaml
ingress:
  - hostname: admin.cloudmc.online
    service: http://localhost:5002
  # ... other services ...
  - service: http_status:404
```

Restart cloudflared:
```bash
sudo systemctl restart cloudflared
```

## Access

Visit: **https://admin.cloudmc.online**

### Default Login
- **Username:** `admin`
- **Password:** `ChangeMe123!`

⚠️ **IMPORTANT:** Change these credentials immediately after first login!

## Usage

### First Login
1. Visit https://admin.cloudmc.online
2. Login with default credentials
3. Click "Settings" in top right
4. Change your password
5. Optionally change your username

### Managing Services
1. View service status in "Services" card
2. Click "Restart" to restart individual service
3. Use "Restart All Services" for quick restart

### Managing Users
1. Go to "Filebrowser Users" tab
2. Click "Add User" to create new user
3. Set username, password, and admin status
4. Click "Delete" to remove users

### Viewing Logs
1. Click "View Logs" in Quick Actions
2. Select service from dropdown
3. Click "Load Logs"

### Storage Configuration
1. Go to "Storage" tab
2. Click "Configure Storage Paths"
3. Enter path to your 8TB drive (e.g., `/mnt/storage`)
4. Click "Apply"
5. Restart services for changes to take effect

### System Control
1. Go to "System" tab
2. Use "Reboot Server" or "Shutdown Server"
3. Confirm action
4. Services will stop gracefully before reboot/shutdown

## Quick Actions Explained

### Restart All Services
Restarts:
- Filebrowser
- Cloudflared
- Pingvin Share (Docker)
- Nextcloud (Docker)

### Fix Database
- Stops Filebrowser
- Backs up corrupted database
- Creates fresh database
- Restarts Filebrowser
- You'll need to recreate users

### Health Check
Shows quick overview of:
- All service statuses
- Disk space
- Memory usage

## Security Best Practices

1. **Change default credentials immediately**
2. **Use strong passwords** (12+ characters)
3. **Don't share admin credentials**
4. **Access only via HTTPS** (Cloudflare tunnel)
5. **Regularly check logs** for suspicious activity

## Management Commands

```bash
# View status
sudo systemctl status unified-admin

# Restart panel
sudo systemctl restart unified-admin

# View logs
sudo journalctl -u unified-admin -f

# Stop panel
sudo systemctl stop unified-admin

# Start panel
sudo systemctl start unified-admin
```

## Troubleshooting

### Can't login
- Check service is running: `sudo systemctl status unified-admin`
- Check logs: `sudo journalctl -u unified-admin -n 50`
- Reset credentials: Delete `/etc/admin-panel/credentials.json` and restart service

### Services not showing
- Ensure you're logged in
- Check browser console for errors
- Verify services are installed

### Can't restart services
- Check you have root permissions
- Verify service names are correct
- Check individual service status

## API Endpoints

All endpoints require authentication (except `/login`).

### Authentication
- `POST /login` - Login
- `POST /logout` - Logout

### System
- `GET /api/system/status` - Get system stats
- `POST /api/system/reboot` - Reboot server
- `POST /api/system/shutdown` - Shutdown server

### Services
- `GET /api/services/status` - Get all service statuses
- `POST /api/services/restart/<service>` - Restart service

### Filebrowser
- `GET /api/filebrowser/users` - List users
- `POST /api/filebrowser/users/add` - Add user
- `DELETE /api/filebrowser/users/delete/<username>` - Delete user

### Quick Actions
- `POST /api/quick/restart-all` - Restart all services
- `POST /api/quick/fix-database` - Fix database
- `GET /api/quick/check-health` - Health check

### Logs
- `GET /api/logs/<service>?lines=50` - Get service logs

### Admin
- `POST /api/admin/change-password` - Change admin password
- `POST /api/admin/change-username` - Change admin username

## Tech Stack

- **Backend:** Python 3 + Flask
- **Frontend:** Vanilla JavaScript + CSS
- **Authentication:** Session-based with password hashing
- **Deployment:** Systemd service
- **Port:** 5002

## License

MIT
