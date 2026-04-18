#!/bin/bash

# Pterodactyl Admin Control Panel
# Visual interface for managing all pteroanyinstall features

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

show_header() {
    clear
    cat <<'EOF'
╔════════════════════════════════════════════════════════════════════════╗
║                  PTERODACTYL ADMIN CONTROL PANEL                       ║
║                     Advanced Management Interface                      ║
╚════════════════════════════════════════════════════════════════════════╝

EOF
}

show_status_bar() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Quick status indicators
    local panel_status="●"
    local wings_status="●"
    local backup_status="●"
    local security_status="●"
    
    systemctl is-active --quiet nginx && panel_status="${GREEN}●${NC}" || panel_status="${RED}●${NC}"
    systemctl is-active --quiet wings 2>/dev/null && wings_status="${GREEN}●${NC}" || wings_status="${YELLOW}●${NC}"
    [ -d "/var/backups/pterodactyl" ] && backup_status="${GREEN}●${NC}" || backup_status="${YELLOW}●${NC}"
    systemctl is-active --quiet fail2ban 2>/dev/null && security_status="${GREEN}●${NC}" || security_status="${YELLOW}●${NC}"
    
    echo -e " Panel: $panel_status  Wings: $wings_status  Backups: $backup_status  Security: $security_status"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

main_menu() {
    show_header
    show_status_bar
    
    echo "Main Menu:"
    echo ""
    echo "  ${GREEN}System Management${NC}"
    echo "    1)  System Health Dashboard"
    echo "    2)  Service Control (Start/Stop/Restart)"
    echo "    3)  Resource Monitor"
    echo "    4)  System Logs Viewer"
    echo ""
    echo "  ${BLUE}Security & Monitoring${NC}"
    echo "    5)  Security Status (Fail2ban)"
    echo "    6)  SSL Certificate Status"
    echo "    7)  Firewall Management"
    echo "    8)  Security Audit"
    echo ""
    echo "  ${YELLOW}Backup & Recovery${NC}"
    echo "    9)  Backup Management"
    echo "    10) Create Manual Backup"
    echo "    11) Restore from Backup"
    echo "    12) Backup Schedule Settings"
    echo ""
    echo "  ${MAGENTA}Updates & Maintenance${NC}"
    echo "    13) Check for Updates"
    echo "    14) Update Panel"
    echo "    15) Update Wings"
    echo "    16) Update All Components"
    echo ""
    echo "  ${CYAN}Advanced Features${NC}"
    echo "    17) Panel Customization"
    echo "    18) Billing System Management"
    echo "    19) Database Management"
    echo "    20) Performance Optimization"
    echo ""
    echo "  ${GREEN}Configuration${NC}"
    echo "    21) Quick Setup Wizard"
    echo "    22) Network Configuration"
    echo "    23) Email Settings"
    echo "    24) API Configuration"
    echo ""
    echo "    0)  Exit"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    read -p "Select option [0-24]: " choice
    
    handle_menu_choice "$choice"
}

handle_menu_choice() {
    case $1 in
        1) system_health_dashboard ;;
        2) service_control ;;
        3) resource_monitor ;;
        4) logs_viewer ;;
        5) security_status ;;
        6) ssl_status ;;
        7) firewall_management ;;
        8) security_audit ;;
        9) backup_management ;;
        10) create_backup ;;
        11) restore_backup ;;
        12) backup_schedule ;;
        13) check_updates ;;
        14) update_panel ;;
        15) update_wings ;;
        16) update_all ;;
        17) panel_customization ;;
        18) billing_management ;;
        19) database_management ;;
        20) performance_optimization ;;
        21) quick_setup ;;
        22) network_config ;;
        23) email_settings ;;
        24) api_config ;;
        0) exit 0 ;;
        *) 
            log_error "Invalid option"
            sleep 2
            main_menu
            ;;
    esac
}

# 1. System Health Dashboard
system_health_dashboard() {
    if [ -f "/usr/local/bin/ptero-health.sh" ]; then
        /usr/local/bin/ptero-health.sh
    else
        show_header
        log_error "Health dashboard not installed"
        log_info "Run quick setup to install it"
    fi
    
    echo ""
    read -p "Press Enter to return to menu..."
    main_menu
}

