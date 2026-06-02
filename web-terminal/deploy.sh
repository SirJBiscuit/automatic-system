#!/bin/bash

#######################################
# Enhanced SSH Terminal Deployment Script
# Secure deployment with backup and rollback
#######################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEPLOY_DIR="/var/www/ssh-terminal"
BACKUP_DIR="/var/backups/ssh-terminal"
NGINX_CONF="/etc/nginx/sites-available/ssh-terminal"
SERVICE_PORT="8095"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Enhanced SSH Terminal Deployment     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}✗ This script must be run as root${NC}"
   exit 1
fi

# Function to create backup
create_backup() {
    echo -e "${YELLOW}➜ Creating backup...${NC}"
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    # Backup existing installation
    if [ -d "$DEPLOY_DIR" ]; then
        BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"
        tar -czf "$BACKUP_FILE" -C "$(dirname $DEPLOY_DIR)" "$(basename $DEPLOY_DIR)" 2>/dev/null || true
        echo -e "${GREEN}✓ Backup created: $BACKUP_FILE${NC}"
        
        # Keep only last 5 backups
        cd "$BACKUP_DIR"
        ls -t backup_*.tar.gz | tail -n +6 | xargs -r rm
        echo -e "${GREEN}✓ Old backups cleaned (kept last 5)${NC}"
    else
        echo -e "${YELLOW}! No existing installation to backup${NC}"
    fi
}

# Function to rollback
rollback() {
    echo -e "${RED}✗ Deployment failed! Rolling back...${NC}"
    
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null | head -1)
    
    if [ -n "$LATEST_BACKUP" ]; then
        rm -rf "$DEPLOY_DIR"
        tar -xzf "$LATEST_BACKUP" -C "$(dirname $DEPLOY_DIR)"
        echo -e "${GREEN}✓ Rolled back to: $LATEST_BACKUP${NC}"
        systemctl restart nginx
    else
        echo -e "${RED}✗ No backup found for rollback${NC}"
    fi
    
    exit 1
}

# Trap errors and rollback
trap rollback ERR

# Create backup
create_backup

# Stop nginx temporarily
echo -e "${YELLOW}➜ Stopping nginx...${NC}"
systemctl stop nginx

# Create deployment directory
echo -e "${YELLOW}➜ Preparing deployment directory...${NC}"
mkdir -p "$DEPLOY_DIR"

# Copy files
echo -e "${YELLOW}➜ Copying files...${NC}"
cp -r index.html "$DEPLOY_DIR/"
cp -r ai-context.json "$DEPLOY_DIR/" 2>/dev/null || echo -e "${YELLOW}! ai-context.json not found, skipping${NC}"

# Set proper permissions
echo -e "${YELLOW}➜ Setting permissions...${NC}"
chown -R www-data:www-data "$DEPLOY_DIR"
chmod -R 755 "$DEPLOY_DIR"
chmod 644 "$DEPLOY_DIR"/*.html "$DEPLOY_DIR"/*.json 2>/dev/null || true

# Configure Nginx with security headers
echo -e "${YELLOW}➜ Configuring Nginx...${NC}"
cat > "$NGINX_CONF" << 'EOF'
server {
    listen 8095;
    listen [::]:8095;
    
    server_name _;
    root /var/www/ssh-terminal;
    index index.html;
    
    # Security headers
    add_header X-Frame-Options "ALLOW-FROM https://ssh.cloudmc.online" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    
    # Content Security Policy - Allow embedding from ssh.cloudmc.online and API calls to ui.cloudmc.online
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com; font-src 'self' https://cdnjs.cloudflare.com data:; img-src 'self' data: https:; connect-src 'self' https://ui.cloudmc.online https://ssh.cloudmc.online ws://localhost:7681 wss://localhost:7681 ws://term.cloudmc.online:7681 wss://term.cloudmc.online:7681; frame-ancestors 'self' https://ssh.cloudmc.online;" always;
    
    # CORS headers for API access
    add_header Access-Control-Allow-Origin "https://ssh.cloudmc.online" always;
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
    add_header Access-Control-Allow-Credentials "true" always;
    
    # Disable server tokens
    server_tokens off;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # Rate limit login attempts
    location ~ /login {
        limit_req zone=login burst=3 nodelay;
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
ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/ssh-terminal 2>/dev/null || true

# Test nginx configuration
echo -e "${YELLOW}➜ Testing Nginx configuration...${NC}"
nginx -t

# Configure firewall
echo -e "${YELLOW}➜ Configuring firewall...${NC}"
if command -v ufw &> /dev/null; then
    ufw allow $SERVICE_PORT/tcp comment 'SSH Terminal'
    echo -e "${GREEN}✓ Firewall rule added${NC}"
fi

# Start nginx
echo -e "${YELLOW}➜ Starting nginx...${NC}"
systemctl start nginx
systemctl enable nginx

# Verify deployment
echo -e "${YELLOW}➜ Verifying deployment...${NC}"
sleep 2

if curl -s -o /dev/null -w "%{http_code}" http://localhost:$SERVICE_PORT | grep -q "200"; then
    echo -e "${GREEN}✓ Deployment successful!${NC}"
else
    echo -e "${RED}✗ Deployment verification failed${NC}"
    rollback
fi

# Display summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Deployment Completed Successfully  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📍 Deployment Directory:${NC} $DEPLOY_DIR"
echo -e "${BLUE}📦 Backup Location:${NC} $BACKUP_DIR"
echo -e "${BLUE}🌐 Access URL:${NC} http://YOUR_SERVER_IP:$SERVICE_PORT"
echo -e "${BLUE}🔒 Security:${NC} Enabled (CSP, XSS Protection, Rate Limiting)"
echo ""
echo -e "${YELLOW}⚠️  Important:${NC}"
echo -e "  1. Set a strong admin password on first login"
echo -e "  2. Configure firewall rules for your network"
echo -e "  3. Consider using HTTPS with SSL certificate"
echo -e "  4. Backups are stored in: $BACKUP_DIR"
echo ""
echo -e "${GREEN}✓ Ready to use!${NC}"
