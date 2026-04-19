#!/bin/bash

# Web Console Access Setup Script
# Allows users to choose between local access or Cloudflare Tunnel

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}✗ This script must be run as root${NC}" 
   exit 1
fi

clear

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          Web Console Access Configuration                  ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Choose how you want to access your web console:${NC}"
echo ""
echo -e "${GREEN}1)${NC} ${CYAN}Local Network Access${NC} (Default)"
echo -e "   • Access via: ${GREEN}http://YOUR_SERVER_IP:8080${NC}"
echo -e "   • Best for: Home networks, VPNs, local management"
echo -e "   • Requirements: None (already configured)"
echo -e "   • Security: Local network only"
echo ""
echo -e "${GREEN}2)${NC} ${PURPLE}Cloudflare Tunnel${NC} (Recommended for remote access)"
echo -e "   • Access via: ${GREEN}https://web.cloudmc.online${NC} (your custom domain)"
echo -e "   • Best for: Access from anywhere, multiple admins"
echo -e "   • Requirements: Domain name, Cloudflare account (free)"
echo -e "   • Security: HTTPS, DDoS protection, no port forwarding"
echo ""
echo -e "${GREEN}3)${NC} ${BLUE}Both${NC} (Local + Cloudflare)"
echo -e "   • Access via both methods"
echo -e "   • Maximum flexibility"
echo ""

read -p "Enter your choice (1/2/3): " -n 1 -r
echo
echo ""

case $REPLY in
    1)
        echo -e "${GREEN}✓ Using Local Network Access${NC}"
        echo ""
        SERVER_IP=$(hostname -I | awk '{print $1}')
        echo -e "${CYAN}Your web console is accessible at:${NC}"
        echo -e "  ${GREEN}http://$SERVER_IP:8080${NC}"
        echo ""
        echo -e "${YELLOW}Note:${NC} This is only accessible from your local network."
        echo -e "${YELLOW}To access remotely, use a VPN or set up Cloudflare Tunnel.${NC}"
        echo ""
        ;;
    2)
        echo -e "${PURPLE}Setting up Cloudflare Tunnel...${NC}"
        echo ""
        bash "$(dirname "$0")/cloudflare-tunnel.sh"
        ;;
    3)
        echo -e "${BLUE}Setting up both access methods...${NC}"
        echo ""
        SERVER_IP=$(hostname -I | awk '{print $1}')
        echo -e "${GREEN}✓ Local access already configured${NC}"
        echo -e "  ${CYAN}http://$SERVER_IP:8080${NC}"
        echo ""
        echo -e "${PURPLE}Now setting up Cloudflare Tunnel...${NC}"
        echo ""
        bash "$(dirname "$0")/cloudflare-tunnel.sh"
        ;;
    *)
        echo -e "${RED}Invalid choice. Using default (Local Network Access)${NC}"
        SERVER_IP=$(hostname -I | awk '{print $1}')
        echo ""
        echo -e "${CYAN}Your web console is accessible at:${NC}"
        echo -e "  ${GREEN}http://$SERVER_IP:8080${NC}"
        ;;
esac

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  You can change this anytime by running this script again ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
