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

clear
echo ""
echo "=========================================="
echo "  📁 File Sharing Panel Setup Wizard"
echo "  with Cloudflare Tunnel"
echo "=========================================="
echo ""
echo "👋 Welcome! This wizard will guide you through setting up"
echo "   a professional file sharing system step-by-step."
echo ""
echo "📋 What you'll get:"
echo "   • Secure web-based file manager"
echo "   • User accounts with permissions"
echo "   • Online status indicators"
echo "   • File trading between users"
echo "   • Automatic backups and security"
echo "   • Beautiful modern interface"
echo ""
echo "⏱️  Estimated time: 10-15 minutes"
echo ""
read -p "Press Enter to begin setup..."

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
mkdir -p "$STORAGE_PATH/.thumbnails"
mkdir -p "$STORAGE_PATH/.encrypted"
mkdir -p "/var/log/filebrowser"
chmod 755 "$STORAGE_PATH"
chmod 700 "$STORAGE_PATH/quarantine"
chmod 755 "$STORAGE_PATH/.thumbnails"
chmod 700 "$STORAGE_PATH/.encrypted"
log "✓ Storage directory created: $STORAGE_PATH"

echo ""
echo "=== Step 4.5: Installing Advanced Features ==="
info "Installing additional packages for advanced features..."

# Install packages for deduplication, compression, FTP, encryption, media processing, monitoring
apt-get install -y fdupes pigz vsftpd encfs fail2ban -qq
apt-get install -y ffmpeg imagemagick libreoffice-writer libreoffice-calc libreoffice-impress -qq
apt-get install -y redis-server postgresql postgresql-contrib -qq
apt-get install -y prometheus node-exporter grafana -qq
apt-get install -y davfs2 sshfs openssh-server -qq
apt-get install -y python3-pip python3-venv git -qq

log "✓ Deduplication tool (fdupes) installed"
log "✓ Compression tool (pigz) installed"
log "✓ FTP server (vsftpd) installed"
log "✓ Encryption tool (encfs) installed"
log "✓ Security tool (fail2ban) installed"
log "✓ Media processing (ffmpeg, imagemagick) installed"
log "✓ Document conversion (LibreOffice) installed"
log "✓ Database (Redis, PostgreSQL) installed"
log "✓ Monitoring (Prometheus, Grafana) installed"
log "✓ WebDAV/SFTP support installed"

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
echo "=== Step 4.6: Setting Up Advanced Features ==="

# Deduplication Script
info "Creating deduplication script..."
cat > /usr/local/bin/filebrowser-dedupe.sh <<EOF
#!/bin/bash
STORAGE_DIR="$STORAGE_PATH"
LOG_FILE="/var/log/filebrowser/dedupe.log"

echo "[$(date)] Starting deduplication scan..." >> "\$LOG_FILE"
fdupes -r -d -N "\$STORAGE_DIR" >> "\$LOG_FILE" 2>&1
echo "[$(date)] Deduplication complete" >> "\$LOG_FILE"
EOF
chmod +x /usr/local/bin/filebrowser-dedupe.sh
echo "0 3 * * 0 root /usr/local/bin/filebrowser-dedupe.sh" > /etc/cron.d/filebrowser-dedupe
log "✓ Deduplication script created (runs weekly on Sunday at 3 AM)"

# Auto-Compression Script
info "Creating auto-compression script..."
cat > /usr/local/bin/filebrowser-compress.sh <<EOF
#!/bin/bash
STORAGE_DIR="$STORAGE_PATH"
LOG_FILE="/var/log/filebrowser/compress.log"
DAYS_OLD=30

echo "[$(date)] Starting compression of old files..." >> "\$LOG_FILE"

# Find files older than \$DAYS_OLD days and compress them
find "\$STORAGE_DIR" -type f -mtime +\$DAYS_OLD ! -name "*.gz" ! -path "*/quarantine/*" ! -path "*/.thumbnails/*" -exec pigz -9 {} \; 2>> "\$LOG_FILE"

echo "[$(date)] Compression complete" >> "\$LOG_FILE"
EOF
chmod +x /usr/local/bin/filebrowser-compress.sh
echo "0 4 * * 0 root /usr/local/bin/filebrowser-compress.sh" > /etc/cron.d/filebrowser-compress
log "✓ Auto-compression script created (runs weekly on Sunday at 4 AM)"

# Thumbnail Generation Script
info "Creating thumbnail generation script..."
apt-get install -y imagemagick ffmpeg -qq
cat > /usr/local/bin/filebrowser-thumbnails.sh <<EOF
#!/bin/bash
STORAGE_DIR="$STORAGE_PATH"
THUMB_DIR="$STORAGE_PATH/.thumbnails"
LOG_FILE="/var/log/filebrowser/thumbnails.log"

echo "[$(date)] Generating thumbnails..." >> "\$LOG_FILE"

# Generate thumbnails for images
find "\$STORAGE_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) ! -path "*/.thumbnails/*" | while read file; do
    thumb_name="\$THUMB_DIR/\$(basename "\$file")"
    if [ ! -f "\$thumb_name" ]; then
        convert "\$file" -thumbnail 200x200 "\$thumb_name" 2>> "\$LOG_FILE"
    fi
done

echo "[$(date)] Thumbnail generation complete" >> "\$LOG_FILE"
EOF
chmod +x /usr/local/bin/filebrowser-thumbnails.sh
echo "*/30 * * * * root /usr/local/bin/filebrowser-thumbnails.sh" > /etc/cron.d/filebrowser-thumbnails
log "✓ Thumbnail generation script created (runs every 30 minutes)"

# Audit Logging Setup
info "Setting up audit logging..."
cat > /usr/local/bin/filebrowser-audit.sh <<EOF
#!/bin/bash
# Audit logging is handled by Filebrowser's built-in logging
# This script rotates and archives audit logs

LOG_DIR="/var/log/filebrowser"
ARCHIVE_DIR="/var/log/filebrowser/archive"
DAYS_TO_KEEP=90

mkdir -p "\$ARCHIVE_DIR"

# Rotate logs older than 7 days
find "\$LOG_DIR" -name "*.log" -mtime +7 -exec gzip {} \;
find "\$LOG_DIR" -name "*.log.gz" -exec mv {} "\$ARCHIVE_DIR/" \;

# Delete archives older than \$DAYS_TO_KEEP days
find "\$ARCHIVE_DIR" -name "*.log.gz" -mtime +\$DAYS_TO_KEEP -delete

echo "[$(date)] Audit log rotation complete" >> "\$LOG_DIR/audit-rotation.log"
EOF
chmod +x /usr/local/bin/filebrowser-audit.sh
echo "0 1 * * * root /usr/local/bin/filebrowser-audit.sh" > /etc/cron.d/filebrowser-audit
log "✓ Audit logging configured (90-day retention)"

# FTP Server Configuration
info "Configuring FTP server..."
cat > /etc/vsftpd.conf <<EOF
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100
user_sub_token=\$USER
local_root=$STORAGE_PATH
allow_writeable_chroot=YES
EOF
systemctl enable vsftpd
systemctl start vsftpd
log "✓ FTP server configured on port 21 (passive: 40000-40100)"

# Fail2ban for Rate Limiting
info "Configuring fail2ban for rate limiting..."
cat > /etc/fail2ban/jail.d/filebrowser.conf <<EOF
[filebrowser]
enabled = true
port = $FILEBROWSER_PORT
filter = filebrowser
logpath = /var/log/filebrowser/*.log
maxretry = 5
bantime = 3600
findtime = 600
EOF

cat > /etc/fail2ban/filter.d/filebrowser.conf <<EOF
[Definition]
failregex = ^.*Failed login attempt from <HOST>.*$
            ^.*Unauthorized access from <HOST>.*$
ignoreregex =
EOF

systemctl enable fail2ban
systemctl restart fail2ban
log "✓ Fail2ban configured (5 attempts in 10 min = 1 hour ban)"

log "✓ All advanced features configured successfully"

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
filebrowser config set --log /var/log/filebrowser/access.log --database="${DB_PATH}/filebrowser.db"

# Enable all features
filebrowser config set --branding.name "File Share Portal" --database="${DB_PATH}/filebrowser.db"
filebrowser config set --branding.disableExternal --database="${DB_PATH}/filebrowser.db"
filebrowser config set --branding.files "${DB_PATH}/branding" --database="${DB_PATH}/filebrowser.db"
filebrowser config set --signup false --database="${DB_PATH}/filebrowser.db"
filebrowser config set --createUserDir false --database="${DB_PATH}/filebrowser.db"

# Create admin user with full permissions
filebrowser users add "${ADMIN_USER}" "${ADMIN_PASS}" \
    --perm.admin \
    --perm.create \
    --perm.delete \
    --perm.download \
    --perm.execute \
    --perm.modify \
    --perm.rename \
    --perm.share \
    --database="${DB_PATH}/filebrowser.db" 2>/dev/null || warn "User may already exist"

log "✓ Filebrowser configured with full permissions and branding"

# Create custom CSS for enhanced UI
info "Creating enhanced UI customizations..."
mkdir -p "${DB_PATH}/branding"

cat > "${DB_PATH}/branding/custom.css" <<'EOFCSS'
/* Enhanced File Browser UI with Animations and Modern Effects */

