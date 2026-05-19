#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

WIZARD_LOG="/var/log/domain-wizard.log"

log_step() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$WIZARD_LOG"
}

show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   🌐 DOMAIN & CLOUDFLARE SETUP WIZARD                        ║
║                                                               ║
║   This wizard will help you configure:                       ║
║   • Domain names for your services                           ║
║   • Cloudflare DNS records                                   ║
║   • Cloudflare Tunnels (optional)                            ║
║   • SSL certificates                                         ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

ask_for_help() {
    local topic=$1
    
    dialog --clear --backtitle "Domain Setup Wizard" \
        --title "Need Help?" \
        --yesno "Do you need help setting up $topic?" 10 60
    
    return $?
}

show_domain_basics() {
    dialog --clear --backtitle "Domain Setup Wizard" \
        --title "📚 Domain Basics" \
        --msgbox "What is a Domain?\n\n\
A domain is your website's address (e.g., example.com)\n\n\
What is a Subdomain?\n\
A subdomain is a prefix to your domain:\n\
• panel.example.com\n\
• wings.example.com\n\
• admin.example.com\n\n\
You'll need:\n\
1. A registered domain (from Namecheap, GoDaddy, etc.)\n\
2. Access to your domain's DNS settings\n\
3. (Optional) A Cloudflare account for free SSL & protection" 20 70
}

show_cloudflare_setup_guide() {
    dialog --clear --backtitle "Domain Setup Wizard" \
        --title "☁️ Cloudflare Setup Guide" \
        --msgbox "Step-by-Step Cloudflare Setup:\n\n\
1. Go to https://cloudflare.com and create a free account\n\n\
2. Click 'Add a Site' and enter your domain\n\n\
3. Choose the FREE plan\n\n\
4. Cloudflare will scan your DNS records\n\n\
5. Copy the nameservers Cloudflare provides\n\n\
6. Go to your domain registrar (Namecheap, GoDaddy, etc.)\n\n\
7. Update your domain's nameservers to Cloudflare's\n\n\
8. Wait 5-60 minutes for propagation\n\n\
9. Return here when Cloudflare shows 'Active'" 22 75
}

show_dns_record_types() {
    dialog --clear --backtitle "Domain Setup Wizard" \
        --title "📋 DNS Record Types Explained" \
        --msgbox "A Record:\n\
• Points a domain/subdomain to an IP address\n\
• Example: panel.example.com → 1.2.3.4\n\
• Use this when: Connecting directly to your server\n\n\
CNAME Record:\n\
• Points a domain to another domain\n\
• Example: www.example.com → example.com\n\
• Use this when: Creating aliases\n\n\
For Pterodactyl, you'll typically use A records:\n\
• panel.example.com → Your Server IP\n\
• node1.example.com → Your Server IP\n\
• admin.example.com → Your Server IP" 22 75
}

show_cloudflare_tunnel_guide() {
    dialog --clear --backtitle "Domain Setup Wizard" \
        --title "🔒 Cloudflare Tunnel Guide" \
        --msgbox "What is a Cloudflare Tunnel?\n\n\
A secure way to expose your services without opening ports!\n\n\
Benefits:\n\
• No port forwarding needed\n\
• Free SSL certificates\n\
• DDoS protection\n\
• Hide your server IP\n\n\
How it works:\n\
1. Install cloudflared on your server\n\
2. Create a tunnel in Cloudflare dashboard\n\
3. Configure which services to expose\n\
4. Cloudflare handles SSL and routing\n\n\
We'll set this up for you automatically!" 22 75
}

