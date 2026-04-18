# Changelog

## Version 2.0.0 - Enhanced Edition (2026-04-18)

### 🎉 Major New Features

#### Network Configuration Wizard
- **Auto-detection of network interfaces** (WiFi and Ethernet)
- **Visual interface selection** with status and IP display
- **Automatic public IP detection** from multiple sources
- **Static IP configuration** to prevent DHCP changes
- **Configuration persistence** across reboots
- **Network configuration saved** to `/etc/pteroanyinstall/config.conf`

#### Visual Guides and Diagrams
- **Network architecture diagram** showing component connections
- **Installation flow diagram** with step-by-step visualization
- **Port requirements display** for firewall configuration
- **ASCII art diagrams** for better understanding

#### Enhanced User Experience
- **Explained prompts** - Every question includes what it does and why
- **Smart defaults** - Auto-detected values with confirmation
- **Progress indicators** - Clear feedback during installation
- **Color-coded messages** - Info (blue), Success (green), Warning (yellow), Error (red)

#### Reboot Protection System
- **Automatic service startup** after server reboot
- **Systemd service integration** (`pterodactyl-startup.service`)
- **Startup script** with comprehensive logging
- **Dependency management** - Services start in correct order
- **10-second delay** for system stability
- **Logs saved** to `/var/log/pterodactyl-startup.log`

#### Billing System Integration
- **WHMCS module** installation and configuration
- **Blesta module** support with installation links
- **HostBill integration** guidance
- **API configuration** for automated billing
- **Module location** at `/var/www/whmcs-pterodactyl`

#### Server Monitoring Tools
- **htop** - Interactive process viewer
- **iotop** - Disk I/O monitoring
- **nethogs** - Network bandwidth per process
- **vnstat** - Network traffic statistics
- **Custom ptero-monitor command** - All-in-one status view
- **Service status checks** - Docker, MariaDB, Nginx, Redis, Wings
- **Resource usage display** - Memory, disk, network

#### Automatic Backup System
- **Daily automated backups** at 2 AM
- **Configurable backup directory** (default: `/var/backups/pterodactyl`)
- **Configurable retention** (default: 7 days)
- **Panel database backup** (MySQL dump)
- **Panel files backup** (tar.gz)
- **Wings configuration backup**
- **Automatic cleanup** of old backups
- **Detailed logging** to `/var/log/pterodactyl-backup.log`
- **Manual backup script** at `/usr/local/bin/pterodactyl-backup.sh`

#### Firewall Auto-Configuration
- **UFW support** (Ubuntu/Debian)
- **firewalld support** (CentOS/RHEL/Rocky/Alma)
- **Automatic port opening** for all required services
- **Default deny policy** for security
- **Port comments** for easy identification
- **SSH, HTTP, HTTPS, Wings API, SFTP, game ports**

#### Optional Features Menu
- **Interactive selection** of additional features
- **Monitoring tools** installation
- **Automatic backups** setup
- **Billing system** integration
- **Firewall configuration**
- **Each feature explained** before installation

### 🔧 Improvements

#### Installation Process
- **Network wizard runs first** to ensure stable connectivity
- **Visual flow diagram** shown at start
- **Public IP auto-detection** with manual override option
- **Static IP configuration** prevents connectivity issues
- **Reboot protection** configured automatically
- **Optional features** presented at end

#### Prompt System
- **prompt_with_explanation()** function for all user inputs
- **Contextual help** for every configuration option
- **Smart defaults** based on auto-detection
- **Validation** of user inputs
- **Confirmation** of critical settings

#### Service Management
- **Startup dependencies** properly configured
- **Service ordering** ensures correct initialization
- **Health checks** verify all services running
- **Automatic restart** on failure
- **Log aggregation** for troubleshooting

#### Documentation
- **ENHANCED_FEATURES.md** - Comprehensive feature documentation
- **QUICK_START.md** - Fast setup guide
- **Updated README.md** - New features highlighted
- **Updated INSTALL_GUIDE.md** - Network setup included
- **Updated EXAMPLES.md** - New scenarios added

### 🐛 Bug Fixes
- Fixed issue where services wouldn't start after reboot
- Fixed DHCP IP changes breaking DNS records
- Fixed missing explanations for configuration prompts
- Fixed firewall rules not persisting across reboots
- Fixed backup script permissions

### 📝 Configuration Files

#### New Files Created
- `/etc/pteroanyinstall/config.conf` - Network configuration
- `/etc/systemd/system/pterodactyl-startup.service` - Reboot protection
- `/usr/local/bin/pterodactyl-startup.sh` - Startup script
- `/usr/local/bin/pterodactyl-backup.sh` - Backup script
- `/usr/local/bin/ptero-monitor` - Monitoring command
- `/var/log/pterodactyl-startup.log` - Startup logs
- `/var/log/pterodactyl-backup.log` - Backup logs

#### Modified Files
- `/etc/netplan/01-netcfg.yaml` - Static IP (Ubuntu)
- `/etc/network/interfaces.d/*` - Static IP (Debian)
- `/etc/sysconfig/network-scripts/ifcfg-*` - Static IP (CentOS)
- Crontab - Daily backup schedule

