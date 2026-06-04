#!/bin/bash

#######################################
# Enhanced SSH Terminal Security Configuration
# - Disable Termux tunnel
# - Add password protection to term tunnel
# - Fix wireless access for ssh.cloudmc.online
#######################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  SSH Terminal Security Configuration  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}✗ Please run as root (use sudo)${NC}"
    exit 1
fi

#######################################
# 1. DISABLE TERMUX TUNNEL
#######################################
echo -e "${YELLOW}➜ Disabling Termux tunnel...${NC}"

# Find and kill any Termux/ttyd processes on non-standard ports
pkill -f "termux.*tunnel" 2>/dev/null || true
pkill -f "cloudflared.*termux" 2>/dev/null || true

# Block Termux tunnel ports in firewall
if command -v ufw &> /dev/null; then
    # Remove any Termux-related rules
    ufw delete allow 8022 2>/dev/null || true
    ufw delete allow 8023 2>/dev/null || true
    ufw reload
    echo -e "${GREEN}✓ Termux tunnel ports blocked in UFW${NC}"
fi

# Check for Cloudflare tunnels and list them
if command -v cloudflared &> /dev/null; then
    echo -e "${YELLOW}  Checking for Cloudflare tunnels...${NC}"
    cloudflared tunnel list 2>/dev/null || true
    echo -e "${YELLOW}  To delete a tunnel: cloudflared tunnel delete <tunnel-name>${NC}"
fi

echo -e "${GREEN}✓ Termux tunnel disabled${NC}"

#######################################
# 2. ADD PASSWORD PROTECTION TO TERM TUNNEL
#######################################
echo -e "${YELLOW}➜ Adding password protection to term.cloudmc.online...${NC}"

# Generate random password if not provided
TERM_PASSWORD="${TERM_PASSWORD:-$(openssl rand -base64 16)}"

# Create htpasswd file for basic auth
apt-get install -y apache2-utils 2>/dev/null || yum install -y httpd-tools 2>/dev/null

# Create password file
mkdir -p /etc/nginx/auth
htpasswd -bc /etc/nginx/auth/term.htpasswd admin "$TERM_PASSWORD"

echo -e "${GREEN}✓ Password file created${NC}"
echo -e "${BLUE}  Username: admin${NC}"
echo -e "${BLUE}  Password: $TERM_PASSWORD${NC}"
echo -e "${YELLOW}  Save this password! It's stored in: /etc/nginx/auth/term.htpasswd${NC}"

# Add rate limiting zone to main nginx config if not exists
if ! grep -q "limit_req_zone.*term_login" /etc/nginx/nginx.conf; then
    sed -i '/http {/a \    # Rate limiting for term.cloudmc.online\n    limit_req_zone $binary_remote_addr zone=term_login:10m rate=5r/m;' /etc/nginx/nginx.conf
fi

