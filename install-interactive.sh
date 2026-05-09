#!/bin/bash

set -e

VERSION="2.0.0"
SCRIPT_NAME="Pterodactyl Automatic System - Interactive Installer"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

PANEL_VERSION="1.11.5"
WINGS_VERSION="1.11.5"

CONFIG_DIR="/etc/automatic-system"
CONFIG_FILE="$CONFIG_DIR/config.conf"
INSTALL_LOG="/var/log/ptero-install.log"

SELECTED_COMPONENTS=()

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[ERROR]${NC} This script must be run as root"
        exit 1
    fi
}

check_dependencies() {
    if ! command -v dialog &> /dev/null; then
        echo "Installing dialog for interactive interface..."
        apt-get update -qq
        apt-get install -y dialog
    fi
}

show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ██████╗ ████████╗███████╗██████╗  ██████╗                 ║
║   ██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██╔═══██╗                ║
║   ██████╔╝   ██║   █████╗  ██████╔╝██║   ██║                ║
║   ██╔═══╝    ██║   ██╔══╝  ██╔══██╗██║   ██║                ║
║   ██║        ██║   ███████╗██║  ██║╚██████╔╝                ║
║   ╚═╝        ╚═╝   ╚══════╝╚═╝  ╚═╝ ╚═════╝                 ║
║                                                               ║
║        AUTOMATIC INSTALLATION SYSTEM v2.0.0                  ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${BOLD}Welcome to the Pterodactyl Automatic Installation System!${NC}"
    echo ""
    sleep 2
}

show_main_menu() {
    local choice
    choice=$(dialog --clear --backtitle "$SCRIPT_NAME" \
        --title "Installation Categories" \
        --menu "Choose what you want to install:" 22 75 12 \
        0 "🤖 AI Assistant First (Recommended for Beginners!)" \
        1 "🎮 Full Stack (Panel + Wings)" \
        2 "🖥️  Panel Only" \
        3 "🚀 Wings Only" \
        4 "🤖 AI Assistant Only (Ollama + Open WebUI)" \
        5 "📁 File Management (FileBrowser + Pingvin)" \
        6 "☁️  Cloud Storage (Nextcloud)" \
        7 "🔧 Admin Panel + SSH Terminal" \
        8 "📊 Custom Selection" \
        9 "ℹ️  View Installation Guide" \
        99 "❌ Exit" \
        3>&1 1>&2 2>&3)
    
    echo "$choice"
}

show_component_selection() {
    local selected
    selected=$(dialog --clear --backtitle "$SCRIPT_NAME" \
        --title "Component Selection" \
        --checklist "Select components to install:" 20 70 12 \
        "panel" "Pterodactyl Panel" off \
        "wings" "Pterodactyl Wings" off \
        "ollama" "Ollama AI Server" off \
        "openwebui" "Open WebUI Interface" off \
        "filebrowser" "FileBrowser" off \
        "pingvin" "Pingvin Share" off \
        "nextcloud" "Nextcloud" off \
        "admin-panel" "Unified Admin Panel" off \
        "ssh-terminal" "Web SSH Terminal" off \
        "discord-bot" "Discord Bot" off \
        "billing" "Billing System" off \
        "backup" "Cloud Backup" off \
        3>&1 1>&2 2>&3)
    
    echo "$selected"
}

