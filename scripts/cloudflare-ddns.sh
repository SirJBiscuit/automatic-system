#!/bin/bash

# Cloudflare Dynamic DNS Updater
# Automatically updates DNS records when public IP changes

# CONFIGURATION - EDIT THESE VALUES
CLOUDFLARE_API_TOKEN="YOUR_CLOUDFLARE_API_TOKEN_HERE"
ZONE_ID="YOUR_ZONE_ID_HERE"
DOMAINS_TO_UPDATE=(
    "cloudmc.online"
    "mc.cloudmc.online"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# File to store last known IP
IP_FILE="/var/lib/cloudflare-ddns/last_ip.txt"

# Create directory if it doesn't exist
sudo mkdir -p /var/lib/cloudflare-ddns

# Get current public IP
echo -e "${BLUE}Checking current public IP...${NC}"
CURRENT_IP=$(curl -s -4 ifconfig.me)

if [ -z "$CURRENT_IP" ]; then
    echo -e "${RED}✗ Failed to get public IP${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Current public IP: $CURRENT_IP"

# Check if IP has changed
if [ -f "$IP_FILE" ]; then
    LAST_IP=$(cat "$IP_FILE")
    echo -e "${BLUE}Last known IP: $LAST_IP${NC}"
    
    if [ "$CURRENT_IP" == "$LAST_IP" ]; then
        echo -e "${GREEN}✓${NC} IP has not changed. No update needed."
        exit 0
    else
        echo -e "${YELLOW}⚠${NC} IP has changed from $LAST_IP to $CURRENT_IP"
    fi
else
    echo -e "${YELLOW}⚠${NC} First run - no previous IP found"
fi

# Function to update DNS record
update_dns_record() {
    local domain=$1
    
    echo -e "\n${BLUE}Updating DNS for $domain...${NC}"
    
    # Get record ID
    RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$domain&type=A" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" | jq -r '.result[0].id')
    
    if [ "$RECORD_ID" == "null" ] || [ -z "$RECORD_ID" ]; then
        echo -e "${RED}✗${NC} Record not found for $domain"
        return 1
    fi
    
    # Update the record
    RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"A\",\"name\":\"$domain\",\"content\":\"$CURRENT_IP\",\"ttl\":120,\"proxied\":false}")
    
    SUCCESS=$(echo $RESPONSE | jq -r '.success')
    
    if [ "$SUCCESS" == "true" ]; then
        echo -e "${GREEN}✓${NC} Successfully updated $domain to $CURRENT_IP"
        return 0
    else
        ERROR=$(echo $RESPONSE | jq -r '.errors[0].message')
        echo -e "${RED}✗${NC} Failed to update $domain: $ERROR"
        return 1
    fi
}

# Check if configuration is set
if [ "$CLOUDFLARE_API_TOKEN" == "YOUR_CLOUDFLARE_API_TOKEN_HERE" ]; then
    echo -e "${RED}✗${NC} Cloudflare API token not configured!"
    echo ""
    echo "Please edit this script and set:"
    echo "  1. CLOUDFLARE_API_TOKEN - Get from Cloudflare dashboard"
    echo "  2. ZONE_ID - Your cloudmc.online zone ID"
    echo "  3. DOMAINS_TO_UPDATE - List of domains to update"
    echo ""
    echo "To get API token:"
    echo "  1. Go to https://dash.cloudflare.com/profile/api-tokens"
    echo "  2. Create Token → Edit zone DNS"
    echo "  3. Select your zone (cloudmc.online)"
    echo ""
    echo "To get Zone ID:"
    echo "  1. Go to https://dash.cloudflare.com"
    echo "  2. Select cloudmc.online domain"
    echo "  3. Scroll down on Overview page - Zone ID is on the right"
    exit 1
fi

# Update all configured domains
UPDATED=0
FAILED=0

for domain in "${DOMAINS_TO_UPDATE[@]}"; do
    if update_dns_record "$domain"; then
        ((UPDATED++))
    else
        ((FAILED++))
    fi
done

# Save current IP if at least one update succeeded
if [ $UPDATED -gt 0 ]; then
    echo "$CURRENT_IP" | sudo tee "$IP_FILE" > /dev/null
    echo ""
    echo -e "${GREEN}============================================================${NC}"
    echo -e "${GREEN}✓ DNS Update Complete!${NC}"
    echo -e "${GREEN}============================================================${NC}"
    echo -e "Updated: $UPDATED domain(s)"
    echo -e "Failed: $FAILED domain(s)"
    echo -e "New IP: $CURRENT_IP"
    
    # Log to syslog
    logger "Cloudflare DDNS: Updated $UPDATED domains to $CURRENT_IP"
else
    echo -e "${RED}✗ All updates failed!${NC}"
    exit 1
fi
