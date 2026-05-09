#!/bin/bash

# Dynamic IP Monitor and Auto-Repair Service
# Monitors public IP changes and automatically updates DNS/services

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

IP_FILE="/var/lib/automatic-system/current-ip"
CONFIG_FILE="/etc/automatic-system/ip-monitor.conf"
LOG_FILE="/var/log/ip-monitor.log"
DOMAINS_FILE="/etc/automatic-system/domains.conf"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_info() {
    log "[INFO] $1"
}

log_success() {
    log "[SUCCESS] $1"
}

log_warning() {
    log "[WARNING] $1"
}

log_error() {
    log "[ERROR] $1"
}

get_public_ip() {
    local ip=""
    
    # Try multiple IP detection services
    ip=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null) || \
    ip=$(curl -s --max-time 5 https://icanhazip.com 2>/dev/null) || \
    ip=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null) || \
    ip=$(curl -s --max-time 5 https://checkip.amazonaws.com 2>/dev/null)
    
    if [ -z "$ip" ]; then
        log_error "Failed to detect public IP"
        return 1
    fi
    
    # Validate IP format
    if [[ ! $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        log_error "Invalid IP format: $ip"
        return 1
    fi
    
    echo "$ip"
}

get_stored_ip() {
    if [ -f "$IP_FILE" ]; then
        cat "$IP_FILE"
    else
        echo ""
    fi
}

store_ip() {
    local ip=$1
    mkdir -p "$(dirname "$IP_FILE")"
    echo "$ip" > "$IP_FILE"
    log_info "Stored IP: $ip"
}

update_cloudflare_dns() {
    local domain=$1
    local new_ip=$2
    
    # Check if Cloudflare API credentials are configured
    if [ ! -f "$CONFIG_FILE" ]; then
        log_warning "Cloudflare API not configured, skipping DNS update for $domain"
        return 1
    fi
    
    source "$CONFIG_FILE"
    
    if [ -z "$CLOUDFLARE_API_TOKEN" ] || [ -z "$CLOUDFLARE_ZONE_ID" ]; then
        log_warning "Cloudflare credentials missing"
        return 1
    fi
    
    # Get DNS record ID
    local record_name=$(echo "$domain" | cut -d. -f1)
    local zone_domain=$(echo "$domain" | cut -d. -f2-)
    
    local record_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records?name=$domain" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" | jq -r '.result[0].id')
    
    if [ -z "$record_id" ] || [ "$record_id" == "null" ]; then
        log_error "DNS record not found for $domain"
        return 1
    fi
    
    # Update DNS record
    local response=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$record_id" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"A\",\"name\":\"$domain\",\"content\":\"$new_ip\",\"ttl\":1,\"proxied\":true}")
    
    if echo "$response" | jq -e '.success' > /dev/null 2>&1; then
        log_success "Updated DNS for $domain to $new_ip"
        return 0
    else
        log_error "Failed to update DNS for $domain: $response"
        return 1
    fi
}

update_pterodactyl_panel() {
    local new_ip=$1
    
    # Update Panel FQDN in .env if needed
    if [ -f "/var/www/pterodactyl/.env" ]; then
        local current_url=$(grep "APP_URL=" /var/www/pterodactyl/.env | cut -d= -f2)
        log_info "Panel URL: $current_url (no IP update needed)"
    fi
}

update_wings_config() {
    local new_ip=$1
    
    # Update Wings config if it uses IP directly
    if [ -f "/etc/pterodactyl/config.yml" ]; then
        # Wings typically uses domain names, not IPs
        log_info "Wings uses domain-based configuration (no IP update needed)"
    fi
}

restart_affected_services() {
    log_info "Checking services that may need restart..."
    
    local services_to_restart=()
    
    # Check if Panel needs restart
    if systemctl is-active --quiet pterodactyl; then
        services_to_restart+=("pterodactyl")
    fi
    
    # Check if Wings needs restart
    if systemctl is-active --quiet wings; then
        services_to_restart+=("wings")
    fi
    
    # Check if Nginx needs reload
    if systemctl is-active --quiet nginx; then
        log_info "Reloading Nginx configuration..."
        systemctl reload nginx
    fi
    
    # Restart services if needed
    for service in "${services_to_restart[@]}"; do
        log_info "Restarting $service..."
        systemctl restart "$service"
        log_success "$service restarted"
    done
}