show_component_info() {
    local component=$1
    local title=""
    local description=""
    
    case $component in
        "panel")
            title="Pterodactyl Panel"
            description="The main web interface for managing game servers.\n\n\
Features:\n\
• Modern web dashboard\n\
• User management\n\
• Server creation and management\n\
• Resource allocation\n\
• File manager\n\
• Database management\n\n\
Requirements:\n\
• PHP 8.1+\n\
• MySQL/MariaDB\n\
• Nginx/Apache\n\
• Redis\n\n\
Installation time: ~10-15 minutes"
            ;;
        "wings")
            title="Pterodactyl Wings"
            description="The server daemon that runs game servers.\n\n\
Features:\n\
• Docker-based server isolation\n\
• Resource management\n\
• Real-time console\n\
• File transfer\n\
• Automated backups\n\n\
Requirements:\n\
• Docker\n\
• 2GB+ RAM\n\
• 10GB+ disk space\n\n\
Installation time: ~5-10 minutes"
            ;;
        "ollama")
            title="Ollama AI Server"
            description="Local AI model server for running LLMs.\n\n\
Features:\n\
• Run AI models locally\n\
• Multiple model support\n\
• API access\n\
• GPU acceleration (if available)\n\n\
Requirements:\n\
• 8GB+ RAM (16GB recommended)\n\
• 20GB+ disk space per model\n\
• Optional: NVIDIA GPU\n\n\
Installation time: ~5 minutes + model download"
            ;;
        "openwebui")
            title="Open WebUI"
            description="Modern chat interface for AI models.\n\n\
Features:\n\
• ChatGPT-like interface\n\
• Multiple model support\n\
• Conversation history\n\
• User management\n\
• Custom prompts\n\n\
Requirements:\n\
• Ollama server\n\
• 2GB+ RAM\n\n\
Installation time: ~5 minutes"
            ;;
        "admin-panel")
            title="Unified Admin Panel"
            description="Centralized control panel for all services.\n\n\
Features:\n\
• System monitoring\n\
• Service management\n\
• User management\n\
• File browser integration\n\
• Docker container management\n\
• Disk health monitoring\n\n\
Installation time: ~3 minutes"
            ;;
        "ssh-terminal")
            title="Web SSH Terminal"
            description="Browser-based SSH terminal with AI assistant.\n\n\
Features:\n\
• Full terminal access\n\
• AI command suggestions\n\
• Session persistence\n\
• Multi-user support\n\n\
Installation time: ~3 minutes"
            ;;
    esac
    
    dialog --clear --backtitle "$SCRIPT_NAME" \
        --title "$title" \
        --msgbox "$description" 20 70
}

show_installation_steps() {
    local component=$1
    local steps=""
    
    case $component in
        "panel")
            steps="1. Installing dependencies (PHP, MySQL, Redis)\n\
2. Downloading Pterodactyl Panel\n\
3. Configuring database\n\
4. Setting up web server\n\
5. Installing SSL certificate\n\
6. Creating admin user\n\
7. Configuring cron jobs"
            ;;
        "wings")
            steps="1. Installing Docker\n\
2. Downloading Wings binary\n\
3. Configuring Wings\n\
4. Setting up systemd service\n\
5. Starting Wings daemon\n\
6. Connecting to Panel"
            ;;
        "ollama")
            steps="1. Downloading Ollama\n\
2. Installing Ollama service\n\
3. Pulling default models\n\
4. Configuring API access\n\
5. Setting up systemd service"
            ;;
    esac
    
    dialog --clear --backtitle "$SCRIPT_NAME" \
        --title "Installation Steps: $component" \
        --msgbox "$steps" 15 70
}

show_progress() {
    local step=$1
    local total=$2
    local description=$3
    local percent=$((step * 100 / total))
    
    echo "$percent" | dialog --backtitle "$SCRIPT_NAME" \
        --title "Installing..." \
        --gauge "$description" 10 70 0
}

install_panel() {
    log_step "Installing Pterodactyl Panel..."
    
    # Run domain setup wizard first
    if dialog --yesno "Do you want to configure a domain for the Panel now?\n\nThis will help you set up DNS records and verify configuration." 10 60; then
        bash /opt/ptero/setup-domain-wizard.sh --component "Pterodactyl Panel" "panel"
        if [ $? -eq 0 ]; then
            # Domain configured successfully, read it
            source /etc/automatic-system/domains.conf
            export PANEL_FQDN="$PANEL_DOMAIN"
        fi
    fi
    
    show_progress 1 7 "Installing dependencies..."
    # Call existing panel installation script
    bash /opt/ptero/install.sh panel
    
    # Configure firewall for panel
    show_progress 6 7 "Configuring firewall..."
    bash /opt/ptero/firewall-manager.sh add-service panel
    
    show_progress 7 7 "Panel installation complete!"
    sleep 2
}

install_wings() {
    log_step "Installing Pterodactyl Wings..."
    
    show_progress 1 6 "Installing Docker..."
    # Call existing wings installation script
    bash /opt/ptero/install.sh wings
    
    # Configure firewall for wings
    show_progress 5 6 "Configuring firewall..."
    bash /opt/ptero/firewall-manager.sh add-service wings
    
    show_progress 6 6 "Wings installation complete!"
    sleep 2
}

install_ollama() {
    log_step "Installing Ollama AI Server..."
    
    show_progress 1 5 "Downloading Ollama..."
    bash /opt/ptero/ollama-setup/install-ollama.sh
    
    show_progress 5 5 "Ollama installation complete!"
    sleep 2
}

install_admin_panel() {
    log_step "Installing Unified Admin Panel..."
    
    show_progress 1 3 "Setting up admin panel..."
    bash /opt/ptero/unified-admin/setup.sh
    
    show_progress 3 3 "Admin panel installation complete!"
    sleep 2
}

