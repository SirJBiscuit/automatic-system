#!/bin/bash

# Pterodactyl Update Checker Service
# Checks for new versions and notifies users

VERSION_FILE="/opt/ptero/.version"
REMOTE_VERSION_URL="https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/VERSION"
NOTIFICATION_FILE="/opt/ptero/.update-notification"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

check_for_updates() {
    if [ ! -f "$VERSION_FILE" ]; then
        return
    fi
    
    local local_version=$(cat "$VERSION_FILE" | tr -d '\n\r')
    local remote_version=$(curl -sSL "$REMOTE_VERSION_URL" 2>/dev/null | tr -d '\n\r' || echo "")
    
    if [ -z "$remote_version" ]; then
        return
    fi
    
    if [ "$local_version" != "$remote_version" ]; then
        # Create notification file
        cat > "$NOTIFICATION_FILE" <<EOF
╔══════════════════════════════════════════════════════════════════╗
║                    🎉 UPDATE AVAILABLE! 🎉                       ║
╚══════════════════════════════════════════════════════════════════╝

New update has been released: Version $remote_version

Current version: $local_version
Latest version:  $remote_version

To update, run these commands:

  cd /opt/ptero
  rm -rf *
  curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/install.sh | sudo bash

This notification will appear when you run pteroanyinstall.sh
EOF
        
        # Log to syslog
        logger -t ptero-update "New version available: $remote_version (current: $local_version)"
        
        # Send notification to all logged-in users
        if command -v wall &> /dev/null; then
            echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}" | wall
            echo -e "${CYAN}║         Pterodactyl Installer Update Available!                 ║${NC}" | wall
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}" | wall
            echo -e "\n${YELLOW}New update has been released: Version $remote_version${NC}" | wall
            echo -e "${BLUE}Run 'cd /opt/ptero && ./pteroanyinstall.sh' for details${NC}\n" | wall
        fi
    else
        # Remove notification file if versions match
        rm -f "$NOTIFICATION_FILE"
    fi
}

check_for_updates