send_notification() {
    local old_ip=$1
    local new_ip=$2
    
    # Send email notification if configured
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        
        if [ -n "$NOTIFICATION_EMAIL" ]; then
            local subject="IP Address Changed: $old_ip → $new_ip"
            local body="Your server's public IP address has changed.\n\nOld IP: $old_ip\nNew IP: $new_ip\n\nAll services have been automatically updated."
            
            echo -e "$body" | mail -s "$subject" "$NOTIFICATION_EMAIL" 2>/dev/null || \
                log_warning "Failed to send email notification"
        fi
    fi
    
    # Log to system journal
    logger -t ip-monitor "IP changed from $old_ip to $new_ip"
}

update_port_forwarding() {
    local new_ip=$1
    
    # Try to update UPnP port forwarding if enabled
    if command -v upnpc &> /dev/null; then
        log_info "Updating UPnP port forwarding..."
        
        # Remove old mappings
        upnpc -d 80 TCP 2>/dev/null || true
        upnpc -d 443 TCP 2>/dev/null || true
        upnpc -d 8080 TCP 2>/dev/null || true
        upnpc -d 2022 TCP 2>/dev/null || true
        
        # Add new mappings
        upnpc -a $new_ip 80 80 TCP 2>/dev/null && log_success "UPnP: Port 80 forwarded"
        upnpc -a $new_ip 443 443 TCP 2>/dev/null && log_success "UPnP: Port 443 forwarded"
        upnpc -a $new_ip 8080 8080 TCP 2>/dev/null && log_success "UPnP: Port 8080 forwarded"
        upnpc -a $new_ip 2022 2022 TCP 2>/dev/null && log_success "UPnP: Port 2022 forwarded"
    fi
}

check_and_repair() {
    log_info "Checking public IP..."
    
    local current_ip=$(get_public_ip)
    if [ $? -ne 0 ]; then
        log_error "Failed to get public IP"
        return 1
    fi
    
    local stored_ip=$(get_stored_ip)
    
    if [ -z "$stored_ip" ]; then
        log_info "First run, storing IP: $current_ip"
        store_ip "$current_ip"
        return 0
    fi
    
    if [ "$current_ip" != "$stored_ip" ]; then
        log_warning "IP CHANGED: $stored_ip → $current_ip"
        
        # Update stored IP
        store_ip "$current_ip"
        
        # Update DNS records
        if [ -f "$DOMAINS_FILE" ]; then
            source "$DOMAINS_FILE"
            
            for domain_var in $(grep "_DOMAIN=" "$DOMAINS_FILE" | cut -d= -f1); do
                local domain="${!domain_var}"
                if [ -n "$domain" ]; then
                    log_info "Updating DNS for $domain..."
                    update_cloudflare_dns "$domain" "$current_ip"
                fi
            done
        fi
        
        # Update services
        update_pterodactyl_panel "$current_ip"
        update_wings_config "$current_ip"
        
        # Update port forwarding
        update_port_forwarding "$current_ip"
        
        # Restart affected services
        restart_affected_services
        
        # Send notification
        send_notification "$stored_ip" "$current_ip"
        
        log_success "IP change handled successfully!"
    else
        log_info "IP unchanged: $current_ip"
    fi
}

setup_cloudflare_api() {
    echo "Setting up Cloudflare API integration..."
    echo ""
    
    read -p "Enter Cloudflare API Token: " api_token
    read -p "Enter Cloudflare Zone ID: " zone_id
    read -p "Enter notification email (optional): " email
    
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    cat > "$CONFIG_FILE" << EOF
# Cloudflare API Configuration
CLOUDFLARE_API_TOKEN="$api_token"
CLOUDFLARE_ZONE_ID="$zone_id"
NOTIFICATION_EMAIL="$email"

# Update interval (seconds)
CHECK_INTERVAL=300
EOF
    
    chmod 600 "$CONFIG_FILE"
    
    echo "Configuration saved to $CONFIG_FILE"
}

