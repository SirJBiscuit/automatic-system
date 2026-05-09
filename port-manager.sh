#!/bin/bash

# Port Manager - Detect conflicts and allow port customization
# Handles port configuration for all services

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PORT_CONFIG="/etc/automatic-system/ports.conf"

# Default port mappings
declare -A DEFAULT_PORTS=(
    ["PANEL_HTTP"]="80"
    ["PANEL_HTTPS"]="443"
    ["WINGS_API"]="8080"
    ["WINGS_SFTP"]="2022"
    ["ADMIN_PANEL"]="5002"
    ["SSH_TERMINAL"]="5000"
    ["OPENWEBUI"]="3000"
    ["OLLAMA"]="11434"
    ["FILEBROWSER"]="8081"
    ["PINGVIN"]="3001"
    ["NEXTCLOUD"]="8082"
    ["MYSQL"]="3306"
    ["REDIS"]="6379"
)

# Service descriptions
declare -A PORT_DESCRIPTIONS=(
    ["PANEL_HTTP"]="Pterodactyl Panel HTTP"
    ["PANEL_HTTPS"]="Pterodactyl Panel HTTPS"
    ["WINGS_API"]="Wings API"
    ["WINGS_SFTP"]="Wings SFTP"
    ["ADMIN_PANEL"]="Admin Panel Web Interface"
    ["SSH_TERMINAL"]="SSH Terminal Web Interface"
    ["OPENWEBUI"]="Open WebUI (AI Chat)"
    ["OLLAMA"]="Ollama AI Server"
    ["FILEBROWSER"]="FileBrowser Web Interface"
    ["PINGVIN"]="Pingvin Share"
    ["NEXTCLOUD"]="Nextcloud"
    ["MYSQL"]="MySQL Database"
    ["REDIS"]="Redis Cache"
)

# Check if port is in use
check_port() {
    local port=$1
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        return 0  # Port is in use
    elif ss -tuln 2>/dev/null | grep -q ":$port "; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Get process using port
get_port_process() {
    local port=$1
    local process=$(lsof -i :$port -t 2>/dev/null | head -1)
    if [ -n "$process" ]; then
        ps -p $process -o comm= 2>/dev/null || echo "Unknown"
    else
        echo "Unknown"
    fi
}

# Scan all ports for conflicts
scan_port_conflicts() {
    local conflicts=()
    
    echo "Scanning for port conflicts..."
    echo ""
    
    for service in "${!DEFAULT_PORTS[@]}"; do
        local port="${DEFAULT_PORTS[$service]}"
        local desc="${PORT_DESCRIPTIONS[$service]}"
        
        if check_port "$port"; then
            local process=$(get_port_process "$port")
            conflicts+=("$service:$port:$process")
            echo -e "${RED}✗${NC} Port $port ($desc) - IN USE by $process"
        else
            echo -e "${GREEN}✓${NC} Port $port ($desc) - Available"
        fi
    done
    
    echo ""
    
    if [ ${#conflicts[@]} -gt 0 ]; then
        echo -e "${YELLOW}Found ${#conflicts[@]} port conflict(s)${NC}"
        return 1
    else
        echo -e "${GREEN}No port conflicts detected!${NC}"
        return 0
    fi
}

# Interactive port configuration
configure_ports_interactive() {
    local service=$1
    
    # Get ports for this service
    local ports=()
    case $service in
        "panel")
            ports=("PANEL_HTTP" "PANEL_HTTPS")
            ;;
        "wings")
            ports=("WINGS_API" "WINGS_SFTP")
            ;;
        "admin-panel")
            ports=("ADMIN_PANEL")
            ;;
        "ssh-terminal")
            ports=("SSH_TERMINAL")
            ;;
        "openwebui")
            ports=("OPENWEBUI")
            ;;
        "ollama")
            ports=("OLLAMA")
            ;;
        "filebrowser")
            ports=("FILEBROWSER")
            ;;
        "pingvin")
            ports=("PINGVIN")
            ;;
        "nextcloud")
            ports=("NEXTCLOUD")
            ;;
    esac
    
    if [ ${#ports[@]} -eq 0 ]; then
        return 0
    fi
    
    # Check each port
    local has_conflicts=false
    for port_name in "${ports[@]}"; do
        local default_port="${DEFAULT_PORTS[$port_name]}"
        local desc="${PORT_DESCRIPTIONS[$port_name]}"
        
        if check_port "$default_port"; then
            has_conflicts=true
            local process=$(get_port_process "$default_port")
            
            whiptail --title "Port Conflict Detected" --msgbox "\n\
⚠️  Port Conflict!\n\n\
Service: $desc\n\
Port: $default_port\n\
Currently used by: $process\n\n\
You'll need to choose a different port." 14 70
            
            # Suggest alternative port
            local new_port=$((default_port + 1000))
            while check_port "$new_port"; do
                ((new_port++))
            done
            
            local custom_port=$(whiptail --title "Choose Port" --inputbox "\n\
$desc\n\n\
Default port $default_port is in use.\n\
Suggested alternative: $new_port\n\n\
Enter port number:" 14 60 "$new_port" 3>&1 1>&2 2>&3)
            
            if [ -n "$custom_port" ]; then
                # Validate port
                if [[ "$custom_port" =~ ^[0-9]+$ ]] && [ "$custom_port" -ge 1024 ] && [ "$custom_port" -le 65535 ]; then
                    if check_port "$custom_port"; then
                        whiptail --title "Error" --msgbox "\nPort $custom_port is also in use!\nPlease try again." 10 50
                        return 1
                    else
                        DEFAULT_PORTS[$port_name]="$custom_port"
                        echo "$port_name=$custom_port" >> "$PORT_CONFIG"
                    fi
                else
                    whiptail --title "Error" --msgbox "\nInvalid port number!\nMust be between 1024-65535." 10 50
                    return 1
                fi
            fi
        fi
    done
    
    if [ "$has_conflicts" = false ]; then
        whiptail --title "Port Check" --msgbox "\n✅ All ports are available!\n\nNo conflicts detected for $service." 10 50
    fi
}

# Show port configuration menu
show_port_menu() {
    local service=$1
    
    # Build menu items
    local menu_items=()
    
    case $service in
        "panel")
            menu_items+=("PANEL_HTTP" "HTTP Port (Default: ${DEFAULT_PORTS[PANEL_HTTP]})")
            menu_items+=("PANEL_HTTPS" "HTTPS Port (Default: ${DEFAULT_PORTS[PANEL_HTTPS]})")
            ;;
        "wings")
            menu_items+=("WINGS_API" "Wings API Port (Default: ${DEFAULT_PORTS[WINGS_API]})")
            menu_items+=("WINGS_SFTP" "Wings SFTP Port (Default: ${DEFAULT_PORTS[WINGS_SFTP]})")
            ;;
        "admin-panel")
            menu_items+=("ADMIN_PANEL" "Admin Panel Port (Default: ${DEFAULT_PORTS[ADMIN_PANEL]})")
            ;;
        "ssh-terminal")
            menu_items+=("SSH_TERMINAL" "SSH Terminal Port (Default: ${DEFAULT_PORTS[SSH_TERMINAL]})")
            ;;
        "openwebui")
            menu_items+=("OPENWEBUI" "Open WebUI Port (Default: ${DEFAULT_PORTS[OPENWEBUI]})")
            ;;
        "ollama")
            menu_items+=("OLLAMA" "Ollama API Port (Default: ${DEFAULT_PORTS[OLLAMA]})")
            ;;
    esac
    
    menu_items+=("AUTO" "Auto-detect and fix conflicts")
    menu_items+=("SCAN" "Scan for port conflicts")
    menu_items+=("DONE" "Continue with installation")
    
    local choice=$(whiptail --title "Port Configuration - $service" --menu "\n\
Configure ports for $service:\n\n\
Choose a port to customize or scan for conflicts." 20 70 10 \
        "${menu_items[@]}" \
        3>&1 1>&2 2>&3)
    
    echo "$choice"
}

