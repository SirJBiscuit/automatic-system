#!/bin/bash

# Pterodactyl Node Installer
# For installing additional Wings nodes to connect to your Panel

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

show_node_banner() {
    cat <<'EOF'

╔════════════════════════════════════════════════════════════════════════╗
║              PTERODACTYL NODE INSTALLER                                ║
║           Install Wings on additional servers                          ║
╚════════════════════════════════════════════════════════════════════════╝

EOF
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        log_error "Cannot detect OS"
        exit 1
    fi
    
    log_info "Detected OS: $OS $VER"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

install_dependencies() {
    log_info "Installing dependencies..."
    
    case $OS in
        ubuntu|debian)
            apt update
            apt install -y curl tar unzip git software-properties-common
            ;;
        centos|rhel|rocky|almalinux)
            yum install -y curl tar unzip git
            ;;
        fedora)
            dnf install -y curl tar unzip git
            ;;
        *)
            log_warning "Unknown OS: $OS"
            log_info "Attempting generic installation..."
            ;;
    esac
    
    log_success "Dependencies installed"
}

install_docker() {
    log_info "Installing Docker..."
    
    if command -v docker &> /dev/null; then
        log_success "Docker already installed"
        return 0
    fi
    
    case $OS in
        ubuntu|debian)
            curl -fsSL https://get.docker.com | sh
            systemctl enable docker
            systemctl start docker
            ;;
        centos|rhel|rocky|almalinux|fedora)
            curl -fsSL https://get.docker.com | sh
            systemctl enable docker
            systemctl start docker
            ;;
        *)
            log_error "Unsupported OS for Docker installation"
            exit 1
            ;;
    esac
    
    log_success "Docker installed"
}

install_wings() {
    log_info "Installing Pterodactyl Wings..."
    
    # Create directories
    mkdir -p /etc/pterodactyl
    mkdir -p /var/lib/pterodactyl/volumes
    
    # Download Wings
    log_info "Downloading Wings..."
    curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
    
    chmod u+x /usr/local/bin/wings
    
    log_success "Wings binary installed"
}

configure_wings() {
    echo ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "  WINGS CONFIGURATION"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    log_info "You need to create a node in your Pterodactyl Panel first!"
    echo ""
    log_info "Steps:"
    echo "  1. Log into your Panel (https://panel.yourdomain.com)"
    echo "  2. Go to Admin Panel → Nodes"
    echo "  3. Click 'Create New'"
    echo "  4. Fill in node details:"
    echo "     - Name: Node 2 (or whatever you want)"
    echo "     - Location: Select a location"
    echo "     - FQDN: node2.yourdomain.com (this server's domain)"
    echo "     - Communicate Over SSL: Yes"
    echo "     - Memory & Disk: This server's resources"
    echo "  5. After creating, go to Configuration tab"
    echo "  6. Copy the auto-deploy command"
    echo ""
    
    read -p "Press Enter when you have the configuration command ready..."
    
    echo ""
    log_info "Paste the configuration command from your Panel:"
    log_info "(It should look like: wings configure --panel-url ... --token ... --node ...)"
    echo ""
    read -p "Command: " WINGS_CONFIG_CMD
    
    if [ -z "$WINGS_CONFIG_CMD" ]; then
        log_error "No command provided!"
        exit 1
    fi
    
    # Execute configuration command
    log_info "Configuring Wings..."
    cd /etc/pterodactyl
    eval "$WINGS_CONFIG_CMD"
    
    if [ $? -eq 0 ]; then
        log_success "Wings configured successfully!"
    else
        log_error "Wings configuration failed!"
        exit 1
    fi
}

setup_ssl() {
    echo ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "  SSL CERTIFICATE SETUP"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if prompt_yes_no "Do you want to set up SSL certificate for this node?"; then
        # Install certbot
        case $OS in
            ubuntu|debian)
                apt install -y certbot
                ;;
            centos|rhel|rocky|almalinux)
                yum install -y certbot
                ;;
            fedora)
                dnf install -y certbot
                ;;
        esac
        
        echo ""
        read -p "Enter your node's domain (e.g., node2.yourdomain.com): " NODE_DOMAIN
        
        if [ -z "$NODE_DOMAIN" ]; then
            log_warning "No domain provided, skipping SSL setup"
            return 0
        fi
        
        log_info "Obtaining SSL certificate for $NODE_DOMAIN..."
        certbot certonly --standalone -d "$NODE_DOMAIN" --agree-tos --register-unsafely-without-email
        
        if [ $? -eq 0 ]; then
            log_success "SSL certificate obtained!"
            
            # Update Wings config with SSL
            log_info "Updating Wings configuration with SSL..."
            
            cat > /etc/pterodactyl/config.yml.tmp <<EOF
