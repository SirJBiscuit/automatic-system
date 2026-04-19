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

# Detect if we're in the cloned repo
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="/opt/ptero"

# Copy bot files from local repo or download from GitHub
log_info "Setting up bot files..."
if [ -f "$REPO_DIR/discord-bot/bot.py" ]; then
    log_info "Copying files from local repository..."
    cp "$REPO_DIR/discord-bot/bot.py" $BOT_DIR/
    cp "$REPO_DIR/discord-bot/requirements.txt" $BOT_DIR/
    cp "$REPO_DIR/discord-bot/.env.example" $BOT_DIR/
    [ -f "$REPO_DIR/discord-bot/voice_handler.py" ] && cp "$REPO_DIR/discord-bot/voice_handler.py" $BOT_DIR/
elif [ -f "$SCRIPT_DIR/bot.py" ]; then
    log_info "Copying files from script directory..."
    cp "$SCRIPT_DIR/bot.py" $BOT_DIR/
    cp "$SCRIPT_DIR/requirements.txt" $BOT_DIR/
    cp "$SCRIPT_DIR/.env.example" $BOT_DIR/
    [ -f "$SCRIPT_DIR/voice_handler.py" ] && cp "$SCRIPT_DIR/voice_handler.py" $BOT_DIR/
else
    log_info "Downloading bot files from GitHub..."
    curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/discord-bot/bot.py -o $BOT_DIR/bot.py
    curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/discord-bot/requirements.txt -o $BOT_DIR/requirements.txt
    curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/discord-bot/.env.example -o $BOT_DIR/.env.example
fi

cd $BOT_DIR

# Create virtual environment
log_info "Setting up Python virtual environment..."
python3 -m venv $BOT_DIR/venv

# Install Python packages in venv
log_info "Installing Python packages..."
$BOT_DIR/venv/bin/pip install --upgrade pip
$BOT_DIR/venv/bin/pip install -r requirements.txt

# Create .env file
if [ ! -f .env ]; then
    log_info "Creating .env configuration file..."
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🤖 DISCORD BOT CONFIGURATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "How to get a Discord Bot Token:"
    echo "  1. Go to https://discord.com/developers/applications"
    echo "  2. Click 'New Application' and give it a name"
    echo "  3. Go to 'Bot' tab → Click 'Add Bot'"
    echo "  4. Under 'Token', click 'Reset Token' → Copy it"
    echo ""
    read -e -p "Enter your Discord Bot Token: " DISCORD_TOKEN
    echo ""
    
    echo "Pterodactyl Panel Configuration:"
    echo ""
    read -e -p "Enter your Panel URL (e.g., panel.cloudmc.online): " PANEL_URL
    
    # Add https:// if not present
    if [[ ! "$PANEL_URL" =~ ^https?:// ]]; then
        PANEL_URL="https://$PANEL_URL"
        echo "  → Added https:// prefix: $PANEL_URL"
    fi
    
    echo ""
    echo "ℹ️  Use a Client API key (starts with ptlc_), not Application key"
    read -e -p "Enter your Pterodactyl API Key: " PTERO_API_KEY
    echo ""
    
    # Create .env file
    cat > .env <<ENVEOF
# Discord Bot Configuration
DISCORD_TOKEN=$DISCORD_TOKEN

# Pterodactyl Configuration
PTERODACTYL_URL=$PANEL_URL
PTERODACTYL_API_KEY=$PTERO_API_KEY

# Optional: P.R.I.S.M AI Integration (leave empty to disable)
ANTHROPIC_API_KEY=
ENVEOF
    
    chmod 600 .env
    log_success "Configuration saved!"
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
ExecStart=$BOT_DIR/venv/bin/python $BOT_DIR/bot.py
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