# Generate random available port
generate_random_port() {
    local min_port=${1:-10000}
    local max_port=${2:-60000}
    local random_port
    
    while true; do
        random_port=$((RANDOM % (max_port - min_port + 1) + min_port))
        if ! check_port "$random_port"; then
            echo "$random_port"
            return 0
        fi
    done
}

# Auto-fix port conflicts
auto_fix_conflicts() {
    echo "Auto-fixing port conflicts..."
    
    for service in "${!DEFAULT_PORTS[@]}"; do
        local port="${DEFAULT_PORTS[$service]}"
        
        if check_port "$port"; then
            # Find next available port
            local new_port=$((port + 1000))
            while check_port "$new_port"; do
                ((new_port++))
            done
            
            echo "Changing $service: $port → $new_port"
            DEFAULT_PORTS[$service]="$new_port"
            echo "$service=$new_port" >> "$PORT_CONFIG"
        fi
    done
    
    echo "Port conflicts resolved!"
}

# Generate random ports for all services
generate_all_random_ports() {
    echo "Generating random ports for all services..."
    echo ""
    
    for service in "${!DEFAULT_PORTS[@]}"; do
        local desc="${PORT_DESCRIPTIONS[$service]}"
        
        # Skip standard ports (80, 443) and localhost-only ports
        if [[ "$service" == "PANEL_HTTP" ]] || [[ "$service" == "PANEL_HTTPS" ]] || \
           [[ "$service" == "MYSQL" ]] || [[ "$service" == "REDIS" ]]; then
            echo "Keeping $service: ${DEFAULT_PORTS[$service]} (standard port)"
            continue
        fi
        
        local old_port="${DEFAULT_PORTS[$service]}"
        local new_port=$(generate_random_port 10000 60000)
        
        DEFAULT_PORTS[$service]="$new_port"
        echo "Generated $service: $old_port → $new_port ($desc)"
    done
    
    echo ""
    echo "Random ports generated!"
}

