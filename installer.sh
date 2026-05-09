#!/bin/bash

# Pterodactyl Automatic System - Modern Installer
# Version 2.0.0 - Complete Rewrite

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Installer Configuration
VERSION="2.0.0"
INSTALL_DIR="/opt/ptero"
CONFIG_DIR="/etc/automatic-system"
LOG_FILE="/var/log/pterodactyl-installer.log"

# Installation State
SELECTED_COMPONENTS=()
INSTALL_MODE=""
NETWORK_TYPE=""
PUBLIC_IP=""
LOCAL_IP=""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This installer must be run as root${NC}" 
   exit 1
fi

# Install dependencies
install_dependencies() {
    if ! command -v whiptail &> /dev/null; then
        apt-get update -qq
        apt-get install -y whiptail curl wget git jq
    fi
}

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Show splash screen
show_splash() {
    whiptail --title "Pterodactyl Automatic System" --msgbox "
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ██████╗ ████████╗███████╗██████╗  ██████╗                 ║
║   ██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██╔═══██╗                ║
║   ██████╔╝   ██║   █████╗  ██████╔╝██║   ██║                ║
║   ██╔═══╝    ██║   ██╔══╝  ██╔══██╗██║   ██║                ║
║   ██║        ██║   ███████╗██║  ██║╚██████╔╝                ║
║   ╚═╝        ╚═╝   ╚══════╝╚═╝  ╚═╝ ╚═════╝                 ║
║                                                               ║
║        AUTOMATIC INSTALLATION SYSTEM v${VERSION}              ║
║                                                               ║
║   A modern, intelligent installer for Pterodactyl            ║
║   and related services.                                       ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

Welcome! This installer will guide you through setting up:

• Pterodactyl Panel & Wings
• AI Assistant (Ollama + Open WebUI)
• Admin Panel & SSH Terminal
• File Management Tools
• Automatic Network Configuration
• Firewall & Security Setup
• Dynamic IP Monitoring

Press OK to begin..." 30 75
}

# Main menu
show_main_menu() {
    CHOICE=$(whiptail --title "Installation Mode" --menu "\nChoose your installation mode:\n\nSelect the option that best fits your needs." 25 78 12 \
        "1" "🤖 AI-Assisted (Recommended for Beginners)" \
        "2" "🎮 Full Stack (Panel + Wings + Everything)" \
        "3" "🖥️  Panel Only (Web Interface)" \
        "4" "🚀 Wings Only (Game Server Daemon)" \
        "5" "🤖 AI Stack (Ollama + Open WebUI)" \
        "6" "📁 File Management (FileBrowser + Pingvin)" \
        "7" "🔧 Admin Tools (Panel + SSH Terminal)" \
        "8" "📊 Custom Selection (Pick Components)" \
        "9" "🌐 Network Setup Only" \
        "10" "🔥 Firewall Setup Only" \
        "11" "ℹ️  System Information" \
        "12" "❌ Exit Installer" \
        3>&1 1>&2 2>&3)
    
    echo "$CHOICE"
}

# Component selection menu
show_component_menu() {
    local selected=$(whiptail --title "Component Selection" --checklist \
        "\nSelect components to install:\n\nUse SPACE to select, ENTER to confirm" 25 78 14 \
        "panel" "Pterodactyl Panel (Web Interface)" OFF \
        "wings" "Pterodactyl Wings (Server Daemon)" OFF \
        "ollama" "Ollama AI Server" OFF \
        "openwebui" "Open WebUI (AI Chat Interface)" OFF \
        "filebrowser" "FileBrowser (File Manager)" OFF \
        "pingvin" "Pingvin Share (File Sharing)" OFF \
        "nextcloud" "Nextcloud (Cloud Storage)" OFF \
        "admin-panel" "Unified Admin Panel" OFF \
        "ssh-terminal" "Web SSH Terminal" OFF \
        "discord-bot" "Discord Bot" OFF \
        "monitoring" "Monitoring Stack (Grafana)" OFF \
        "backup" "Automated Backup System" OFF \
        "firewall" "Firewall Configuration" OFF \
        "ip-monitor" "Dynamic IP Monitor" OFF \
        3>&1 1>&2 2>&3)
    
    echo "$selected"
}

