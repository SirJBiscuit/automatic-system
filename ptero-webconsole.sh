#!/bin/bash

# Pterodactyl Web Console Management Script
# Usage: ./ptero-webconsole.sh [enable|disable|status|reinstall]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_CONSOLE_DIR="$SCRIPT_DIR/web-console"
INSTALL_SCRIPT="$WEB_CONSOLE_DIR/install.sh"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}✗ This script must be run as root${NC}" 
   exit 1
fi

# Function to show usage
show_usage() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     Pterodactyl Web Console Management                    ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  ${GREEN}./ptero-webconsole.sh enable${NC}      - Install and enable web console"
    echo -e "  ${GREEN}./ptero-webconsole.sh disable${NC}     - Disable web console"
    echo -e "  ${GREEN}./ptero-webconsole.sh status${NC}      - Check web console status"
    echo -e "  ${GREEN}./ptero-webconsole.sh reinstall${NC}   - Reinstall web console"
    echo -e "  ${GREEN}./ptero-webconsole.sh uninstall${NC}   - Completely remove web console"
    echo ""
}

# Function to check if web console is installed
is_installed() {
    [ -f "/opt/pterodactyl-web-console/app.py" ] && [ -f "/etc/systemd/system/pterodactyl-web-console.service" ]
}

# Function to check if web console is running
is_running() {
    systemctl is-active --quiet pterodactyl-web-console
}

# Function to show status
show_status() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          Web Console Status                                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if is_installed; then
        echo -e "${GREEN}✓ Web Console is installed${NC}"
        echo ""
        
        if is_running; then
            echo -e "${GREEN}✓ Service is running${NC}"
            
            # Get server IP
            SERVER_IP=$(hostname -I | awk '{print $1}')
            echo ""
            echo -e "${YELLOW}Access URL:${NC} ${GREEN}http://$SERVER_IP:8080${NC}"
        else
            echo -e "${RED}✗ Service is not running${NC}"
            echo ""
            echo -e "${YELLOW}Start with:${NC} systemctl start pterodactyl-web-console"
        fi
        
        echo ""
        echo -e "${CYAN}Service Status:${NC}"
        systemctl status pterodactyl-web-console --no-pager || true
    else
        echo -e "${YELLOW}⚠ Web Console is not installed${NC}"
        echo ""
        echo -e "${CYAN}Install with:${NC} ./ptero-webconsole.sh enable"
    fi
    echo ""
}

