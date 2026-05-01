# Pingvin Share Setup

Modern, beautiful file sharing platform - no database corruption issues!

## Features

- 🎨 Beautiful modern UI
- 🔗 Share links with expiration dates
- 🔒 Password protection for shares
- 📤 Easy file upload/download
- 👥 User management
- 🚫 Disable public registration
- ⚡ Fast and lightweight
- 🐳 Docker-based (easy updates)

## Installation

```bash
cd /tmp
git clone https://github.com/SirJBiscuit/automatic-system.git
cd automatic-system/pingvin-share-setup

chmod +x install.sh
sudo ./install.sh
```

## Configure Cloudflare Tunnel

Edit `/root/.cloudflared/config.yml`:

```yaml
ingress:
  - hostname: share.cloudmc.online
    service: http://localhost:3000
```

Then restart:
```bash
sudo systemctl restart cloudflared
```

## Access

Visit: **https://share.cloudmc.online**

On first visit, create your admin account.

## Management

```bash
cd /opt/pingvin-share

# View logs
docker-compose logs -f

# Restart
docker-compose restart

# Stop
docker-compose stop

# Start
docker-compose start

# Update to latest version
docker-compose pull
docker-compose up -d
```

## Uninstall

```bash
cd /tmp/automatic-system/pingvin-share-setup
chmod +x uninstall.sh
sudo ./uninstall.sh
```

## Why Pingvin Share?

- ✅ No SQLite corruption issues
- ✅ Modern React-based UI
- ✅ Active development
- ✅ Docker makes it easy to manage
- ✅ Built-in user management
- ✅ Share expiration and passwords
- ✅ Clean, simple interface

## Comparison to Filebrowser

| Feature | Pingvin Share | Filebrowser |
|---------|--------------|-------------|
| Database | SQLite (works!) | SQLite (corrupts) |
| UI | Modern React | Basic |
| Share Links | ✅ Built-in | Limited |
| User Management | ✅ Easy | Complex |
| Updates | Docker pull | Manual binary |
| Stability | ✅ Excellent | ❌ Database issues |
