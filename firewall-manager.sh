#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

FIREWALL_CONFIG="/etc/automatic-system/firewall-config.conf"
INSTALLED_SERVICES="/etc/automatic-system/installed-services.conf"

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

# Port definitions for each service
declare -A SERVICE_PORTS=(
    ["panel"]="80 443"
    ["wings"]="8080 2022"
    ["admin-panel"]="5002"
    ["ssh-terminal"]="5000"
    ["openwebui"]="3000"
    ["ollama"]="11434"
    ["filebrowser"]="8081"
    ["pingvin"]="3001"
    ["nextcloud"]="8082"
    ["mysql"]="3306"
    ["redis"]="6379"
    ["nginx"]="80 443"
    ["docker"]="2375 2376"
)

# Port descriptions
declare -A PORT_DESCRIPTIONS=(
    ["22"]="SSH"
    ["80"]="HTTP"
    ["443"]="HTTPS"
    ["3000"]="Open WebUI"
    ["3001"]="Pingvin Share"
    ["3306"]="MySQL (localhost only)"
    ["5000"]="SSH Terminal"
    ["5002"]="Admin Panel"
    ["6379"]="Redis (localhost only)"
    ["8080"]="Wings API"
    ["8081"]="FileBrowser"
    ["8082"]="Nextcloud"
    ["2022"]="Wings SFTP"
    ["11434"]="Ollama API"
)

install_ufw() {
    if ! command -v ufw &> /dev/null; then
        log_info "Installing UFW firewall..."
        apt-get update -qq
        apt-get install -y ufw
        log_success "UFW installed"
    else
        log_info "UFW already installed"
    fi
}

configure_base_firewall() {
    log_info "Configuring base firewall rules..."
    
    # Set defaults
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    
    # Always allow SSH
    ufw allow 22/tcp comment 'SSH'
    
    log_success "Base firewall configured"
}

allow_service_ports() {
    local service=$1
    local ports="${SERVICE_PORTS[$service]}"
    
    if [ -z "$ports" ]; then
        log_warning "No ports defined for service: $service"
        return 1
    fi
    
    log_info "Allowing ports for $service..."
    
    for port in $ports; do
        local description="${PORT_DESCRIPTIONS[$port]}"
        if [ -z "$description" ]; then
            description="$service"
        fi
        
        # Check if port should be localhost only
        if [[ "$port" == "3306" ]] || [[ "$port" == "6379" ]]; then
            # Database ports - localhost only
            log_info "Port $port ($description) - localhost only"
        else
            # Public ports
            ufw allow $port/tcp comment "$description"
            log_success "Allowed port $port/tcp ($description)"
        fi
    done
    
    # Record service in installed services
    echo "$service" >> "$INSTALLED_SERVICES"
}

remove_service_ports() {
    local service=$1
    local ports="${SERVICE_PORTS[$service]}"
    
    if [ -z "$ports" ]; then
        log_warning "No ports defined for service: $service"
        return 1
    fi
    
    log_info "Removing ports for $service..."
    
    for port in $ports; do
        ufw delete allow $port/tcp 2>/dev/null || true
        log_success "Removed port $port/tcp"
    done
    
    # Remove from installed services
    sed -i "/$service/d" "$INSTALLED_SERVICES"
}

auto_detect_services() {
    log_info "Auto-detecting installed services..."
    
    local detected_services=()
    
    # Check for Pterodactyl Panel
    if [ -d "/var/www/pterodactyl" ]; then
        detected_services+=("panel")
        log_info "Detected: Pterodactyl Panel"
    fi
    
    # Check for Wings
    if [ -f "/usr/local/bin/wings" ] || [ -f "/etc/pterodactyl/config.yml" ]; then
        detected_services+=("wings")
        log_info "Detected: Pterodactyl Wings"
    fi
    
    # Check for Ollama
    if command -v ollama &> /dev/null; then
        detected_services+=("ollama")
        log_info "Detected: Ollama"
    fi
    
    # Check for Open WebUI
    if docker ps | grep -q "open-webui"; then
        detected_services+=("openwebui")
        log_info "Detected: Open WebUI"
    fi
    
    # Check for Admin Panel
    if [ -d "/opt/unified-admin" ]; then
        detected_services+=("admin-panel")
        log_info "Detected: Admin Panel"
    fi
    
    # Check for SSH Terminal
    if [ -d "/opt/ssh-terminal" ]; then
        detected_services+=("ssh-terminal")
        log_info "Detected: SSH Terminal"
    fi
    
    # Check for FileBrowser
    if command -v filebrowser &> /dev/null; then
        detected_services+=("filebrowser")
        log_info "Detected: FileBrowser"
    fi
    
    # Check for Nginx
    if command -v nginx &> /dev/null; then
        detected_services+=("nginx")
        log_info "Detected: Nginx"
    fi
    
    # Check for MySQL
    if command -v mysql &> /dev/null || command -v mariadb &> /dev/null; then
        detected_services+=("mysql")
        log_info "Detected: MySQL/MariaDB"
    fi
    
    # Check for Redis
    if command -v redis-server &> /dev/null; then
        detected_services+=("redis")
        log_info "Detected: Redis"
    fi
    
    echo "${detected_services[@]}"
}