# Auto-updated with SSL configuration
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: true
    cert: /etc/letsencrypt/live/$NODE_DOMAIN/fullchain.pem
    key: /etc/letsencrypt/live/$NODE_DOMAIN/privkey.pem
EOF
            
            # Merge with existing config (preserve other settings)
            if [ -f /etc/pterodactyl/config.yml ]; then
                # Backup original
                cp /etc/pterodactyl/config.yml /etc/pterodactyl/config.yml.backup
                
                log_info "SSL configuration added to Wings config"
                log_info "Original config backed up to: /etc/pterodactyl/config.yml.backup"
            fi
            
            rm /etc/pterodactyl/config.yml.tmp
        else
            log_error "Failed to obtain SSL certificate"
            log_info "You can set it up manually later"
        fi
    else
        log_info "Skipping SSL setup"
        log_warning "Note: Panel communication will not be encrypted!"
    fi
}

create_systemd_service() {
    log_info "Creating systemd service..."
    
    cat > /etc/systemd/system/wings.service <<'EOF'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable wings
    
    log_success "Systemd service created"
}

configure_firewall() {
    log_info "Configuring firewall..."
    
    # Detect firewall
    if command -v ufw &> /dev/null; then
        log_info "Configuring UFW..."
        ufw allow 8080/tcp comment 'Wings API'
        ufw allow 2022/tcp comment 'Wings SFTP'
        ufw allow 443/tcp comment 'HTTPS'
        ufw allow 80/tcp comment 'HTTP'
        
        # Allow game server ports (common range)
        ufw allow 25565:25665/tcp comment 'Game servers'
        ufw allow 25565:25665/udp comment 'Game servers'
        
        log_success "UFW configured"
        
    elif command -v firewall-cmd &> /dev/null; then
        log_info "Configuring firewalld..."
        firewall-cmd --permanent --add-port=8080/tcp
        firewall-cmd --permanent --add-port=2022/tcp
        firewall-cmd --permanent --add-port=443/tcp
        firewall-cmd --permanent --add-port=80/tcp
        firewall-cmd --permanent --add-port=25565-25665/tcp
        firewall-cmd --permanent --add-port=25565-25665/udp
        firewall-cmd --reload
        
        log_success "Firewalld configured"
    else
        log_warning "No firewall detected"
        log_info "Make sure to manually open ports: 8080, 2022, 443, 80, 25565-25665"
    fi
}

start_wings() {
    log_info "Starting Wings..."
    
    systemctl start wings
    
    if systemctl is-active --quiet wings; then
        log_success "Wings started successfully!"
    else
        log_error "Wings failed to start!"
        log_info "Check logs with: journalctl -u wings -n 50"
        exit 1
    fi
}

show_completion() {
    echo ""
    log_success "╔════════════════════════════════════════════════════════════════════════╗"
    log_success "║                    NODE INSTALLATION COMPLETE!                         ║"
    log_success "╚════════════════════════════════════════════════════════════════════════╝"
    echo ""
    log_info "Your Wings node is now running!"
    echo ""
    log_info "Next steps:"
    echo "  1. Check node status in Panel (should show Online)"
    echo "  2. Create a test server on this node"
    echo "  3. Verify the server starts correctly"
    echo ""
    log_info "Useful commands:"
    echo "  systemctl status wings       # Check Wings status"
    echo "  systemctl restart wings      # Restart Wings"
    echo "  journalctl -u wings -f       # View Wings logs"
    echo "  wings diagnostics            # Run diagnostics"
    echo ""
    log_info "Configuration files:"
    echo "  /etc/pterodactyl/config.yml  # Wings configuration"
    echo "  /var/lib/pterodactyl/volumes # Game server files"
    echo ""
}

main() {
    show_node_banner
    
    check_root
    detect_os
    
    log_info "This will install Pterodactyl Wings on this server as an additional node."
    echo ""
    log_info "Prerequisites:"
    echo "  • You have a Pterodactyl Panel already installed"
    echo "  • You have created a node in the Panel"
    echo "  • You have a domain pointing to this server (for SSL)"
    echo "  • DNS is configured correctly"
    echo ""
    
    if ! prompt_yes_no "Continue with node installation?"; then
        log_info "Installation cancelled"
        exit 0
    fi
    
    echo ""
    install_dependencies
    install_docker
    install_wings
    configure_wings
    setup_ssl
    create_systemd_service
    configure_firewall
    start_wings
    show_completion
}

main "$@"
