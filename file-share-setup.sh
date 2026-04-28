#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG_FILE="/tmp/file-share-setup-$(date +%Y%m%d-%H%M%S).log"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_internet() {
    info "Checking internet connectivity..."
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        error "No internet connection detected. Please check your network."
        exit 1
    fi
    log "✓ Internet connection verified"
}

echo ""
echo "=========================================="
echo "  File Sharing Panel Setup"
echo "  with Cloudflare Tunnel"
echo "=========================================="
echo ""
echo "This will install:"
echo "  • Filebrowser (Modern file manager)"
echo "  • Cloudflared (Secure tunnel)"
echo "  • Nginx (Reverse proxy)"
echo "  • Automatic SSL via Cloudflare"
echo ""
echo "Log file: $LOG_FILE"
echo ""

check_root
check_internet

DOMAIN="cloudmc.online"
SUBDOMAIN="share"
FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"
FILEBROWSER_PORT=8080
STORAGE_PATH="/var/filebrowser"
DB_PATH="/etc/filebrowser"

echo "=== Configuration ==="
read -p "Enter your domain (default: cloudmc.online): " DOMAIN_INPUT
DOMAIN=${DOMAIN_INPUT:-$DOMAIN}

read -p "Enter subdomain (default: share): " SUBDOMAIN_INPUT
SUBDOMAIN=${SUBDOMAIN_INPUT:-$SUBDOMAIN}

FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"

read -p "Enter storage path (default: /var/filebrowser): " STORAGE_INPUT
STORAGE_PATH=${STORAGE_INPUT:-$STORAGE_PATH}

read -p "Enter admin username (default: admin): " ADMIN_USER
ADMIN_USER=${ADMIN_USER:-admin}

read -s -p "Enter admin password: " ADMIN_PASS
echo ""

if [ -z "$ADMIN_PASS" ]; then
    error "Password cannot be empty!"
    exit 1
fi

echo ""
echo "Configuration Summary:"
echo "  - URL:           https://${FULL_DOMAIN}"
echo "  - Storage Path:  ${STORAGE_PATH}"
echo "  - Admin User:    ${ADMIN_USER}"
echo "  - Local Port:    ${FILEBROWSER_PORT}"
echo ""
read -p "Continue with this configuration? [Y/n]: " CONFIRM
if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi
echo ""

echo "=== Step 1: System Update ==="
info "Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq
log "✓ System updated"

echo ""
echo "=== Step 2: Installing Dependencies ==="
info "Installing required packages..."
apt-get install -y curl wget tar nginx -qq
log "✓ Dependencies installed"

echo ""
echo "=== Step 3: Installing Filebrowser ==="
info "Downloading Filebrowser..."

if [ ! -f /usr/local/bin/filebrowser ]; then
    curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
    log "✓ Filebrowser installed"
else
    log "✓ Filebrowser already installed"
fi

echo ""
echo "=== Step 4: Creating Storage Directory ==="
info "Setting up storage..."
mkdir -p "$STORAGE_PATH"
mkdir -p "$DB_PATH"
chmod 755 "$STORAGE_PATH"
log "✓ Storage directory created: $STORAGE_PATH"

echo ""
echo "=== Step 5: Configuring Filebrowser ==="
info "Creating Filebrowser configuration..."

cat > "$DB_PATH/filebrowser.json" <<EOF
{
  "port": ${FILEBROWSER_PORT},
  "baseURL": "",
  "address": "127.0.0.1",
  "log": "stdout",
  "database": "${DB_PATH}/filebrowser.db",
  "root": "${STORAGE_PATH}"
}
EOF

filebrowser config init --database="${DB_PATH}/filebrowser.db"
filebrowser config set --address 127.0.0.1 --port ${FILEBROWSER_PORT} --database="${DB_PATH}/filebrowser.db"
filebrowser config set --root "${STORAGE_PATH}" --database="${DB_PATH}/filebrowser.db"
filebrowser users add "${ADMIN_USER}" "${ADMIN_PASS}" --perm.admin --database="${DB_PATH}/filebrowser.db" 2>/dev/null || warn "User may already exist"

log "✓ Filebrowser configured"

echo ""
echo "=== Step 6: Creating Systemd Service ==="
info "Setting up Filebrowser service..."

cat > /etc/systemd/system/filebrowser.service <<EOF
[Unit]
Description=File Browser
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/filebrowser --database=${DB_PATH}/filebrowser.db --config=${DB_PATH}/filebrowser.json
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable filebrowser
systemctl start filebrowser

sleep 3

if systemctl is-active --quiet filebrowser; then
    log "✓ Filebrowser service started"
else
    error "Filebrowser failed to start. Check logs with: journalctl -u filebrowser -n 50"
    exit 1
fi

echo ""
echo "=== Step 7: Installing Cloudflared ==="
if command -v cloudflared &> /dev/null; then
    log "✓ Cloudflared already installed"
else
    info "Installing Cloudflared..."
    
    ARCH=$(dpkg --print-architecture)
    if [ "$ARCH" = "amd64" ]; then
        CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
    elif [ "$ARCH" = "arm64" ]; then
        CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb"
    else
        error "Unsupported architecture: $ARCH"
        exit 1
    fi
    
    wget -q "$CLOUDFLARED_URL" -O /tmp/cloudflared.deb
    dpkg -i /tmp/cloudflared.deb
    rm /tmp/cloudflared.deb
    log "✓ Cloudflared installed"
fi

