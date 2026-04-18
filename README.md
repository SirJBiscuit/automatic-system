# Pterodactyl Universal Installer (pteroanyinstall)

A comprehensive, interactive installation script for Pterodactyl Panel and Wings that works on any Linux distribution.

## Features

### Core Features
- **Universal Compatibility**: Works on Ubuntu, Debian, CentOS, RHEL, Rocky Linux, and AlmaLinux
- **Interactive Installation**: Prompts for all necessary information with explanations
- **Component Selection**: Install Panel, Wings, or both
- **GPU Support**: Optional NVIDIA GPU support for game servers
- **Automatic DNS Verification**: Checks DNS records before installation
- **SSL/TLS Setup**: Automatic Let's Encrypt SSL certificate installation
- **Cloudflare Integration**: Optional Cloudflare DNS API integration
- **Health Monitoring**: Built-in service health checks
- **Update Management**: Easy updates for all components
- **Scan & Fix**: Automatic detection and repair of common issues

### Enhanced Features (NEW!)
- **🌐 Network Configuration Wizard**: Auto-detects WiFi/Ethernet interfaces with visual display
- **📍 Public IP Detection**: Automatically detects and confirms your public IP address
- **🔒 Static IP Configuration**: Prevents IP changes after reboots (DHCP protection)
- **🎨 Visual Network Diagrams**: ASCII art showing how everything connects
- **💬 Explained Prompts**: Every question includes an explanation of what it does
- **🔄 Reboot Protection**: All services auto-start after server restart
- **💰 Billing System Integration**: Automatic PayPal billing setup with customer portal
- **🎭 Panel Customization**: Interactive wizard to customize colors, logos, and styling
- **📊 Server Monitoring Tools**: htop, iotop, nethogs, vnstat + custom monitor command
- **💾 Automatic Backups**: Daily backups with configurable retention
- **🔥 Firewall Auto-Configuration**: Automatic UFW/firewalld setup with required ports
- **📋 Installation Flow Diagram**: Visual guide of the installation process
- **⚙️ Optional Features Menu**: Choose which extras to install

### Quick Wins (ESSENTIAL!)
- **🔐 SSL Auto-Renewal Monitoring**: Daily certificate expiry checks with auto-renewal
- **🛡️ Fail2ban Security**: Automatic brute-force protection for Panel, SSH, and Nginx
- **💾 Scheduled Backups**: Automated daily/weekly backups with retention policies
- **📊 Health Dashboard**: Real-time system status and resource monitoring
- **🔔 Update Notifications**: Automatic checks for Pterodactyl updates

### Admin Control Panel (NEW!)
- **🎛️ Visual Management Interface**: Full-featured admin dashboard
- **⚡ Service Control**: Start/stop/restart all services from one place
- **📈 Resource Monitor**: Live CPU, memory, and disk usage
- **📝 Logs Viewer**: Easy access to all system and application logs
- **🔒 Security Management**: Fail2ban status, SSL monitoring, firewall control
- **💾 Backup Management**: Create, restore, and schedule backups
- **🔄 Update Manager**: Check and apply updates to all components
- **⚙️ Advanced Configuration**: Database, performance, network settings

### AI Assistant (REVOLUTIONARY!)
- **🤖 Local AI with Ollama & Gemma2**: Runs entirely on your server, no external APIs
- **🔍 Intelligent Monitoring**: AI-powered system health analysis every 5 minutes
- **🔧 Auto-Fix Common Issues**: Automatically restarts services, clears cache, cleans logs
- **💬 Interactive Chatbot**: Ask questions anytime with `chatbot ask "your question"`
- **⚡ Lightweight**: Gemma2:1b uses only ~1GB RAM (perfect for LLM game server hosting)
- **🎯 Smart Model Selection**: Auto-selects optimal model based on your use case
- **🛡️ Proactive Defense**: Detects and prevents issues before they become critical
- **📊 Easy Control**: Simple `chatbot -enable/-disable` commands

