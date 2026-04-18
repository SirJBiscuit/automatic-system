# 🌐 Pterodactyl Web Console

**Modern web-based dashboard for managing Pterodactyl game servers from any device!**

## ✨ Features

### 📊 Dashboard
- Real-time server statistics
- Server status overview (online/offline)
- CPU and RAM usage monitoring
- Beautiful, responsive UI

### 🎮 Server Management
- Start/Stop/Restart servers
- Force kill unresponsive servers
- Send console commands
- Real-time console output
- Server resource monitoring

### 📱 Mobile Friendly
- Responsive design
- Works on phones, tablets, laptops
- Touch-optimized controls
- Access from anywhere

### 🔒 Secure
- Password-protected login
- Session management
- Nginx reverse proxy support
- HTTPS ready

## 🚀 Quick Install

```bash
# Download and run installer
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/web-console/install.sh -o install-web-console.sh
chmod +x install-web-console.sh
sudo ./install-web-console.sh
```

## 📋 Requirements

- Ubuntu/Debian Linux
- Python 3.8+
- Nginx
- Pterodactyl Panel with API access

## ⚙️ Configuration

Edit `/opt/pterodactyl-web-console/.env`:

```env
# Pterodactyl Configuration
PTERODACTYL_URL=https://panel.yourdomain.com
PTERODACTYL_API_KEY=your_api_key_here

# Web Console Login
WEB_USERNAME=admin
WEB_PASSWORD=your_secure_password

# Secret Key (auto-generated)
SECRET_KEY=...

# Port
PORT=5000
```

## 🌐 Access

After installation, access at:
```
http://YOUR_SERVER_IP:8080
```

**Default Login:**
- Username: `admin`
- Password: `changeme123`

⚠️ **Change the password immediately!**

## 🎯 Features Overview

### Dashboard View
- **Total Servers** - Count of all game servers
- **Online Servers** - Currently running servers
- **Offline Servers** - Stopped servers
- **Total CPU Usage** - Combined CPU usage

### Server Cards
Click any server to open the management console:
- **Power Controls** - Start, Stop, Restart, Kill
- **Resource Stats** - CPU, RAM, Disk usage
- **Console** - Send commands and view output
- **Real-time Updates** - Auto-refresh every 10 seconds

## 🔧 Management Commands

```bash
# View logs
journalctl -u pterodactyl-web-console -f

# Restart service
systemctl restart pterodactyl-web-console

# Stop service
systemctl stop pterodactyl-web-console

# Edit configuration
nano /opt/pterodactyl-web-console/.env
systemctl restart pterodactyl-web-console
```

## 🔐 Security Best Practices

### 1. Change Default Password
```bash
nano /opt/pterodactyl-web-console/.env
# Change WEB_PASSWORD
systemctl restart pterodactyl-web-console
```

### 2. Enable HTTPS (Recommended)
```bash
# Install Certbot
apt-get install certbot python3-certbot-nginx

# Get SSL certificate
certbot --nginx -d console.yourdomain.com

# Nginx will auto-configure HTTPS
```

### 3. Firewall Rules
```bash
# Allow only specific IPs (optional)
ufw allow from YOUR_IP to any port 8080
ufw deny 8080
```

### 4. Use Strong Passwords
- Minimum 12 characters
- Mix of letters, numbers, symbols
- Don't reuse passwords

## 📱 Mobile Access

The web console is fully responsive:
- **Phone** - Optimized touch controls
- **Tablet** - Split-screen friendly
- **Desktop** - Full feature set

Access from anywhere with internet connection!

## 🎨 Screenshots

### Dashboard
- Clean, modern interface
- Dark theme (easy on eyes)
- Real-time stats
- Server list with status indicators

### Server Console
- Power controls (Start/Stop/Restart/Kill)
- Resource monitoring (CPU/RAM/Status)
- Console input/output
- Command history

## 🔄 Updates

```bash
cd /opt/pterodactyl-web-console
git pull  # If using git
# Or re-run installer
systemctl restart pterodactyl-web-console
```

## 🆚 Web Console vs Discord Bot

### Web Console
- ✅ Visual dashboard
- ✅ Mobile-friendly
- ✅ Real-time console
- ✅ Resource graphs
- ❌ Requires browser

### Discord Bot
- ✅ Quick commands
- ✅ Voice control
- ✅ Notifications
- ✅ AI assistance
- ❌ Text-based only

**Best Solution:** Use both!
- Web console for detailed management
- Discord bot for quick actions and alerts

## 🛠️ Troubleshooting

### Web console won't start
```bash
# Check logs
journalctl -u pterodactyl-web-console -f

# Verify .env file
cat /opt/pterodactyl-web-console/.env

# Check if port is in use
netstat -tulpn | grep 5000
```

### Can't login
```bash
# Verify credentials in .env
nano /opt/pterodactyl-web-console/.env

# Restart service
systemctl restart pterodactyl-web-console
```

### Servers not showing
- Verify Pterodactyl API key has correct permissions
- Check PTERODACTYL_URL is correct
- Ensure Pterodactyl panel is accessible

### Nginx errors
```bash
# Test Nginx config
nginx -t

# Reload Nginx
systemctl reload nginx

# Check Nginx logs
tail -f /var/log/nginx/error.log
```

## 🌟 Advanced Features

### Custom Port
Edit `.env`:
```env
PORT=3000
```

Update Nginx config:
```bash
nano /etc/nginx/sites-available/pterodactyl-web-console
# Change proxy_pass port
systemctl reload nginx
```

### Multiple Users
Currently supports single user. For multi-user:
- Use Pterodactyl panel's built-in user system
- Or implement custom auth in `app.py`

### API Integration
The web console uses Pterodactyl's Client API:
- `/api/client` - List servers
- `/api/client/servers/{id}/resources` - Server stats
- `/api/client/servers/{id}/power` - Power actions
- `/api/client/servers/{id}/command` - Console commands

## 📊 Performance

- **Lightweight** - ~50MB RAM usage
- **Fast** - Sub-second response times
- **Scalable** - Handles 100+ servers
- **Efficient** - WebSocket for real-time updates

## 🔗 Integration

### With Discord Bot
Both can run simultaneously:
- Web console on port 8080
- Discord bot as systemd service
- Share same Pterodactyl API

### With Monitoring
Add to existing monitoring:
- Prometheus metrics (future)
- Grafana dashboards (future)
- Alert integration (future)

## 📄 License

MIT License

---

**Made with ❤️ for Pterodactyl server management**
**Access your servers from anywhere, anytime!** 🌐📱💻
