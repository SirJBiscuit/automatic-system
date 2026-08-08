#!/bin/bash

# Pterodactyl Panel Diagnostics & Quick Fix Script
# Helps diagnose and fix common panel connectivity issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PANEL_DIR="/var/www/pterodactyl"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
TUNNEL_CONFIG="/root/.cloudflared/config.yml"
TUNNEL_SERVICE="cloudflared-webconsole"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Pterodactyl Panel Diagnostics & Quick Fix Tool          ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo ""

# Function to print section headers
print_header() {
    echo -e "\n${YELLOW}═══ $1 ═══${NC}\n"
}

# Function to check if a port is listening
check_port() {
    local port=$1
    local service=$2
    if sudo netstat -tlnp | grep -q ":$port "; then
        local process=$(sudo netstat -tlnp | grep ":$port " | awk '{print $7}' | head -1)
        echo -e "${GREEN}✓${NC} Port $port is ${GREEN}LISTENING${NC} ($service) - Process: $process"
        return 0
    else
        echo -e "${RED}✗${NC} Port $port is ${RED}NOT LISTENING${NC} ($service)"
        return 1
    fi
}

# Function to test HTTP endpoint
test_endpoint() {
    local url=$1
    local name=$2
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|302"; then
        echo -e "${GREEN}✓${NC} $name is ${GREEN}RESPONDING${NC}"
        return 0
    else
        echo -e "${RED}✗${NC} $name is ${RED}NOT RESPONDING${NC}"
        return 1
    fi
}

# 1. Check all important ports
print_header "Port Status Check"
check_port 8082 "Panel (Tunnel)"
check_port 443 "HTTPS/Nginx"
check_port 8080 "Web Console Proxy"
check_port 8081 "Web Console App"
check_port 5050 "Pingvin Share"
check_port 5051 "Nextcloud"
check_port 3000 "Open WebUI"

# 2. Check services
print_header "Service Status Check"
services=("nginx" "php8.2-fpm" "$TUNNEL_SERVICE" "pterodactyl-web-console")
for service in "${services[@]}"; do
    if sudo systemctl is-active --quiet "$service"; then
        echo -e "${GREEN}✓${NC} $service is ${GREEN}RUNNING${NC}"
    else
        echo -e "${RED}✗${NC} $service is ${RED}NOT RUNNING${NC}"
    fi
done

# 3. Test endpoints
print_header "Endpoint Testing"
test_endpoint "http://localhost:8082" "Panel (Port 8082)"
test_endpoint "https://localhost:443" "Nginx HTTPS"
test_endpoint "https://panel.cloudmc.online" "Panel (Public)"

# 4. Check Cloudflare Tunnel Configuration
print_header "Cloudflare Tunnel Configuration"
if [ -f "$TUNNEL_CONFIG" ]; then
    echo -e "${GREEN}✓${NC} Tunnel config found at: $TUNNEL_CONFIG"
    echo ""
    echo "Panel tunnel configuration:"
    sudo cat "$TUNNEL_CONFIG" | grep -A 2 "panel.cloudmc.online" || echo -e "${RED}✗${NC} Panel not found in tunnel config!"
else
    echo -e "${RED}✗${NC} Tunnel config not found at: $TUNNEL_CONFIG"
fi

# 5. Show important file locations
print_header "Important File Locations"
echo -e "${BLUE}Panel Files:${NC}"
echo "  • Panel Directory: $PANEL_DIR"
echo "  • Panel Config: $PANEL_DIR/.env"
echo "  • Panel Public: $PANEL_DIR/public"
echo ""
echo -e "${BLUE}Nginx Configurations:${NC}"
echo "  • Enabled Sites: $NGINX_SITES_ENABLED"
echo "  • Available Sites: $NGINX_SITES_AVAILABLE"
echo "  • Panel Config: $NGINX_SITES_ENABLED/pterodactyl.conf"
echo "  • Panel Tunnel: $NGINX_SITES_ENABLED/pterodactyl-tunnel"
echo "  • Web Console: $NGINX_SITES_ENABLED/pterodactyl-web-console"
echo ""
echo -e "${BLUE}Cloudflare Tunnel:${NC}"
echo "  • Config: $TUNNEL_CONFIG"
echo "  • Service: $TUNNEL_SERVICE"
echo ""
echo -e "${BLUE}Logs:${NC}"
echo "  • Nginx Error: /var/log/nginx/pterodactyl.app-error.log"
echo "  • PHP-FPM: /var/log/php8.2-fpm.log"
echo "  • Tunnel: sudo journalctl -u $TUNNEL_SERVICE -n 50"