## Requirements

- Fresh Linux installation (Ubuntu 20.04+, Debian 11+, CentOS 8+, Rocky/Alma 8+)
- Root access
- Public IP address
- Domain name with DNS configured
- Minimum 2GB RAM (4GB+ recommended)
- Minimum 10GB disk space

## Quick Start

### Download and Run

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/pteroanyinstall/main/pteroanyinstall.sh -o pteroanyinstall.sh
chmod +x pteroanyinstall.sh
sudo ./pteroanyinstall.sh
```

### Installation Options

#### Interactive Mode (Recommended)
```bash
sudo ./pteroanyinstall.sh
```

#### Install Panel Only
```bash
sudo ./pteroanyinstall.sh install-panel
```

#### Install Wings Only
```bash
sudo ./pteroanyinstall.sh install-wings
```

#### Full Installation (Panel + Wings)
```bash
sudo ./pteroanyinstall.sh install-full
```

## Commands

| Command | Description |
|---------|-------------|
| `install-panel` | Install Pterodactyl Panel only |
| `install-wings` | Install Pterodactyl Wings only |
| `install-full` | Install both Panel and Wings |
| `update` | Update all Pterodactyl components |
| `health-check` | Check status of all services |
| `scan` | Scan and fix existing installation |
| `help` | Show help message |

## Installation Process

### Panel Installation

The script will:
1. Install system dependencies
2. Install and configure MariaDB
3. Install Redis
4. Install PHP 8.1 and required extensions
5. Install Composer
6. Install and configure Nginx
7. Install Certbot for SSL
8. Download and configure Pterodactyl Panel
9. Create database and user
10. Configure environment
11. Set up Nginx virtual host
12. Generate SSL certificate (optional)
13. Create admin user

**You will be prompted for:**
- Panel FQDN (e.g., panel.example.com)
- Public IP address
- Email address
- Admin password
- SSL setup preference
- Cloudflare integration (optional)

### Wings Installation

The script will:
1. Install system dependencies
2. Install Docker
3. Configure GPU support (optional)
4. Download Wings binary
5. Prompt for Wings configuration from Panel
6. Set up systemd service
7. Generate SSL certificate (optional)

**You will be prompted for:**
- Wings FQDN (e.g., node.example.com)
- Public IP address
- Email address
- GPU support preference
- Node configuration from Panel

## DNS Setup

Before running the installation, ensure your DNS records are configured:

### For Panel
```
A    panel.example.com    -> YOUR_PUBLIC_IP
```

### For Wings
```
A    node.example.com     -> YOUR_PUBLIC_IP
```

The script will verify DNS records and warn you if they're not configured correctly.

## GPU Support

If you have an NVIDIA GPU and want to use it for game servers:

1. Ensure NVIDIA drivers are installed on your system
2. Answer "yes" when prompted for GPU support
3. The script will install nvidia-docker2 and configure Docker

## Cloudflare Integration

For Cloudflare DNS integration:

1. Log in to Cloudflare
2. Go to My Profile → API Tokens
3. Create a token with `Zone:DNS:Edit` permissions
4. Copy your Zone ID from the domain overview
5. Provide these when prompted during installation

## Post-Installation

### Panel Credentials

After Panel installation, credentials are saved to:
```
/root/panel_credentials.txt
```

**Important**: Save these credentials securely and delete the file after copying.

### Wings Configuration

1. Log in to your Panel admin area
2. Go to Admin → Locations → Create Location
3. Go to Admin → Nodes → Create Node
4. Enter the Wings FQDN
5. Copy the auto-generated configuration
6. Paste it when prompted by the script

### First Steps

1. Access your panel at `https://panel.example.com`
2. Log in with admin credentials
3. Create a location
4. Create a node (if Wings is on a different server)
5. Create a server

## Updating

To update all components:

```bash
sudo ./pteroanyinstall.sh update
```