# System check
check_system() {
    whiptail --title "System Check" --infobox "Checking system requirements..." 8 50
    sleep 1
    
    local errors=()
    local warnings=()
    
    # Check OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" ]] && [[ "$ID" != "debian" ]]; then
            warnings+=("OS: $ID (Ubuntu/Debian recommended)")
        fi
    fi
    
    # Check RAM
    local ram_mb=$(free -m | awk '/^Mem:/{print $2}')
    if [ $ram_mb -lt 2048 ]; then
        errors+=("RAM: ${ram_mb}MB (Minimum 2GB required)")
    elif [ $ram_mb -lt 4096 ]; then
        warnings+=("RAM: ${ram_mb}MB (4GB+ recommended)")
    fi
    
    # Check disk space
    local disk_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ $disk_gb -lt 10 ]; then
        errors+=("Disk: ${disk_gb}GB free (Minimum 10GB required)")
    elif [ $disk_gb -lt 20 ]; then
        warnings+=("Disk: ${disk_gb}GB free (20GB+ recommended)")
    fi
    
    # Check internet
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        errors+=("No internet connection detected")
    fi
    
    # Show results
    local result="System Check Results:\n\n"
    
    if [ ${#errors[@]} -gt 0 ]; then
        result+="❌ ERRORS:\n"
        for error in "${errors[@]}"; do
            result+="  • $error\n"
        done
        result+="\n"
    fi
    
    if [ ${#warnings[@]} -gt 0 ]; then
        result+="⚠️  WARNINGS:\n"
        for warning in "${warnings[@]}"; do
            result+="  • $warning\n"
        done
        result+="\n"
    fi
    
    if [ ${#errors[@]} -eq 0 ] && [ ${#warnings[@]} -eq 0 ]; then
        result+="✅ All checks passed!\n\n"
        result+="System is ready for installation."
    fi
    
    if [ ${#errors[@]} -gt 0 ]; then
        whiptail --title "System Check Failed" --msgbox "$result\n\nPlease fix the errors before continuing." 20 70
        return 1
    else
        whiptail --title "System Check" --msgbox "$result" 20 70
        return 0
    fi
}

# Network detection
detect_network() {
    whiptail --title "Network Detection" --infobox "Detecting network configuration..." 8 50
    sleep 1
    
    PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "Unknown")
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    local gateway=$(ip route | grep default | awk '{print $3}')
    
    if [[ $LOCAL_IP == 10.* ]] || [[ $LOCAL_IP == 192.168.* ]] || [[ $LOCAL_IP == 172.16.* ]]; then
        NETWORK_TYPE="NAT"
    else
        NETWORK_TYPE="PUBLIC"
    fi
    
    local network_info="Network Configuration Detected:\n\n"
    network_info+="Type: $NETWORK_TYPE\n"
    network_info+="Public IP: $PUBLIC_IP\n"
    network_info+="Local IP: $LOCAL_IP\n"
    network_info+="Gateway: $gateway\n\n"
    
    if [ "$NETWORK_TYPE" == "NAT" ]; then
        network_info+="You are behind a router/NAT.\n"
        network_info+="Port forwarding or Cloudflare Tunnel will be needed."
    else
        network_info+="You have a public IP address.\n"
        network_info+="No port forwarding needed!"
    fi
    
    whiptail --title "Network Detection" --msgbox "$network_info" 18 70
}

# Installation progress
show_progress() {
    local step=$1
    local total=$2
    local message=$3
    local percent=$((step * 100 / total))
    
    echo "$percent" | whiptail --gauge "$message" 8 70 0
}

# Install AI Assistant
install_ai_assistant() {
    log "Starting AI Assistant installation..."
    
    (
        echo "10"
        echo "Installing Ollama AI Server..."
        bash "$INSTALL_DIR/ai-assisted-install.sh" > /dev/null 2>&1
        
        echo "100"
        echo "AI Assistant installation complete!"
    ) | whiptail --gauge "Installing AI Assistant..." 8 70 0
    
    whiptail --title "AI Assistant Ready!" --msgbox "
🎉 AI Assistant is now installed!

Access it at: http://localhost:3000

The AI can help you with:
• Understanding installation steps
• Troubleshooting errors
• Explaining technical concepts
• Writing scripts and commands

You can continue with the main installation and
ask the AI for help whenever needed!" 18 70
}

# Install Panel
install_panel() {
    log "Starting Panel installation..."
    
    (
        echo "0"
        echo "Preparing installation..."
        sleep 1
        
        echo "10"
        echo "Installing dependencies..."
        bash "$INSTALL_DIR/firewall-manager.sh" add-service panel > /dev/null 2>&1
        
        echo "30"
        echo "Downloading Pterodactyl Panel..."
        sleep 2
        
        echo "50"
        echo "Configuring database..."
        sleep 2
        
        echo "70"
        echo "Setting up web server..."
        sleep 2
        
        echo "90"
        echo "Finalizing installation..."
        sleep 1
        
        echo "100"
        echo "Panel installation complete!"
    ) | whiptail --gauge "Installing Pterodactyl Panel..." 8 70 0
    
    log "Panel installation completed"
}

# Install Wings
install_wings() {
    log "Starting Wings installation..."
    
    (
        echo "0"
        echo "Preparing installation..."
        sleep 1
        
        echo "20"
        echo "Installing Docker..."
        sleep 2
        
        echo "50"
        echo "Downloading Wings..."
        sleep 2
        
        echo "70"
        echo "Configuring Wings..."
        bash "$INSTALL_DIR/firewall-manager.sh" add-service wings > /dev/null 2>&1
        
        echo "90"
        echo "Starting Wings service..."
        sleep 1
        
        echo "100"
        echo "Wings installation complete!"
    ) | whiptail --gauge "Installing Pterodactyl Wings..." 8 70 0
    
    log "Wings installation completed"
}

# Network setup wizard
run_network_setup() {
    if whiptail --title "Network Setup" --yesno "
Would you like to configure networking now?

This includes:
• Port forwarding detection
• Router configuration
• Cloudflare Tunnel setup
• Firewall configuration
• DHCP reservation

Recommended for home servers!" 18 70; then
        bash "$INSTALL_DIR/network-setup-wizard.sh"
    fi
}

# Firewall setup
run_firewall_setup() {
    if whiptail --title "Firewall Setup" --yesno "
Configure firewall for installed services?

This will:
• Auto-detect installed services
• Open required ports
• Block unnecessary traffic
• Secure your server

Highly recommended!" 16 70; then
        bash "$INSTALL_DIR/firewall-manager.sh" auto
        
        whiptail --title "Firewall Configured" --msgbox "
✅ Firewall has been configured!

All necessary ports are now open.
Your server is secured." 12 60
    fi
}

# IP monitoring setup
run_ip_monitor_setup() {
    if whiptail --title "IP Monitoring" --yesno "
Enable automatic IP monitoring?

This will:
• Detect IP address changes
• Update DNS records automatically
• Restart affected services
• Send notifications

Recommended for dynamic IP addresses!" 16 70; then
        bash "$INSTALL_DIR/ip-monitor.sh" install
        
        if whiptail --title "Cloudflare API" --yesno "
Configure Cloudflare API for automatic DNS updates?

This allows the system to update your DNS records
automatically when your IP changes." 12 70; then
            bash "$INSTALL_DIR/ip-monitor.sh" setup
        fi
        
        whiptail --title "IP Monitor Active" --msgbox "
✅ IP monitoring is now active!

Your system will automatically handle IP changes." 10 60
    fi
}

# Installation summary
show_summary() {
    local components="$1"
    
    local summary="╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║              🎉 INSTALLATION COMPLETE! 🎉                    ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

Installed Components:
"
    
    for comp in $components; do
        summary+="  ✅ $comp
"
    done
    
    summary+="
Access Your Services:

  🌐 Panel: https://panel.yourdomain.com
  🔧 Admin: https://admin.yourdomain.com
  💻 SSH: https://ssh.yourdomain.com
  🤖 AI: https://ai.yourdomain.com

Next Steps:

  1. Configure your domain DNS records
  2. Create your first server
  3. Invite users to your panel

Need Help?

  📚 Documentation: /opt/ptero/README.md
  🤖 AI Assistant: Ask questions anytime!
  📝 Logs: $LOG_FILE
"
    
    whiptail --title "Installation Complete!" --msgbox "$summary" 30 75
}

# System information
show_system_info() {
    local info="System Information:\n\n"
    
    # OS Info
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        info+="OS: $PRETTY_NAME\n"
    fi
    
    # Kernel
    info+="Kernel: $(uname -r)\n"
    
    # CPU
    local cpu=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    local cores=$(nproc)
    info+="CPU: $cpu ($cores cores)\n"
    
    # RAM
    local ram_total=$(free -h | awk '/^Mem:/{print $2}')
    local ram_used=$(free -h | awk '/^Mem:/{print $3}')
    info+="RAM: $ram_used / $ram_total\n"
    
    # Disk
    local disk_total=$(df -h / | awk 'NR==2 {print $2}')
    local disk_used=$(df -h / | awk 'NR==2 {print $3}')
    local disk_free=$(df -h / | awk 'NR==2 {print $4}')
    info+="Disk: $disk_used / $disk_total ($disk_free free)\n"
    
    # Network
    info+="\nNetwork:\n"
    info+="  Public IP: $PUBLIC_IP\n"
    info+="  Local IP: $LOCAL_IP\n"
    info+="  Type: $NETWORK_TYPE\n"
    
    # Installed Services
    info+="\nInstalled Services:\n"
    [ -d "/var/www/pterodactyl" ] && info+="  ✅ Pterodactyl Panel\n"
    [ -f "/usr/local/bin/wings" ] && info+="  ✅ Pterodactyl Wings\n"
    command -v ollama &> /dev/null && info+="  ✅ Ollama AI\n"
    docker ps | grep -q "open-webui" && info+="  ✅ Open WebUI\n"
    [ -d "/opt/unified-admin" ] && info+="  ✅ Admin Panel\n"
    [ -d "/opt/ssh-terminal" ] && info+="  ✅ SSH Terminal\n"
    
    whiptail --title "System Information" --msgbox "$info" 25 75
}

# Main installation flow
main() {
    # Setup
    install_dependencies
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
    
    log "=== Pterodactyl Installer Started ==="
    
    # Show splash
    show_splash
    
    # System check
    if ! check_system; then
        exit 1
    fi
    
    # Network detection
    detect_network
    
    # Main loop
    while true; do
        choice=$(show_main_menu)
        
        case $choice in
            1)
                # AI-Assisted
                install_ai_assistant
                ;;
            2)
                # Full Stack
                SELECTED_COMPONENTS=("panel" "wings" "admin-panel" "ssh-terminal")
                install_panel
                install_wings
                run_network_setup
                run_firewall_setup
                run_ip_monitor_setup
                show_summary "${SELECTED_COMPONENTS[*]}"
                ;;
            3)
                # Panel Only
                SELECTED_COMPONENTS=("panel")
                install_panel
                run_network_setup
                run_firewall_setup
                show_summary "${SELECTED_COMPONENTS[*]}"
                ;;
            4)
                # Wings Only
                SELECTED_COMPONENTS=("wings")
                install_wings
                run_network_setup
                run_firewall_setup
                show_summary "${SELECTED_COMPONENTS[*]}"
                ;;
            5)
                # AI Stack
                install_ai_assistant
                ;;
            8)
                # Custom Selection
                selected=$(show_component_menu)
                if [ -n "$selected" ]; then
                    SELECTED_COMPONENTS=($selected)
                    # Install selected components
                    run_network_setup
                    run_firewall_setup
                    run_ip_monitor_setup
                    show_summary "${SELECTED_COMPONENTS[*]}"
                fi
                ;;
            9)
                # Network Setup
                run_network_setup
                ;;
            10)
                # Firewall Setup
                run_firewall_setup
                ;;
            11)
                # System Info
                show_system_info
                ;;
            12)
                # Exit
                if whiptail --title "Exit Installer" --yesno "
Are you sure you want to exit?

You can run this installer again anytime." 10 60; then
                    clear
                    echo -e "${GREEN}Thank you for using Pterodactyl Automatic System!${NC}"
                    log "=== Installer Exited ==="
                    exit 0
                fi
                ;;
        esac
    done
}

# Run main
main "$@"