# 6. Quick fix menu
print_header "Quick Fix Options"
echo "What would you like to do?"
echo ""
echo "1) Restart all services"
echo "2) Edit tunnel configuration"
echo "3) Edit panel nginx config"
echo "4) View tunnel logs"
echo "5) View nginx error logs"
echo "6) Test panel connectivity"
echo "7) Change panel tunnel port"
echo "8) Show tunnel status"
echo "9) Exit"
echo ""

read -p "Enter your choice (1-9): " choice

case $choice in
    1)
        print_header "Restarting Services"
        echo "Restarting nginx..."
        sudo systemctl restart nginx
        echo "Restarting PHP-FPM..."
        sudo systemctl restart php8.2-fpm
        echo "Restarting Cloudflare tunnel..."
        sudo systemctl restart $TUNNEL_SERVICE
        echo -e "${GREEN}✓${NC} All services restarted!"
        sleep 3
        echo ""
        echo "Testing panel..."
        curl -I https://panel.cloudmc.online
        ;;
    2)
        print_header "Editing Tunnel Configuration"
        echo "Opening $TUNNEL_CONFIG in nano..."
        sleep 1
        sudo nano "$TUNNEL_CONFIG"
        echo ""
        read -p "Restart tunnel service? (y/n): " restart
        if [[ $restart == "y" ]]; then
            sudo systemctl restart $TUNNEL_SERVICE
            echo -e "${GREEN}✓${NC} Tunnel restarted!"
        fi
        ;;
    3)
        print_header "Editing Panel Nginx Config"
        echo "Which config would you like to edit?"
        echo "1) Main panel (pterodactyl.conf)"
        echo "2) Tunnel config (pterodactyl-tunnel)"
        read -p "Choice: " nginx_choice
        if [[ $nginx_choice == "1" ]]; then
            sudo nano "$NGINX_SITES_ENABLED/pterodactyl.conf"
        else
            sudo nano "$NGINX_SITES_ENABLED/pterodactyl-tunnel"
        fi
        echo ""
        read -p "Test and reload nginx? (y/n): " reload
        if [[ $reload == "y" ]]; then
            sudo nginx -t && sudo systemctl reload nginx
            echo -e "${GREEN}✓${NC} Nginx reloaded!"
        fi
        ;;
    4)
        print_header "Tunnel Logs (Last 50 lines)"
        sudo journalctl -u $TUNNEL_SERVICE -n 50 --no-pager
        ;;
    5)
        print_header "Nginx Error Logs (Last 50 lines)"
        sudo tail -50 /var/log/nginx/pterodactyl.app-error.log
        ;;
    6)
        print_header "Testing Panel Connectivity"
        echo "Testing local port 8082..."
        curl -I http://localhost:8082
        echo ""
        echo "Testing HTTPS (443)..."
        curl -k -I https://localhost:443 -H "Host: panel.cloudmc.online"
        echo ""
        echo "Testing public domain..."
        curl -I https://panel.cloudmc.online
        ;;
    7)
        print_header "Change Panel Tunnel Port"
        echo "Current tunnel configuration:"
        sudo cat "$TUNNEL_CONFIG" | grep -A 2 "panel.cloudmc.online"
        echo ""
        echo "Available ports:"
        echo "  8082 - Panel tunnel (current)"
        echo "  8080 - Web console proxy"
        echo "  443  - HTTPS (requires noTLSVerify)"
        echo ""
        read -p "Enter new port number: " new_port
        read -p "Use HTTP or HTTPS? (http/https): " protocol
        
        if [[ $protocol == "https" ]]; then
            echo "Updating to https://localhost:$new_port with noTLSVerify..."
            sudo sed -i "/hostname: panel.cloudmc.online/,/service:/ s|service:.*|service: https://localhost:$new_port|" "$TUNNEL_CONFIG"
        else
            echo "Updating to http://localhost:$new_port..."
            sudo sed -i "/hostname: panel.cloudmc.online/,/service:/ s|service:.*|service: http://localhost:$new_port|" "$TUNNEL_CONFIG"
        fi
        
        echo -e "${GREEN}✓${NC} Tunnel config updated!"
        echo ""
        read -p "Restart tunnel? (y/n): " restart
        if [[ $restart == "y" ]]; then
            sudo systemctl restart $TUNNEL_SERVICE
            sleep 3
            echo "Testing..."
            curl -I https://panel.cloudmc.online
        fi
        ;;
    8)
        print_header "Tunnel Status"
        sudo systemctl status $TUNNEL_SERVICE
        echo ""
        echo "Recent tunnel activity:"
        sudo journalctl -u $TUNNEL_SERVICE --since "5 minutes ago" --no-pager | tail -20
        ;;
    9)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice!${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    Operation Complete!                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