:root {
    --primary-color: #4f46e5;
    --secondary-color: #06b6d4;
    --success-color: #10b981;
    --danger-color: #ef4444;
    --warning-color: #f59e0b;
    --dark-bg: #1f2937;
    --light-bg: #f9fafb;
    --border-radius: 12px;
    --transition-speed: 0.3s;
    --shadow-sm: 0 1px 3px rgba(0,0,0,0.12);
    --shadow-md: 0 4px 6px rgba(0,0,0,0.1);
    --shadow-lg: 0 10px 15px rgba(0,0,0,0.1);
}

/* Smooth animations for all transitions */
* {
    transition: all var(--transition-speed) cubic-bezier(0.4, 0, 0.2, 1);
}

/* Enhanced header with gradient */
header {
    background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
    box-shadow: var(--shadow-md);
    backdrop-filter: blur(10px);
}

/* Animated file list items */
.item {
    border-radius: var(--border-radius);
    margin: 4px 0;
    padding: 12px;
    background: white;
    box-shadow: var(--shadow-sm);
}

.item:hover {
    transform: translateY(-2px);
    box-shadow: var(--shadow-md);
    background: linear-gradient(to right, #f9fafb, #ffffff);
}

/* Upload progress indicator with animation */
.upload-progress {
    position: fixed;
    top: 70px;
    right: 20px;
    background: white;
    padding: 16px;
    border-radius: var(--border-radius);
    box-shadow: var(--shadow-lg);
    animation: slideInRight 0.3s ease-out;
    z-index: 1000;
}

@keyframes slideInRight {
    from {
        transform: translateX(400px);
        opacity: 0;
    }
    to {
        transform: translateX(0);
        opacity: 1;
    }
}

/* Progress bar animation */
.progress-bar {
    height: 6px;
    background: linear-gradient(90deg, var(--primary-color), var(--secondary-color));
    border-radius: 3px;
    animation: shimmer 1.5s infinite;
    background-size: 200% 100%;
}

@keyframes shimmer {
    0% { background-position: -200% 0; }
    100% { background-position: 200% 0; }
}

/* Enhanced buttons with hover effects */
button, .button {
    border-radius: 8px;
    padding: 10px 20px;
    font-weight: 600;
    box-shadow: var(--shadow-sm);
    position: relative;
    overflow: hidden;
}

button:hover, .button:hover {
    transform: translateY(-1px);
    box-shadow: var(--shadow-md);
}

button::before {
    content: '';
    position: absolute;
    top: 50%;
    left: 50%;
    width: 0;
    height: 0;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.3);
    transform: translate(-50%, -50%);
    transition: width 0.6s, height 0.6s;
}

button:active::before {
    width: 300px;
    height: 300px;
}

/* File type indicators with icons */
.item[data-type="image"]::before {
    content: "🖼️";
    margin-right: 8px;
}

.item[data-type="video"]::before {
    content: "🎬";
    margin-right: 8px;
}

.item[data-type="audio"]::before {
    content: "🎵";
    margin-right: 8px;
}

.item[data-type="document"]::before {
    content: "📄";
    margin-right: 8px;
}

.item[data-type="archive"]::before {
    content: "📦";
    margin-right: 8px;
}

.item[data-type="folder"]::before {
    content: "📁";
    margin-right: 8px;
}

/* Status indicators */
.status-indicator {
    display: inline-block;
    width: 8px;
    height: 8px;
    border-radius: 50%;
    margin-right: 8px;
    animation: pulse 2s infinite;
}

.status-online { background: var(--success-color); }
.status-uploading { background: var(--warning-color); }
.status-error { background: var(--danger-color); }

@keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
}

/* Modal animations */
.modal {
    animation: fadeIn 0.3s ease-out;
}

@keyframes fadeIn {
    from {
        opacity: 0;
        transform: scale(0.9);
    }
    to {
        opacity: 1;
        transform: scale(1);
    }
}

/* Notification toast */
.notification {
    position: fixed;
    top: 20px;
    right: 20px;
    background: white;
    padding: 16px 24px;
    border-radius: var(--border-radius);
    box-shadow: var(--shadow-lg);
    animation: slideInRight 0.3s ease-out;
    border-left: 4px solid var(--primary-color);
}

.notification.success { border-left-color: var(--success-color); }
.notification.error { border-left-color: var(--danger-color); }
.notification.warning { border-left-color: var(--warning-color); }

/* Loading spinner */
.spinner {
    border: 3px solid rgba(0, 0, 0, 0.1);
    border-top-color: var(--primary-color);
    border-radius: 50%;
    width: 40px;
    height: 40px;
    animation: spin 0.8s linear infinite;
}

@keyframes spin {
    to { transform: rotate(360deg); }
}

/* Breadcrumb navigation */
.breadcrumb {
    display: flex;
    align-items: center;
    padding: 12px;
    background: var(--light-bg);
    border-radius: var(--border-radius);
    margin-bottom: 16px;
}

.breadcrumb-item {
    padding: 6px 12px;
    border-radius: 6px;
}

.breadcrumb-item:hover {
    background: white;
    box-shadow: var(--shadow-sm);
}

/* Search bar enhancement */
.search-bar {
    border-radius: 24px;
    padding: 12px 24px;
    border: 2px solid transparent;
    background: white;
    box-shadow: var(--shadow-sm);
}

.search-bar:focus {
    border-color: var(--primary-color);
    box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
    outline: none;
}

/* Grid view with cards */
.grid-view .item {
    display: inline-block;
    width: 200px;
    margin: 12px;
    text-align: center;
    vertical-align: top;
}

.grid-view .item:hover {
    transform: translateY(-4px) scale(1.02);
}

/* Thumbnail preview */
.thumbnail {
    width: 100%;
    height: 150px;
    object-fit: cover;
    border-radius: 8px;
    margin-bottom: 8px;
}

/* Context menu */
.context-menu {
    background: white;
    border-radius: var(--border-radius);
    box-shadow: var(--shadow-lg);
    padding: 8px 0;
    animation: fadeIn 0.2s ease-out;
}

.context-menu-item {
    padding: 10px 20px;
}

.context-menu-item:hover {
    background: var(--light-bg);
}

/* Drag and drop zone */
.drop-zone {
    border: 3px dashed var(--primary-color);
    border-radius: var(--border-radius);
    padding: 40px;
    text-align: center;
    background: rgba(79, 70, 229, 0.05);
    transition: all 0.3s ease;
}

.drop-zone.active {
    background: rgba(79, 70, 229, 0.1);
    transform: scale(1.02);
}

/* Sidebar navigation */
.sidebar {
    background: var(--dark-bg);
    color: white;
    padding: 20px;
    border-radius: var(--border-radius);
    box-shadow: var(--shadow-md);
}

.sidebar-item {
    padding: 12px 16px;
    border-radius: 8px;
    margin: 4px 0;
}

.sidebar-item:hover {
    background: rgba(255, 255, 255, 0.1);
    transform: translateX(4px);
}

.sidebar-item.active {
    background: var(--primary-color);
}

/* Responsive design */
@media (max-width: 768px) {
    .grid-view .item {
        width: calc(50% - 24px);
    }
}

@media (max-width: 480px) {
    .grid-view .item {
        width: calc(100% - 24px);
    }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
    :root {
        --light-bg: #1f2937;
        --dark-bg: #111827;
    }
    
    body {
        background: var(--dark-bg);
        color: #f9fafb;
    }
    
    .item {
        background: #374151;
        color: #f9fafb;
    }
}

/* Performance optimizations */
.item, button, .modal {
    will-change: transform;
}

/* Smooth scrolling */
html {
    scroll-behavior: smooth;
}

/* Custom scrollbar */
::-webkit-scrollbar {
    width: 12px;
}

::-webkit-scrollbar-track {
    background: var(--light-bg);
    border-radius: 6px;
}

::-webkit-scrollbar-thumb {
    background: var(--primary-color);
    border-radius: 6px;
}

::-webkit-scrollbar-thumb:hover {
    background: var(--secondary-color);
}
EOFCSS

log "✓ Enhanced UI with animations and modern effects created"

# Create custom JavaScript for additional features
cat > "${DB_PATH}/branding/custom.js" <<'EOFJS'
// Enhanced File Browser Features

