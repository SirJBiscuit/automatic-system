#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

show_pre_install_banner() {
    cat <<'EOF'

╔════════════════════════════════════════════════════════════════════════╗
║              PRE-INSTALLATION CHECKS & REQUIREMENTS                    ║
║           Let's make sure everything is ready to go!                   ║
╚════════════════════════════════════════════════════════════════════════╝

EOF
}

check_existing_pterodactyl() {
    log_info "Checking for existing Pterodactyl installation..."
    
    EXISTING_PANEL=false
    EXISTING_WINGS=false
    
    # Check for Panel
    if [ -d "/var/www/pterodactyl" ]; then
        EXISTING_PANEL=true
        log_warning "Existing Pterodactyl Panel detected at /var/www/pterodactyl"
    fi
    
    # Check for Wings
    if [ -f "/usr/local/bin/wings" ] || [ -f "/etc/pterodactyl/config.yml" ]; then
        EXISTING_WINGS=true
        log_warning "Existing Pterodactyl Wings detected"
    fi
    
    if [ "$EXISTING_PANEL" = true ] || [ "$EXISTING_WINGS" = true ]; then
        echo ""
        log_warning "EXISTING PTERODACTYL INSTALLATION FOUND!"
        echo ""
        log_info "You have the following options:"
        echo "  1) Clean wipe and fresh install (saves ports/configs only)"
        echo "  2) Backup everything and migrate (keeps all data)"
        echo "  3) Continue and update existing installation"
        echo "  4) Exit and manually backup first"
        echo ""
        
        read -p "Select option [1-4]: " migration_choice
        
        case $migration_choice in
            1)
                clean_wipe_and_install
                return 0
                ;;
            2)
                backup_and_migrate
                return 0
                ;;
            3)
                log_info "Continuing with existing installation..."
                return 0
                ;;
            4)
                log_info "Please backup your installation manually, then run this script again."
                exit 0
                ;;
            *)
                log_error "Invalid selection"
                exit 1
                ;;
        esac
    else
        log_success "No existing Pterodactyl installation found - fresh install!"
    fi
}