### 🔐 Security Enhancements
- **Firewall auto-configuration** with minimal open ports
- **Static IP** prevents man-in-the-middle attacks via DHCP
- **Backup encryption** recommendations
- **Secure credential storage** with proper permissions
- **Service isolation** through systemd

### 📊 Monitoring and Logging
- **Centralized logging** for all custom scripts
- **Service status monitoring** via ptero-monitor
- **Network usage tracking** with vnstat
- **Resource monitoring** with htop/iotop
- **Startup logging** for troubleshooting

### 🚀 Performance Improvements
- **Parallel service startup** where possible
- **Optimized backup compression**
- **Efficient network interface detection**
- **Cached public IP detection**

### 🎯 Use Cases Supported

#### Personal Use
- Single server setup with Panel + Wings
- Automatic backups for data protection
- Monitoring for resource tracking
- Reboot protection for reliability

#### Small Business
- Multi-node setup with separate Panel and Wings
- Billing system integration (WHMCS/Blesta)
- Automatic backups with retention
- Firewall security
- Monitoring tools

#### Enterprise
- Scalable multi-node architecture
- Cloudflare integration for DDoS protection
- Comprehensive monitoring
- Automated backups to external storage
- Static IP for network stability

### 📚 Documentation Updates
- Added ENHANCED_FEATURES.md with detailed explanations
- Added QUICK_START.md for fast setup
- Updated README.md with new features
- Updated INSTALL_GUIDE.md with network setup
- Updated EXAMPLES.md with new scenarios
- Added CHANGELOG.md (this file)

### 🔄 Upgrade Path

#### From Version 1.0.0
1. Download new script version
2. Run `./pteroanyinstall.sh scan` to check existing installation
3. Run network wizard to configure static IP
4. Enable reboot protection: Script will offer during scan
5. Optionally add monitoring, backups, firewall

#### Fresh Installation
- All new features enabled by default
- Interactive prompts guide through setup
- Network wizard runs automatically
- Reboot protection configured automatically
- Optional features presented at end

### ⚠️ Breaking Changes
- None - Fully backward compatible with existing installations

### 🎁 Bonus Features
- **clear** command at start for clean display
- **Network diagram** shown in interactive mode
- **Installation flow** visualization
- **Color-coded output** for better readability
- **Comprehensive help** with `--help` flag

### 🛠️ Technical Details

#### Supported Operating Systems
- Ubuntu 20.04, 22.04, 24.04
- Debian 11, 12
- CentOS 8, 9
- RHEL 8, 9
- Rocky Linux 8, 9
- AlmaLinux 8, 9

#### Network Configuration Methods
- **Netplan** (Modern Ubuntu/Debian)
- **interfaces.d** (Legacy Debian)
- **network-scripts** (CentOS/RHEL)

#### Firewall Systems
- **UFW** (Ubuntu/Debian)
- **firewalld** (CentOS/RHEL/Rocky/Alma)

#### Backup Methods
- **mysqldump** for databases
- **tar.gz** for file compression
- **Cron** for scheduling

#### Monitoring Tools
- **systemd** for service management
- **vnstat** for network statistics
- **Custom scripts** for aggregated status

### 📞 Support
- GitHub Issues for bug reports
- Discord community for help
- Documentation for guides
- Examples for common scenarios

### 🙏 Credits
- Pterodactyl Software team
- Community contributors
- Beta testers
- Documentation writers

---

## Version 1.0.0 - Initial Release (2026-04-17)

### Features
- Universal OS compatibility
- Interactive installation
- Panel and Wings installation
- GPU support
- DNS verification
- SSL/TLS setup
- Cloudflare integration
- Health monitoring
- Update management
- Scan and fix functionality

### Components Installed
- Docker
- MariaDB
- Redis
- PHP 8.1
- Composer
- Nginx
- Certbot
- Pterodactyl Panel
- Pterodactyl Wings

### Commands
- `install-panel` - Install Panel only
- `install-wings` - Install Wings only
- `install-full` - Install both
- `update` - Update components
- `health-check` - Check services
- `scan` - Scan and fix
- `help` - Show help

---

## Roadmap

### Version 2.1.0 (Planned)
- [ ] Web-based configuration interface
- [ ] Email notifications for backups
- [ ] Grafana integration for monitoring
- [ ] Multi-language support
- [ ] Custom egg installation
- [ ] Database clustering support
- [ ] Load balancer integration

### Version 3.0.0 (Future)
- [ ] Kubernetes support
- [ ] Container orchestration
- [ ] Advanced networking options
- [ ] Multi-datacenter support
- [ ] Automated scaling
- [ ] Advanced security features
- [ ] Compliance reporting

---

## Migration Guide

### From Manual Installation
1. Run `./pteroanyinstall.sh scan` to detect existing installation
2. Script will fix permissions and configurations
3. Optionally add new features (monitoring, backups, etc.)
4. Configure reboot protection
5. Setup static IP if needed

### From Other Scripts
1. Backup existing installation
2. Run `./pteroanyinstall.sh scan` to verify compatibility
3. Script will integrate with existing setup
4. Add enhanced features as needed
5. Test thoroughly before production use

---

## Known Issues
- None currently reported

## Feedback
We welcome feedback! Please:
- Report bugs via GitHub Issues
- Suggest features via GitHub Discussions
- Share success stories on Discord
- Contribute improvements via Pull Requests
