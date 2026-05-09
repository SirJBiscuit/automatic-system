# Pterodactyl Automatic System - Installation Steps

## 📋 Table of Contents
- [Quick Start](#quick-start)
- [Installation Categories](#installation-categories)
- [Detailed Steps](#detailed-steps)
- [Post-Installation](#post-installation)

## 🚀 Quick Start

```bash
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/install-interactive.sh | sudo bash
```

## 📦 Installation Categories

### 1. 🎮 Full Stack (Panel + Wings)
**What it includes:**
- Pterodactyl Panel (Web Interface)
- Pterodactyl Wings (Server Daemon)
- MySQL Database
- Redis Cache
- Nginx Web Server
- SSL Certificates

**Installation Steps:**
1. ✓ System preparation and dependency check
2. ✓ Install PHP 8.1 and extensions
3. ✓ Install and configure MySQL/MariaDB
4. ✓ Install Redis
5. ✓ Download and setup Pterodactyl Panel
6. ✓ Configure database and environment
7. ✓ Install Nginx and configure virtual host
8. ✓ Obtain SSL certificate via Let's Encrypt
9. ✓ Create admin user
10. ✓ Setup cron jobs and queue workers
11. ✓ Install Docker
12. ✓ Download and configure Wings
13. ✓ Connect Wings to Panel
14. ✓ Start Wings daemon

**Time:** ~15-20 minutes  
**Requirements:** 4GB RAM, 20GB disk, Ubuntu 20.04+

---

### 2. 🖥️ Panel Only
**What it includes:**
- Pterodactyl Panel
- MySQL Database
- Redis Cache
- Nginx Web Server
- SSL Certificates

**Installation Steps:**
1. ✓ System preparation
2. ✓ Install dependencies (PHP, MySQL, Redis)
3. ✓ Download Pterodactyl Panel
4. ✓ Configure database
5. ✓ Setup web server
6. ✓ Install SSL certificate
7. ✓ Create admin user
8. ✓ Configure cron jobs

**Time:** ~10-15 minutes  
**Requirements:** 2GB RAM, 10GB disk

---

### 3. 🚀 Wings Only
**What it includes:**
- Pterodactyl Wings
- Docker
- Docker Compose

**Installation Steps:**
1. ✓ Install Docker
2. ✓ Configure Docker daemon
3. ✓ Download Wings binary
4. ✓ Create Wings configuration
5. ✓ Setup systemd service
6. ✓ Start Wings daemon
7. ✓ Connect to Panel

**Time:** ~5-10 minutes  
**Requirements:** 2GB RAM, 10GB disk

---

### 4. 🤖 AI Assistant Stack
**What it includes:**
- Ollama AI Server
- Open WebUI
- AI Models (Llama 3, Mistral, etc.)

**Installation Steps:**
1. ✓ Install Ollama
2. ✓ Pull AI models
3. ✓ Configure Ollama service
4. ✓ Install Open WebUI
5. ✓ Setup reverse proxy
6. ✓ Configure SSL
7. ✓ Create admin user

**Time:** ~10 minutes + model download time  
**Requirements:** 8GB RAM (16GB recommended), 20GB+ disk per model

---

### 5. 📁 File Management Stack
**What it includes:**
- FileBrowser (File manager)
- Pingvin Share (File sharing)
- Social FileBrowser (Enhanced version)

**Installation Steps:**
1. ✓ Install FileBrowser
2. ✓ Configure user database
3. ✓ Setup branding
4. ✓ Install Pingvin Share
5. ✓ Configure storage
6. ✓ Setup reverse proxy
7. ✓ Install SSL certificates

**Time:** ~8 minutes  
**Requirements:** 1GB RAM, 5GB disk

---

### 6. ☁️ Cloud Storage (Nextcloud)
**What it includes:**
- Nextcloud
- PostgreSQL Database
- Redis Cache
- PHP-FPM

**Installation Steps:**
1. ✓ Install dependencies
2. ✓ Setup PostgreSQL
3. ✓ Download Nextcloud
4. ✓ Configure Nextcloud
5. ✓ Setup web server
6. ✓ Install SSL certificate
7. ✓ Configure cron jobs
8. ✓ Enable recommended apps

**Time:** ~12 minutes  
**Requirements:** 2GB RAM, 20GB disk

---

### 7. 🔧 Admin Panel + SSH Terminal
**What it includes:**
- Unified Admin Panel
- Web SSH Terminal
- AI Command Assistant

**Installation Steps:**
1. ✓ Install Python dependencies
2. ✓ Setup admin panel
3. ✓ Configure authentication
4. ✓ Install SSH terminal
5. ✓ Setup WebSocket server
6. ✓ Configure reverse proxy
7. ✓ Install SSL certificates

**Time:** ~5 minutes  
**Requirements:** 1GB RAM, 2GB disk

---

### 8. 📊 Custom Selection
**What it includes:**
- Choose any combination of components

**Available Components:**
- ✓ Pterodactyl Panel
- ✓ Pterodactyl Wings
- ✓ Ollama AI Server
- ✓ Open WebUI
- ✓ FileBrowser
- ✓ Pingvin Share
- ✓ Nextcloud
- ✓ Admin Panel
- ✓ SSH Terminal
- ✓ Discord Bot
- ✓ Billing System
- ✓ Cloud Backup

---

## 🔧 Detailed Installation Process

### Pre-Installation Checks
```
[1/5] Checking system requirements...
  ✓ OS: Ubuntu 20.04+ or Debian 11+
  ✓ RAM: Sufficient for selected components
  ✓ Disk: Sufficient space available
  ✓ Network: Internet connection active
  ✓ Permissions: Running as root

[2/5] Updating system packages...
  ✓ apt update
  ✓ apt upgrade

[3/5] Installing base dependencies...
  ✓ curl
  ✓ wget
  ✓ git
  ✓ software-properties-common

[4/5] Configuring firewall...
  ✓ UFW installed
  ✓ Required ports opened

[5/5] Pre-installation complete!
```

### Panel Installation (Detailed)
```
[1/10] Installing PHP 8.1...
  ✓ Adding PHP repository
  ✓ Installing PHP and extensions
  ✓ Configuring PHP-FPM

[2/10] Installing MySQL...
  ✓ Installing MariaDB
  ✓ Securing installation
  ✓ Creating panel database
  ✓ Creating database user

[3/10] Installing Redis...
  ✓ Installing Redis server
  ✓ Configuring Redis
  ✓ Starting Redis service

[4/10] Downloading Panel...
  ✓ Creating directory
  ✓ Downloading latest release
  ✓ Extracting files
  ✓ Setting permissions

[5/10] Installing Composer dependencies...
  ✓ Installing Composer
  ✓ Running composer install
  ✓ Optimizing autoloader

[6/10] Configuring Panel...
  ✓ Copying environment file
  ✓ Generating app key
  ✓ Running migrations
  ✓ Seeding database

[7/10] Installing Nginx...
  ✓ Installing Nginx
  ✓ Creating virtual host
  ✓ Enabling site
  ✓ Testing configuration

[8/10] Installing SSL...
  ✓ Installing Certbot
  ✓ Obtaining certificate
  ✓ Configuring auto-renewal

[9/10] Creating admin user...
  ✓ Email: admin@example.com
  ✓ Username: admin
  ✓ Password: [generated]

[10/10] Finalizing installation...
  ✓ Setting up cron jobs
  ✓ Starting queue workers
  ✓ Restarting services
```

### Wings Installation (Detailed)
```
[1/6] Installing Docker...
  ✓ Adding Docker repository
  ✓ Installing Docker CE
  ✓ Starting Docker service
  ✓ Enabling Docker on boot

[2/6] Configuring Docker...
  ✓ Creating daemon.json
  ✓ Setting up logging
  ✓ Configuring storage driver
  ✓ Restarting Docker

[3/6] Downloading Wings...
  ✓ Creating directory
  ✓ Downloading latest release
  ✓ Setting permissions
  ✓ Making executable

[4/6] Configuring Wings...
  ✓ Creating config directory
  ✓ Generating configuration
  ✓ Setting up SSL certificates

[5/6] Installing systemd service...
  ✓ Creating service file
  ✓ Enabling service
  ✓ Starting Wings

[6/6] Connecting to Panel...
  ✓ Registering node
  ✓ Verifying connection
  ✓ Wings ready!
```

---

## 📊 Installation Progress Indicators

### Real-time Progress Display
```
╔══════════════════════════════════════════════════════════╗
║  Installing Pterodactyl Panel                            ║
╠══════════════════════════════════════════════════════════╣
║                                                          ║
║  [████████████████████░░░░░░░░░░] 65%                   ║
║                                                          ║
║  Current Step: Installing Nginx                          ║
║  Time Elapsed: 8m 32s                                    ║
║  Estimated Remaining: 4m 15s                             ║
║                                                          ║
║  Completed Steps:                                        ║
║  ✓ System preparation                                    ║
║  ✓ PHP installation                                      ║
║  ✓ MySQL setup                                           ║
║  ✓ Redis installation                                    ║
║  ✓ Panel download                                        ║
║  ✓ Composer dependencies                                 ║
║  ⟳ Nginx installation (in progress)                      ║
║  ○ SSL certificate                                       ║
║  ○ Admin user creation                                   ║
║  ○ Finalization                                          ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
```

---

## ✅ Post-Installation

### Access Your Services
```
✓ Panel: https://panel.yourdomain.com
✓ Admin Panel: https://admin.yourdomain.com
✓ SSH Terminal: https://ssh.yourdomain.com
✓ AI Assistant: https://ai.yourdomain.com
✓ FileBrowser: https://files.yourdomain.com
```

### Default Credentials
```
Panel Admin:
  Email: [provided during installation]
  Password: [generated and displayed]

Admin Panel:
  Username: admin
  Password: [set during installation]
```

### Next Steps
1. ✓ Change default passwords
2. ✓ Configure DNS records
3. ✓ Create your first server
4. ✓ Configure backup system
5. ✓ Setup monitoring

---

## 🔄 Improvements Over Current Installer

### Current Installer Issues
- ❌ No visual progress indication
- ❌ Limited component selection
- ❌ No step-by-step explanations
- ❌ Difficult to track installation status
- ❌ No time estimates
- ❌ Limited error handling visibility

### New Interactive Installer Features
- ✅ Beautiful TUI with dialog
- ✅ Category-based installation
- ✅ Real-time progress bars
- ✅ Detailed step descriptions
- ✅ Time estimates
- ✅ Component information before install
- ✅ Installation summary
- ✅ Detailed logging
- ✅ Error recovery options
- ✅ Rollback capability

---

## 📝 Installation Log Example

```log
[2026-05-09 14:35:12] Starting Pterodactyl Automatic System v2.0.0
[2026-05-09 14:35:13] Selected components: panel, wings
[2026-05-09 14:35:15] Pre-installation checks passed
[2026-05-09 14:35:16] Installing Pterodactyl Panel...
[2026-05-09 14:35:20] Installing PHP 8.1... OK
[2026-05-09 14:36:45] Installing MySQL... OK
[2026-05-09 14:37:12] Installing Redis... OK
[2026-05-09 14:37:30] Downloading Panel... OK
[2026-05-09 14:38:15] Installing Composer dependencies... OK
[2026-05-09 14:40:22] Configuring Panel... OK
[2026-05-09 14:41:05] Installing Nginx... OK
[2026-05-09 14:41:45] Installing SSL certificate... OK
[2026-05-09 14:42:10] Creating admin user... OK
[2026-05-09 14:42:25] Panel installation complete!
[2026-05-09 14:42:26] Installing Pterodactyl Wings...
[2026-05-09 14:42:30] Installing Docker... OK
[2026-05-09 14:44:15] Downloading Wings... OK
[2026-05-09 14:44:30] Configuring Wings... OK
[2026-05-09 14:44:45] Starting Wings service... OK
[2026-05-09 14:45:00] Wings installation complete!
[2026-05-09 14:45:01] Installation finished successfully!
```

---

## 🎯 Future Enhancements

- [ ] Web-based installer (GUI in browser)
- [ ] One-click updates
- [ ] Automated backups before updates
- [ ] Health check dashboard
- [ ] Performance optimization wizard
- [ ] Migration assistant
- [ ] Multi-server deployment
- [ ] Kubernetes support