echo ""
echo "=== Step 8: Cloudflare Authentication ==="
if [ ! -f ~/.cloudflared/cert.pem ]; then
    warn "Please authenticate with Cloudflare..."
    echo ""
    echo "A browser window will open. Please:"
    echo "  1. Log in to your Cloudflare account"
    echo "  2. Select your domain: ${DOMAIN}"
    echo "  3. Authorize the tunnel"
    echo ""
    read -p "Press Enter to continue..."
    cloudflared tunnel login
    log "✓ Cloudflare authenticated"
else
    log "✓ Already authenticated with Cloudflare"
fi

echo ""
echo "=== Step 9: Creating Cloudflare Tunnel ==="
TUNNEL_NAME="file-share-$(hostname -s)"
TUNNEL_ID=$(cloudflared tunnel list 2>/dev/null | grep "$TUNNEL_NAME" | head -1 | awk '{print $1}')

if [ -z "$TUNNEL_ID" ]; then
    info "Creating new tunnel: ${TUNNEL_NAME}"
    cloudflared tunnel create "${TUNNEL_NAME}"
    TUNNEL_ID=$(cloudflared tunnel list | grep "${TUNNEL_NAME}" | awk '{print $1}')
    log "✓ Tunnel created: ${TUNNEL_ID}"
else
    log "✓ Using existing tunnel: ${TUNNEL_ID}"
fi

echo ""
echo "=== Step 10: Configuring Tunnel ==="
mkdir -p ~/.cloudflared

cat > ~/.cloudflared/config.yml <<EOF
tunnel: ${TUNNEL_ID}
credentials-file: /root/.cloudflared/${TUNNEL_ID}.json

ingress:
  - hostname: ${FULL_DOMAIN}
    service: http://127.0.0.1:${FILEBROWSER_PORT}
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF

log "✓ Tunnel configured"

echo ""
echo "=== Step 11: Setting up DNS ==="
info "Creating DNS record for ${FULL_DOMAIN}..."
cloudflared tunnel route dns "${TUNNEL_ID}" "${FULL_DOMAIN}" 2>/dev/null || warn "DNS route may already exist"
log "✓ DNS configured"

echo ""
echo "=== Step 12: Installing Tunnel Service ==="
cloudflared service install
systemctl enable cloudflared
systemctl restart cloudflared

sleep 5

if systemctl is-active --quiet cloudflared; then
    log "✓ Cloudflared service started"
else
    error "Cloudflared failed to start. Check logs with: journalctl -u cloudflared -n 50"
    exit 1
fi

echo ""
echo "=== Step 13: Testing Connectivity ==="
sleep 5

info "Testing local Filebrowser..."
LOCAL_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:${FILEBROWSER_PORT} 2>/dev/null)
if [ "$LOCAL_TEST" = "200" ]; then
    log "✓ Filebrowser is responding locally"
else
    warn "Filebrowser local test returned: $LOCAL_TEST"
fi

echo ""
echo "=========================================="
echo "✓✓✓ Setup Complete! ✓✓✓"
echo "=========================================="
echo ""
echo -e "${GREEN}Access Your File Share:${NC}"
echo "  🌐 External URL:  https://${FULL_DOMAIN}"
echo "  🏠 Local URL:     http://$(hostname -I | awk '{print $1}'):${FILEBROWSER_PORT}"
echo ""
echo -e "${BLUE}Login Credentials:${NC}"
echo "  👤 Username:      ${ADMIN_USER}"
echo "  🔑 Password:      [the password you entered]"
echo ""
echo -e "${YELLOW}Storage Location:${NC}"
echo "  📁 Files stored in: ${STORAGE_PATH}"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo "  📊 Check Filebrowser:     sudo systemctl status filebrowser"
echo "  📊 Check Cloudflared:     sudo systemctl status cloudflared"
echo "  🔄 Restart Filebrowser:   sudo systemctl restart filebrowser"
echo "  🔄 Restart Cloudflared:   sudo systemctl restart cloudflared"
echo "  📝 View Filebrowser logs: sudo journalctl -u filebrowser -f"
echo "  📝 View Cloudflared logs: sudo journalctl -u cloudflared -f"
echo ""
echo -e "${GREEN}Features Available:${NC}"
echo "  ✅ Upload/Download files"
echo "  ✅ Create folders"
echo "  ✅ Share files (generate links)"
echo "  ✅ File preview (images, videos, documents)"
echo "  ✅ Search files"
echo "  ✅ User management"
echo "  ✅ Mobile responsive"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Visit https://${FULL_DOMAIN}"
echo "  2. Log in with your credentials"
echo "  3. Start uploading files!"
echo "  4. Optional: Create additional users in Settings"
echo ""
echo -e "${BLUE}Configuration Files:${NC}"
echo "  - Filebrowser config:  ${DB_PATH}/filebrowser.json"
echo "  - Filebrowser DB:      ${DB_PATH}/filebrowser.db"
echo "  - Cloudflared config:  ~/.cloudflared/config.yml"
echo "  - Setup log:           ${LOG_FILE}"
echo ""
echo -e "${YELLOW}Troubleshooting:${NC}"
echo "  If you can't access the site:"
echo "    1. Wait 2-3 minutes for DNS propagation"
echo "    2. Check tunnel: sudo systemctl status cloudflared"
echo "    3. Check Filebrowser: sudo systemctl status filebrowser"
echo "    4. Verify in Cloudflare dashboard: Zero Trust → Networks → Tunnels"
echo ""
echo -e "${GREEN}Setup completed successfully!${NC}"
echo "Log saved to: ${LOG_FILE}"
echo ""