# 2. Service Control
service_control() {
    show_header
    echo "Service Control"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Show current status
    echo "Current Status:"
    echo ""
    
    check_service_status() {
        local service=$1
        local display_name=$2
        
        if systemctl is-active --quiet $service 2>/dev/null; then
            echo -e "  $display_name: ${GREEN}Running${NC}"
        else
            echo -e "  $display_name: ${RED}Stopped${NC}"
        fi
    }
    
    check_service_status "nginx" "Nginx"
    check_service_status "mysql" "MySQL" || check_service_status "mariadb" "MariaDB"
    check_service_status "redis-server" "Redis" || check_service_status "redis" "Redis"
    check_service_status "wings" "Wings"
    check_service_status "docker" "Docker"
    check_service_status "fail2ban" "Fail2ban"
    
    echo ""
    echo "Actions:"
    echo "  1) Restart All Services"
    echo "  2) Stop All Services"
    echo "  3) Start All Services"
    echo "  4) Restart Specific Service"
    echo "  0) Back to Main Menu"
    echo ""
    read -p "Select action [0-4]: " action
    
    case $action in
        1)
            log_info "Restarting all services..."
            systemctl restart nginx
            systemctl restart mysql 2>/dev/null || systemctl restart mariadb
            systemctl restart redis-server 2>/dev/null || systemctl restart redis
            systemctl restart wings 2>/dev/null || true
            systemctl restart docker
            log_success "All services restarted"
            ;;
        2)
            log_warning "Stopping all services..."
            systemctl stop nginx
            systemctl stop wings 2>/dev/null || true
            log_success "Services stopped"
            ;;
        3)
            log_info "Starting all services..."
            systemctl start nginx
            systemctl start mysql 2>/dev/null || systemctl start mariadb
            systemctl start redis-server 2>/dev/null || systemctl start redis
            systemctl start wings 2>/dev/null || true
            systemctl start docker
            log_success "Services started"
            ;;
        4)
            echo ""
            echo "Select service:"
            echo "  1) Nginx"
            echo "  2) MySQL/MariaDB"
            echo "  3) Redis"
            echo "  4) Wings"
            echo "  5) Docker"
            read -p "Service [1-5]: " svc
            
            case $svc in
                1) systemctl restart nginx && log_success "Nginx restarted" ;;
                2) systemctl restart mysql 2>/dev/null || systemctl restart mariadb && log_success "Database restarted" ;;
                3) systemctl restart redis-server 2>/dev/null || systemctl restart redis && log_success "Redis restarted" ;;
                4) systemctl restart wings && log_success "Wings restarted" ;;
                5) systemctl restart docker && log_success "Docker restarted" ;;
            esac
            ;;
    esac
    
    sleep 2
    service_control
}

# 3. Resource Monitor
resource_monitor() {
    show_header
    echo "Resource Monitor (Live)"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Press Ctrl+C to return to menu"
    echo ""
    
    htop 2>/dev/null || top
    
    main_menu
}

# 4. Logs Viewer
logs_viewer() {
    show_header
    echo "System Logs Viewer"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Select log to view:"
    echo "  1) Pterodactyl Panel Logs"
    echo "  2) Wings Logs"
    echo "  3) Nginx Error Log"
    echo "  4) Nginx Access Log"
    echo "  5) MySQL/MariaDB Log"
    echo "  6) System Log"
    echo "  7) Fail2ban Log"
    echo "  0) Back"
    echo ""
    read -p "Select [0-7]: " log_choice
    
    case $log_choice in
        1) tail -f /var/www/pterodactyl/storage/logs/laravel-$(date +%Y-%m-%d).log 2>/dev/null || echo "No logs found" ;;
        2) journalctl -u wings -f ;;
        3) tail -f /var/log/nginx/error.log ;;
        4) tail -f /var/log/nginx/access.log ;;
        5) tail -f /var/log/mysql/error.log 2>/dev/null || tail -f /var/log/mariadb/mariadb.log ;;
        6) journalctl -f ;;
        7) tail -f /var/log/fail2ban.log 2>/dev/null || echo "Fail2ban not installed" ;;
        0) main_menu ;;
    esac
    
    echo ""
    read -p "Press Enter to return..."
    logs_viewer
}

# 5. Security Status
security_status() {
    show_header
    echo "Security Status"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if command -v fail2ban-client &> /dev/null; then
        if systemctl is-active --quiet fail2ban; then
            log_success "Fail2ban is active"
            echo ""
            fail2ban-client status
            echo ""
            echo "Banned IPs:"
            fail2ban-client status | grep "Jail list" | sed 's/.*://g' | tr ',' '\n' | while read jail; do
                [ -n "$jail" ] && fail2ban-client status $jail | grep "Banned IP"
            done
        else
            log_warning "Fail2ban is installed but not running"
        fi
    else
        log_error "Fail2ban is not installed"
        echo ""
        if read -p "Install Fail2ban now? (y/n): " -n 1 -r; then
            echo ""
            bash quick-setup.sh
        fi
    fi
    
    echo ""
    read -p "Press Enter to return..."
    main_menu
}

