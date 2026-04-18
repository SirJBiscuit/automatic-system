#!/bin/bash

# Cloud Backup Script for Pterodactyl Game Servers
# Supports Google Drive and Mega.nz

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

prompt_yes_no() {
    local prompt="$1"
    local response
    
    while true; do
        read -p "$prompt (y/n): " response
        case $response in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

show_banner() {
    cat <<'EOF'

╔════════════════════════════════════════════════════════════════════════╗
║              PTERODACTYL CLOUD BACKUP TOOL                             ║
║           Backup game servers to Google Drive or Mega.nz               ║
╚════════════════════════════════════════════════════════════════════════╝

EOF
}

backup_to_gdrive() {
    echo ""
    log_info "╔════════════════════════════════════════════════════════════════════════╗"
    log_info "║                  GOOGLE DRIVE BACKUP                                   ║"
    log_info "╚════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Check if game servers exist
    if [ ! -d "/var/lib/pterodactyl/volumes" ]; then
        log_error "No game server files found at /var/lib/pterodactyl/volumes"
        exit 1
    fi
    
    GAME_SIZE=$(du -sh /var/lib/pterodactyl/volumes 2>/dev/null | cut -f1)
    log_info "Game server size: $GAME_SIZE"
    echo ""
    
    # Check if rclone is installed
    if ! command -v rclone &> /dev/null; then
        log_info "Installing rclone..."
        curl https://rclone.org/install.sh | bash
        
        if [ $? -ne 0 ]; then
            log_error "Failed to install rclone!"
            exit 1
        fi
        
        log_success "Rclone installed!"
    fi
    
    echo ""
    log_info "Setting up Google Drive connection..."
    echo ""
    
    # Check if gdrive remote already exists
    if rclone listremotes | grep -q "gdrive:"; then
        log_success "Google Drive already configured!"
    else
        log_info "First-time setup required!"
        echo ""
        log_info "This will:"
        echo "  1. Open your browser for Google authentication"
        echo "  2. Ask you to grant rclone access to Google Drive"
        echo "  3. Save the credentials for future use"
        echo ""
        
        if ! prompt_yes_no "Continue with Google Drive setup?"; then
            log_info "Setup cancelled"
            exit 0
        fi
        
        echo ""
        log_info "Configuring Google Drive remote..."
        
        # Auto-configure Google Drive
        rclone config create gdrive drive \
            config_is_local=false \
            scope=drive
        
        if [ $? -ne 0 ]; then
            log_error "Failed to configure Google Drive!"
            log_info "You can manually configure with: rclone config"
            exit 1
        fi
        
        log_success "Google Drive configured!"
    fi
    
    # Create backup directory name
    BACKUP_DIR="Pterodactyl-Backups/gameservers-$(date +%Y%m%d-%H%M%S)"
    
    echo ""
    log_info "Starting backup to Google Drive..."
    log_info "Destination: gdrive:/$BACKUP_DIR"
    log_info "Size: $GAME_SIZE"
    echo ""
    log_warning "This may take a while depending on your upload speed..."
    echo ""
    
    # Upload with progress
    rclone copy /var/lib/pterodactyl/volumes "gdrive:/$BACKUP_DIR" \
        --progress \
        --transfers 4 \
        --checkers 8 \
        --stats 10s \
        --stats-one-line
    
    if [ $? -eq 0 ]; then
        echo ""
        log_success "╔════════════════════════════════════════════════════════════════════════╗"
        log_success "║                  BACKUP SUCCESSFUL!                                    ║"
        log_success "╚════════════════════════════════════════════════════════════════════════╝"
        echo ""
        log_info "Game servers backed up to Google Drive!"
        log_info "Location: $BACKUP_DIR"
        echo ""
        
        # Create restore instructions
        cat > /tmp/RESTORE_INSTRUCTIONS.txt <<EOF
Pterodactyl Game Server Backup - Google Drive
==============================================
Backup Date: $(date)
Backup Size: $GAME_SIZE
Google Drive Location: $BACKUP_DIR

To Restore:
-----------
1. Install rclone (if not installed):
   curl https://rclone.org/install.sh | bash

2. Configure Google Drive (if not configured):
   rclone config

3. Restore files:
   rclone copy "gdrive:/$BACKUP_DIR" /var/lib/pterodactyl/volumes --progress

4. Fix permissions:
   chown -R pterodactyl:pterodactyl /var/lib/pterodactyl/volumes

5. Restart Wings:
   systemctl restart wings

Files Backed Up:
$(rclone ls "gdrive:/$BACKUP_DIR" | head -20)
...
EOF
        
        # Upload restore instructions
        rclone copy /tmp/RESTORE_INSTRUCTIONS.txt "gdrive:/$BACKUP_DIR/"
        
        log_info "Restore instructions uploaded to Google Drive"
        echo ""
        log_success "✓ Backup complete! Check your Google Drive."
        
    else
        log_error "Backup failed!"
        exit 1
    fi
}

backup_to_mega() {
    echo ""
    log_info "╔════════════════════════════════════════════════════════════════════════╗"
    log_info "║                     MEGA.NZ BACKUP                                     ║"
    log_info "╚════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Check if game servers exist
    if [ ! -d "/var/lib/pterodactyl/volumes" ]; then
        log_error "No game server files found at /var/lib/pterodactyl/volumes"
        exit 1
    fi
    
    GAME_SIZE=$(du -sh /var/lib/pterodactyl/volumes 2>/dev/null | cut -f1)
    log_info "Game server size: $GAME_SIZE"
    echo ""
    
    # Check if megatools is installed
    if ! command -v megacopy &> /dev/null; then
        log_info "Installing MEGAcmd..."
        
        # Detect OS and install
        if [ -f /etc/debian_version ]; then
            # Debian/Ubuntu
            wget https://mega.nz/linux/repo/Debian_12/amd64/megacmd-Debian_12_amd64.deb
            apt install -y ./megacmd-Debian_12_amd64.deb
            rm megacmd-Debian_12_amd64.deb
        else
            log_error "Unsupported OS for automatic MEGAcmd installation"
            log_info "Please install MEGAcmd manually from: https://mega.nz/cmd"
            exit 1
        fi
        
        if [ $? -ne 0 ]; then
            log_error "Failed to install MEGAcmd!"
            exit 1
        fi
        
        log_success "MEGAcmd installed!"
    fi
    
    echo ""
    log_info "Setting up Mega.nz connection..."
    echo ""
    
    # Check if already logged in
    if mega-whoami &> /dev/null; then
        MEGA_USER=$(mega-whoami)
        log_success "Already logged in as: $MEGA_USER"
    else
        log_info "Mega.nz login required!"
        echo ""
        read -p "Enter your Mega.nz email: " MEGA_EMAIL
        read -sp "Enter your Mega.nz password: " MEGA_PASS
        echo ""
        
        mega-login "$MEGA_EMAIL" "$MEGA_PASS"
        
        if [ $? -ne 0 ]; then
            log_error "Failed to login to Mega.nz!"
            log_info "Please check your credentials and try again"
            exit 1
        fi
        
        log_success "Logged in to Mega.nz!"
    fi
    
    # Create backup directory
    BACKUP_DIR="/Pterodactyl-Backups/gameservers-$(date +%Y%m%d-%H%M%S)"
    
    echo ""
    log_info "Creating backup directory on Mega.nz..."
    mega-mkdir -p "$BACKUP_DIR"
    
    echo ""
    log_info "Starting backup to Mega.nz..."
    log_info "Destination: $BACKUP_DIR"
    log_info "Size: $GAME_SIZE"
    echo ""
    log_warning "This may take a while depending on your upload speed..."
    echo ""
    
    # Create temporary archive
    TEMP_ARCHIVE="/tmp/pterodactyl-gameservers-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    log_info "Creating compressed archive..."
    tar -czf "$TEMP_ARCHIVE" -C /var/lib/pterodactyl volumes
    
    ARCHIVE_SIZE=$(du -sh "$TEMP_ARCHIVE" | cut -f1)
    log_info "Archive size: $ARCHIVE_SIZE"
    echo ""
    
    # Upload to Mega
    log_info "Uploading to Mega.nz..."
    mega-put "$TEMP_ARCHIVE" "$BACKUP_DIR/"
    
    if [ $? -eq 0 ]; then
        echo ""
        log_success "╔════════════════════════════════════════════════════════════════════════╗"
        log_success "║                  BACKUP SUCCESSFUL!                                    ║"
        log_success "╚════════════════════════════════════════════════════════════════════════╝"
        echo ""
        log_info "Game servers backed up to Mega.nz!"
        log_info "Location: $BACKUP_DIR"
        echo ""
        
        # Create restore instructions
        cat > /tmp/RESTORE_INSTRUCTIONS.txt <<EOF
Pterodactyl Game Server Backup - Mega.nz
=========================================
Backup Date: $(date)
Original Size: $GAME_SIZE
Archive Size: $ARCHIVE_SIZE
Mega.nz Location: $BACKUP_DIR

To Restore:
-----------
1. Install MEGAcmd (if not installed):
   https://mega.nz/cmd

2. Login to Mega.nz:
   mega-login your@email.com

3. Download backup:
   mega-get "$BACKUP_DIR/$(basename $TEMP_ARCHIVE)" /tmp/

4. Extract:
   tar -xzf /tmp/$(basename $TEMP_ARCHIVE) -C /var/lib/pterodactyl/

5. Fix permissions:
   chown -R pterodactyl:pterodactyl /var/lib/pterodactyl/volumes

6. Restart Wings:
   systemctl restart wings

Archive Contents:
Game server volumes from /var/lib/pterodactyl/volumes
EOF
        
        # Upload restore instructions
        mega-put /tmp/RESTORE_INSTRUCTIONS.txt "$BACKUP_DIR/"
        
        # Clean up temp archive
        rm "$TEMP_ARCHIVE"
        
        log_info "Restore instructions uploaded to Mega.nz"
        echo ""
        log_success "✓ Backup complete! Check your Mega.nz account."
        
    else
        log_error "Backup failed!"
        rm "$TEMP_ARCHIVE"
        exit 1
    fi
}

show_menu() {
    show_banner
    
    log_info "Select backup destination:"
    echo ""
    echo "  1) Google Drive (unlimited storage with Google Workspace)"
    echo "  2) Mega.nz (20GB free, up to 16TB paid)"
    echo "  3) Exit"
    echo ""
    
    read -p "Select option [1-3]: " choice
    
    case $choice in
        1)
            backup_to_gdrive
            ;;
        2)
            backup_to_mega
            ;;
        3)
            log_info "Exiting..."
            exit 0
            ;;
        *)
            log_error "Invalid selection"
            exit 1
            ;;
    esac
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    exit 1
fi

# Parse command line arguments
case "${1:-menu}" in
    gdrive|google-drive)
        backup_to_gdrive
        ;;
    mega|mega.nz)
        backup_to_mega
        ;;
    menu|*)
        show_menu
        ;;
esac
