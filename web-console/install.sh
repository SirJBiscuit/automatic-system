#!/bin/bash

# Pterodactyl Web Console Installer
# This script installs the web-based console for Pterodactyl server management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}║         ${PURPLE}Pterodactyl Web Console Installer${CYAN}                 ║${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}║  ${GREEN}Professional Web Dashboard for Server Management${CYAN}       ║${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Features:${NC}"
echo -e "  ${GREEN}✓${NC} Real-time server monitoring"
echo -e "  ${GREEN}✓${NC} File manager with editor"
echo -e "  ${GREEN}✓${NC} Scheduled actions"
echo -e "  ${GREEN}✓${NC} GPU monitoring support"
echo -e "  ${GREEN}✓${NC} Mobile-responsive design"
echo -e "  ${GREEN}✓${NC} Professional UI with animations"
echo -e "  ${GREEN}✓${NC} Tabbed navigation"
echo -e "  ${GREEN}✓${NC} Device detection"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}✗ This script must be run as root${NC}" 
   exit 1
fi

# Ask for confirmation
echo -e "${YELLOW}Do you want to install the Pterodactyl Web Console? (y/n)${NC}"
read -p "> " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installation cancelled.${NC}"
    exit 0
fi

# Install dependencies
echo -e "${BLUE}[1/7]${NC} Installing system dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv nginx

# Create directory
WEB_DIR="/opt/pterodactyl-web-console"
echo -e "${BLUE}[2/7]${NC} Creating web console directory: ${GREEN}$WEB_DIR${NC}"
mkdir -p $WEB_DIR
cd $WEB_DIR

# Download files
echo -e "${BLUE}[3/7]${NC} Downloading web console files..."
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/web-console/app.py -o app.py
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/web-console/requirements.txt -o requirements.txt
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/web-console/.env.example -o .env.example

# Create templates directory
mkdir -p templates
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/web-console/templates/dashboard.html -o templates/dashboard.html
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/web-console/templates/login.html -o templates/login.html

# Install Python packages
echo -e "${BLUE}[4/7]${NC} Installing Python packages..."
pip3 install -r requirements.txt

# Create .env file
if [ ! -f .env ]; then
    echo -e "${BLUE}[5/7]${NC} Creating .env configuration file..."
    cp .env.example .env
    
    # Generate secret key
    SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
    sed -i "s/your_secret_key_here/$SECRET_KEY/" .env
    
    echo ""
    echo -e "${YELLOW}⚠ Please configure the .env file with your credentials:${NC}"
    echo ""
    echo "  1. Pterodactyl URL and API Key"
    echo "  2. Web console username and password"
    echo ""
    
    read -p "Press Enter to edit .env file..."
    nano .env
else
    echo -e "${GREEN}✓ .env file already exists${NC}"
fi

# Create systemd service
echo -e "${BLUE}[6/7]${NC} Creating systemd service..."
cat > /etc/systemd/system/pterodactyl-web-console.service <<EOF
[Unit]
Description=Pterodactyl Web Console
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$WEB_DIR
EnvironmentFile=$WEB_DIR/.env
ExecStart=/usr/bin/python3 $WEB_DIR/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Configure Nginx
echo -e "${BLUE}[7/7]${NC} Configuring Nginx reverse proxy..."
cat > /etc/nginx/sites-available/pterodactyl-web-console <<EOF
server {
    listen 8080;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /socket.io {
        proxy_pass http://127.0.0.1:5000/socket.io;
        proxy_http_version 1.1;
        proxy_buffering off;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

ln -sf /etc/nginx/sites-available/pterodactyl-web-console /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# Enable and start service
echo -e "${GREEN}Starting web console service...${NC}"
systemctl daemon-reload
systemctl enable pterodactyl-web-console
systemctl start pterodactyl-web-console

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Web Console installed successfully!                   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Web Console Status:${NC}"
systemctl status pterodactyl-web-console --no-pager
echo ""
echo -e "${CYAN}Access your web console at:${NC}"
echo -e "  ${GREEN}http://YOUR_SERVER_IP:8080${NC}"
echo ""
echo -e "${YELLOW}Default credentials (change in .env):${NC}"
echo -e "  Username: ${PURPLE}admin${NC}"
echo -e "  Password: ${PURPLE}changeme123${NC}"
echo ""
echo -e "${CYAN}Useful commands:${NC}"
echo "  • View logs: journalctl -u pterodactyl-web-console -f"
echo "  • Restart: systemctl restart pterodactyl-web-console"
echo "  • Edit config: nano $WEB_DIR/.env"
echo ""
echo -e "${GREEN}✅ Setup complete! 🎉${NC}"
echo ""