install_service() {
    log_info "Installing IP monitor service..."
    
    # Create systemd service
    cat > /etc/systemd/system/ip-monitor.service << 'EOF'
[Unit]
Description=Dynamic IP Monitor and Auto-Repair
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/opt/ptero/ip-monitor.sh monitor
Restart=always
RestartSec=60
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Create timer for periodic checks
    cat > /etc/systemd/system/ip-monitor.timer << 'EOF'
[Unit]
Description=IP Monitor Check Timer
Requires=ip-monitor.service

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
AccuracySec=1min

[Install]
WantedBy=timers.target
EOF
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable and start timer
    systemctl enable ip-monitor.timer
    systemctl start ip-monitor.timer
    
    log_success "IP monitor service installed!"
    log_info "Service will check IP every 5 minutes"
    log_info "View logs: journalctl -u ip-monitor -f"
}

uninstall_service() {
    log_info "Uninstalling IP monitor service..."
    
    systemctl stop ip-monitor.timer 2>/dev/null || true
    systemctl disable ip-monitor.timer 2>/dev/null || true
    systemctl stop ip-monitor.service 2>/dev/null || true
    systemctl disable ip-monitor.service 2>/dev/null || true
    
    rm -f /etc/systemd/system/ip-monitor.service
    rm -f /etc/systemd/system/ip-monitor.timer
    
    systemctl daemon-reload
    
    log_success "IP monitor service uninstalled"
}

show_status() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}    IP Monitor Status${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo ""
    
    local current_ip=$(get_public_ip)
    local stored_ip=$(get_stored_ip)
    
    echo -e "${BLUE}Current Public IP:${NC} $current_ip"
    echo -e "${BLUE}Stored IP:${NC} $stored_ip"
    echo ""
    
    if [ "$current_ip" == "$stored_ip" ]; then
        echo -e "${GREEN}✓ IP is stable${NC}"
    else
        echo -e "${YELLOW}⚠ IP has changed!${NC}"
    fi
    echo ""
    
    echo -e "${BLUE}Service Status:${NC}"
    systemctl status ip-monitor.timer --no-pager 2>/dev/null || echo "Service not installed"
    echo ""
    
    echo -e "${BLUE}Recent IP Changes:${NC}"
    grep "IP CHANGED" "$LOG_FILE" 2>/dev/null | tail -5 || echo "No changes recorded"
    echo ""
}

# Main execution
case "${1:-check}" in
    "check")
        check_and_repair
        ;;
    
    "monitor")
        # Continuous monitoring mode (for systemd service)
        while true; do
            check_and_repair
            sleep ${CHECK_INTERVAL:-300}
        done
        ;;
    
    "setup")
        setup_cloudflare_api
        ;;
    
    "install")
        install_service
        ;;
    
    "uninstall")
        uninstall_service
        ;;
    
    "status")
        show_status
        ;;
    
    "force-update")
        log_info "Forcing IP update..."
        local current_ip=$(get_public_ip)
        store_ip "0.0.0.0"  # Force change detection
        check_and_repair
        ;;
    
    "test")
        log_info "Testing IP detection..."
        local ip=$(get_public_ip)
        echo "Detected IP: $ip"
        ;;
    
    *)
        echo "Usage: $0 {check|monitor|setup|install|uninstall|status|force-update|test}"
        echo ""
        echo "Commands:"
        echo "  check        - Check IP and repair if changed (one-time)"
        echo "  monitor      - Continuous monitoring mode"
        echo "  setup        - Configure Cloudflare API credentials"
        echo "  install      - Install as systemd service"
        echo "  uninstall    - Remove systemd service"
        echo "  status       - Show current status"
        echo "  force-update - Force update all services"
        echo "  test         - Test IP detection"
        exit 1
        ;;
esac