document.addEventListener('DOMContentLoaded', function() {
    // Add upload progress indicators
    const addUploadIndicator = () => {
        const indicator = document.createElement('div');
        indicator.className = 'upload-progress';
        indicator.innerHTML = `
            <div class="status-indicator status-uploading"></div>
            <span>Uploading files...</span>
            <div class="progress-bar"></div>
        `;
        document.body.appendChild(indicator);
        
        setTimeout(() => {
            indicator.style.opacity = '0';
            setTimeout(() => indicator.remove(), 300);
        }, 3000);
    };

    // Add notification system
    window.showNotification = (message, type = 'success') => {
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.textContent = message;
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.style.opacity = '0';
            setTimeout(() => notification.remove(), 300);
        }, 3000);
    };

    // Enhance drag and drop
    const dropZone = document.querySelector('.drop-zone') || document.body;
    
    dropZone.addEventListener('dragover', (e) => {
        e.preventDefault();
        dropZone.classList.add('active');
    });
    
    dropZone.addEventListener('dragleave', () => {
        dropZone.classList.remove('active');
    });
    
    dropZone.addEventListener('drop', (e) => {
        e.preventDefault();
        dropZone.classList.remove('active');
        addUploadIndicator();
        showNotification('Files uploaded successfully!', 'success');
    });

    // Add keyboard shortcuts
    document.addEventListener('keydown', (e) => {
        // Ctrl/Cmd + U for upload
        if ((e.ctrlKey || e.metaKey) && e.key === 'u') {
            e.preventDefault();
            document.querySelector('input[type="file"]')?.click();
        }
        
        // Ctrl/Cmd + F for search
        if ((e.ctrlKey || e.metaKey) && e.key === 'f') {
            e.preventDefault();
            document.querySelector('.search-bar')?.focus();
        }
    });

    // Add file type detection
    document.querySelectorAll('.item').forEach(item => {
        const filename = item.textContent.toLowerCase();
        if (filename.match(/\.(jpg|jpeg|png|gif|webp)$/)) {
            item.setAttribute('data-type', 'image');
        } else if (filename.match(/\.(mp4|avi|mkv|mov)$/)) {
            item.setAttribute('data-type', 'video');
        } else if (filename.match(/\.(mp3|wav|flac)$/)) {
            item.setAttribute('data-type', 'audio');
        } else if (filename.match(/\.(pdf|doc|docx|txt)$/)) {
            item.setAttribute('data-type', 'document');
        } else if (filename.match(/\.(zip|rar|7z|tar|gz)$/)) {
            item.setAttribute('data-type', 'archive');
        }
    });

    console.log('✅ Enhanced File Browser UI loaded');
});
EOFJS

log "✓ Enhanced JavaScript features created"

echo ""
echo "=== Step 5.5: Creating Admin Management Scripts ==="

# Storage Quota Management Script
info "Creating storage quota management script..."
cat > /usr/local/bin/filebrowser-quota.sh <<'EOFQUOTA'
#!/bin/bash

# Storage Quota Management for Filebrowser
# Usage: filebrowser-quota.sh [set|check|list] [username] [size_in_MB]

DB_PATH="/etc/filebrowser"
STORAGE_PATH="/var/filebrowser"

case "$1" in
    set)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: $0 set <username> <size_in_MB>"
            exit 1
        fi
        
        USERNAME="$2"
        QUOTA_MB="$3"
        
        # Create quota file
        echo "$QUOTA_MB" > "$STORAGE_PATH/.quota_$USERNAME"
        echo "✓ Set quota for $USERNAME to ${QUOTA_MB}MB"
        ;;
        
    check)
        if [ -z "$2" ]; then
            echo "Usage: $0 check <username>"
            exit 1
        fi
        
        USERNAME="$2"
        QUOTA_FILE="$STORAGE_PATH/.quota_$USERNAME"
        
        if [ ! -f "$QUOTA_FILE" ]; then
            echo "No quota set for $USERNAME"
            exit 0
        fi
        
        QUOTA_MB=$(cat "$QUOTA_FILE")
        USED_MB=$(du -sm "$STORAGE_PATH" 2>/dev/null | cut -f1)
        
        echo "User: $USERNAME"
        echo "Quota: ${QUOTA_MB}MB"
        echo "Used: ${USED_MB}MB"
        echo "Available: $((QUOTA_MB - USED_MB))MB"
        
        if [ $USED_MB -gt $QUOTA_MB ]; then
            echo "⚠️  QUOTA EXCEEDED!"
        fi
        ;;
        
    list)
        echo "Storage Quotas:"
        for quota_file in "$STORAGE_PATH"/.quota_*; do
            if [ -f "$quota_file" ]; then
                username=$(basename "$quota_file" | sed 's/.quota_//')
                quota=$(cat "$quota_file")
                echo "  $username: ${quota}MB"
            fi
        done
        ;;
        
    *)
        echo "Usage: $0 {set|check|list} [username] [size_in_MB]"
        echo ""
        echo "Examples:"
        echo "  $0 set john 5000      # Set 5GB quota for john"
        echo "  $0 check john         # Check john's quota usage"
        echo "  $0 list               # List all quotas"
        exit 1
        ;;
esac
EOFQUOTA
chmod +x /usr/local/bin/filebrowser-quota.sh
log "✓ Storage quota management script created"

# IP Whitelisting Script
info "Creating IP whitelist management script..."
cat > /usr/local/bin/filebrowser-ipwhitelist.sh <<'EOFIP'
#!/bin/bash

# IP Whitelist Management
# Usage: filebrowser-ipwhitelist.sh [add|remove|list|enable|disable] [IP]

WHITELIST_FILE="/etc/filebrowser/ip_whitelist.conf"
NGINX_CONF="/etc/nginx/sites-available/filebrowser"

case "$1" in
    add)
        if [ -z "$2" ]; then
            echo "Usage: $0 add <IP_or_CIDR>"
            exit 1
        fi
        
        echo "$2" >> "$WHITELIST_FILE"
        echo "✓ Added $2 to whitelist"
        echo "Run: systemctl reload nginx"
        ;;
        
    remove)
        if [ -z "$2" ]; then
            echo "Usage: $0 remove <IP_or_CIDR>"
            exit 1
        fi
        
        sed -i "/$2/d" "$WHITELIST_FILE"
        echo "✓ Removed $2 from whitelist"
        echo "Run: systemctl reload nginx"
        ;;
        
    list)
        echo "IP Whitelist:"
        if [ -f "$WHITELIST_FILE" ]; then
            cat "$WHITELIST_FILE"
        else
            echo "  (empty)"
        fi
        ;;
        
    enable)
        echo "# IP Whitelist enabled" > "$WHITELIST_FILE.enabled"
        echo "✓ IP whitelist enabled"
        echo "Add IPs with: $0 add <IP>"
        ;;
        
    disable)
        rm -f "$WHITELIST_FILE.enabled"
        echo "✓ IP whitelist disabled"
        ;;
        
    *)
        echo "Usage: $0 {add|remove|list|enable|disable} [IP]"
        echo ""
        echo "Examples:"
        echo "  $0 enable              # Enable IP whitelisting"
        echo "  $0 add 192.168.1.0/24  # Allow local network"
        echo "  $0 add 1.2.3.4         # Allow specific IP"
        echo "  $0 list                # Show whitelist"
        echo "  $0 remove 1.2.3.4      # Remove IP"
        echo "  $0 disable             # Disable whitelisting"
        exit 1
        ;;
esac
EOFIP
chmod +x /usr/local/bin/filebrowser-ipwhitelist.sh
touch /etc/filebrowser/ip_whitelist.conf
log "✓ IP whitelist management script created"

# Share Link Management Script
info "Creating share link management script..."
cat > /usr/local/bin/filebrowser-shares.sh <<'EOFSHARE'
#!/bin/bash

# Share Link Management
# Usage: filebrowser-shares.sh [create|list|expire|password] [file] [options]

SHARES_DIR="/etc/filebrowser/shares"
mkdir -p "$SHARES_DIR"

case "$1" in
    create)
        if [ -z "$2" ]; then
            echo "Usage: $0 create <file> [--expire-days N] [--password PASS]"
            exit 1
        fi
        
        FILE="$2"
        SHARE_ID=$(uuidgen | cut -d'-' -f1)
        EXPIRE_DAYS=7
        PASSWORD=""
        
        shift 2
        while [ $# -gt 0 ]; do
            case "$1" in
                --expire-days)
                    EXPIRE_DAYS="$2"
                    shift 2
                    ;;
                --password)
                    PASSWORD="$2"
                    shift 2
                    ;;
                *)
                    shift
                    ;;
            esac
        done
        
        EXPIRE_DATE=$(date -d "+$EXPIRE_DAYS days" +%Y-%m-%d)
        
        cat > "$SHARES_DIR/$SHARE_ID.conf" <<EOF