clean_wipe_and_install() {
    echo ""
    log_warning "╔════════════════════════════════════════════════════════════════════════╗"
    log_warning "║                    CLEAN WIPE & FRESH INSTALL                          ║"
    log_warning "╚════════════════════════════════════════════════════════════════════════╝"
    echo ""
    log_warning "This will:"
    echo "  ✓ Save your ports and network configurations"
    echo "  ✓ Save your domain names"
    echo "  ✓ Save your SSL certificates"
    echo "  ✗ DELETE all Panel data (users, servers, databases)"
    echo "  ✗ DELETE all game server files"
    echo "  ✗ DELETE all Wings data"
    echo ""
    log_error "THIS CANNOT BE UNDONE!"
    echo ""
    
    if ! prompt_yes_no "Are you ABSOLUTELY SURE you want to wipe everything?"; then
        log_info "Cancelled. Returning to menu..."
        check_existing_pterodactyl
        return 0
    fi
    
    echo ""
    log_info "Creating config backup directory..."
    CONFIG_BACKUP="/root/pterodactyl-config-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$CONFIG_BACKUP"
    
    # Save ports and network config
    log_info "Saving network configuration..."
    
    # Save Panel domain/URL
    if [ -f "/var/www/pterodactyl/.env" ]; then
        PANEL_URL=$(grep APP_URL /var/www/pterodactyl/.env | cut -d '=' -f2)
        echo "PANEL_URL=$PANEL_URL" > "$CONFIG_BACKUP/saved_config.txt"
        log_success "Panel URL saved: $PANEL_URL"
    fi
    
    # Save Wings config (ports, domain)
    if [ -f "/etc/pterodactyl/config.yml" ]; then
        cp /etc/pterodactyl/config.yml "$CONFIG_BACKUP/wings_config.yml"
        
        # Extract important info
        WINGS_PORT=$(grep -A 5 "api:" /etc/pterodactyl/config.yml | grep "port:" | awk '{print $2}')
        WINGS_SFTP_PORT=$(grep -A 5 "sftp:" /etc/pterodactyl/config.yml | grep "bind_port:" | awk '{print $2}')
        
        echo "WINGS_PORT=$WINGS_PORT" >> "$CONFIG_BACKUP/saved_config.txt"
        echo "WINGS_SFTP_PORT=$WINGS_SFTP_PORT" >> "$CONFIG_BACKUP/saved_config.txt"
        log_success "Wings ports saved: API=$WINGS_PORT, SFTP=$WINGS_SFTP_PORT"
    fi
    
    # Save SSL certificates
    if [ -d "/etc/letsencrypt" ]; then
        log_info "Backing up SSL certificates..."
        tar -czf "$CONFIG_BACKUP/ssl_certificates.tar.gz" /etc/letsencrypt 2>/dev/null
        log_success "SSL certificates backed up"
    fi
    
    # Save Nginx config
    if [ -f "/etc/nginx/sites-available/pterodactyl.conf" ]; then
        cp /etc/nginx/sites-available/pterodactyl.conf "$CONFIG_BACKUP/nginx_pterodactyl.conf"
        log_success "Nginx config saved"
    fi
    
    # Save firewall rules
    if command -v ufw &> /dev/null; then
        ufw status numbered > "$CONFIG_BACKUP/ufw_rules.txt"
        log_success "Firewall rules saved"
    fi
    
    # Create restore script
    cat > "$CONFIG_BACKUP/RESTORE_CONFIG.sh" <<'EOF'
#!/bin/bash
# Auto-generated config restore script
# Run this after fresh installation to restore your saved settings

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Restoring saved configuration...${NC}"

# Source saved config
source saved_config.txt

echo "Panel URL: $PANEL_URL"
echo "Wings Port: $WINGS_PORT"
echo "SFTP Port: $WINGS_SFTP_PORT"

# Restore SSL certificates
if [ -f "ssl_certificates.tar.gz" ]; then
    echo -e "${GREEN}Restoring SSL certificates...${NC}"
    tar -xzf ssl_certificates.tar.gz -C /
fi

echo ""
echo -e "${GREEN}Configuration restored!${NC}"
echo ""
echo "Next steps:"
echo "  1. Update Panel .env with: APP_URL=$PANEL_URL"
echo "  2. Update Wings config with ports: $WINGS_PORT, $WINGS_SFTP_PORT"
echo "  3. Restart services"
EOF
    
    chmod +x "$CONFIG_BACKUP/RESTORE_CONFIG.sh"
    
    # Create summary
    cat > "$CONFIG_BACKUP/README.txt" <<EOF
Pterodactyl Configuration Backup
=================================
Created: $(date)
Location: $CONFIG_BACKUP

Saved Items:
  - Panel URL and domain
  - Wings ports (API and SFTP)
  - SSL certificates
  - Nginx configuration
  - Firewall rules

To restore after fresh install:
  1. Run: ./RESTORE_CONFIG.sh
  2. Or manually apply settings from saved_config.txt

Saved Configuration:
$(cat saved_config.txt)
EOF
    
    log_success "Configuration backup complete!"
    echo ""
    cat "$CONFIG_BACKUP/README.txt"
    echo ""
    
    # Now wipe everything
    log_warning "Starting clean wipe in 5 seconds... (Ctrl+C to cancel)"
    sleep 5
    
    echo ""
    log_info "Stopping services..."
    systemctl stop wings 2>/dev/null || true
    systemctl stop pteroctl 2>/dev/null || true
    systemctl stop nginx 2>/dev/null || true
    
    # Remove Panel
    if [ "$EXISTING_PANEL" = true ]; then
        log_info "Removing Panel..."
        
        # Drop database
        if [ -f "/var/www/pterodactyl/.env" ]; then
            DB_NAME=$(grep DB_DATABASE /var/www/pterodactyl/.env | cut -d '=' -f2)
            if [ -n "$DB_NAME" ]; then
                mysql -u root -e "DROP DATABASE IF EXISTS $DB_NAME;" 2>/dev/null || true
                log_success "Database dropped"
            fi
        fi
        
        # Remove Panel files
        rm -rf /var/www/pterodactyl
        log_success "Panel files removed"
    fi
    
    # Remove Wings
    if [ "$EXISTING_WINGS" = true ]; then
        log_info "Removing Wings..."
        
        # Stop and disable Wings
        systemctl disable wings 2>/dev/null || true
        rm -f /etc/systemd/system/wings.service
        systemctl daemon-reload
        
        # Remove Wings binary
        rm -f /usr/local/bin/wings
        
        # Remove Wings config
        rm -rf /etc/pterodactyl
        
        # Remove Wings data (game servers)
        log_warning "Removing all game server files..."
        rm -rf /var/lib/pterodactyl
        
        log_success "Wings removed"
    fi
    
    # Clean up Docker
    if command -v docker &> /dev/null; then
        log_info "Cleaning up Docker..."
        docker system prune -af --volumes 2>/dev/null || true
        log_success "Docker cleaned"
    fi
    
    # Remove Nginx config
    rm -f /etc/nginx/sites-available/pterodactyl.conf
    rm -f /etc/nginx/sites-enabled/pterodactyl.conf
    
    echo ""
    log_success "╔════════════════════════════════════════════════════════════════════════╗"
    log_success "║                    CLEAN WIPE COMPLETE!                                ║"
    log_success "╚════════════════════════════════════════════════════════════════════════╝"
    echo ""
    log_info "Your configuration has been saved to:"
    log_info "  $CONFIG_BACKUP"
    echo ""
    log_info "You can now proceed with a fresh installation!"
    echo ""
    
    if prompt_yes_no "Would you like to start the fresh installation now?"; then
        echo ""
        log_info "Starting fresh installation..."
        # The main script will continue
        return 0
    else
        log_info "You can run the installation later with:"
        log_info "  cd /opt/ptero && ./pteroanyinstall.sh install-full"
        echo ""
        log_info "To restore your saved configuration:"
        log_info "  cd $CONFIG_BACKUP && ./RESTORE_CONFIG.sh"
        exit 0
    fi
}