log_step() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$INSTALL_LOG"
}

show_installation_summary() {
    local components="$1"
    local summary="Installation Complete!\n\n"
    summary+="Installed Components:\n"
    
    for comp in $components; do
        summary+="✓ $comp\n"
    done
    
    summary+="\n\nNext Steps:\n"
    summary+="1. Access the admin panel at https://admin.yourdomain.com\n"
    summary+="2. Configure your services\n"
    summary+="3. Create your first server\n\n"
    summary+="Installation log: $INSTALL_LOG"
    
    dialog --clear --backtitle "$SCRIPT_NAME" \
        --title "Installation Complete!" \
        --msgbox "$summary" 20 70
    
    # Offer to set up IP monitoring
    if dialog --yesno "Would you like to enable automatic IP monitoring?\n\nThis will:\n• Detect when your public IP changes\n• Automatically update DNS records\n• Restart affected services\n• Send notifications\n\nRecommended for home servers with dynamic IPs!" 16 70; then
        bash /opt/ptero/ip-monitor.sh install
        
        # Ask if they want to configure Cloudflare API
        if dialog --yesno "Do you want to configure Cloudflare API for automatic DNS updates?" 10 60; then
            bash /opt/ptero/ip-monitor.sh setup
        fi
    fi
}

main() {
    check_root
    check_dependencies
    show_banner
    
    while true; do
        choice=$(show_main_menu)
        
        case $choice in
            0)
                # AI Assistant First (Recommended for Beginners)
                dialog --clear --backtitle "$SCRIPT_NAME" \
                    --title "🤖 AI-Assisted Installation Mode" \
                    --yesno "This will install an AI assistant FIRST, then help you with the rest!\n\n\
Benefits:\n\
• Get instant help during installation\n\
• Ask questions about technical concepts\n\
• Troubleshoot errors in real-time\n\
• Learn as you install\n\n\
The AI will be available at ai.yourdomain.com\n\n\
Proceed with AI-assisted installation?" 18 70
                
                if [ $? -eq 0 ]; then
                    bash /opt/ptero/ai-assisted-install.sh
                fi
                ;;
            1)
                # Full Stack
                SELECTED_COMPONENTS=("panel" "wings")
                show_component_info "panel"
                show_component_info "wings"
                if dialog --yesno "Install Full Stack (Panel + Wings)?" 10 50; then
                    install_panel
                    install_wings
                    show_installation_summary "${SELECTED_COMPONENTS[*]}"
                fi
                ;;
            2)
                # Panel Only
                SELECTED_COMPONENTS=("panel")
                show_component_info "panel"
                if dialog --yesno "Install Panel Only?" 10 50; then
                    install_panel
                    show_installation_summary "${SELECTED_COMPONENTS[*]}"
                fi
                ;;
            3)
                # Wings Only
                SELECTED_COMPONENTS=("wings")
                show_component_info "wings"
                if dialog --yesno "Install Wings Only?" 10 50; then
                    install_wings
                    show_installation_summary "${SELECTED_COMPONENTS[*]}"
                fi
                ;;
            4)
                # AI Assistant
                SELECTED_COMPONENTS=("ollama" "openwebui")
                show_component_info "ollama"
                show_component_info "openwebui"
                if dialog --yesno "Install AI Assistant Stack?" 10 50; then
                    install_ollama
                    show_installation_summary "${SELECTED_COMPONENTS[*]}"
                fi
                ;;
            7)
                # Admin Panel + SSH
                SELECTED_COMPONENTS=("admin-panel" "ssh-terminal")
                show_component_info "admin-panel"
                show_component_info "ssh-terminal"
                if dialog --yesno "Install Admin Panel + SSH Terminal?" 10 50; then
                    install_admin_panel
                    show_installation_summary "${SELECTED_COMPONENTS[*]}"
                fi
                ;;
            8)
                # Custom Selection
                selected=$(show_component_selection)
                if [ -n "$selected" ]; then
                    SELECTED_COMPONENTS=($selected)
                    # Install selected components
                    show_installation_summary "${SELECTED_COMPONENTS[*]}"
                fi
                ;;
            9)
                # View Guide
                dialog --textbox README.md 30 80
                ;;
            99)
                clear
                echo -e "${GREEN}Thank you for using Pterodactyl Automatic System!${NC}"
                exit 0
                ;;
        esac
    done
}

main "$@"
