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
GRAY='\033[0;90m'
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

# Create and activate virtual environment
echo -e "${BLUE}[4/7]${NC} Creating Python virtual environment..."
python3 -m venv venv

# Install Python packages in virtual environment
echo -e "${BLUE}[4.5/7]${NC} Installing Python packages..."
./venv/bin/pip install -r requirements.txt

# Create .env file
if [ ! -f .env ]; then
    echo -e "${BLUE}[5/7]${NC} Creating .env configuration file..."
    cp .env.example .env
    
    # Generate secret key
    SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
    sed -i "s/your_secret_key_here/$SECRET_KEY/" .env
    
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          Web Console Configuration Setup                  ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Prompt for Pterodactyl URL
    echo -e "${YELLOW}📍 Pterodactyl Panel Configuration${NC}"
    echo ""
    read -p "Enter your Pterodactyl Panel URL (e.g., https://panel.example.com): " PTERO_URL
    while [[ -z "$PTERO_URL" ]]; do
        echo -e "${RED}✗ URL cannot be empty!${NC}"
        read -p "Enter your Pterodactyl Panel URL: " PTERO_URL
    done
    
    # Remove trailing slash if present
    PTERO_URL="${PTERO_URL%/}"
    
    echo ""
    echo -e "${YELLOW}🔑 Pterodactyl API Key${NC}"
    echo -e "${GRAY}You can get this from: ${PTERO_URL}/account/api${NC}"
    echo ""
    read -p "Enter your Pterodactyl API Key: " PTERO_API_KEY
    while [[ -z "$PTERO_API_KEY" ]]; do
        echo -e "${RED}✗ API Key cannot be empty!${NC}"
        read -p "Enter your Pterodactyl API Key: " PTERO_API_KEY
    done
    
    echo ""
    echo -e "${YELLOW}👤 Web Console Admin Account${NC}"
    echo ""
    read -p "Enter admin username (default: admin): " WEB_USERNAME
    WEB_USERNAME=${WEB_USERNAME:-admin}
    
    while true; do
        read -s -p "Enter admin password: " WEB_PASSWORD
        echo ""
        if [[ ${#WEB_PASSWORD} -lt 8 ]]; then
            echo -e "${RED}✗ Password must be at least 8 characters!${NC}"
            continue
        fi
        read -s -p "Confirm admin password: " WEB_PASSWORD_CONFIRM
        echo ""
        if [[ "$WEB_PASSWORD" == "$WEB_PASSWORD_CONFIRM" ]]; then
            break
        else
            echo -e "${RED}✗ Passwords do not match! Try again.${NC}"
        fi
    done
    
    echo ""
    echo -e "${GREEN}✓ Configuration collected successfully!${NC}"
    echo ""
    
    # Update .env file with collected values
    sed -i "s|PTERODACTYL_URL=.*|PTERODACTYL_URL=$PTERO_URL|" .env
    sed -i "s|PTERODACTYL_API_KEY=.*|PTERODACTYL_API_KEY=$PTERO_API_KEY|" .env
    sed -i "s|WEB_USERNAME=.*|WEB_USERNAME=$WEB_USERNAME|" .env
    sed -i "s|WEB_PASSWORD=.*|WEB_PASSWORD=$WEB_PASSWORD|" .env
    
    echo -e "${CYAN}Configuration saved to .env file${NC}"
    echo ""
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
ExecStart=$WEB_DIR/venv/bin/python $WEB_DIR/app.py
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

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                 Access Information                         ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}🌐 Web Console URL:${NC}"
echo -e "  ${GREEN}http://$SERVER_IP:8080${NC}"
echo ""
echo -e "${YELLOW}👤 Login Credentials:${NC}"
if [[ -n "$WEB_USERNAME" ]]; then
    echo -e "  Username: ${PURPLE}$WEB_USERNAME${NC}"
    echo -e "  Password: ${PURPLE}********${NC} (set during installation)"
else
    echo -e "  Username: ${PURPLE}admin${NC}"
    echo -e "  Password: ${PURPLE}changeme123${NC} ${RED}(change in .env!)${NC}"
fi
echo ""
echo -e "${YELLOW}🔗 Connected to Pterodactyl:${NC}"
if [[ -n "$PTERO_URL" ]]; then
    echo -e "  ${GREEN}$PTERO_URL${NC}"
else
    echo -e "  ${GRAY}(configured in .env)${NC}"
fi
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                 Service Status                             ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
systemctl status pterodactyl-web-console --no-pager
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                 Useful Commands                            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${YELLOW}View logs:${NC}      journalctl -u pterodactyl-web-console -f"
echo -e "  ${YELLOW}Restart:${NC}        systemctl restart pterodactyl-web-console"
echo -e "  ${YELLOW}Stop:${NC}           systemctl stop pterodactyl-web-console"
echo -e "  ${YELLOW}Edit config:${NC}    nano $WEB_DIR/.env"
echo ""
echo -e "${GREEN}✅ Setup complete! 🎉${NC}"
echo -e "${CYAN}Open ${GREEN}http://$SERVER_IP:8080${CYAN} in your browser to get started!${NC}"
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          Optional: Remote Access Setup                     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Would you like to set up remote access via Cloudflare Tunnel?${NC}"
echo ""
echo -e "This allows you to access your web console from anywhere using a custom domain"
echo -e "(e.g., ${GREEN}https://web.cloudmc.online${NC}) with automatic HTTPS."
echo ""
echo -e "${CYAN}Benefits:${NC}"
echo -e "  ${GREEN}✓${NC} Access from anywhere (not just local network)"
echo -e "  ${GREEN}✓${NC} Custom domain (e.g., web.yourdomain.com)"
echo -e "  ${GREEN}✓${NC} Automatic HTTPS/SSL"
echo -e "  ${GREEN}✓${NC} DDoS protection"
echo -e "  ${GREEN}✓${NC} No port forwarding needed"
echo ""
echo -e "${YELLOW}Requirements:${NC}"
echo -e "  • A domain name (can be free from Freenom)"
echo -e "  • Free Cloudflare account"
echo ""
read -p "Set up Cloudflare Tunnel now? (y/n): " -n 1 -r
echo
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    bash "$WEB_DIR/../cloudflare-tunnel.sh"
else
    echo -e "${CYAN}You can set this up later by running:${NC}"
    echo -e "  ${GREEN}bash $WEB_DIR/../setup-access.sh${NC}"
    echo ""
fi
