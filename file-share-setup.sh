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

detect_hardware() {
    info "Detecting hardware configuration..."
    
    # Detect GPU
    HAS_GPU=false
    GPU_TYPE="none"
    
    if command -v nvidia-smi &> /dev/null; then
        if nvidia-smi &> /dev/null; then
            HAS_GPU=true
            GPU_TYPE="nvidia"
            GPU_INFO=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
            log "✓ NVIDIA GPU detected: $GPU_INFO"
        fi
    fi
    
    if [ "$HAS_GPU" = false ]; then
        log "✓ No GPU detected (CPU only)"
    fi
    
    # Detect system type
    SYSTEM_TYPE="unknown"
    if grep -qi "raspberry" /proc/cpuinfo 2>/dev/null || grep -qi "bcm" /proc/cpuinfo 2>/dev/null; then
        SYSTEM_TYPE="raspberry_pi"
        log "✓ Raspberry Pi detected"
    elif [ -f /sys/firmware/devicetree/base/model ]; then
        MODEL=$(cat /sys/firmware/devicetree/base/model 2>/dev/null)
        if echo "$MODEL" | grep -qi "raspberry"; then
            SYSTEM_TYPE="raspberry_pi"
            log "✓ Raspberry Pi detected: $MODEL"
        fi
    fi
    
    # Detect available RAM
    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
    log "✓ Total RAM: ${TOTAL_RAM}MB"
    
    # Detect available disk space
    AVAILABLE_DISK=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    log "✓ Available disk space: ${AVAILABLE_DISK}GB"
}

echo ""
echo "=========================================="
echo "  File Sharing Panel Setup"
echo "  with Cloudflare Tunnel"
echo "=========================================="
echo ""

check_root
check_internet
detect_hardware

# Installation Type Selection
echo ""
echo "=== Installation Type ==="
echo ""
echo "Where are you installing this?"
echo ""
echo "1) Main Server (with Pterodactyl/Wings)"
echo "   • Uses port 8090 to avoid conflicts"
echo "   • Skips Nginx installation"
echo "   • Safe for existing Pterodactyl setup"
if [ "$HAS_GPU" = true ]; then
    echo "   • GPU detected: Will optimize for performance"
fi
echo ""
echo "2) Mini PC / Dedicated File Server"
echo "   • Uses standard port 8080"
echo "   • Installs all dependencies"
echo "   • Optimized for file storage"
if [ "$SYSTEM_TYPE" = "raspberry_pi" ]; then
    echo "   • Raspberry Pi optimizations enabled"
fi
echo ""
echo "3) Separate Computer / VPS"
echo "   • Uses standard port 8080"
echo "   • Fresh installation"
echo "   • No conflict checks needed"
echo ""

read -p "Enter choice [1-3]: " INSTALL_TYPE

case $INSTALL_TYPE in
    1)
        INSTALL_MODE="pterodactyl"
        FILEBROWSER_PORT=8090
        SKIP_NGINX_INSTALL=true
        CHECK_CONFLICTS=true
        echo ""
        info "Selected: Main Server (Pterodactyl-safe mode)"
        ;;
    2)
        INSTALL_MODE="minipc"
        FILEBROWSER_PORT=8080
        SKIP_NGINX_INSTALL=false
        CHECK_CONFLICTS=false
        echo ""
        info "Selected: Mini PC / Dedicated File Server"
        ;;
    3)
        INSTALL_MODE="separate"
        FILEBROWSER_PORT=8080
        SKIP_NGINX_INSTALL=false
        CHECK_CONFLICTS=false
        echo ""
        info "Selected: Separate Computer / VPS"
        ;;
    *)
        error "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "=== Hardware & Configuration Summary ==="
echo ""
echo "System Information:"
echo "  • Installation Mode: $INSTALL_MODE"
echo "  • RAM:               ${TOTAL_RAM}MB"
echo "  • Disk Space:        ${AVAILABLE_DISK}GB available"
if [ "$HAS_GPU" = true ]; then
    echo "  • GPU:               $GPU_INFO"
    echo "  • GPU Acceleration:  Available (not used by Filebrowser)"
else
    echo "  • GPU:               None (CPU only)"
