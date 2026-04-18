#!/bin/bash

# Quick Setup Script - Essential post-installation features
# SSL monitoring, Fail2ban, Backups, Health checks, Update notifications

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

prompt_yes_no() {
    local prompt="$1"
    local response
    
    while true; do
        read -p "$prompt (y/n): " response
        case $response in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

show_quick_setup_banner() {
    cat <<'EOF'

╔════════════════════════════════════════════════════════════════════════╗
║                    QUICK SETUP - ESSENTIAL FEATURES                    ║
║          SSL Monitoring • Security • Backups • Health Checks           ║
╚════════════════════════════════════════════════════════════════════════╝

EOF
}

# 1. SSL Auto-Renewal Monitoring
setup_ssl_monitoring() {
    log_info "Setting up SSL certificate monitoring..."
    
    cat > /usr/local/bin/check-ssl-expiry.sh <<'EOFSSL'
#!/bin/bash

# SSL Certificate Expiry Checker
PANEL_DOMAIN="$1"
ALERT_DAYS=30
ALERT_EMAIL="${2:-root@localhost}"

if [ -z "$PANEL_DOMAIN" ]; then
    echo "Usage: $0 <domain> [alert_email]"
    exit 1
fi

# Check certificate expiry
EXPIRY_DATE=$(echo | openssl s_client -servername "$PANEL_DOMAIN" -connect "$PANEL_DOMAIN:443" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

if [ -z "$EXPIRY_DATE" ]; then
    echo "ERROR: Could not retrieve SSL certificate for $PANEL_DOMAIN"
    exit 1
fi

EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
CURRENT_EPOCH=$(date +%s)
DAYS_UNTIL_EXPIRY=$(( ($EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))

echo "SSL Certificate Status for $PANEL_DOMAIN"
echo "========================================"
echo "Expires: $EXPIRY_DATE"
echo "Days until expiry: $DAYS_UNTIL_EXPIRY"

if [ $DAYS_UNTIL_EXPIRY -lt $ALERT_DAYS ]; then
    echo "WARNING: Certificate expires in $DAYS_UNTIL_EXPIRY days!"
    
    # Send alert email
    if command -v mail &> /dev/null; then
        echo "SSL certificate for $PANEL_DOMAIN expires in $DAYS_UNTIL_EXPIRY days!" | \
            mail -s "SSL Certificate Expiry Warning - $PANEL_DOMAIN" "$ALERT_EMAIL"
    fi
    
    # Try to renew with certbot
    if command -v certbot &> /dev/null; then
        echo "Attempting automatic renewal..."
        certbot renew --quiet
    fi
    
    exit 1
else
    echo "Certificate is valid for $DAYS_UNTIL_EXPIRY more days"
    exit 0
fi
EOFSSL

    chmod +x /usr/local/bin/check-ssl-expiry.sh
    
    # Get panel domain
    if [ -f "/var/www/pterodactyl/.env" ]; then
        PANEL_URL=$(grep APP_URL /var/www/pterodactyl/.env | cut -d '=' -f2 | sed 's|https://||' | sed 's|http://||')
    else
        read -p "Enter your panel domain (e.g., panel.example.com): " PANEL_URL
    fi
    
    read -p "Enter alert email address [root@localhost]: " ALERT_EMAIL
    ALERT_EMAIL=${ALERT_EMAIL:-root@localhost}
    
    # Create daily cron job
    cat > /etc/cron.daily/ssl-check <<EOFCRON
#!/bin/bash
/usr/local/bin/check-ssl-expiry.sh "$PANEL_URL" "$ALERT_EMAIL"
EOFCRON
    
    chmod +x /etc/cron.daily/ssl-check
    
    log_success "SSL monitoring configured for $PANEL_URL"
    log_info "Daily checks will alert $ALERT_EMAIL if certificate expires within 30 days"
}

# 2. Fail2ban Security Setup
setup_fail2ban() {
    log_info "Setting up Fail2ban for Pterodactyl..."
    
    # Install fail2ban
    if ! command -v fail2ban-client &> /dev/null; then
        log_info "Installing Fail2ban..."
        if [ -f /etc/debian_version ]; then
            apt-get update && apt-get install -y fail2ban
        elif [ -f /etc/redhat-release ]; then
            yum install -y epel-release
            yum install -y fail2ban
        fi
    fi
    
    # Create Pterodactyl filter
    cat > /etc/fail2ban/filter.d/pterodactyl.conf <<'EOFF2B'
[Definition]
failregex = .*authentication failure.* rhost=<HOST>
            .*Failed login attempt.* from <HOST>
            .*Invalid credentials.* from <HOST>
ignoreregex =
EOFF2B
    
    # Create Pterodactyl jail
    cat > /etc/fail2ban/jail.d/pterodactyl.conf <<'EOFJAIL'
[pterodactyl]
enabled = true
port = http,https
filter = pterodactyl
logpath = /var/www/pterodactyl/storage/logs/laravel-*.log
maxretry = 5
bantime = 3600
findtime = 600

[nginx-limit-req]
enabled = true
port = http,https
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
maxretry = 10
findtime = 600
bantime = 7200

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 86400
findtime = 600
EOFJAIL
    
    # Restart fail2ban
    systemctl enable fail2ban
    systemctl restart fail2ban
    
    log_success "Fail2ban configured and running"
    log_info "Protected services: Pterodactyl Panel, Nginx, SSH"
    log_info "View banned IPs: fail2ban-client status"
}

# 3. Automated Backup System
setup_backup_automation() {
    log_info "Setting up automated backup system..."
    
    # Create backup script
    cat > /usr/local/bin/pterodactyl-backup.sh <<'EOFBACKUP'
#!/bin/bash

BACKUP_DIR="/var/backups/pterodactyl"
RETENTION_DAYS=7
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "Starting Pterodactyl backup - $DATE"

# Backup Panel files
if [ -d "/var/www/pterodactyl" ]; then
    echo "Backing up Panel files..."
    tar -czf "$BACKUP_DIR/panel-$DATE.tar.gz" -C /var/www pterodactyl
fi

# Backup database
if [ -f "/var/www/pterodactyl/.env" ]; then
    DB_NAME=$(grep DB_DATABASE /var/www/pterodactyl/.env | cut -d '=' -f2)
    DB_USER=$(grep DB_USERNAME /var/www/pterodactyl/.env | cut -d '=' -f2)
    DB_PASS=$(grep DB_PASSWORD /var/www/pterodactyl/.env | cut -d '=' -f2)
    
    if [ -n "$DB_NAME" ]; then
        echo "Backing up database..."
        mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip > "$BACKUP_DIR/database-$DATE.sql.gz"
    fi
fi

# Backup Wings config
if [ -f "/etc/pterodactyl/config.yml" ]; then
    echo "Backing up Wings config..."
    cp /etc/pterodactyl/config.yml "$BACKUP_DIR/wings-config-$DATE.yml"
fi

# Delete old backups
echo "Cleaning up old backups (older than $RETENTION_DAYS days)..."
find "$BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -delete

echo "Backup completed: $BACKUP_DIR"
ls -lh "$BACKUP_DIR" | tail -5
EOFBACKUP
    
    chmod +x /usr/local/bin/pterodactyl-backup.sh
    
    # Ask for backup schedule
    echo ""
    echo "Backup Schedule Options:"
    echo "1) Daily at 2 AM"
    echo "2) Daily at 3 AM"
    echo "3) Twice daily (2 AM and 2 PM)"
    echo "4) Custom"
    echo ""
    read -p "Select backup schedule [1-4]: " backup_schedule
    
    case $backup_schedule in
        1)
            CRON_SCHEDULE="0 2 * * *"
            ;;
        2)
            CRON_SCHEDULE="0 3 * * *"
            ;;
        3)
            CRON_SCHEDULE="0 2,14 * * *"
            ;;
        4)
            read -p "Enter cron schedule (e.g., '0 2 * * *'): " CRON_SCHEDULE
            ;;
        *)
            CRON_SCHEDULE="0 2 * * *"
            ;;
    esac
    
    # Add to crontab
    (crontab -l 2>/dev/null | grep -v pterodactyl-backup; echo "$CRON_SCHEDULE /usr/local/bin/pterodactyl-backup.sh >> /var/log/pterodactyl-backup.log 2>&1") | crontab -
    
    # Ask about retention
    read -p "Backup retention in days [7]: " retention
    retention=${retention:-7}
    sed -i "s/RETENTION_DAYS=.*/RETENTION_DAYS=$retention/" /usr/local/bin/pterodactyl-backup.sh
    
    log_success "Automated backups configured"
    log_info "Schedule: $CRON_SCHEDULE"
    log_info "Retention: $retention days"
    log_info "Location: /var/backups/pterodactyl"
    log_info "Run manually: /usr/local/bin/pterodactyl-backup.sh"
}

