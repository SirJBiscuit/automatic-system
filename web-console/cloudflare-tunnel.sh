#!/bin/bash

# Cloudflare Tunnel Setup for Web Console
# Enables secure remote access via custom domain

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}✗ This script must be run as root${NC}" 
   exit 1
fi

echo ""
echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║          Cloudflare Tunnel Setup                           ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo -e "${BLUE}[1/5]${NC} Installing Cloudflare Tunnel (cloudflared)..."
    
    # Add Cloudflare GPG key and repository
    mkdir -p /usr/share/keyrings
    curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
    
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflared.list
    
    apt-get update
    apt-get install -y cloudflared
    
    echo -e "${GREEN}✓ Cloudflared installed${NC}"
else
    echo -e "${GREEN}✓ Cloudflared already installed${NC}"
fi

echo ""
echo -e "${BLUE}[2/5]${NC} Domain Configuration"
echo ""
echo -e "${YELLOW}Enter your domain information:${NC}"
echo ""

# Get subdomain
read -p "Enter subdomain (e.g., 'web' for web.cloudmc.online): " SUBDOMAIN
while [[ -z "$SUBDOMAIN" ]]; do
    echo -e "${RED}✗ Subdomain cannot be empty!${NC}"
    read -p "Enter subdomain: " SUBDOMAIN
done

# Get domain
read -p "Enter your domain (e.g., 'cloudmc.online'): " DOMAIN
while [[ -z "$DOMAIN" ]]; do
    echo -e "${RED}✗ Domain cannot be empty!${NC}"
    read -p "Enter your domain: " DOMAIN
done

FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"

echo ""
echo -e "${GREEN}✓ Will configure: ${CYAN}https://$FULL_DOMAIN${NC}"
echo ""

# Check if tunnel already exists
TUNNEL_NAME="pterodactyl-web-console"
TUNNEL_ID=$(cloudflared tunnel list 2>/dev/null | grep "$TUNNEL_NAME" | awk '{print $1}' || echo "")

if [[ -z "$TUNNEL_ID" ]]; then
    echo -e "${BLUE}[3/5]${NC} Authenticating with Cloudflare..."
    echo ""
    echo -e "${YELLOW}A browser window will open for authentication.${NC}"
    echo -e "${YELLOW}Please log in to your Cloudflare account.${NC}"
    echo ""
    read -p "Press Enter to continue..."
    
    cloudflared tunnel login
    
    echo ""
    echo -e "${GREEN}✓ Authenticated with Cloudflare${NC}"
    echo ""
    
    echo -e "${BLUE}[4/5]${NC} Creating tunnel..."
    cloudflared tunnel create "$TUNNEL_NAME"
    
    TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
    echo -e "${GREEN}✓ Tunnel created: $TUNNEL_ID${NC}"
else
    echo -e "${GREEN}✓ Tunnel already exists: $TUNNEL_ID${NC}"
fi

echo ""
echo -e "${BLUE}[5/5]${NC} Configuring tunnel..."

# Create config directory
mkdir -p /root/.cloudflared

# Create tunnel configuration
cat > /root/.cloudflared/config.yml <<EOF
tunnel: $TUNNEL_ID
credentials-file: /root/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: $FULL_DOMAIN
    service: http://localhost:8080
  - service: http_status:404
EOF

echo -e "${GREEN}✓ Configuration created${NC}"

# Configure DNS
echo ""
echo -e "${CYAN}Configuring DNS...${NC}"
cloudflared tunnel route dns "$TUNNEL_NAME" "$FULL_DOMAIN"

echo -e "${GREEN}✓ DNS configured${NC}"

# Create systemd service
echo ""
echo -e "${CYAN}Creating systemd service...${NC}"

cat > /etc/systemd/system/cloudflared-webconsole.service <<EOF
[Unit]
Description=Cloudflare Tunnel for Pterodactyl Web Console
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/cloudflared tunnel --config /root/.cloudflared/config.yml run
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable cloudflared-webconsole
systemctl start cloudflared-webconsole

echo -e "${GREEN}✓ Service started${NC}"

# Wait a moment for tunnel to establish
sleep 3

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Cloudflare Tunnel configured successfully!            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                 Access Information                         ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}🌐 Your web console is now accessible at:${NC}"
echo -e "  ${GREEN}https://$FULL_DOMAIN${NC}"
echo ""
echo -e "${YELLOW}🔒 Features:${NC}"
echo -e "  ${GREEN}✓${NC} Automatic HTTPS"
echo -e "  ${GREEN}✓${NC} Access from anywhere"
echo -e "  ${GREEN}✓${NC} DDoS protection"
echo -e "  ${GREEN}✓${NC} No port forwarding needed"
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                 Service Management                         ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${YELLOW}Check status:${NC}   systemctl status cloudflared-webconsole"
echo -e "  ${YELLOW}View logs:${NC}      journalctl -u cloudflared-webconsole -f"
echo -e "  ${YELLOW}Restart:${NC}        systemctl restart cloudflared-webconsole"
echo -e "  ${YELLOW}Stop:${NC}           systemctl stop cloudflared-webconsole"
echo ""
echo -e "${YELLOW}Note:${NC} DNS propagation may take a few minutes."
echo -e "      If the site doesn't load immediately, wait 2-5 minutes and try again."
echo ""