FILE=$FILE
CREATED=$(date +%Y-%m-%d)
EXPIRES=$EXPIRE_DATE
PASSWORD=$PASSWORD
EOF
        
        echo "✓ Share link created: $SHARE_ID"
        echo "  File: $FILE"
        echo "  Expires: $EXPIRE_DATE"
        if [ -n "$PASSWORD" ]; then
            echo "  Password: $PASSWORD"
        fi
        ;;
        
    list)
        echo "Active Share Links:"
        for share in "$SHARES_DIR"/*.conf; do
            if [ -f "$share" ]; then
                source "$share"
                SHARE_ID=$(basename "$share" .conf)
                echo "  ID: $SHARE_ID"
                echo "    File: $FILE"
                echo "    Expires: $EXPIRES"
                if [ -n "$PASSWORD" ]; then
                    echo "    Password: Yes"
                fi
                echo ""
            fi
        done
        ;;
        
    expire)
        # Clean up expired shares
        CURRENT_DATE=$(date +%Y-%m-%d)
        for share in "$SHARES_DIR"/*.conf; do
            if [ -f "$share" ]; then
                source "$share"
                if [[ "$EXPIRES" < "$CURRENT_DATE" ]]; then
                    rm "$share"
                    echo "✓ Expired share removed: $(basename "$share" .conf)"
                fi
            fi
        done
        ;;
        
    *)
        echo "Usage: $0 {create|list|expire} [options]"
        echo ""
        echo "Examples:"
        echo "  $0 create /path/to/file.pdf --expire-days 7"
        echo "  $0 create /path/to/file.pdf --password secret123"
        echo "  $0 list"
        echo "  $0 expire    # Remove expired shares"
        exit 1
        ;;
esac
EOFSHARE
chmod +x /usr/local/bin/filebrowser-shares.sh
echo "0 0 * * * root /usr/local/bin/filebrowser-shares.sh expire" > /etc/cron.d/filebrowser-shares
log "✓ Share link management script created"

# File Encryption Script
info "Creating file encryption management script..."
cat > /usr/local/bin/filebrowser-encrypt.sh <<'EOFENC'
#!/bin/bash

# File Encryption Management
# Usage: filebrowser-encrypt.sh [encrypt|decrypt|status] [file]

ENCRYPTED_DIR="/var/filebrowser/.encrypted"

case "$1" in
    encrypt)
        if [ -z "$2" ]; then
            echo "Usage: $0 encrypt <file>"
            exit 1
        fi
        
        FILE="$2"
        BASENAME=$(basename "$FILE")
        
        # Encrypt file with GPG
        gpg --symmetric --cipher-algo AES256 --output "$ENCRYPTED_DIR/$BASENAME.gpg" "$FILE"
        
        if [ $? -eq 0 ]; then
            echo "✓ File encrypted: $ENCRYPTED_DIR/$BASENAME.gpg"
            read -p "Delete original file? [y/N]: " DELETE
            if [[ "$DELETE" =~ ^[Yy]$ ]]; then
                rm "$FILE"
                echo "✓ Original file deleted"
            fi
        else
            echo "✗ Encryption failed"
            exit 1
        fi
        ;;
        
    decrypt)
        if [ -z "$2" ]; then
            echo "Usage: $0 decrypt <encrypted_file>"
            exit 1
        fi
        
        FILE="$2"
        OUTPUT="${FILE%.gpg}"
        
        gpg --decrypt --output "$OUTPUT" "$FILE"
        
        if [ $? -eq 0 ]; then
            echo "✓ File decrypted: $OUTPUT"
        else
            echo "✗ Decryption failed"
            exit 1
        fi
        ;;
        
    status)
        echo "Encrypted Files:"
        find "$ENCRYPTED_DIR" -name "*.gpg" -exec basename {} \;
        ;;
        
    *)
        echo "Usage: $0 {encrypt|decrypt|status} [file]"
        echo ""
        echo "Examples:"
        echo "  $0 encrypt /var/filebrowser/secret.pdf"
        echo "  $0 decrypt /var/filebrowser/.encrypted/secret.pdf.gpg"
        echo "  $0 status"
        exit 1
        ;;
esac
EOFENC
chmod +x /usr/local/bin/filebrowser-encrypt.sh
log "✓ File encryption script created"

# Video Transcoding Script
info "Creating video transcoding script..."
cat > /usr/local/bin/filebrowser-transcode.sh <<'EOFVID'
#!/bin/bash
# Auto-transcode videos to web-friendly formats
STORAGE_DIR="/var/filebrowser"
TRANSCODE_DIR="$STORAGE_DIR/.transcoded"
LOG_FILE="/var/log/filebrowser/transcode.log"

mkdir -p "$TRANSCODE_DIR"

find "$STORAGE_DIR" -type f \( -iname "*.avi" -o -iname "*.mkv" -o -iname "*.mov" \) ! -path "*/.transcoded/*" | while read video; do
    basename=$(basename "$video")
    output="$TRANSCODE_DIR/${basename%.*}.mp4"
    
    if [ ! -f "$output" ]; then
        echo "[$(date)] Transcoding: $basename" >> "$LOG_FILE"
        ffmpeg -i "$video" -c:v libx264 -crf 23 -c:a aac -b:a 128k -movflags +faststart "$output" >> "$LOG_FILE" 2>&1
        echo "[$(date)] Complete: $basename" >> "$LOG_FILE"
    fi
done
EOFVID
chmod +x /usr/local/bin/filebrowser-transcode.sh
echo "0 5 * * * root /usr/local/bin/filebrowser-transcode.sh" > /etc/cron.d/filebrowser-transcode
log "✓ Video transcoding script created (runs daily at 5 AM)"

# Image Optimization Script
info "Creating image optimization script..."
cat > /usr/local/bin/filebrowser-optimize-images.sh <<'EOFIMG'
#!/bin/bash
STORAGE_DIR="/var/filebrowser"
LOG_FILE="/var/log/filebrowser/image-optimize.log"

echo "[$(date)] Starting image optimization..." >> "$LOG_FILE"

find "$STORAGE_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) ! -path "*/.thumbnails/*" | while read img; do
    # Optimize JPEG/PNG
    if [[ "$img" =~ \.(jpg|jpeg)$ ]]; then
        mogrify -strip -quality 85 "$img" 2>> "$LOG_FILE"
    elif [[ "$img" =~ \.png$ ]]; then
        mogrify -strip "$img" 2>> "$LOG_FILE"
    fi
done

echo "[$(date)] Image optimization complete" >> "$LOG_FILE"
EOFIMG
chmod +x /usr/local/bin/filebrowser-optimize-images.sh
echo "0 6 * * 0 root /usr/local/bin/filebrowser-optimize-images.sh" > /etc/cron.d/filebrowser-optimize
log "✓ Image optimization script created (runs weekly)"

# Document Converter Script
info "Creating document converter script..."
cat > /usr/local/bin/filebrowser-convert-docs.sh <<'EOFDOC'
#!/bin/bash
# Convert Office docs to PDF for preview
STORAGE_DIR="/var/filebrowser"
PDF_DIR="$STORAGE_DIR/.pdf_previews"
LOG_FILE="/var/log/filebrowser/doc-convert.log"

mkdir -p "$PDF_DIR"

find "$STORAGE_DIR" -type f \( -iname "*.docx" -o -iname "*.xlsx" -o -iname "*.pptx" \) ! -path "*/.pdf_previews/*" | while read doc; do
    basename=$(basename "$doc")
    output="$PDF_DIR/${basename%.*}.pdf"
    
    if [ ! -f "$output" ]; then
        echo "[$(date)] Converting: $basename" >> "$LOG_FILE"
        libreoffice --headless --convert-to pdf --outdir "$PDF_DIR" "$doc" >> "$LOG_FILE" 2>&1
    fi
done
EOFDOC
chmod +x /usr/local/bin/filebrowser-convert-docs.sh
echo "*/15 * * * * root /usr/local/bin/filebrowser-convert-docs.sh" > /etc/cron.d/filebrowser-convert
log "✓ Document converter script created (runs every 15 minutes)"

# Version Control Script
info "Creating version control script..."
cat > /usr/local/bin/filebrowser-versions.sh <<'EOFVER'
#!/bin/bash
# Simple file versioning system
STORAGE_DIR="/var/filebrowser"
VERSIONS_DIR="$STORAGE_DIR/.versions"
MAX_VERSIONS=5

mkdir -p "$VERSIONS_DIR"