# Update Nginx config for term.cloudmc.online with auth
cat > /etc/nginx/sites-available/ssh-terminal << 'NGINX_EOF'
server {
    listen 8095;
    listen [::]:8095;
    
    server_name term.cloudmc.online;
    root /var/www/ssh-terminal;
    index index.html;
    
    # Basic Authentication - Password protection
    auth_basic "Restricted Access - Admin Only";
    auth_basic_user_file /etc/nginx/auth/term.htpasswd;
    
    # Security headers
    add_header X-Frame-Options "ALLOW-FROM https://ssh.cloudmc.online" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    
    # Content Security Policy
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com; font-src 'self' https://cdnjs.cloudflare.com data:; img-src 'self' data: https:; connect-src 'self' https://ui.cloudmc.online https://ssh.cloudmc.online ws://localhost:7681 wss://localhost:7681 ws://term.cloudmc.online:7681 wss://term.cloudmc.online:7681; frame-ancestors 'self' https://ssh.cloudmc.online;" always;
    
    # CORS headers - Only allow ssh.cloudmc.online
    add_header Access-Control-Allow-Origin "https://ssh.cloudmc.online" always;
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
    add_header Access-Control-Allow-Credentials "true" always;
    
    # Disable server tokens
    server_tokens off;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # Rate limit login attempts
    location ~ /login {
        limit_req zone=term_login burst=3 nodelay;
        try_files $uri $uri/ =404;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # WebSocket proxy for ttyd (terminal)
    location /ws {
        proxy_pass http://localhost:7681;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_EOF

echo -e "${GREEN}✓ Nginx config updated with password protection${NC}"

#######################################
# 3. FIX WIRELESS ACCESS FOR SSH.CLOUDMC.ONLINE
#######################################
echo -e "${YELLOW}➜ Fixing wireless access for ssh.cloudmc.online...${NC}"

# The "insecure connection" error is usually due to:
# 1. Missing SSL certificate
# 2. Self-signed certificate
# 3. HTTP instead of HTTPS

# Check if Cloudflare tunnel is being used
if systemctl is-active --quiet cloudflared; then
    echo -e "${GREEN}✓ Cloudflare tunnel is active (provides SSL automatically)${NC}"
else
    echo -e "${YELLOW}  Cloudflare tunnel not detected${NC}"
    echo -e "${YELLOW}  Installing/configuring Cloudflare tunnel for secure access...${NC}"
    
    # Install cloudflared if not present
    if ! command -v cloudflared &> /dev/null; then
        wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
        dpkg -i cloudflared-linux-amd64.deb || apt-get install -f -y
        rm cloudflared-linux-amd64.deb
    fi
    
    echo -e "${BLUE}  Cloudflared installed${NC}"
    echo -e "${YELLOW}  To configure Cloudflare tunnel:${NC}"
    echo -e "${YELLOW}  1. Run: cloudflared tunnel login${NC}"
    echo -e "${YELLOW}  2. Run: cloudflared tunnel create ssh-terminal${NC}"
    echo -e "${YELLOW}  3. Configure tunnel to point to localhost:8095${NC}"
fi

# Allow admin to connect from anywhere
echo -e "${YELLOW}➜ Configuring firewall for admin access...${NC}"

if command -v ufw &> /dev/null; then
    # Allow SSH from anywhere (for admin)
    ufw allow 22/tcp comment 'SSH - Admin access from anywhere'
    
    # Allow HTTPS from anywhere (for web access)
    ufw allow 443/tcp comment 'HTTPS - Secure web access'
    ufw allow 80/tcp comment 'HTTP - Redirect to HTTPS'
    
    # Allow term.cloudmc.online port (with password protection)
    ufw allow 8095/tcp comment 'term.cloudmc.online - Password protected'
    
    ufw reload
    echo -e "${GREEN}✓ Firewall configured for admin access${NC}"
fi

# Create Nginx config for ssh.cloudmc.online with HTTPS redirect
cat > /etc/nginx/sites-available/ssh-cloudmc << 'NGINX_SSH_EOF'
# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name ssh.cloudmc.online;
    
    # Redirect all HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

# HTTPS server (requires SSL certificate)
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ssh.cloudmc.online;
    
    # SSL certificate paths (update these with your actual cert paths)
    # If using Cloudflare tunnel, this is handled automatically
    # If using Let's Encrypt:
    # ssl_certificate /etc/letsencrypt/live/ssh.cloudmc.online/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/ssh.cloudmc.online/privkey.pem;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    root /var/www/ssh-cloudmc;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # Embed term.cloudmc.online
    location /terminal {
        proxy_pass http://term.cloudmc.online:8095;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_SSH_EOF

# Enable the config
ln -sf /etc/nginx/sites-available/ssh-cloudmc /etc/nginx/sites-enabled/

echo -e "${GREEN}✓ SSH.cloudmc.online configured with HTTPS redirect${NC}"

# Test Nginx configuration
nginx -t

if [ $? -eq 0 ]; then
    systemctl reload nginx
    echo -e "${GREEN}✓ Nginx reloaded successfully${NC}"
else
    echo -e "${RED}✗ Nginx configuration error - please check${NC}"
    exit 1
fi

#######################################
# SUMMARY
#######################################
echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Configuration Complete         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓ Termux tunnel disabled${NC}"
echo -e "${GREEN}✓ term.cloudmc.online password protected${NC}"
echo -e "${GREEN}✓ Firewall configured for admin access${NC}"
echo -e "${GREEN}✓ HTTPS redirect configured${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT CREDENTIALS:${NC}"
echo -e "${BLUE}  term.cloudmc.online${NC}"
echo -e "${BLUE}  Username: admin${NC}"
echo -e "${BLUE}  Password: $TERM_PASSWORD${NC}"
echo ""
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo -e "  1. Save the password above"
echo -e "  2. Configure SSL certificate for ssh.cloudmc.online"
echo -e "     Option A: Use Cloudflare tunnel (automatic SSL)"
echo -e "     Option B: Use Let's Encrypt: certbot --nginx -d ssh.cloudmc.online"
echo -e "  3. Test wireless access to https://ssh.cloudmc.online"
echo ""
echo -e "${YELLOW}To change term.cloudmc.online password:${NC}"
echo -e "  htpasswd /etc/nginx/auth/term.htpasswd admin"
echo ""