This will:
- Update system packages
- Update Pterodactyl Panel
- Update Pterodactyl Wings
- Run health checks

## Troubleshooting

### Scan and Fix

If you encounter issues:

```bash
sudo ./pteroanyinstall.sh scan
```

This will:
- Check Panel installation
- Fix file permissions
- Clear caches
- Verify database connection
- Restart services
- Run health checks

### Health Check

To check service status:

```bash
sudo ./pteroanyinstall.sh health-check
```

### Common Issues

#### Panel shows 500 error
```bash
cd /var/www/pterodactyl
php artisan config:clear
php artisan cache:clear
chown -R www-data:www-data /var/www/pterodactyl/*
```

#### Wings not connecting
```bash
systemctl status wings
journalctl -u wings -n 50
```

Check that:
- DNS points to correct IP
- SSL certificate is valid
- Firewall allows ports 8080 and 2022
- Configuration in `/etc/pterodactyl/config.yml` is correct

#### Database connection failed
```bash
systemctl status mariadb
mysql -u pterodactyl -p panel
```

### Firewall Configuration

Ensure these ports are open:

**Panel:**
- 80 (HTTP)
- 443 (HTTPS)

**Wings:**
- 8080 (Wings API)
- 2022 (SFTP)
- 443 (HTTPS)
- Game server ports (varies)

**Ubuntu/Debian:**
```bash
ufw allow 80
ufw allow 443
ufw allow 8080
ufw allow 2022
```

**CentOS/RHEL/Rocky/Alma:**
```bash
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --permanent --add-port=2022/tcp
firewall-cmd --reload
```

## Security Recommendations

1. **Change default passwords** immediately after installation
2. **Enable 2FA** in Panel settings
3. **Keep system updated** regularly
4. **Use strong passwords** for database and admin accounts
5. **Restrict SSH access** to key-based authentication
6. **Configure firewall** properly
7. **Regular backups** of Panel database and Wings configurations
8. **Monitor logs** for suspicious activity

## Backup

### Panel Backup
```bash
cd /var/www/pterodactyl
php artisan p:environment:database
mysqldump -u pterodactyl -p panel > panel_backup.sql
tar -czf panel_backup.tar.gz /var/www/pterodactyl /etc/nginx/sites-available/pterodactyl.conf
```

### Wings Backup
```bash
tar -czf wings_backup.tar.gz /etc/pterodactyl /var/lib/pterodactyl
```

## Uninstallation

To remove Pterodactyl:

### Panel
```bash
systemctl stop nginx
rm -rf /var/www/pterodactyl
rm /etc/nginx/sites-enabled/pterodactyl.conf
rm /etc/nginx/sites-available/pterodactyl.conf
mysql -u root -e "DROP DATABASE panel; DROP USER 'pterodactyl'@'127.0.0.1';"
```

### Wings
```bash
systemctl stop wings
systemctl disable wings
rm /etc/systemd/system/wings.service
rm /usr/local/bin/wings
rm -rf /etc/pterodactyl
rm -rf /var/lib/pterodactyl
```

## Support

For issues with:
- **This script**: Open an issue on GitHub
- **Pterodactyl**: Visit [Pterodactyl Discord](https://discord.gg/pterodactyl)
- **Documentation**: [Pterodactyl Docs](https://pterodactyl.io/project/introduction.html)

## License

MIT License - Feel free to modify and distribute

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Changelog

### Version 1.0.0
- Initial release
- Support for Ubuntu, Debian, CentOS, RHEL, Rocky, AlmaLinux
- Panel and Wings installation
- GPU support
- Cloudflare integration
- Update and health check features
- Scan and fix functionality

## Credits

- Pterodactyl Software: [pterodactyl.io](https://pterodactyl.io)
- Script Author: Your Name

## Disclaimer

This script is provided as-is without warranty. Always review scripts before running them with root privileges. Test in a non-production environment first.