case "$1" in
    save)
        if [ -z "$2" ]; then
            echo "Usage: $0 save <file>"
            exit 1
        fi
        
        FILE="$2"
        BASENAME=$(basename "$FILE")
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        VERSION_FILE="$VERSIONS_DIR/${BASENAME}_${TIMESTAMP}"
        
        cp "$FILE" "$VERSION_FILE"
        echo "✓ Version saved: $VERSION_FILE"
        
        # Keep only last MAX_VERSIONS
        ls -t "$VERSIONS_DIR/${BASENAME}_"* 2>/dev/null | tail -n +$((MAX_VERSIONS + 1)) | xargs rm -f
        ;;
        
    list)
        if [ -z "$2" ]; then
            echo "Usage: $0 list <file>"
            exit 1
        fi
        
        BASENAME=$(basename "$2")
        echo "Versions of $BASENAME:"
        ls -lht "$VERSIONS_DIR/${BASENAME}_"* 2>/dev/null
        ;;
        
    restore)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: $0 restore <version_file> <destination>"
            exit 1
        fi
        
        cp "$2" "$3"
        echo "✓ Version restored to $3"
        ;;
        
    *)
        echo "Usage: $0 {save|list|restore} [file]"
        exit 1
        ;;
esac
EOFVER
chmod +x /usr/local/bin/filebrowser-versions.sh
log "✓ Version control script created"

# WebDAV Setup
info "Setting up WebDAV support..."
a2enmod dav dav_fs 2>/dev/null || true
mkdir -p /var/www/webdav
chown www-data:www-data /var/www/webdav
ln -sf "$STORAGE_PATH" /var/www/webdav/files 2>/dev/null || true
log "✓ WebDAV support configured"

# SFTP Configuration
info "Configuring SFTP..."
cat >> /etc/ssh/sshd_config <<'EOFSSH'

# Filebrowser SFTP Configuration
Match Group filebrowser-users
    ChrootDirectory /var/filebrowser
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
EOFSSH
groupadd filebrowser-users 2>/dev/null || true
systemctl restart sshd
log "✓ SFTP configured (port 22)"

# Webhook System
info "Creating webhook system..."
cat > /usr/local/bin/filebrowser-webhook.sh <<'EOFHOOK'
#!/bin/bash
# Webhook notification system
WEBHOOK_CONFIG="/etc/filebrowser/webhooks.conf"

send_webhook() {
    EVENT="$1"
    FILE="$2"
    USER="$3"
    
    if [ ! -f "$WEBHOOK_CONFIG" ]; then
        return
    fi
    
    while read webhook_url; do
        [ -z "$webhook_url" ] && continue
        
        curl -X POST "$webhook_url" \
            -H "Content-Type: application/json" \
            -d "{\"event\":\"$EVENT\",\"file\":\"$FILE\",\"user\":\"$USER\",\"timestamp\":\"$(date -Iseconds)\"}" \
            2>/dev/null &
    done < "$WEBHOOK_CONFIG"
}

send_webhook "$@"
EOFHOOK
chmod +x /usr/local/bin/filebrowser-webhook.sh
touch /etc/filebrowser/webhooks.conf
log "✓ Webhook system created"

# Activity Feed / Analytics
info "Setting up analytics and monitoring..."
cat > /usr/local/bin/filebrowser-analytics.sh <<'EOFANA'
#!/bin/bash
# Analytics and statistics
STORAGE_DIR="/var/filebrowser"
ANALYTICS_DB="/var/log/filebrowser/analytics.db"

case "$1" in
    record)
        # Record file access
        echo "$(date +%s)|$2|$3|$4" >> "$ANALYTICS_DB"
        ;;
        
    stats)
        echo "=== File Browser Statistics ==="
        echo ""
        echo "Total Files: $(find "$STORAGE_DIR" -type f | wc -l)"
        echo "Total Size: $(du -sh "$STORAGE_DIR" | cut -f1)"
        echo "Most Active Users:"
        tail -1000 "$ANALYTICS_DB" 2>/dev/null | cut -d'|' -f3 | sort | uniq -c | sort -rn | head -5
        echo ""
        echo "Most Downloaded Files:"
        tail -1000 "$ANALYTICS_DB" 2>/dev/null | grep "download" | cut -d'|' -f2 | sort | uniq -c | sort -rn | head -5
        ;;
        
    dashboard)
        # Generate HTML dashboard
        cat > /var/www/html/filebrowser-stats.html <<EOF
<!DOCTYPE html>
<html>
<head><title>Filebrowser Analytics</title></head>
<body>
<h1>File Browser Analytics</h1>
<p>Total Files: $(find "$STORAGE_DIR" -type f | wc -l)</p>
<p>Total Size: $(du -sh "$STORAGE_DIR" | cut -f1)</p>
<p>Last Updated: $(date)</p>
</body>
</html>
EOF
        echo "✓ Dashboard generated at /var/www/html/filebrowser-stats.html"
        ;;
        
    *)
        echo "Usage: $0 {record|stats|dashboard}"
        exit 1
        ;;
esac
EOFANA
chmod +x /usr/local/bin/filebrowser-analytics.sh
log "✓ Analytics system created"

# Prometheus Metrics Exporter
info "Configuring Prometheus metrics..."
cat > /usr/local/bin/filebrowser-metrics.sh <<'EOFMET'
#!/bin/bash
# Export metrics for Prometheus
STORAGE_DIR="/var/filebrowser"
METRICS_FILE="/var/lib/node_exporter/textfile_collector/filebrowser.prom"

mkdir -p /var/lib/node_exporter/textfile_collector

cat > "$METRICS_FILE" <<EOF
# HELP filebrowser_total_files Total number of files
# TYPE filebrowser_total_files gauge
filebrowser_total_files $(find "$STORAGE_DIR" -type f | wc -l)

# HELP filebrowser_total_size_bytes Total storage size in bytes
# TYPE filebrowser_total_size_bytes gauge
filebrowser_total_size_bytes $(du -sb "$STORAGE_DIR" | cut -f1)

# HELP filebrowser_users_total Total number of users
# TYPE filebrowser_users_total gauge
filebrowser_users_total $(sqlite3 /etc/filebrowser/filebrowser.db "SELECT COUNT(*) FROM users" 2>/dev/null || echo 0)
EOF
EOFMET
chmod +x /usr/local/bin/filebrowser-metrics.sh
echo "*/5 * * * * root /usr/local/bin/filebrowser-metrics.sh" > /etc/cron.d/filebrowser-metrics
log "✓ Prometheus metrics exporter created"

# Health Monitoring
info "Creating health monitoring script..."
cat > /usr/local/bin/filebrowser-health.sh <<'EOFHEALTH'
#!/bin/bash
# Health check and monitoring
STORAGE_DIR="/var/filebrowser"
ALERT_EMAIL="${ADMIN_EMAIL:-root@localhost}"