# Function to enable/install web console
enable_console() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          Pterodactyl Web Console                           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if is_installed; then
        echo -e "${YELLOW}⚠ Web Console is already installed${NC}"
        echo ""
        read -p "Do you want to reinstall? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Installation cancelled${NC}"
            exit 0
        fi
    else
        # Show what the web console does
        echo -e "${PURPLE}What is the Web Console?${NC}"
        echo ""
        echo -e "A professional web dashboard for managing your Pterodactyl game servers"
        echo -e "with advanced features and beautiful UI."
        echo ""
        echo -e "${GREEN}✓${NC} ${YELLOW}Key Features:${NC}"
        echo ""
        echo -e "  ${CYAN}📊 Real-Time Monitoring${NC}"
        echo -e "     • Live CPU, RAM, Disk, Network stats"
        echo -e "     • GPU monitoring (NVIDIA)"
        echo -e "     • Performance graphs with Chart.js"
        echo -e "     • Server status tracking"
        echo ""
        echo -e "  ${CYAN}🎮 Server Management${NC}"
        echo -e "     • Start/Stop/Restart individual servers"
        echo -e "     • Bulk actions (control multiple servers)"
        echo -e "     • Live console output"
        echo -e "     • Send commands to servers"
        echo ""
        echo -e "  ${CYAN}📂 File Manager${NC}"
        echo -e "     • Browse server files in your browser"
        echo -e "     • Edit configuration files"
        echo -e "     • Save changes directly"
        echo ""
        echo -e "  ${CYAN}⏰ Scheduled Actions${NC}"
        echo -e "     • Schedule server restarts"
        echo -e "     • Automated backups"
        echo -e "     • Custom commands on schedule"
        echo ""
        echo -e "  ${CYAN}🎨 Professional UI${NC}"
        echo -e "     • Beautiful modern design"
        echo -e "     • Mobile-responsive"
        echo -e "     • Dark theme with animations"
        echo -e "     • Customizable (themes, toggles)"
        echo ""
        echo -e "  ${CYAN}🔍 Advanced Features${NC}"
        echo -e "     • Search and filter servers"
        echo -e "     • Server groups/categories"
        echo -e "     • Device detection (mobile/desktop)"
        echo -e "     • 60+ total features"
        echo ""
        echo -e "${YELLOW}Access:${NC} Web browser at ${GREEN}http://YOUR_IP:8080${NC}"
        echo -e "${YELLOW}Requirements:${NC} ~50MB RAM, Port 8080, Python 3"
        echo ""
        echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║  This is completely optional and can be removed anytime   ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "Do you want to install the Web Console? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            echo -e "${YELLOW}Installation cancelled${NC}"
            echo ""
            echo -e "${CYAN}You can install it later with:${NC} ./ptero-webconsole.sh enable"
            echo ""
            exit 0
        fi
    fi
    
    # Check if install script exists
    if [ ! -f "$INSTALL_SCRIPT" ]; then
        echo -e "${RED}✗ Install script not found at: $INSTALL_SCRIPT${NC}"
        echo -e "${YELLOW}Please ensure you have the complete pteroanyinstall repository${NC}"
        exit 1
    fi
    
    # Run the installer
    echo -e "${BLUE}Running web console installer...${NC}"
    echo ""
    bash "$INSTALL_SCRIPT"
}

# Function to disable web console
disable_console() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          Disable Web Console                               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if ! is_installed; then
        echo -e "${YELLOW}⚠ Web Console is not installed${NC}"
        exit 0
    fi
    
    echo -e "${YELLOW}This will stop the web console service but keep it installed.${NC}"
    echo ""
    read -p "Continue? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Operation cancelled${NC}"
        exit 0
    fi
    
    echo ""
    echo -e "${BLUE}Stopping web console service...${NC}"
    systemctl stop pterodactyl-web-console
    systemctl disable pterodactyl-web-console
    
    echo -e "${GREEN}✓ Web Console disabled${NC}"
    echo ""
    echo -e "${CYAN}To re-enable:${NC} ./ptero-webconsole.sh enable"
    echo ""
}

# Function to uninstall web console
uninstall_console() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          Uninstall Web Console                             ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if ! is_installed; then
        echo -e "${YELLOW}⚠ Web Console is not installed${NC}"
        exit 0
    fi
    
    echo -e "${RED}⚠ WARNING: This will completely remove the web console!${NC}"
    echo ""
    read -p "Are you sure? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Uninstallation cancelled${NC}"
        exit 0
    fi
    
    echo ""
    echo -e "${BLUE}Removing web console...${NC}"
    
    # Stop and disable service
    systemctl stop pterodactyl-web-console 2>/dev/null || true
    systemctl disable pterodactyl-web-console 2>/dev/null || true
    
    # Remove service file
    rm -f /etc/systemd/system/pterodactyl-web-console.service
    systemctl daemon-reload
    
    # Remove Nginx config
    rm -f /etc/nginx/sites-enabled/pterodactyl-web-console
    rm -f /etc/nginx/sites-available/pterodactyl-web-console
    systemctl reload nginx 2>/dev/null || true
    
    # Remove installation directory
    rm -rf /opt/pterodactyl-web-console
    
    echo -e "${GREEN}✓ Web Console uninstalled${NC}"
    echo ""
    echo -e "${CYAN}To reinstall:${NC} ./ptero-webconsole.sh enable"
    echo ""
}

# Main script logic
case "${1:-}" in
    enable)
        enable_console
        ;;
    disable)
        disable_console
        ;;
    status)
        show_status
        ;;
    reinstall)
        enable_console
        ;;
    uninstall)
        uninstall_console
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