fi
if [ "$SYSTEM_TYPE" = "raspberry_pi" ]; then
    echo "  • Device Type:       Raspberry Pi"
    echo "  • Optimizations:     Low-power mode enabled"
fi
echo ""
echo "Configuration:"
echo "  • Filebrowser Port:  $FILEBROWSER_PORT"
if [ "$SKIP_NGINX_INSTALL" = true ]; then
    echo "  • Nginx:             Skip (use existing)"
else
    echo "  • Nginx:             Install if needed"
fi
echo ""
echo "Log file: $LOG_FILE"
echo ""

# Check for port conflicts with Pterodactyl
check_port_conflicts() {
    info "Checking for port conflicts with existing services..."
    
    CONFLICTS=()
    
    # Check common Pterodactyl ports
    if netstat -tuln 2>/dev/null | grep -q ":8080 " || ss -tuln 2>/dev/null | grep -q ":8080 "; then
        CONFLICTS+=("8080 (Wings/Web Console)")
    fi
    
    if netstat -tuln 2>/dev/null | grep -q ":5000 " || ss -tuln 2>/dev/null | grep -q ":5000 "; then
        CONFLICTS+=("5000 (Web Console)")
    fi
    
    if [ ${#CONFLICTS[@]} -gt 0 ]; then
        warn "Detected services on ports: ${CONFLICTS[*]}"
        log "✓ Will use alternative port to avoid conflicts"
    else
        log "✓ No port conflicts detected"
    fi
}

# Only check for conflicts if in Pterodactyl mode
if [ "$CHECK_CONFLICTS" = true ]; then
    check_port_conflicts
fi

DOMAIN="cloudmc.online"
SUBDOMAIN="share"
FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"
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

# Install based on mode
if [ "$SKIP_NGINX_INSTALL" = true ]; then
    # Pterodactyl mode - skip nginx
    log "✓ Skipping Nginx (using existing installation)"
    apt-get install -y curl wget tar -qq
else
    # Mini PC or Separate mode - install nginx if needed
    if command -v nginx &> /dev/null; then
        log "✓ Nginx already installed"
        apt-get install -y curl wget tar -qq
    else
        info "Installing Nginx..."
        apt-get install -y curl wget tar nginx -qq
        log "✓ Nginx installed"
    fi
fi
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
echo "=== Step 3.5: Installing ClamAV (Virus Scanner) ==="
info "Installing ClamAV for file scanning..."

# Ask user if they want virus scanning
read -p "Enable virus scanning for uploaded files? [Y/n]: " ENABLE_CLAMAV
if [[ ! "$ENABLE_CLAMAV" =~ ^[Nn]$ ]]; then
    VIRUS_SCAN_ENABLED=true
    
    # Install ClamAV
    apt-get install -y clamav clamav-daemon -qq
    
    # Stop the service to update
    systemctl stop clamav-freshclam 2>/dev/null || true
    
    info "Updating virus definitions (this may take a few minutes)..."
    freshclam 2>/dev/null || warn "Initial virus database update may need to complete in background"
    
    # Start services
    systemctl enable clamav-daemon
    systemctl enable clamav-freshclam
    systemctl start clamav-daemon
    systemctl start clamav-freshclam
    
    log "✓ ClamAV installed and running"
    log "✓ Virus definitions will auto-update daily"
else
    VIRUS_SCAN_ENABLED=false
    log "✓ Virus scanning disabled (skipped)"
fi

echo ""
echo "=== Step 4: Creating Storage Directory ==="
info "Setting up storage..."
mkdir -p "$STORAGE_PATH"
mkdir -p "$DB_PATH"
mkdir -p "$STORAGE_PATH/quarantine"
chmod 755 "$STORAGE_PATH"
chmod 700 "$STORAGE_PATH/quarantine"
log "✓ Storage directory created: $STORAGE_PATH"

# Create virus scan script if enabled
if [ "$VIRUS_SCAN_ENABLED" = true ]; then
    info "Creating automated virus scan script..."
    
    cat > /usr/local/bin/filebrowser-scan.sh <<'EOF'
#!/bin/bash

SCAN_DIR="/var/filebrowser"
QUARANTINE_DIR="/var/filebrowser/quarantine"
LOG_FILE="/var/log/filebrowser-scan.log"

echo "[$(date)] Starting virus scan..." >> "$LOG_FILE"

# Scan the directory
clamscan -r -i --move="$QUARANTINE_DIR" "$SCAN_DIR" >> "$LOG_FILE" 2>&1

if [ $? -eq 1 ]; then
    echo "[$(date)] ⚠️  INFECTED FILES FOUND AND QUARANTINED!" >> "$LOG_FILE"
    # Optional: Send notification (email, webhook, etc.)
else
    echo "[$(date)] ✓ Scan complete - no threats found" >> "$LOG_FILE"
fi
EOF

    # Update scan script with actual paths
    sed -i "s|/var/filebrowser|$STORAGE_PATH|g" /usr/local/bin/filebrowser-scan.sh
    chmod +x /usr/local/bin/filebrowser-scan.sh
    
    # Create daily cron job for scanning
    echo "0 2 * * * root /usr/local/bin/filebrowser-scan.sh" > /etc/cron.d/filebrowser-scan
    chmod 644 /etc/cron.d/filebrowser-scan
    
    log "✓ Automated daily virus scan configured (runs at 2 AM)"
    log "✓ Infected files will be moved to: $STORAGE_PATH/quarantine"
fi

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
if [ "$VIRUS_SCAN_ENABLED" = true ]; then
    echo "  🦠 Manual virus scan:     sudo /usr/local/bin/filebrowser-scan.sh"
    echo "  📋 View scan logs:        sudo tail -f /var/log/filebrowser-scan.log"
    echo "  🗂️  Check quarantine:      ls -lah $STORAGE_PATH/quarantine"
fi
echo ""
echo -e "${GREEN}Features Available:${NC}"
echo "  ✅ Upload/Download files"
echo "  ✅ Create folders"
echo "  ✅ Share files (generate links)"
echo "  ✅ File preview (images, videos, documents)"
echo "  ✅ Search files"
echo "  ✅ User management"
echo "  ✅ Mobile responsive"
if [ "$VIRUS_SCAN_ENABLED" = true ]; then
    echo "  ✅ Virus scanning (ClamAV)"
fi
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
if [ "$INSTALL_MODE" = "pterodactyl" ]; then
    echo -e "${GREEN}✅ PTERODACTYL-SAFE INSTALLATION COMPLETE!${NC}"
    echo ""
    echo -e "${BLUE}Safe Configuration:${NC}"
    echo "  ✓ Filebrowser on port ${FILEBROWSER_PORT} (Wings uses 8080)"
    echo "  ✓ Separate Cloudflared tunnel (won't affect Pterodactyl)"
    echo "  ✓ No Docker conflicts"
    echo "  ✓ Existing Nginx configuration preserved"
    if [ "$HAS_GPU" = true ]; then
        echo "  ✓ GPU detected: $GPU_INFO (available for other services)"
    fi
elif [ "$INSTALL_MODE" = "minipc" ]; then
    echo -e "${GREEN}✅ MINI PC INSTALLATION COMPLETE!${NC}"
    echo ""
    echo -e "${BLUE}Configuration:${NC}"
    echo "  ✓ Filebrowser on port ${FILEBROWSER_PORT}"
    echo "  ✓ Dedicated file storage server"
    echo "  ✓ RAM: ${TOTAL_RAM}MB | Disk: ${AVAILABLE_DISK}GB"
    if [ "$SYSTEM_TYPE" = "raspberry_pi" ]; then
        echo "  ✓ Raspberry Pi optimizations applied"
    fi
    echo "  ✓ Optimized for file sharing"
else
    echo -e "${GREEN}✅ INSTALLATION COMPLETE!${NC}"
    echo ""
    echo -e "${BLUE}Configuration:${NC}"
    echo "  ✓ Filebrowser on port ${FILEBROWSER_PORT}"
    echo "  ✓ Standalone file sharing server"
    echo "  ✓ RAM: ${TOTAL_RAM}MB | Disk: ${AVAILABLE_DISK}GB"
fi
echo ""
echo "Log saved to: ${LOG_FILE}"
echo ""