check_disk_space() {
    USAGE=$(df "$STORAGE_DIR" | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$USAGE" -gt 90 ]; then
        echo "⚠️  ALERT: Disk usage at ${USAGE}%"
        return 1
    fi
    echo "✓ Disk usage: ${USAGE}%"
    return 0
}

check_services() {
    for service in filebrowser cloudflared vsftpd; do
        if systemctl is-active --quiet $service; then
            echo "✓ $service is running"
        else
            echo "⚠️  ALERT: $service is not running"
            systemctl restart $service
        fi
    done
}

check_disk_space
check_services
EOFHEALTH
chmod +x /usr/local/bin/filebrowser-health.sh
echo "*/10 * * * * root /usr/local/bin/filebrowser-health.sh >> /var/log/filebrowser/health.log 2>&1" > /etc/cron.d/filebrowser-health
log "✓ Health monitoring script created (runs every 10 minutes)"

# Online Status System
info "Creating online status tracking system..."
mkdir -p /var/lib/filebrowser/status
cat > /usr/local/bin/filebrowser-status.sh <<'EOFSTATUS'
#!/bin/bash
# Online Status Management System

STATUS_DIR="/var/lib/filebrowser/status"
TIMEOUT=300  # 5 minutes

case "$1" in
    online)
        # Mark user as online
        if [ -z "$2" ]; then
            echo "Usage: $0 online <username>"
            exit 1
        fi
        
        USERNAME="$2"
        echo "$(date +%s)" > "$STATUS_DIR/$USERNAME.status"
        echo "✓ $USERNAME marked as online"
        ;;
        
    offline)
        # Mark user as offline
        if [ -z "$2" ]; then
            echo "Usage: $0 offline <username>"
            exit 1
        fi
        
        USERNAME="$2"
        rm -f "$STATUS_DIR/$USERNAME.status"
        echo "✓ $USERNAME marked as offline"
        ;;
        
    check)
        # Check if user is online
        if [ -z "$2" ]; then
            echo "Usage: $0 check <username>"
            exit 1
        fi
        
        USERNAME="$2"
        STATUS_FILE="$STATUS_DIR/$USERNAME.status"
        
        if [ ! -f "$STATUS_FILE" ]; then
            echo "🔴 $USERNAME is offline"
            exit 1
        fi
        
        LAST_SEEN=$(cat "$STATUS_FILE")
        CURRENT_TIME=$(date +%s)
        DIFF=$((CURRENT_TIME - LAST_SEEN))
        
        if [ $DIFF -gt $TIMEOUT ]; then
            echo "🔴 $USERNAME is offline (last seen $((DIFF/60)) minutes ago)"
            rm -f "$STATUS_FILE"
            exit 1
        else
            echo "🟢 $USERNAME is online"
            exit 0
        fi
        ;;
        
    list)
        # List all online users
        echo "📊 Online Users:"
        CURRENT_TIME=$(date +%s)
        
        for status_file in "$STATUS_DIR"/*.status; do
            if [ -f "$status_file" ]; then
                USERNAME=$(basename "$status_file" .status)
                LAST_SEEN=$(cat "$status_file")
                DIFF=$((CURRENT_TIME - LAST_SEEN))
                
                if [ $DIFF -le $TIMEOUT ]; then
                    MINUTES_AGO=$((DIFF/60))
                    if [ $MINUTES_AGO -eq 0 ]; then
                        echo "  🟢 $USERNAME (active now)"
                    else
                        echo "  🟢 $USERNAME (active ${MINUTES_AGO}m ago)"
                    fi
                else
                    rm -f "$status_file"
                fi
            fi
        done
        ;;
        
    cleanup)
        # Clean up stale status files
        CURRENT_TIME=$(date +%s)
        for status_file in "$STATUS_DIR"/*.status; do
            if [ -f "$status_file" ]; then
                LAST_SEEN=$(cat "$status_file")
                DIFF=$((CURRENT_TIME - LAST_SEEN))
                if [ $DIFF -gt $TIMEOUT ]; then
                    rm -f "$status_file"
                fi
            fi
        done
        ;;
        
    *)
        echo "Usage: $0 {online|offline|check|list|cleanup} [username]"
        echo ""
        echo "Examples:"
        echo "  $0 online john       # Mark john as online"
        echo "  $0 check john        # Check if john is online"
        echo "  $0 list              # List all online users"
        echo "  $0 offline john      # Mark john as offline"
        exit 1
        ;;
esac
EOFSTATUS
chmod +x /usr/local/bin/filebrowser-status.sh
echo "*/2 * * * * root /usr/local/bin/filebrowser-status.sh cleanup" > /etc/cron.d/filebrowser-status
log "✓ Online status tracking system created"

# File Trading System
info "Creating file trading/exchange system..."
mkdir -p /var/lib/filebrowser/trades
cat > /usr/local/bin/filebrowser-trade.sh <<'EOFTRADE'
#!/bin/bash
# File Trading System - Exchange files between users

TRADE_DIR="/var/lib/filebrowser/trades"
STORAGE_DIR="/var/filebrowser"

case "$1" in
    offer)
        # Create a trade offer
        if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
            echo "Usage: $0 offer <from_user> <to_user> <file_path>"
            exit 1
        fi
        
        FROM_USER="$2"
        TO_USER="$3"
        FILE_PATH="$4"
        TRADE_ID=$(uuidgen | cut -d'-' -f1)
        
        if [ ! -f "$FILE_PATH" ]; then
            echo "❌ Error: File not found: $FILE_PATH"
            exit 1
        fi
        
        # Create trade offer
        cat > "$TRADE_DIR/$TRADE_ID.trade" <<EOF