backup_and_migrate() {
    log_info "Starting backup and migration process..."
    echo ""
    
    # Ask for backup location
    read -p "Enter backup destination (e.g., /mnt/external, /backup): " BACKUP_DEST
    
    if [ -z "$BACKUP_DEST" ]; then
        BACKUP_DEST="/var/backups/pterodactyl-migration-$(date +%Y%m%d-%H%M%S)"
        log_info "Using default backup location: $BACKUP_DEST"
    fi
    
    mkdir -p "$BACKUP_DEST"
    
    log_info "Backup will be saved to: $BACKUP_DEST"
    echo ""
    
    # Backup Panel
    if [ "$EXISTING_PANEL" = true ]; then
        log_info "Backing up Panel files..."
        
        # Backup Panel directory
        if [ -d "/var/www/pterodactyl" ]; then
            tar -czf "$BACKUP_DEST/panel-files.tar.gz" -C /var/www pterodactyl
            log_success "Panel files backed up"
        fi
        
        # Backup database
        log_info "Backing up Panel database..."
        if [ -f "/var/www/pterodactyl/.env" ]; then
            DB_NAME=$(grep DB_DATABASE /var/www/pterodactyl/.env | cut -d '=' -f2)
            DB_USER=$(grep DB_USERNAME /var/www/pterodactyl/.env | cut -d '=' -f2)
            DB_PASS=$(grep DB_PASSWORD /var/www/pterodactyl/.env | cut -d '=' -f2)
            
            if [ -n "$DB_NAME" ]; then
                mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DEST/panel-database.sql"
                log_success "Database backed up"
            fi
        fi
        
        # Backup .env file
        cp /var/www/pterodactyl/.env "$BACKUP_DEST/panel.env"
        
        # Backup nginx config
        if [ -f "/etc/nginx/sites-available/pterodactyl.conf" ]; then
            cp /etc/nginx/sites-available/pterodactyl.conf "$BACKUP_DEST/nginx-panel.conf"
        fi
    fi
    
    # Backup Wings
    if [ "$EXISTING_WINGS" = true ]; then
        log_info "Backing up Wings configuration..."
        
        if [ -f "/etc/pterodactyl/config.yml" ]; then
            mkdir -p "$BACKUP_DEST/wings"
            cp /etc/pterodactyl/config.yml "$BACKUP_DEST/wings/config.yml"
            log_success "Wings config backed up"
        fi
        
        # Backup Wings data
        if [ -d "/var/lib/pterodactyl" ]; then
            log_warning "Wings data directory is large. This may take a while..."
            tar -czf "$BACKUP_DEST/wings-data.tar.gz" -C /var/lib pterodactyl
            log_success "Wings data backed up"
        fi
    fi
    
    # Create backup manifest
    cat > "$BACKUP_DEST/BACKUP_INFO.txt" <<EOF
Pterodactyl Backup Information
==============================
Backup Date: $(date)
Backup Location: $BACKUP_DEST

Contents:
EOF
    
    if [ "$EXISTING_PANEL" = true ]; then
        echo "  - Panel files (panel-files.tar.gz)" >> "$BACKUP_DEST/BACKUP_INFO.txt"
        echo "  - Panel database (panel-database.sql)" >> "$BACKUP_DEST/BACKUP_INFO.txt"
        echo "  - Panel .env (panel.env)" >> "$BACKUP_DEST/BACKUP_INFO.txt"
        echo "  - Nginx config (nginx-panel.conf)" >> "$BACKUP_DEST/BACKUP_INFO.txt"
    fi
    
    if [ "$EXISTING_WINGS" = true ]; then
        echo "  - Wings config (wings/config.yml)" >> "$BACKUP_DEST/BACKUP_INFO.txt"
        echo "  - Wings data (wings-data.tar.gz)" >> "$BACKUP_DEST/BACKUP_INFO.txt"
    fi
    
    log_success "Backup completed successfully!"
    echo ""
    log_info "Backup saved to: $BACKUP_DEST"
    log_info "Backup manifest: $BACKUP_DEST/BACKUP_INFO.txt"
    echo ""
    
    # Ask about wiping
    if prompt_yes_no "Do you want to wipe the existing Panel files and start fresh?"; then
        log_warning "Wiping existing installation..."
        
        if [ "$EXISTING_PANEL" = true ]; then
            systemctl stop nginx || true
            rm -rf /var/www/pterodactyl
            rm -f /etc/nginx/sites-enabled/pterodactyl.conf
            rm -f /etc/nginx/sites-available/pterodactyl.conf
            log_success "Panel files wiped"
        fi
        
        if [ "$EXISTING_WINGS" = true ]; then
            systemctl stop wings || true
            systemctl disable wings || true
            rm -f /etc/systemd/system/wings.service
            log_success "Wings service removed"
        fi
        
        log_success "System ready for fresh installation!"
    else
        log_info "Keeping existing files - will update in place"
    fi
}

