#!/bin/bash

# Web Console Installation Script

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

echo ""
echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║              Pterodactyl Web Console Installer                         ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root (sudo)"
    exit 1
fi

# Install dependencies
log_info "Installing system dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv nginx

# Create directory
WEB_DIR="/opt/pterodactyl-web-console"
log_info "Creating web console directory: $WEB_DIR"
mkdir -p $WEB_DIR
cd $WEB_DIR

# Download files
log_info "Downloading web console files..."
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/web-console/app.py -o app.py
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/web-console/requirements.txt -o requirements.txt
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/web-console/.env.example -o .env.example

# Create templates directory
mkdir -p templates
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/web-console/templates/dashboard.html -o templates/dashboard.html
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/web-console/templates/login.html -o templates/login.html

# Install Python packages
log_info "Installing Python packages..."
pip3 install -r requirements.txt

# Create .env file
if [ ! -f .env ]; then
    log_info "Creating .env configuration file..."
    cp .env.example .env
    
    # Generate secret key
    SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
    sed -i "s/your_secret_key_here/$SECRET_KEY/" .env
    
    echo ""
    log_warning "Please configure the .env file with your credentials:"
    echo ""
    echo "  1. Pterodactyl URL and API Key"
    echo "  2. Web Console Username and Password"
    echo ""
    
    read -p "Press Enter to edit .env file..."
    nano .env
else
    log_success ".env file already exists"
fi

# Create systemd service
log_info "Creating systemd service..."
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
log_info "Configuring Nginx reverse proxy..."
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
log_info "Enabling and starting web console service..."
systemctl daemon-reload
systemctl enable pterodactyl-web-console
systemctl start pterodactyl-web-console

echo ""
log_success "✅ Web Console installed successfully!"
echo ""
log_info "Web Console Status:"
systemctl status pterodactyl-web-console --no-pager
echo ""
log_info "Access your web console at:"
echo "  http://YOUR_SERVER_IP:8080"
echo ""
log_info "Default credentials (change in .env):"
echo "  Username: admin"
echo "  Password: changeme123"
echo ""
log_info "Useful commands:"
echo "  • View logs: journalctl -u pterodactyl-web-console -f"
echo "  • Restart: systemctl restart pterodactyl-web-console"
echo "  • Edit config: nano $WEB_DIR/.env"
echo ""
log_success "Setup complete! 🎉"
echo ""