configure_firewall_for_services() {
    local services=("$@")
    
    log_info "Configuring firewall for ${#services[@]} services..."
    
    for service in "${services[@]}"; do
        allow_service_ports "$service"
    done
}

enable_firewall() {
    log_info "Enabling firewall..."
    ufw --force enable
    log_success "Firewall enabled"
}

show_firewall_status() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}    Firewall Status${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo ""
    ufw status verbose
    echo ""
}

create_firewall_backup() {
    local backup_dir="/etc/automatic-system/firewall-backups"
    mkdir -p "$backup_dir"
    
    local backup_file="$backup_dir/ufw-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    tar -czf "$backup_file" /etc/ufw/ 2>/dev/null
    
    log_success "Firewall backup created: $backup_file"
}

restore_firewall_backup() {
    local backup_dir="/etc/automatic-system/firewall-backups"
    
    if [ ! -d "$backup_dir" ]; then
        log_error "No backups found"
        return 1
    fi
    
    local latest_backup=$(ls -t "$backup_dir"/*.tar.gz 2>/dev/null | head -1)
    
    if [ -z "$latest_backup" ]; then
        log_error "No backup files found"
        return 1
    fi
    
    log_info "Restoring from: $latest_backup"
    
    ufw disable
    tar -xzf "$latest_backup" -C /
    ufw enable
    
    log_success "Firewall restored from backup"
}

add_custom_port() {
    local port=$1
    local description=$2
    local protocol=${3:-tcp}
    
    if [ -z "$port" ]; then
        log_error "Port number required"
        return 1
    fi
    
    if [ -z "$description" ]; then
        description="Custom port $port"
    fi
    
    ufw allow $port/$protocol comment "$description"
    log_success "Allowed custom port $port/$protocol ($description)"
}

remove_custom_port() {
    local port=$1
    local protocol=${2:-tcp}
    
    if [ -z "$port" ]; then
        log_error "Port number required"
        return 1
    fi
    
    ufw delete allow $port/$protocol 2>/dev/null
    log_success "Removed port $port/$protocol"
}

# Main execution
case "${1:-auto}" in
    "install")
        install_ufw
        configure_base_firewall
        
        # Auto-detect services
        services=($(auto_detect_services))
        
        if [ ${#services[@]} -gt 0 ]; then
            configure_firewall_for_services "${services[@]}"
        fi
        
        enable_firewall
        show_firewall_status
        ;;
    
    "auto")
        install_ufw
        configure_base_firewall
        
        # Auto-detect and configure
        services=($(auto_detect_services))
        
        if [ ${#services[@]} -gt 0 ]; then
            configure_firewall_for_services "${services[@]}"
        else
            log_warning "No services detected, configuring base firewall only"
        fi
        
        enable_firewall
        show_firewall_status
        ;;
    
    "add-service")
        if [ -z "$2" ]; then
            log_error "Service name required"
            exit 1
        fi
        allow_service_ports "$2"
        ufw reload
        show_firewall_status
        ;;
    
    "remove-service")
        if [ -z "$2" ]; then
            log_error "Service name required"
            exit 1
        fi
        remove_service_ports "$2"
        ufw reload
        show_firewall_status
        ;;
    
    "add-port")
        add_custom_port "$2" "$3" "$4"
        ufw reload
        show_firewall_status
        ;;
    
    "remove-port")
        remove_custom_port "$2" "$3"
        ufw reload
        show_firewall_status
        ;;
    
    "status")
        show_firewall_status
        ;;
    
    "backup")
        create_firewall_backup
        ;;
    
    "restore")
        restore_firewall_backup
        show_firewall_status
        ;;
    
    "reset")
        log_warning "Resetting firewall to defaults..."
        configure_base_firewall
        enable_firewall
        show_firewall_status
        ;;
    
    *)
        echo "Usage: $0 {install|auto|add-service|remove-service|add-port|remove-port|status|backup|restore|reset}"
        echo ""
        echo "Commands:"
        echo "  install              - Install and configure firewall"
        echo "  auto                 - Auto-detect services and configure (default)"
        echo "  add-service <name>   - Add firewall rules for a service"
        echo "  remove-service <name> - Remove firewall rules for a service"
        echo "  add-port <port> <description> [protocol] - Add custom port"
        echo "  remove-port <port> [protocol] - Remove custom port"
        echo "  status               - Show firewall status"
        echo "  backup               - Backup firewall configuration"
        echo "  restore              - Restore firewall from backup"
        echo "  reset                - Reset firewall to defaults"
        echo ""
        echo "Available services:"
        for service in "${!SERVICE_PORTS[@]}"; do
            echo "  - $service (ports: ${SERVICE_PORTS[$service]})"
        done
        exit 1
        ;;
esac