# 6. SSL Status
ssl_status() {
    show_header
    echo "SSL Certificate Status"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ -f "/var/www/pterodactyl/.env" ]; then
        PANEL_URL=$(grep APP_URL /var/www/pterodactyl/.env | cut -d '=' -f2 | sed 's|https://||' | sed 's|http://||')
        
        if [ -n "$PANEL_URL" ]; then
            echo "Checking SSL for: $PANEL_URL"
            echo ""
            
            CERT_INFO=$(echo | openssl s_client -servername "$PANEL_URL" -connect "$PANEL_URL:443" 2>/dev/null | openssl x509 -noout -dates -subject -issuer 2>/dev/null)
            
            if [ -n "$CERT_INFO" ]; then
                echo "$CERT_INFO"
                echo ""
                
                EXPIRY=$(echo "$CERT_INFO" | grep "notAfter" | cut -d= -f2)
                DAYS=$(( ($(date -d "$EXPIRY" +%s) - $(date +%s)) / 86400 ))
                
                if [ $DAYS -lt 30 ]; then
                    log_warning "Certificate expires in $DAYS days!"
                else
                    log_success "Certificate valid for $DAYS more days"
                fi
                
                # Test SSL grade
                echo ""
                log_info "Testing SSL configuration..."
                echo "Visit: https://www.ssllabs.com/ssltest/analyze.html?d=$PANEL_URL"
            else
                log_error "Could not retrieve SSL certificate"
            fi
        fi
    else
        log_error "Panel not found"
    fi
    
    echo ""
    read -p "Press Enter to return..."
    main_menu
}

# 9. Backup Management
backup_management() {
    show_header
    echo "Backup Management"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ -d "/var/backups/pterodactyl" ]; then
        echo "Recent Backups:"
        echo ""
        ls -lht /var/backups/pterodactyl | head -10 | tail -9 | awk '{print "  " $9, "-", $5, "-", $6, $7, $8}'
        echo ""
        
        BACKUP_COUNT=$(ls -1 /var/backups/pterodactyl | wc -l)
        BACKUP_SIZE=$(du -sh /var/backups/pterodactyl | awk '{print $1}')
        
        echo "Total backups: $BACKUP_COUNT"
        echo "Total size: $BACKUP_SIZE"
    else
        log_warning "No backups found"
    fi
    
    echo ""
    echo "Actions:"
    echo "  1) Create backup now"
    echo "  2) View backup schedule"
    echo "  3) Restore from backup"
    echo "  4) Delete old backups"
    echo "  0) Back"
    echo ""
    read -p "Select [0-4]: " backup_action
    
    case $backup_action in
        1) create_backup ;;
        2) backup_schedule ;;
        3) restore_backup ;;
        4) 
            read -p "Delete backups older than how many days? [30]: " days
            days=${days:-30}
            find /var/backups/pterodactyl -type f -mtime +$days -delete
            log_success "Old backups deleted"
            sleep 2
            backup_management
            ;;
        0) main_menu ;;
    esac
}

# 10. Create Backup
create_backup() {
    show_header
    log_info "Creating backup..."
    
    if [ -f "/usr/local/bin/pterodactyl-backup.sh" ]; then
        /usr/local/bin/pterodactyl-backup.sh
    else
        log_error "Backup script not found. Run quick setup first."
    fi
    
    echo ""
    read -p "Press Enter to return..."
    backup_management
}

# 17. Panel Customization
panel_customization() {
    show_header
    log_info "Launching panel customizer..."
    
    if [ -f "$(dirname $0)/panel-customizer.sh" ]; then
        bash "$(dirname $0)/panel-customizer.sh"
    else
        log_error "Panel customizer not found"
    fi
    
    main_menu
}

# 21. Quick Setup
quick_setup() {
    if [ -f "$(dirname $0)/quick-setup.sh" ]; then
        bash "$(dirname $0)/quick-setup.sh"
    else
        log_error "Quick setup script not found"
        sleep 2
    fi
    
    main_menu
}

# Stub functions for features to be implemented
firewall_management() { show_header; log_info "Feature coming soon..."; sleep 2; main_menu; }
security_audit() { show_header; log_info "Feature coming soon..."; sleep 2; main_menu; }
restore_backup() { show_header; log_info "Feature coming soon..."; sleep 2; main_menu; }
backup_schedule() { show_header; log_info "Feature coming soon..."; sleep 2; main_menu; }
check_updates() { show_header; bash /usr/local/bin/check-ptero-updates.sh 2>/dev/null || log_error "Update checker not installed"; read -p "Press Enter..."; main_menu; }
update_panel() { show_header; log_info "Feature coming soon..."; sleep 2; main_menu; }
update_wings() { show_header; log_info "Feature coming soon..."; sleep 2; main_menu; }
update_all() { show_header; log_info "Feature coming soon..."; sleep 2; main_menu; }
billing_management() { show_header; log_info "Feature coming soon..."; sleep 2; main_menu; }
database_management() { show_header; log_info "Feature coming soon..."; sleep 2; main_menu; }
performance_optimization() { show_header; log_info "Feature coming soon..."; sleep 2; main_menu; }
network_config() { show_header; log_info "Feature coming soon..."; sleep 2; main_menu; }
email_settings() { show_header; log_info "Feature coming soon..."; sleep 2; main_menu; }
api_config() { show_header; log_info "Feature coming soon..."; sleep 2; main_menu; }

# Main entry point
main() {
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
    
    main_menu
}

main "$@"