# 4. Health Dashboard
setup_health_dashboard() {
    log_info "Setting up health monitoring dashboard..."
    
    cat > /usr/local/bin/ptero-health.sh <<'EOFHEALTH'
#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║              PTERODACTYL HEALTH DASHBOARD                              ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""

# System Resources
echo -e "${BLUE}System Resources:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2 " (" int($3/$2 * 100) "%)"}')"
echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

# Service Status
echo -e "${BLUE}Service Status:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

check_service() {
    if systemctl is-active --quiet $1; then
        echo -e "$1: ${GREEN}●${NC} Running"
    else
        echo -e "$1: ${RED}●${NC} Stopped"
    fi
}

check_service "nginx"
check_service "mysql" || check_service "mariadb"
check_service "redis-server" || check_service "redis"
check_service "wings" 2>/dev/null || echo "wings: Not installed"
check_service "docker"
echo ""

# SSL Certificate
echo -e "${BLUE}SSL Certificate:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f "/var/www/pterodactyl/.env" ]; then
    PANEL_URL=$(grep APP_URL /var/www/pterodactyl/.env | cut -d '=' -f2 | sed 's|https://||' | sed 's|http://||')
    if [ -n "$PANEL_URL" ]; then
        EXPIRY=$(echo | openssl s_client -servername "$PANEL_URL" -connect "$PANEL_URL:443" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
        if [ -n "$EXPIRY" ]; then
            DAYS=$(( ($(date -d "$EXPIRY" +%s) - $(date +%s)) / 86400 ))
            if [ $DAYS -lt 30 ]; then
                echo -e "Expires: ${YELLOW}$EXPIRY${NC} (${YELLOW}$DAYS days${NC})"
            else
                echo -e "Expires: ${GREEN}$EXPIRY${NC} (${GREEN}$DAYS days${NC})"
            fi
        else
            echo "Could not check SSL certificate"
        fi
    fi
else
    echo "Panel not installed"
fi
echo ""

# Recent Backups
echo -e "${BLUE}Recent Backups:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -d "/var/backups/pterodactyl" ]; then
    ls -lht /var/backups/pterodactyl | head -4 | tail -3 | awk '{print $9, "-", $5, "-", $6, $7, $8}'
else
    echo "No backups found"
fi
echo ""

# Fail2ban Status
echo -e "${BLUE}Security (Fail2ban):${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v fail2ban-client &> /dev/null; then
    if systemctl is-active --quiet fail2ban; then
        BANNED=$(fail2ban-client status | grep "Jail list" | sed 's/.*://g' | tr ',' '\n' | wc -l)
        echo -e "Status: ${GREEN}Active${NC}"
        echo "Active jails: $BANNED"
        fail2ban-client status | grep "Jail list"
    else
        echo -e "Status: ${RED}Inactive${NC}"
    fi
else
    echo "Not installed"
fi
echo ""

# Docker Containers (if Wings installed)
if command -v docker &> /dev/null; then
    echo -e "${BLUE}Docker Containers:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    RUNNING=$(docker ps -q | wc -l)
    TOTAL=$(docker ps -aq | wc -l)
    echo "Running: $RUNNING / $TOTAL containers"
    echo ""
fi

echo "Last updated: $(date)"
echo "Run 'ptero-health' anytime to view this dashboard"
EOFHEALTH
    
    chmod +x /usr/local/bin/ptero-health.sh
    ln -sf /usr/local/bin/ptero-health.sh /usr/local/bin/ptero-health
    
    log_success "Health dashboard installed"
    log_info "Run 'ptero-health' to view system status"
}

# 5. Update Notifier
setup_update_notifier() {
    log_info "Setting up update notification system..."
    
    cat > /usr/local/bin/check-ptero-updates.sh <<'EOFUPDATE'
#!/bin/bash

PANEL_DIR="/var/www/pterodactyl"
CURRENT_VERSION=""
LATEST_VERSION=""

# Check Panel version
if [ -f "$PANEL_DIR/config/app.php" ]; then
    CURRENT_VERSION=$(grep "'version'" "$PANEL_DIR/config/app.php" | cut -d "'" -f4)
fi

# Get latest version from GitHub
LATEST_VERSION=$(curl -s https://api.github.com/repos/pterodactyl/panel/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

echo "Pterodactyl Update Check"
echo "========================"
echo "Current Panel Version: ${CURRENT_VERSION:-Unknown}"
echo "Latest Panel Version: ${LATEST_VERSION:-Unknown}"

if [ -n "$CURRENT_VERSION" ] && [ -n "$LATEST_VERSION" ]; then
    if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
        echo ""
        echo "⚠️  UPDATE AVAILABLE!"
        echo "A new version of Pterodactyl Panel is available: v$LATEST_VERSION"
        echo ""
        echo "To update, run:"
        echo "  cd /var/www/pterodactyl"
        echo "  php artisan p:upgrade"
        echo ""
        echo "Or use pteroanyinstall:"
        echo "  ./pteroanyinstall.sh update"
        
        # Send notification if configured
        if [ -n "$NOTIFICATION_EMAIL" ]; then
            echo "Update available: Pterodactyl v$LATEST_VERSION" | \
                mail -s "Pterodactyl Update Available" "$NOTIFICATION_EMAIL"
        fi
    else
        echo "✓ You are running the latest version"
    fi
fi

# Check Wings version
if command -v wings &> /dev/null; then
    WINGS_VERSION=$(wings --version 2>/dev/null | grep -oP 'v\K[0-9.]+' || echo "Unknown")
    LATEST_WINGS=$(curl -s https://api.github.com/repos/pterodactyl/wings/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    
    echo ""
    echo "Current Wings Version: ${WINGS_VERSION}"
    echo "Latest Wings Version: ${LATEST_WINGS:-Unknown}"
    
    if [ -n "$WINGS_VERSION" ] && [ -n "$LATEST_WINGS" ] && [ "$WINGS_VERSION" != "$LATEST_WINGS" ]; then
        echo "⚠️  Wings update available: v$LATEST_WINGS"
    fi
fi
EOFUPDATE
    
    chmod +x /usr/local/bin/check-ptero-updates.sh
    
    # Add weekly cron job
    (crontab -l 2>/dev/null | grep -v check-ptero-updates; echo "0 9 * * 1 /usr/local/bin/check-ptero-updates.sh") | crontab -
    
    log_success "Update notifier configured"
    log_info "Weekly checks every Monday at 9 AM"
    log_info "Run manually: check-ptero-updates.sh"
}

# Main setup function
main() {
    show_quick_setup_banner
    
    log_info "This will set up essential post-installation features:"
    echo "  1. SSL Certificate Monitoring"
    echo "  2. Fail2ban Security"
    echo "  3. Automated Backups"
    echo "  4. Health Dashboard"
    echo "  5. Update Notifications"
    echo ""
    
    if ! prompt_yes_no "Continue with quick setup?"; then
        log_info "Setup cancelled"
        exit 0
    fi
    
    echo ""
    
    # SSL Monitoring
    if prompt_yes_no "Set up SSL certificate monitoring?"; then
        setup_ssl_monitoring
        echo ""
    fi
    
    # Fail2ban
    if prompt_yes_no "Set up Fail2ban security?"; then
        setup_fail2ban
        echo ""
    fi
    
    # Automated Backups
    if prompt_yes_no "Set up automated backups?"; then
        setup_backup_automation
        echo ""
    fi
    
    # Health Dashboard
    if prompt_yes_no "Set up health monitoring dashboard?"; then
        setup_health_dashboard
        echo ""
    fi
    
    # Update Notifier
    if prompt_yes_no "Set up update notifications?"; then
        setup_update_notifier
        echo ""
    fi
    
    log_success "Quick setup completed!"
    echo ""
    log_info "Available commands:"
    echo "  • ptero-health          - View system health dashboard"
    echo "  • check-ptero-updates.sh - Check for updates"
    echo "  • pterodactyl-backup.sh  - Run manual backup"
    echo "  • fail2ban-client status - View security status"
    echo ""
    
    if prompt_yes_no "View health dashboard now?"; then
        /usr/local/bin/ptero-health.sh
    fi
}

main "$@"