check_cloudflare_setup() {
    log_info "Cloudflare Integration Check"
    echo ""
    log_info "EXPLANATION: Cloudflare can provide DDoS protection, CDN, and automatic SSL."
    log_info "If you use Cloudflare, we can integrate it for better security and performance."
    echo ""
    
    if prompt_yes_no "Do you already have Cloudflare set up for your domain?"; then
        CLOUDFLARE_ENABLED=true
        log_success "Great! We'll help you integrate it."
        echo ""
        log_info "You'll need:"
        log_info "  • Cloudflare API Token (Zone:DNS:Edit permission)"
        log_info "  • Zone ID (found in domain overview)"
        echo ""
        log_info "Get your API token: https://dash.cloudflare.com/profile/api-tokens"
        echo ""
        
        read -p "Press Enter when you have your API credentials ready..."
    else
        CLOUDFLARE_ENABLED=false
        log_info "No problem! You can add Cloudflare later if needed."
        echo ""
        log_info "Benefits of Cloudflare:"
        log_info "  • Free DDoS protection"
        log_info "  • Global CDN for faster loading"
        log_info "  • Automatic SSL certificates"
        log_info "  • DNS management"
        echo ""
        log_info "Visit https://cloudflare.com to sign up (free tier available)"
    fi
}

check_dns_setup() {
    log_info "DNS Configuration Check"
    echo ""
    log_info "EXPLANATION: Your domain must point to this server's IP address."
    log_info "This is required for SSL certificates and accessing your panel."
    echo ""
    
    # Get public IP
    PUBLIC_IP=$(curl -s https://api.ipify.org || curl -s https://ifconfig.me || echo "Unable to detect")
    log_info "Your server's public IP: $PUBLIC_IP"
    echo ""
    
    if prompt_yes_no "Have you already configured DNS records for your domain?"; then
        DNS_CONFIGURED=true
        log_success "Great! We'll verify the DNS records during installation."
        echo ""
        log_info "Required DNS records:"
        log_info "  Panel: A record pointing panel.yourdomain.com -> $PUBLIC_IP"
        log_info "  Wings: A record pointing node.yourdomain.com -> $PUBLIC_IP"
    else
        DNS_CONFIGURED=false
        log_warning "You need to configure DNS before continuing!"
        echo ""
        log_info "How to set up DNS:"
        echo ""
        echo "1. Log in to your domain registrar (GoDaddy, Namecheap, Cloudflare, etc.)"
        echo "2. Find DNS settings or DNS management"
        echo "3. Add A records:"
        echo ""
        echo "   Type: A"
        echo "   Name: panel (or panel.yourdomain.com)"
        echo "   Value: $PUBLIC_IP"
        echo "   TTL: 3600 (or Auto)"
        echo ""
        echo "   Type: A"
        echo "   Name: node (or node.yourdomain.com)"
        echo "   Value: $PUBLIC_IP"
        echo "   TTL: 3600 (or Auto)"
        echo ""
        log_info "DNS propagation can take 5-60 minutes"
        echo ""
        
        if prompt_yes_no "Do you want to continue anyway? (DNS will be verified later)"; then
            log_warning "Continuing - remember to configure DNS before accessing the panel!"
        else
            log_info "Please configure DNS and run this script again."
            exit 0
        fi
    fi
}

check_port_forwarding() {
    log_info "Port Forwarding Check"
    echo ""
    log_info "EXPLANATION: If you're behind a router, you need to forward ports to this server."
    log_info "This allows external access to your Pterodactyl Panel and game servers."
    echo ""
    
    if prompt_yes_no "Is this server behind a router/firewall?"; then
        BEHIND_ROUTER=true
        
        if prompt_yes_no "Have you already configured port forwarding on your router?"; then
            PORT_FORWARDING_DONE=true
            log_success "Great! Make sure these ports are forwarded:"
        else
            PORT_FORWARDING_DONE=false
            log_warning "You'll need to configure port forwarding!"
            echo ""
            
            if prompt_yes_no "Would you like a port forwarding walkthrough?"; then
                show_port_forwarding_guide
            fi
        fi
        
        echo ""
        log_info "Required ports to forward:"
        echo ""
        echo "  Panel:"
        echo "    • Port 80 (HTTP) -> This server's local IP"
        echo "    • Port 443 (HTTPS) -> This server's local IP"
        echo ""
        echo "  Wings:"
        echo "    • Port 8080 (Wings API) -> This server's local IP"
        echo "    • Port 2022 (SFTP) -> This server's local IP"
        echo ""
        echo "  Game Servers (common):"
        echo "    • Port 25565 (Minecraft)"
        echo "    • Port 27015 (Source games)"
        echo "    • Port 7777 (ARK, Rust)"
        echo "    • Ports 30000-30100 (Dynamic allocation range)"
        echo ""
    else
        BEHIND_ROUTER=false
        log_success "Server has direct internet access - no port forwarding needed!"
    fi
}

show_port_forwarding_guide() {
    cat <<'EOF'

╔════════════════════════════════════════════════════════════════════════╗
║                    PORT FORWARDING WALKTHROUGH                         ║
╚════════════════════════════════════════════════════════════════════════╝

Step 1: Find Your Router's IP Address
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Usually: 192.168.1.1 or 192.168.0.1

On Linux: ip route | grep default
On Windows: ipconfig (look for Default Gateway)

Step 2: Find This Server's Local IP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

    # Detect local IP
    LOCAL_IP=$(ip route get 1 | awk '{print $7}' | head -1)
    echo "This server's local IP: $LOCAL_IP"
    
    cat <<'EOF'

Step 3: Access Router Admin Panel
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Open web browser
2. Go to http://192.168.1.1 (or your router IP)
3. Log in (common defaults: admin/admin, admin/password)
   Check router label for credentials

Step 4: Find Port Forwarding Section
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Look for sections named:
  • Port Forwarding
  • Virtual Servers
  • NAT Forwarding
  • Applications & Gaming

Step 5: Add Port Forwarding Rules
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
For each port, create a rule:

Rule 1: HTTP
  Service Name: Pterodactyl-HTTP
  External Port: 80
  Internal Port: 80
  Internal IP: [This server's local IP]
  Protocol: TCP

Rule 2: HTTPS
  Service Name: Pterodactyl-HTTPS
  External Port: 443
  Internal Port: 443
  Internal IP: [This server's local IP]
  Protocol: TCP

Rule 3: Wings API
  Service Name: Pterodactyl-Wings
  External Port: 8080
  Internal Port: 8080
  Internal IP: [This server's local IP]
  Protocol: TCP

Rule 4: SFTP
  Service Name: Pterodactyl-SFTP
  External Port: 2022
  Internal Port: 2022
  Internal IP: [This server's local IP]
  Protocol: TCP

Rule 5: Game Servers (Port Range)
  Service Name: Game-Servers
  External Port: 25565-25665
  Internal Port: 25565-25665
  Internal IP: [This server's local IP]
  Protocol: TCP/UDP

Step 6: Save and Apply
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Save the port forwarding rules
2. Apply/Restart router if required
3. Wait 1-2 minutes for changes to take effect

Step 7: Test Port Forwarding
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
After installation, test at: https://www.yougetsignal.com/tools/open-ports/

Common Router Brands:
  • TP-Link: Advanced > NAT Forwarding > Virtual Servers
  • Netgear: Advanced > Advanced Setup > Port Forwarding
  • Linksys: Security > Apps and Gaming > Single Port Forwarding
  • ASUS: WAN > Virtual Server / Port Forwarding
  • D-Link: Advanced > Port Forwarding

Need help? Visit: https://portforward.com (router-specific guides)

EOF

    read -p "Press Enter to continue..."
}

generate_pre_install_report() {
    REPORT_FILE="/tmp/pteroanyinstall-precheck-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "$REPORT_FILE" <<EOF
Pterodactyl Pre-Installation Check Report
==========================================
Generated: $(date)

System Information:
  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d '"' -f2)
  Kernel: $(uname -r)
  Public IP: $PUBLIC_IP
  Local IP: $(ip route get 1 | awk '{print $7}' | head -1)

Checks Performed:
  Existing Installation: $([ "$EXISTING_PANEL" = true ] || [ "$EXISTING_WINGS" = true ] && echo "Found" || echo "None")
  Cloudflare Setup: $([ "$CLOUDFLARE_ENABLED" = true ] && echo "Yes" || echo "No")
  DNS Configured: $([ "$DNS_CONFIGURED" = true ] && echo "Yes" || echo "No")
  Behind Router: $([ "$BEHIND_ROUTER" = true ] && echo "Yes" || echo "No")
  Port Forwarding: $([ "$PORT_FORWARDING_DONE" = true ] && echo "Configured" || echo "Needs Setup")

Next Steps:
  1. Complete any pending configurations (DNS, port forwarding)
  2. Run the main installation script
  3. Follow the interactive prompts

Backup Location (if applicable):
  $BACKUP_DEST

EOF

    log_success "Pre-installation report saved: $REPORT_FILE"
}

main() {
    show_pre_install_banner
    
    check_existing_pterodactyl
    check_cloudflare_setup
    check_dns_setup
    check_port_forwarding
    
    echo ""
    log_success "Pre-installation checks complete!"
    echo ""
    
    generate_pre_install_report
    
    echo ""
    log_info "You're ready to proceed with installation!"
    log_info "Run: sudo ./pteroanyinstall.sh install-full"
    echo ""
}

main "$@"