# Configure all ports interactively
configure_all_ports_interactive() {
    local services=("WINGS_API" "WINGS_SFTP" "ADMIN_PANEL" "SSH_TERMINAL" "OPENWEBUI" "OLLAMA" "FILEBROWSER" "PINGVIN" "NEXTCLOUD")
    
    for port_name in "${services[@]}"; do
        local default_port="${DEFAULT_PORTS[$port_name]}"
        local desc="${PORT_DESCRIPTIONS[$port_name]}"
        
        # Check if port is in use
        local status="Available"
        local color="${GREEN}"
        if check_port "$default_port"; then
            status="IN USE"
            color="${RED}"
        fi
        
        local custom_port=$(whiptail --title "Configure Port" --inputbox "\n\
Service: $desc\n\
Default Port: $default_port\n\
Status: $status\n\n\
Enter port number (or press Enter to keep default):" 14 60 "$default_port" 3>&1 1>&2 2>&3)
        
        if [ -n "$custom_port" ] && [ "$custom_port" != "$default_port" ]; then
            # Validate port
            if [[ "$custom_port" =~ ^[0-9]+$ ]] && [ "$custom_port" -ge 1024 ] && [ "$custom_port" -le 65535 ]; then
                if check_port "$custom_port"; then
                    whiptail --title "Warning" --msgbox "\n⚠️  Port $custom_port is in use!\n\nKeeping default: $default_port" 10 50
                else
                    DEFAULT_PORTS[$port_name]="$custom_port"
                    echo "$port_name=$custom_port" >> "$PORT_CONFIG"
                fi
            else
                whiptail --title "Error" --msgbox "\n❌ Invalid port number!\n\nMust be between 1024-65535.\nKeeping default: $default_port" 10 50
            fi
        fi
    done
    
    whiptail --title "Configuration Complete" --msgbox "\n✅ Port configuration complete!\n\nAll ports have been configured." 10 50
}

# Get port for service
get_port() {
    local port_name=$1
    
    # Check config file first
    if [ -f "$PORT_CONFIG" ]; then
        local configured_port=$(grep "^$port_name=" "$PORT_CONFIG" | cut -d= -f2)
        if [ -n "$configured_port" ]; then
            echo "$configured_port"
            return
        fi
    fi
    
    # Return default
    echo "${DEFAULT_PORTS[$port_name]}"
}

# Save port configuration
save_port_config() {
    mkdir -p "$(dirname "$PORT_CONFIG")"
    
    echo "# Port Configuration" > "$PORT_CONFIG"
    echo "# Generated: $(date)" >> "$PORT_CONFIG"
    echo "" >> "$PORT_CONFIG"
    
    for service in "${!DEFAULT_PORTS[@]}"; do
        echo "$service=${DEFAULT_PORTS[$service]}" >> "$PORT_CONFIG"
    done
}

# Load port configuration
load_port_config() {
    if [ -f "$PORT_CONFIG" ]; then
        while IFS='=' read -r key value; do
            if [[ ! "$key" =~ ^# ]] && [ -n "$key" ]; then
                DEFAULT_PORTS[$key]="$value"
            fi
        done < "$PORT_CONFIG"
    fi
}

# Main execution
case "${1:-scan}" in
    "scan")
        scan_port_conflicts
        ;;
    
    "configure")
        if [ -z "$2" ]; then
            echo "Usage: $0 configure <service>"
            exit 1
        fi
        configure_ports_interactive "$2"
        ;;
    
    "auto-fix")
        auto_fix_conflicts
        save_port_config
        ;;
    
    "get")
        if [ -z "$2" ]; then
            echo "Usage: $0 get <port_name>"
            exit 1
        fi
        load_port_config
        get_port "$2"
        ;;
    
    "save")
        save_port_config
        ;;
    
    "load")
        load_port_config
        ;;
    
    "list")
        load_port_config
        echo "Current Port Configuration:"
        echo ""
        for service in "${!DEFAULT_PORTS[@]}"; do
            printf "%-20s %s\n" "$service:" "${DEFAULT_PORTS[$service]}"
        done
        ;;
    
    "generate-random")
        generate_all_random_ports
        save_port_config
        ;;
    
    "configure-all")
        configure_all_ports_interactive
        save_port_config
        ;;
    
    *)
        echo "Usage: $0 {scan|configure|auto-fix|get|save|load|list|generate-random|configure-all}"
        echo ""
        echo "Commands:"
        echo "  scan              - Scan for port conflicts"
        echo "  configure <svc>   - Configure ports for service"
        echo "  auto-fix          - Automatically fix all conflicts"
        echo "  generate-random   - Generate random ports for all services"
        echo "  configure-all     - Interactively configure all service ports"
        echo "  get <port_name>   - Get configured port"
        echo "  save              - Save port configuration"
        echo "  load              - Load port configuration"
        echo "  list              - List all configured ports"
        exit 1
        ;;
esac