validate_domain() {
    local domain=$1
    
    # Check if domain format is valid
    if [[ ! $domain =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    
    return 0
}

validate_subdomain() {
    local subdomain=$1
    
    # Check if subdomain format is valid
    if [[ ! $subdomain =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]$ ]]; then
        return 1
    fi
    
    return 0
}

check_dns_propagation() {
    local domain=$1
    local expected_ip=$2
    
    echo "Checking DNS propagation for $domain..."
    
    # Try to resolve the domain
    local resolved_ip=$(dig +short $domain @8.8.8.8 | tail -n1)
    
    if [ -z "$resolved_ip" ]; then
        return 1
    fi
    
    if [ "$resolved_ip" == "$expected_ip" ]; then
        return 0
    else
        return 2
    fi
}

get_server_ip() {
    # Try multiple methods to get public IP
    local ip=""
    
    ip=$(curl -s https://api.ipify.org)
    if [ -z "$ip" ]; then
        ip=$(curl -s https://icanhazip.com)
    fi
    if [ -z "$ip" ]; then
        ip=$(curl -s https://ifconfig.me)
    fi
    
    echo "$ip"
}

setup_domain_interactive() {
    local component=$1
    local default_subdomain=$2
    
    # Ask if user needs help
    if ask_for_help "domain configuration"; then
        show_domain_basics
        show_dns_record_types
    fi
    
    # Get server IP
    local server_ip=$(get_server_ip)
    
    dialog --clear --backtitle "Domain Setup Wizard" \
        --title "Server IP Detected" \
        --msgbox "Your server's public IP address is:\n\n${BOLD}$server_ip${NC}\n\nYou'll need this for DNS records." 10 60
    
    # Get base domain
    local base_domain=""
    while true; do
        base_domain=$(dialog --clear --backtitle "Domain Setup Wizard" \
            --title "Enter Your Domain" \
            --inputbox "Enter your base domain (e.g., example.com):\n\nDon't include 'www' or subdomains." 12 60 \
            3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            return 1
        fi
        
        if validate_domain "$base_domain"; then
            break
        else
            dialog --clear --backtitle "Domain Setup Wizard" \
                --title "Invalid Domain" \
                --msgbox "The domain '$base_domain' is not valid.\n\nPlease enter a valid domain like:\n• example.com\n• mydomain.net\n• mysite.org" 12 60
            
            if ask_for_help "domain format"; then
                show_domain_basics
            fi
        fi
    done
    
    # Get subdomain
    local subdomain=""
    while true; do
        subdomain=$(dialog --clear --backtitle "Domain Setup Wizard" \
            --title "Enter Subdomain" \
            --inputbox "Enter subdomain for $component:\n\nSuggested: $default_subdomain\n\nFull domain will be: [subdomain].$base_domain" 14 60 \
            "$default_subdomain" \
            3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            return 1
        fi
        
        if validate_subdomain "$subdomain"; then
            break
        else
            dialog --clear --backtitle "Domain Setup Wizard" \
                --title "Invalid Subdomain" \
                --msgbox "The subdomain '$subdomain' is not valid.\n\nValid examples:\n• panel\n• admin\n• node1\n• ssh" 12 60
        fi
    done
    
    local full_domain="${subdomain}.${base_domain}"
    
    # Show DNS setup instructions
    dialog --clear --backtitle "Domain Setup Wizard" \
        --title "📝 DNS Setup Instructions" \
        --msgbox "Please create this DNS record:\n\n\
Type: A\n\
Name: $subdomain\n\
Content: $server_ip\n\
TTL: Auto (or 300)\n\
Proxy: Enabled (Orange cloud in Cloudflare)\n\n\
Full domain: $full_domain\n\n\
If using Cloudflare:\n\
1. Go to cloudflare.com\n\
2. Select your domain\n\
3. Click 'DNS' in the menu\n\
4. Click 'Add record'\n\
5. Enter the details above\n\
6. Click 'Save'" 22 70
    
    # Ask if they need help with Cloudflare
    if ask_for_help "Cloudflare setup"; then
        show_cloudflare_setup_guide
    fi
    
    # Wait for user to confirm DNS is set up
    dialog --clear --backtitle "Domain Setup Wizard" \
        --title "Waiting for DNS Setup" \
        --yesno "Have you created the DNS record?\n\nClick Yes when ready to verify." 10 60
    
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Verify DNS propagation
    local max_attempts=5
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        dialog --clear --backtitle "Domain Setup Wizard" \
            --title "Checking DNS..." \
            --infobox "Verifying DNS propagation for $full_domain\n\nAttempt $attempt of $max_attempts\n\nThis may take a few minutes..." 10 60
        
        sleep 3
        
        check_dns_propagation "$full_domain" "$server_ip"
        local result=$?
        
        if [ $result -eq 0 ]; then
            dialog --clear --backtitle "Domain Setup Wizard" \
                --title "✅ DNS Verified!" \
                --msgbox "DNS is properly configured!\n\n$full_domain → $server_ip\n\nProceeding with installation..." 10 60
            
            echo "$full_domain"
            return 0
        elif [ $result -eq 2 ]; then
            local resolved_ip=$(dig +short $full_domain @8.8.8.8 | tail -n1)
            dialog --clear --backtitle "Domain Setup Wizard" \
                --title "⚠️ DNS Mismatch" \
                --msgbox "DNS record found but IP doesn't match!\n\nExpected: $server_ip\nFound: $resolved_ip\n\nPlease check your DNS settings." 12 60
            
            if ask_for_help "fixing DNS records"; then
                show_dns_record_types
            fi
        else
            dialog --clear --backtitle "Domain Setup Wizard" \
                --title "⏳ DNS Not Ready" \
                --yesno "DNS record not found yet.\n\nDNS propagation can take 5-60 minutes.\n\nRetry? (Attempt $attempt of $max_attempts)" 12 60
            
            if [ $? -ne 0 ]; then
                break
            fi
        fi
        
        ((attempt++))
    done
    
    # DNS verification failed
    dialog --clear --backtitle "Domain Setup Wizard" \
        --title "DNS Verification Failed" \
        --yesno "Unable to verify DNS configuration.\n\nOptions:\n\n1. Continue anyway (not recommended)\n2. Skip this component\n3. Try again later\n\nContinue anyway?" 14 60
    
    if [ $? -eq 0 ]; then
        echo "$full_domain"
        return 0
    else
        return 1
    fi
}

setup_cloudflare_tunnel() {
    local service_name=$1
    local local_port=$2
    local subdomain=$3
    local base_domain=$4
    
    # Ask if user wants to use Cloudflare Tunnel
    dialog --clear --backtitle "Domain Setup Wizard" \
        --title "Cloudflare Tunnel Option" \
        --yesno "Would you like to use Cloudflare Tunnel for $service_name?\n\nBenefits:\n• No port forwarding needed\n• Free SSL\n• DDoS protection\n• Hide server IP\n\nRequires: Cloudflare account" 16 60
    
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Show tunnel setup guide
    if ask_for_help "Cloudflare Tunnel setup"; then
        show_cloudflare_tunnel_guide
    fi
    
    # Install cloudflared if not installed
    if ! command -v cloudflared &> /dev/null; then
        dialog --clear --backtitle "Domain Setup Wizard" \
            --title "Installing Cloudflared" \
            --infobox "Installing Cloudflare Tunnel client..." 8 50
        
        wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
        dpkg -i cloudflared-linux-amd64.deb
        rm cloudflared-linux-amd64.deb
    fi
    
    # Get Cloudflare credentials
    dialog --clear --backtitle "Domain Setup Wizard" \
        --title "Cloudflare Tunnel Setup" \
        --msgbox "Next steps:\n\n\
1. Go to https://dash.cloudflare.com\n\
2. Select your domain\n\
3. Go to 'Zero Trust' → 'Access' → 'Tunnels'\n\
4. Click 'Create a tunnel'\n\
5. Name it: $service_name\n\
6. Copy the tunnel token\n\
7. Paste it in the next screen" 18 70
    
    local tunnel_token=""
    tunnel_token=$(dialog --clear --backtitle "Domain Setup Wizard" \
        --title "Enter Tunnel Token" \
        --inputbox "Paste your Cloudflare Tunnel token:" 10 70 \
        3>&1 1>&2 2>&3)
    
    if [ $? -ne 0 ] || [ -z "$tunnel_token" ]; then
        return 1
    fi
    
    # Configure tunnel
    cloudflared service install "$tunnel_token"
    
    dialog --clear --backtitle "Domain Setup Wizard" \
        --title "✅ Tunnel Configured!" \
        --msgbox "Cloudflare Tunnel is now active!\n\nYour service will be accessible at:\nhttps://${subdomain}.${base_domain}\n\nNo port forwarding needed!" 12 60
    
    return 0
}

setup_all_domains() {
    show_banner
    
    # Ask if user needs general help
    if ask_for_help "domain and DNS setup"; then
        show_domain_basics
        show_dns_record_types
        show_cloudflare_setup_guide
    fi
    
    # Detect which components are being installed
    local components=("$@")
    local domains=()
    
    for component in "${components[@]}"; do
        case $component in
            "panel")
                domain=$(setup_domain_interactive "Pterodactyl Panel" "panel")
                if [ $? -eq 0 ]; then
                    domains+=("PANEL_DOMAIN=$domain")
                    echo "PANEL_DOMAIN=$domain" >> /etc/automatic-system/domains.conf
                fi
                ;;
            "wings")
                domain=$(setup_domain_interactive "Pterodactyl Wings" "node1")
                if [ $? -eq 0 ]; then
                    domains+=("WINGS_DOMAIN=$domain")
                    echo "WINGS_DOMAIN=$domain" >> /etc/automatic-system/domains.conf
                fi
                ;;
            "admin-panel")
                domain=$(setup_domain_interactive "Admin Panel" "admin")
                if [ $? -eq 0 ]; then
                    domains+=("ADMIN_DOMAIN=$domain")
                    echo "ADMIN_DOMAIN=$domain" >> /etc/automatic-system/domains.conf
                    
                    # Offer Cloudflare Tunnel
                    setup_cloudflare_tunnel "admin-panel" "5002" "admin" "${domain#*.}"
                fi
                ;;
            "ssh-terminal")
                domain=$(setup_domain_interactive "SSH Terminal" "ssh")
                if [ $? -eq 0 ]; then
                    domains+=("SSH_DOMAIN=$domain")
                    echo "SSH_DOMAIN=$domain" >> /etc/automatic-system/domains.conf
                    
                    # Offer Cloudflare Tunnel
                    setup_cloudflare_tunnel "ssh-terminal" "8095" "ssh" "${domain#*.}"
                fi
                ;;
            "openwebui")
                domain=$(setup_domain_interactive "Open WebUI" "ai")
                if [ $? -eq 0 ]; then
                    domains+=("AI_DOMAIN=$domain")
                    echo "AI_DOMAIN=$domain" >> /etc/automatic-system/domains.conf
                fi
                ;;
            "filebrowser")
                domain=$(setup_domain_interactive "FileBrowser" "files")
                if [ $? -eq 0 ]; then
                    domains+=("FILES_DOMAIN=$domain")
                    echo "FILES_DOMAIN=$domain" >> /etc/automatic-system/domains.conf
                fi
                ;;
        esac
    done
    
    # Show summary
    if [ ${#domains[@]} -gt 0 ]; then
        local summary="Configured Domains:\n\n"
        for domain_entry in "${domains[@]}"; do
            summary+="✓ $domain_entry\n"
        done
        summary+="\nDomains saved to: /etc/automatic-system/domains.conf"
        
        dialog --clear --backtitle "Domain Setup Wizard" \
            --title "✅ Domain Setup Complete!" \
            --msgbox "$summary" 18 70
    fi
}

# Main execution
if [ "$1" == "--help" ]; then
    show_domain_basics
    show_dns_record_types
    show_cloudflare_setup_guide
    show_cloudflare_tunnel_guide
elif [ "$1" == "--component" ]; then
    setup_domain_interactive "$2" "$3"
else
    setup_all_domains "$@"
fi