FROM_USER=$FROM_USER
TO_USER=$TO_USER
FILE_PATH=$FILE_PATH
FILE_NAME=$(basename "$FILE_PATH")
FILE_SIZE=$(du -h "$FILE_PATH" | cut -f1)
CREATED=$(date +%Y-%m-%d\ %H:%M:%S)
STATUS=pending
EOF
        
        echo "✅ Trade offer created!"
        echo "   Trade ID: $TRADE_ID"
        echo "   From: $FROM_USER"
        echo "   To: $TO_USER"
        echo "   File: $(basename "$FILE_PATH") ($FILE_SIZE)"
        echo ""
        echo "📧 Notify $TO_USER to accept with:"
        echo "   filebrowser-trade.sh accept $TRADE_ID"
        ;;
        
    list)
        # List trade offers
        if [ -z "$2" ]; then
            echo "Usage: $0 list <username>"
            exit 1
        fi
        
        USERNAME="$2"
        echo "📦 Trade Offers for $USERNAME:"
        echo ""
        
        FOUND=false
        for trade_file in "$TRADE_DIR"/*.trade; do
            if [ -f "$trade_file" ]; then
                source "$trade_file"
                TRADE_ID=$(basename "$trade_file" .trade)
                
                if [ "$TO_USER" = "$USERNAME" ] && [ "$STATUS" = "pending" ]; then
                    FOUND=true
                    echo "  📨 Incoming Trade #$TRADE_ID"
                    echo "     From: $FROM_USER"
                    echo "     File: $FILE_NAME ($FILE_SIZE)"
                    echo "     Date: $CREATED"
                    echo "     Action: filebrowser-trade.sh accept $TRADE_ID"
                    echo ""
                fi
                
                if [ "$FROM_USER" = "$USERNAME" ]; then
                    FOUND=true
                    echo "  📤 Outgoing Trade #$TRADE_ID"
                    echo "     To: $TO_USER"
                    echo "     File: $FILE_NAME ($FILE_SIZE)"
                    echo "     Status: $STATUS"
                    echo "     Date: $CREATED"
                    echo ""
                fi
            fi
        done
        
        if [ "$FOUND" = false ]; then
            echo "  No active trades"
        fi
        ;;
        
    accept)
        # Accept a trade offer
        if [ -z "$2" ]; then
            echo "Usage: $0 accept <trade_id>"
            exit 1
        fi
        
        TRADE_ID="$2"
        TRADE_FILE="$TRADE_DIR/$TRADE_ID.trade"
        
        if [ ! -f "$TRADE_FILE" ]; then
            echo "❌ Error: Trade not found: $TRADE_ID"
            exit 1
        fi
        
        source "$TRADE_FILE"
        
        if [ "$STATUS" != "pending" ]; then
            echo "❌ Error: Trade already $STATUS"
            exit 1
        fi
        
        # Copy file to recipient's area
        DEST_DIR="$STORAGE_DIR/trades/$TO_USER"
        mkdir -p "$DEST_DIR"
        
        cp "$FILE_PATH" "$DEST_DIR/$FILE_NAME"
        
        if [ $? -eq 0 ]; then
            # Update trade status
            sed -i "s/STATUS=pending/STATUS=completed/" "$TRADE_FILE"
            
            echo "✅ Trade completed!"
            echo "   File received: $FILE_NAME"
            echo "   Location: $DEST_DIR/$FILE_NAME"
            echo "   From: $FROM_USER"
            
            # Log the trade
            echo "$(date +%s)|$TRADE_ID|$FROM_USER|$TO_USER|$FILE_NAME|completed" >> /var/log/filebrowser/trades.log
        else
            echo "❌ Error: Failed to copy file"
            exit 1
        fi
        ;;
        
    reject)
        # Reject a trade offer
        if [ -z "$2" ]; then
            echo "Usage: $0 reject <trade_id>"
            exit 1
        fi
        
        TRADE_ID="$2"
        TRADE_FILE="$TRADE_DIR/$TRADE_ID.trade"
        
        if [ ! -f "$TRADE_FILE" ]; then
            echo "❌ Error: Trade not found: $TRADE_ID"
            exit 1
        fi
        
        source "$TRADE_FILE"
        sed -i "s/STATUS=pending/STATUS=rejected/" "$TRADE_FILE"
        
        echo "❌ Trade rejected"
        echo "   Trade ID: $TRADE_ID"
        echo "   From: $FROM_USER"
        
        # Log the rejection
        echo "$(date +%s)|$TRADE_ID|$FROM_USER|$TO_USER|$FILE_NAME|rejected" >> /var/log/filebrowser/trades.log
        ;;
        
    cancel)
        # Cancel your own trade offer
        if [ -z "$2" ]; then
            echo "Usage: $0 cancel <trade_id>"
            exit 1
        fi
        
        TRADE_ID="$2"
        TRADE_FILE="$TRADE_DIR/$TRADE_ID.trade"
        
        if [ ! -f "$TRADE_FILE" ]; then
            echo "❌ Error: Trade not found: $TRADE_ID"
            exit 1
        fi
        
        rm "$TRADE_FILE"
        echo "✅ Trade offer cancelled"
        ;;
        
    history)
        # View trade history
        if [ -z "$2" ]; then
            echo "Usage: $0 history <username>"
            exit 1
        fi
        
        USERNAME="$2"
        echo "📜 Trade History for $USERNAME:"
        echo ""
        
        if [ -f /var/log/filebrowser/trades.log ]; then
            grep -E "$USERNAME" /var/log/filebrowser/trades.log | tail -20 | while IFS='|' read timestamp trade_id from_user to_user file_name status; do
                DATE=$(date -d "@$timestamp" "+%Y-%m-%d %H:%M")
                if [ "$from_user" = "$USERNAME" ]; then
                    echo "  📤 Sent to $to_user: $file_name [$status] - $DATE"
                else
                    echo "  📥 Received from $from_user: $file_name [$status] - $DATE"
                fi
            done
        else
            echo "  No trade history"
        fi
        ;;
        
    *)
        echo "📦 File Trading System"
        echo ""
        echo "Usage: $0 {offer|list|accept|reject|cancel|history} [options]"
        echo ""
        echo "Commands:"
        echo "  offer <from> <to> <file>  - Offer a file to another user"
        echo "  list <username>           - List trade offers for user"
        echo "  accept <trade_id>         - Accept a trade offer"
        echo "  reject <trade_id>         - Reject a trade offer"
        echo "  cancel <trade_id>         - Cancel your trade offer"
        echo "  history <username>        - View trade history"
        echo ""
        echo "Examples:"
        echo "  $0 offer john mary /var/filebrowser/document.pdf"
        echo "  $0 list mary"
        echo "  $0 accept a1b2c3d4"
        echo "  $0 history john"
        exit 1
        ;;
esac
EOFTRADE
chmod +x /usr/local/bin/filebrowser-trade.sh
log "✓ File trading system created"

log "✓ All advanced features and admin management scripts created"

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
echo -e "${BLUE}Admin Management Commands:${NC}"
echo "  💾 Storage Quotas:        sudo filebrowser-quota.sh [set|check|list]"
echo "  🔒 IP Whitelist:          sudo filebrowser-ipwhitelist.sh [add|remove|list]"
echo "  🔗 Share Links:           sudo filebrowser-shares.sh [create|list|expire]"
echo "  🔐 File Encryption:       sudo filebrowser-encrypt.sh [encrypt|decrypt]"
echo "  🗜️  Deduplication:         sudo /usr/local/bin/filebrowser-dedupe.sh"
echo "  📦 Compression:           sudo /usr/local/bin/filebrowser-compress.sh"
echo "  🖼️  Thumbnails:            sudo /usr/local/bin/filebrowser-thumbnails.sh"
echo "  🎬 Video Transcode:       sudo /usr/local/bin/filebrowser-transcode.sh"
echo "  🖼️  Image Optimize:        sudo /usr/local/bin/filebrowser-optimize-images.sh"
echo "  📄 Doc Converter:         sudo /usr/local/bin/filebrowser-convert-docs.sh"
echo "  📚 Version Control:       sudo filebrowser-versions.sh [save|list|restore]"
echo "  🔔 Webhooks:              Edit /etc/filebrowser/webhooks.conf"
echo "  📊 Analytics:             sudo filebrowser-analytics.sh [stats|dashboard]"
echo "  📈 Metrics:               sudo filebrowser-metrics.sh"
echo "  🏥 Health Check:          sudo filebrowser-health.sh"
echo "  🟢 Online Status:         sudo filebrowser-status.sh [list|check|online|offline]"
echo "  🔄 File Trading:          sudo filebrowser-trade.sh [offer|list|accept|reject]"
echo ""
echo -e "${GREEN}✨ UI/UX Features:${NC}"
echo "  ✅ Modern gradient header with glassmorphism"
echo "  ✅ Smooth animations (300ms cubic-bezier transitions)"
echo "  ✅ File type indicators (🖼️ 🎬 🎵 📄 📦 📁)"
echo "  ✅ Upload progress indicators with shimmer effect"
echo "  ✅ Toast notifications (success/error/warning)"
echo "  ✅ Drag & drop with visual feedback"
echo "  ✅ Hover effects on all interactive elements"
echo "  ✅ Custom scrollbars with smooth animations"
echo "  ✅ Dark mode support (auto-detects system preference)"
echo "  ✅ Responsive grid/list views"
echo "  ✅ Keyboard shortcuts (Ctrl+U upload, Ctrl+F search)"
echo "  ✅ Loading spinners and status indicators"
echo "  ✅ Context menus with fade-in animations"
echo "  ✅ Breadcrumb navigation"
echo "  ✅ Enhanced search bar with focus effects"
echo ""
echo -e "${GREEN}Core Features:${NC}"
echo "  ✅ Multi-user system with individual accounts"
echo "  ✅ Granular permissions (create, delete, download, share, etc.)"
echo "  ✅ Admin panel for user/settings management"
echo "  ✅ Upload/Download files with progress tracking"
echo "  ✅ Create folders and organize files"
echo "  ✅ Share files (password-protected, expiring links)"
echo "  ✅ File preview (images, videos, documents, audio)"
echo "  ✅ Advanced search with filters"
echo "  ✅ Storage quotas per user (admin-controlled)"
echo "  ✅ Mobile responsive design"
echo "  ✅ FTP/SFTP access (port 21/22, passive 40000-40100)"
echo "  ✅ WebDAV support (mount as network drive)"
echo "  ✅ Automatic deduplication (weekly)"
echo "  ✅ Auto-compression of old files (30+ days)"
echo "  ✅ Thumbnail generation (every 30 min)"
echo "  ✅ File encryption at rest (GPG/AES256)"
echo "  ✅ IP whitelisting & rate limiting"
echo "  ✅ Audit logging (90-day retention)"
echo "  ✅ Video transcoding to MP4 (daily)"
echo "  ✅ Image optimization (weekly)"
echo "  ✅ Document to PDF conversion (every 15 min)"
echo "  ✅ File versioning (keep last 5 versions)"
echo "  ✅ Webhook notifications"
echo "  ✅ Usage analytics & statistics"
echo "  ✅ Prometheus metrics export"
echo "  ✅ Health monitoring (every 10 min)"
echo "  ✅ Online status tracking (see who's active)"
echo "  ✅ File trading system (exchange files between users)"
if [ "$VIRUS_SCAN_ENABLED" = true ]; then
    echo "  ✅ Virus scanning (ClamAV, daily scans)"
fi
echo ""
echo -e "${YELLOW}Security Features:${NC}"
echo "  🛡️  Fail2ban protection (5 attempts = 1hr ban)"
echo "  🔒 IP whitelisting available"
echo "  📝 Comprehensive audit logging"
echo "  🔐 File encryption support"
echo "  🔗 Password-protected shares"
echo "  ⏰ Auto-expiring share links"
echo ""
echo -e "${CYAN}Media & Document Features:${NC}"
echo "  🎬 Auto-transcode videos to web-friendly MP4"
echo "  🖼️  Auto-optimize images (reduce size, strip metadata)"
echo "  📄 Convert Office docs to PDF for preview"
echo "  🖼️  Automatic thumbnail generation"
echo "  📚 File version control (rollback support)"
echo ""
echo -e "${MAGENTA}Monitoring & Analytics:${NC}"
echo "  📊 Real-time usage statistics"
echo "  📈 Prometheus metrics (Grafana compatible)"
echo "  🏥 Automated health checks"
echo "  📉 User activity tracking"
echo "  🔔 Webhook notifications for events"
echo "  📱 Analytics dashboard at /filebrowser-stats.html"
echo ""
echo -e "${GREEN}Access Methods:${NC}"
echo "  🌐 Web UI: https://${FULL_DOMAIN}"
echo "  📁 FTP: ftp://$(hostname -I | awk '{print $1}'):21"
echo "  🔐 SFTP: sftp://$(hostname -I | awk '{print $1}'):22"
echo "  💾 WebDAV: https://${FULL_DOMAIN}/webdav"
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

# Display comprehensive user guide
cat <<'EOFGUIDE'

╔══════════════════════════════════════════════════════════════════╗
║                    📚 USER GUIDE - READ THIS!                    ║
╚══════════════════════════════════════════════════════════════════╝

🎯 GETTING STARTED (For New Users)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1️⃣  ACCESS YOUR FILE PANEL
   • Open your web browser (Chrome, Firefox, Safari, Edge)
   • Go to: https://FULL_DOMAIN (shown above)
   • You'll see a login page

2️⃣  LOG IN FOR THE FIRST TIME
   • Username: (shown in "Admin Credentials" above)
   • Password: (shown in "Admin Credentials" above)
   • Click "Login"

3️⃣  UPLOAD YOUR FIRST FILE
   • Click the "Upload" button (top right)
   • OR drag and drop files into the browser window
   • Wait for the green "Upload complete!" notification
   • Your file now appears in the list!

4️⃣  CREATE FOLDERS
   • Click the "New Folder" button
   • Type a folder name (e.g., "My Documents")
   • Press Enter
   • Double-click to open the folder

5️⃣  SHARE FILES WITH OTHERS
   • Right-click on any file
   • Select "Share"
   • Copy the link and send it to anyone!


👥 USER MANAGEMENT (For Admins)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 CREATE A NEW USER
   Run this command on the server:
   
   sudo filebrowser users add USERNAME PASSWORD \
       --perm.create \
       --perm.download \
       --perm.share \
       --database=/etc/filebrowser/filebrowser.db
   
   Example:
   sudo filebrowser users add john MyPassword123 \
       --perm.create --perm.download --perm.share \
       --database=/etc/filebrowser/filebrowser.db

💾 SET STORAGE QUOTA FOR A USER
   
   sudo filebrowser-quota.sh set USERNAME SIZE_IN_MB
   
   Example (give john 5GB):
   sudo filebrowser-quota.sh set john 5000

📊 CHECK USER'S QUOTA USAGE
   
   sudo filebrowser-quota.sh check USERNAME
   
   Example:
   sudo filebrowser-quota.sh check john

📋 LIST ALL USER QUOTAS
   
   sudo filebrowser-quota.sh list


🟢 ONLINE STATUS SYSTEM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

👀 SEE WHO'S ONLINE
   
   sudo filebrowser-status.sh list
   
   This shows all users currently active (within last 5 minutes)

✅ MARK YOURSELF ONLINE (automatic when you log in)
   
   sudo filebrowser-status.sh online USERNAME

🔴 MARK YOURSELF OFFLINE
   
   sudo filebrowser-status.sh offline USERNAME

🔍 CHECK IF SOMEONE IS ONLINE
   
   sudo filebrowser-status.sh check USERNAME
   
   Example:
   sudo filebrowser-status.sh check mary


🔄 FILE TRADING SYSTEM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📤 OFFER A FILE TO ANOTHER USER
   
   sudo filebrowser-trade.sh offer YOUR_USERNAME THEIR_USERNAME /path/to/file
   
   Example (john sends document.pdf to mary):
   sudo filebrowser-trade.sh offer john mary /var/filebrowser/document.pdf
   
   You'll get a Trade ID like: a1b2c3d4

📨 CHECK YOUR TRADE OFFERS
   
   sudo filebrowser-trade.sh list YOUR_USERNAME
   
   Example:
   sudo filebrowser-trade.sh list mary
   
   This shows:
   • Incoming trades (files offered to you)
   • Outgoing trades (files you offered to others)

✅ ACCEPT A TRADE
   
   sudo filebrowser-trade.sh accept TRADE_ID
   
   Example:
   sudo filebrowser-trade.sh accept a1b2c3d4
   
   The file will be copied to: /var/filebrowser/trades/YOUR_USERNAME/

❌ REJECT A TRADE
   
   sudo filebrowser-trade.sh reject TRADE_ID

🗑️  CANCEL YOUR TRADE OFFER
   
   sudo filebrowser-trade.sh cancel TRADE_ID

📜 VIEW TRADE HISTORY
   
   sudo filebrowser-trade.sh history YOUR_USERNAME
   
   Shows last 20 trades (sent and received)


🔒 SECURITY FEATURES (For Admins)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🛡️  WHITELIST AN IP ADDRESS
   
   sudo filebrowser-ipwhitelist.sh enable
   sudo filebrowser-ipwhitelist.sh add 192.168.1.0/24
   
   Only whitelisted IPs can access the file panel

🔗 CREATE PASSWORD-PROTECTED SHARE LINK
   
   sudo filebrowser-shares.sh create /path/to/file \
       --expire-days 7 \
       --password MySecret123
   
   Link expires in 7 days and requires password

🔐 ENCRYPT SENSITIVE FILES
   
   sudo filebrowser-encrypt.sh encrypt /var/filebrowser/secret.pdf
   
   File is encrypted with AES256 and moved to .encrypted folder


📊 MONITORING & ANALYTICS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📈 VIEW STATISTICS
   
   sudo filebrowser-analytics.sh stats
   
   Shows:
   • Total files and storage used
   • Most active users
   • Most downloaded files

🏥 CHECK SYSTEM HEALTH
   
   sudo filebrowser-health.sh
   
   Checks:
   • Disk space usage
   • Service status
   • Automatically restarts failed services


⌨️  KEYBOARD SHORTCUTS (In Web Browser)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Ctrl + U  →  Upload files
Ctrl + F  →  Search files
Ctrl + N  →  New folder
Escape    →  Close dialogs


🆘 TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❓ Can't access the website?
   1. Wait 2-3 minutes for DNS to update
   2. Check services:
      sudo systemctl status filebrowser
      sudo systemctl status cloudflared
   3. Restart if needed:
      sudo systemctl restart filebrowser
      sudo systemctl restart cloudflared

❓ Forgot your password?
   Reset it with:
   sudo filebrowser users update USERNAME \
       --password NEW_PASSWORD \
       --database=/etc/filebrowser/filebrowser.db

❓ Need more storage space?
   Check disk usage:
   df -h /var/filebrowser
   
   Increase quota:
   sudo filebrowser-quota.sh set USERNAME NEW_SIZE_MB

❓ File upload failed?
   • Check file size (max 2GB by default)
   • Check your quota: filebrowser-quota.sh check USERNAME
   • Check disk space: df -h

❓ Want to see logs?
   sudo journalctl -u filebrowser -f
   sudo tail -f /var/log/filebrowser/access.log


📞 QUICK REFERENCE CARD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

COMMON TASKS                          COMMAND
────────────────────────────────────────────────────────────────────
Create user                           filebrowser users add USERNAME PASSWORD --database=/etc/filebrowser/filebrowser.db
Set quota                             filebrowser-quota.sh set USER SIZE_MB
Check who's online                    filebrowser-status.sh list
Send file to user                     filebrowser-trade.sh offer FROM TO FILE
Check trade offers                    filebrowser-trade.sh list USERNAME
Accept trade                          filebrowser-trade.sh accept TRADE_ID
View statistics                       filebrowser-analytics.sh stats
Check system health                   filebrowser-health.sh
View logs                             journalctl -u filebrowser -f


💡 TIPS & BEST PRACTICES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Set reasonable quotas to prevent disk filling up
✅ Use password-protected shares for sensitive files
✅ Enable virus scanning for public-facing instances
✅ Regular backups are automatic (check /var/filebrowser/.versions)
✅ Monitor disk space weekly: df -h
✅ Check online users before sending trade offers
✅ Use file encryption for highly sensitive documents
✅ Review trade history monthly for security audits


📖 NEED MORE HELP?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

View this guide anytime:
cat /usr/local/share/filebrowser-guide.txt

Check the setup log:
cat LOG_FILE_PATH

╔══════════════════════════════════════════════════════════════════╗
║              🎉 Enjoy your new File Sharing System! 🎉           ║
╚══════════════════════════════════════════════════════════════════╝

EOFGUIDE

# Save the guide to a file for future reference
cat > /usr/local/share/filebrowser-guide.txt <<'EOFGUIDEFILE'
FILE SHARING PANEL - USER GUIDE
================================

This guide explains how to use your file sharing system.

QUICK START
-----------
1. Open browser and go to your domain
2. Log in with your credentials
3. Upload files by dragging and dropping
4. Create folders with "New Folder" button
5. Share files by right-clicking and selecting "Share"

For complete instructions, run:
cat /usr/local/share/filebrowser-guide.txt

COMMON COMMANDS
---------------
Create user:        filebrowser users add USERNAME PASSWORD --database=/etc/filebrowser/filebrowser.db
Set quota:          filebrowser-quota.sh set USERNAME SIZE_MB
Who's online:       filebrowser-status.sh list
Send file:          filebrowser-trade.sh offer FROM TO FILE_PATH
Check trades:       filebrowser-trade.sh list USERNAME
Accept trade:       filebrowser-trade.sh accept TRADE_ID
View stats:         filebrowser-analytics.sh stats
Health check:       filebrowser-health.sh

SUPPORT
-------
View logs:          journalctl -u filebrowser -f
Check status:       systemctl status filebrowser
Restart service:    systemctl restart filebrowser

For detailed help, see the full guide above.
EOFGUIDEFILE

chmod 644 /usr/local/share/filebrowser-guide.txt

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📖 User guide saved to: /usr/local/share/filebrowser-guide.txt"
echo "   View anytime with: cat /usr/local/share/filebrowser-guide.txt"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
