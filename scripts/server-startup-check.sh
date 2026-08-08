#!/bin/bash

# Server Startup & Recovery Script
# Ensures all services start correctly after reboot/network changes

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}     Server Startup & Recovery Check - cloudmc.online      ${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

# Function to wait for service
wait_for_service() {
    local service=$1
    local max_wait=30
    local count=0
    
    echo -n "Waiting for $service to be ready..."
    while ! sudo systemctl is-active --quiet "$service" && [ $count -lt $max_wait ]; do
        sleep 1
        count=$((count + 1))
        echo -n "."
    done
    
    if sudo systemctl is-active --quiet "$service"; then
        echo -e " ${GREEN}OK${NC}"
        return 0
    else
        echo -e " ${RED}FAILED${NC}"
        return 1
    fi
}

# Function to check port
check_port() {
    local port=$1
    local service=$2
    if sudo netstat -tlnp | grep -q ":$port "; then
        echo -e "${GREEN}✓${NC} Port $port ($service) is listening"
        return 0
    else
        echo -e "${RED}✗${NC} Port $port ($service) is NOT listening"
        return 1
    fi
}

# 1. Check network connectivity
echo -e "\n${YELLOW}=== Network Connectivity ===${NC}"
if ping -c 3 8.8.8.8 > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Internet connection is working"
else
    echo -e "${RED}✗${NC} No internet connection - waiting 30 seconds..."
    sleep 30
    if ! ping -c 3 8.8.8.8 > /dev/null 2>&1; then
        echo -e "${RED}✗${NC} Still no internet. Check your network!"
        exit 1
    fi
fi

# Get public IP
PUBLIC_IP=$(curl -s -4 ifconfig.me)
echo -e "${BLUE}Public IP:${NC} $PUBLIC_IP"

# 2. Start/Check Docker
echo -e "\n${YELLOW}=== Docker Service ===${NC}"
if ! sudo systemctl is-active --quiet docker; then
    echo "Starting Docker..."
    sudo systemctl start docker
    wait_for_service docker
else
    echo -e "${GREEN}✓${NC} Docker is already running"
fi

# 3. Start/Check Wings
echo -e "\n${YELLOW}=== Pterodactyl Wings ===${NC}"
if ! sudo systemctl is-active --quiet wings; then
    echo "Starting Wings..."
    sudo systemctl start wings
    wait_for_service wings
else
    echo -e "${GREEN}✓${NC} Wings is already running"
fi

# Give Wings time to initialize
sleep 5

# 4. Check critical services
echo -e "\n${YELLOW}=== Critical Services ===${NC}"
services=("nginx" "php8.2-fpm" "cloudflared-webconsole")
for service in "${services[@]}"; do
    if sudo systemctl is-active --quiet "$service"; then
        echo -e "${GREEN}✓${NC} $service is running"
    else
        echo -e "${YELLOW}⚠${NC} $service is not running - attempting to start..."
        sudo systemctl start "$service" 2>/dev/null || echo -e "${RED}✗${NC} Failed to start $service"
    fi
done

# 5. Check important ports
echo -e "\n${YELLOW}=== Port Status ===${NC}"
check_port 443 "HTTPS/Nginx"
check_port 8082 "Panel Tunnel"
check_port 8083 "Wings API"
check_port 5050 "Pingvin Share"
check_port 3000 "Open WebUI"

# 6. Check Pterodactyl game servers
echo -e "\n${YELLOW}=== Game Servers ===${NC}"
GAME_PORTS=(25570 25565 25566 25567 25568 25569 25571 25572 25573 25574 25575)
for port in "${GAME_PORTS[@]}"; do
    if sudo netstat -tlnp | grep -q ":$port "; then
        echo -e "${GREEN}✓${NC} Game server on port $port is running"
    fi
done

# 7. Check Cloudflare Tunnel
echo -e "\n${YELLOW}=== Cloudflare Tunnel ===${NC}"
if sudo systemctl is-active --quiet cloudflared-webconsole; then
    echo -e "${GREEN}✓${NC} Cloudflare tunnel is running"
    
    # Check recent tunnel logs for errors
    if sudo journalctl -u cloudflared-webconsole --since "1 minute ago" --no-pager | grep -qi "error"; then
        echo -e "${YELLOW}⚠${NC} Recent tunnel errors detected:"
        sudo journalctl -u cloudflared-webconsole --since "1 minute ago" --no-pager | grep -i "error" | tail -5
    else
        echo -e "${GREEN}✓${NC} No recent tunnel errors"
    fi
else
    echo -e "${RED}✗${NC} Cloudflare tunnel is not running"
fi

# 8. Test external connectivity
echo -e "\n${YELLOW}=== External Connectivity Test ===${NC}"
echo "Testing panel.cloudmc.online..."
if curl -s -I https://panel.cloudmc.online | grep -q "HTTP"; then
    echo -e "${GREEN}✓${NC} Panel is accessible from internet"
else
    echo -e "${RED}✗${NC} Panel is NOT accessible from internet"
fi

# 9. DNS Check
echo -e "\n${YELLOW}=== DNS Resolution ===${NC}"
DOMAINS=("cloudmc.online" "panel.cloudmc.online" "share.cloudmc.online")
for domain in "${DOMAINS[@]}"; do
    if dig +short "$domain" | grep -q "$PUBLIC_IP"; then
        echo -e "${GREEN}✓${NC} $domain resolves to $PUBLIC_IP"
    else
        RESOLVED=$(dig +short "$domain" | head -1)
        echo -e "${YELLOW}⚠${NC} $domain resolves to $RESOLVED (expected $PUBLIC_IP)"
    fi
done

# 10. Check Minecraft SRV records
echo -e "\n${YELLOW}=== Minecraft SRV Records ===${NC}"
if dig +short _minecraft._tcp.block.cloudmc.online SRV | grep -q "25570"; then
    echo -e "${GREEN}✓${NC} SRV record for block.cloudmc.online is configured"
else
    echo -e "${RED}✗${NC} SRV record for block.cloudmc.online is missing or incorrect"
fi

# 11. Summary
echo -e "\n${BLUE}============================================================${NC}"
echo -e "${BLUE}                    Startup Check Complete                  ${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

# Count issues
ISSUES=0
if ! sudo systemctl is-active --quiet docker; then ((ISSUES++)); fi
if ! sudo systemctl is-active --quiet wings; then ((ISSUES++)); fi
if ! sudo systemctl is-active --quiet nginx; then ((ISSUES++)); fi
if ! sudo systemctl is-active --quiet cloudflared-webconsole; then ((ISSUES++)); fi

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ All systems operational!${NC}"
    echo ""
    echo "Services running:"
    echo "  • Panel: https://panel.cloudmc.online"
    echo "  • Share: https://share.cloudmc.online"
    echo "  • WebUI: https://ui.cloudmc.online"
    echo ""
else
    echo -e "${YELLOW}⚠ Found $ISSUES issue(s) - review output above${NC}"
    echo ""
    echo "To fix issues, try:"
    echo "  sudo systemctl restart docker"
    echo "  sudo systemctl restart wings"
    echo "  sudo systemctl restart nginx"
    echo "  sudo systemctl restart cloudflared-webconsole"
fi

echo ""
echo -e "${BLUE}Logs:${NC}"
echo "  • Wings: sudo journalctl -u wings -n 50"
echo "  • Tunnel: sudo journalctl -u cloudflared-webconsole -n 50"
echo "  • Nginx: sudo tail -50 /var/log/nginx/error.log"
