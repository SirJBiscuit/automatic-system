#!/bin/bash

# Discord Bot Installation Script
# Installs and configures the Pterodactyl Discord Bot with P.R.I.S.M AI

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
echo "║         Pterodactyl Discord Bot with P.R.I.S.M AI Installer           ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root (sudo)"
    exit 1
fi

# Install Python and pip
log_info "Installing Python dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv git

# Create bot directory
BOT_DIR="/opt/pterodactyl-bot"
log_info "Creating bot directory: $BOT_DIR"
mkdir -p $BOT_DIR
cd $BOT_DIR

# Download bot files
log_info "Downloading bot files..."
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/discord-bot/bot.py -o bot.py
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/discord-bot/requirements.txt -o requirements.txt
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/discord-bot/.env.example -o .env.example

# Install Python packages
log_info "Installing Python packages..."
pip3 install -r requirements.txt

# Create .env file
if [ ! -f .env ]; then
    log_info "Creating .env configuration file..."
    cp .env.example .env
    
    echo ""
    log_warning "Please configure the .env file with your credentials:"
    echo ""
    echo "  1. Discord Bot Token"
    echo "  2. Pterodactyl URL and API Key"
    echo "  3. Anthropic API Key (for P.R.I.S.M AI)"
    echo ""
    
    read -p "Press Enter to edit .env file..."
    nano .env
else
    log_success ".env file already exists"
fi

# Create systemd service
log_info "Creating systemd service..."
cat > /etc/systemd/system/pterodactyl-bot.service <<EOF
[Unit]
Description=Pterodactyl Discord Bot with P.R.I.S.M AI
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$BOT_DIR
EnvironmentFile=$BOT_DIR/.env
ExecStart=/usr/bin/python3 $BOT_DIR/bot.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
log_info "Enabling and starting bot service..."
systemctl daemon-reload
systemctl enable pterodactyl-bot
systemctl start pterodactyl-bot

echo ""
log_success "✅ Discord Bot installed successfully!"
echo ""
log_info "Bot Status:"
systemctl status pterodactyl-bot --no-pager
echo ""
log_info "Useful commands:"
echo "  • View logs: journalctl -u pterodactyl-bot -f"
echo "  • Restart bot: systemctl restart pterodactyl-bot"
echo "  • Stop bot: systemctl stop pterodactyl-bot"
echo "  • Edit config: nano $BOT_DIR/.env"
echo ""
log_info "Invite bot to Discord:"
echo "  https://discord.com/api/oauth2/authorize?client_id=YOUR_CLIENT_ID&permissions=8&scope=bot"
echo ""
log_success "Setup complete! 🎉"
echo ""
