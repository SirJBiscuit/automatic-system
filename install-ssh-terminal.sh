#!/bin/bash

#######################################
# Enhanced SSH Terminal Installation
# Part of automatic-system installer
#######################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
INSTALL_DIR="/var/www/ssh-terminal"
BACKUP_DIR="/var/backups/ssh-terminal"
NGINX_CONF="/etc/nginx/sites-available/ssh-terminal"
SERVICE_PORT="8095"
TTYD_PORT="7681"
REPO_URL="https://github.com/SirJBiscuit/automatic-system.git"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

output() {
    echo -e "${GREEN}[SSH Terminal]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
   exit 1
fi

output "Starting Enhanced SSH Terminal installation..."

# Install dependencies
install_dependencies() {
    output "Installing dependencies..."
    
    apt-get update -qq
    apt-get install -y nginx curl wget git || true
    
    output "Dependencies installed (ttyd will be installed separately)"
}

# Install ttyd if not present
install_ttyd() {
    if ! command -v ttyd &> /dev/null; then
        output "Installing ttyd..."
        
        # Get latest ttyd release
        output "Fetching latest ttyd version..."
        TTYD_VERSION=$(curl -s https://api.github.com/repos/tsl0922/ttyd/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
        output "Latest version: $TTYD_VERSION"
        
        TTYD_URL="https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.x86_64"
        
        output "Downloading ttyd..."
        wget "$TTYD_URL" -O /usr/local/bin/ttyd
        chmod +x /usr/local/bin/ttyd
        
        output "ttyd installed: $TTYD_VERSION"
    else
        output "ttyd already installed"
    fi
}

# Create ttyd systemd service
create_ttyd_service() {
    output "Creating ttyd service..."
    
    cat > /etc/systemd/system/ttyd.service << 'EOF'
[Unit]
Description=ttyd - Terminal over HTTP
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/ttyd -p 7681 -W bash
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    output "Reloading systemd daemon..."
    systemctl daemon-reload
    
    output "Enabling ttyd service..."
    systemctl enable ttyd
    
    output "Starting ttyd service..."
    systemctl start ttyd
    
    output "ttyd service created and started"
}

# Create backup
create_backup() {
    if [ -d "$INSTALL_DIR" ]; then
        output "Creating backup..."
        mkdir -p "$BACKUP_DIR"
        tar -czf "$BACKUP_DIR/backup_$TIMESTAMP.tar.gz" -C "$(dirname $INSTALL_DIR)" "$(basename $INSTALL_DIR)" 2>/dev/null || true
        
        # Keep only last 5 backups
        cd "$BACKUP_DIR"
        ls -t backup_*.tar.gz 2>/dev/null | tail -n +6 | xargs -r rm
        
        output "Backup created"
    fi
}

# Deploy application files
deploy_files() {
    output "Deploying application files..."
    
    # Create installation directory
    output "Creating installation directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    
    # Clone or copy files
    if [ -d "/tmp/automatic-system/web-terminal" ]; then
        output "Copying files from /tmp/automatic-system/web-terminal..."
        cp -r /tmp/automatic-system/web-terminal/* "$INSTALL_DIR/"
    elif [ -d "$(dirname $0)/web-terminal" ]; then
        output "Copying files from $(dirname $0)/web-terminal..."
        cp -r "$(dirname $0)/web-terminal"/* "$INSTALL_DIR/"
    else
        error "Source files not found"
        return 1
    fi
    
    # Set permissions
    output "Setting file permissions..."
    chown -R www-data:www-data "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"
    chmod 644 "$INSTALL_DIR"/*.html "$INSTALL_DIR"/*.json 2>/dev/null || true
    
    output "Files deployed successfully"
}

# Configure Nginx
configure_nginx() {
    output "Configuring Nginx..."
    
    output "Creating Nginx configuration file..."
    cat > "$NGINX_CONF" << 'EOF'
server {
    listen 8095;
    listen [::]:8095;
    
    server_name _;
    root /var/www/ssh-terminal;
    index index.html;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    
    # Content Security Policy
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com; font-src 'self' https://cdnjs.cloudflare.com data:; img-src 'self' data: https:; connect-src 'self' https://ui.cloudmc.online ws://localhost:7681 wss://localhost:7681; frame-ancestors 'self';" always;
    
    # Disable server tokens
    server_tokens off;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=sshterminal_login:10m rate=5r/m;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # Rate limit login attempts
    location ~ /login {
        limit_req zone=sshterminal_login burst=3 nodelay;
        try_files $uri $uri/ =404;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Deny access to backup files
    location ~ ~$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;
}
EOF

    # Enable site
    output "Enabling Nginx site..."
    ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/ssh-terminal
    
    # Test nginx configuration
    output "Testing Nginx configuration..."
    if nginx -t 2>&1; then
        output "Reloading Nginx..."
        systemctl reload nginx
        output "Nginx configured successfully"
    else
        error "Nginx configuration test failed"
        return 1
    fi
}

# Configure firewall
configure_firewall() {
    output "Configuring firewall..."
    
    # Use firewall-manager if available
    if [ -f "$(dirname $0)/firewall-manager.sh" ]; then
        bash "$(dirname $0)/firewall-manager.sh" add ssh-terminal
    elif command -v ufw &> /dev/null; then
        ufw allow $SERVICE_PORT/tcp comment 'SSH Terminal' > /dev/null 2>&1
        ufw allow $TTYD_PORT/tcp comment 'ttyd' > /dev/null 2>&1
    fi
    
    output "Firewall configured"
}

# Verify installation
verify_installation() {
    output "Verifying installation..."
    
    output "Waiting for services to start..."
    sleep 2
    
    # Check if service is responding
    output "Testing HTTP endpoint on port $SERVICE_PORT..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$SERVICE_PORT)
    
    if echo "$HTTP_CODE" | grep -q "200"; then
        output "✓ Installation verified successfully (HTTP $HTTP_CODE)"
        return 0
    else
        error "✗ Installation verification failed (HTTP $HTTP_CODE)"
        return 1
    fi
}

# Display summary
show_summary() {
    local SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Enhanced SSH Terminal Installed Successfully!       ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}📍 Installation Directory:${NC} $INSTALL_DIR"
    echo -e "${BLUE}📦 Backup Directory:${NC} $BACKUP_DIR"
    echo -e "${BLUE}🌐 Access URL:${NC} http://$SERVER_IP:$SERVICE_PORT"
    echo -e "${BLUE}🔌 ttyd Port:${NC} $TTYD_PORT"
    echo -e "${BLUE}🔒 Security:${NC} Enabled (CSP, XSS, Rate Limiting)"
    echo ""
    echo -e "${YELLOW}⚠️  Important Next Steps:${NC}"
    echo -e "  1. Access the URL above in your browser"
    echo -e "  2. Set a strong admin password on first login"
    echo -e "  3. Configure your SSH servers in the interface"
    echo -e "  4. Consider enabling HTTPS with SSL certificate"
    echo ""
    echo -e "${GREEN}✓ Ready to use!${NC}"
    echo ""
}

# Main installation flow
main() {
    install_dependencies
    install_ttyd
    create_ttyd_service
    create_backup
    deploy_files
    configure_nginx
    configure_firewall
    
    if verify_installation; then
        show_summary
        exit 0
    else
        error "Installation failed"
        exit 1
    fi
}

# Run main function
main
