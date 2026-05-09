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

WIZARD_LOG="/var/log/network-wizard.log"

show_network_intro() {
    dialog --clear --backtitle "Network Setup Wizard" \
        --title "🌐 Network Configuration" \
        --msgbox "This wizard will help you configure networking for Pterodactyl.\n\n\
We'll help you with:\n\
• Detecting your network setup\n\
• Public IP vs Private IP\n\
• Port forwarding (if needed)\n\
• Router configuration\n\
• DHCP reservation\n\
• Cloudflare Tunnels (no port forwarding!)\n\n\
This works on:\n\
✓ Dedicated servers\n\
✓ VPS/Cloud servers\n\
✓ Home servers\n\
✓ Mini PCs\n\
✓ Raspberry Pi\n\n\
Let's get started!" 22 70
}

detect_network_type() {
    local public_ip=$(curl -s https://api.ipify.org)
    local local_ip=$(hostname -I | awk '{print $1}')
    local gateway=$(ip route | grep default | awk '{print $3}')
    
    echo "PUBLIC_IP=$public_ip" > /tmp/network-info
    echo "LOCAL_IP=$local_ip" >> /tmp/network-info
    echo "GATEWAY=$gateway" >> /tmp/network-info
    
    # Detect if behind NAT
    if [[ $local_ip == 10.* ]] || [[ $local_ip == 192.168.* ]] || [[ $local_ip == 172.16.* ]]; then
        echo "NETWORK_TYPE=NAT" >> /tmp/network-info
        echo "NAT"
    else
        echo "NETWORK_TYPE=PUBLIC" >> /tmp/network-info
        echo "PUBLIC"
    fi
}

show_network_detection() {
    source /tmp/network-info
    
    local network_desc=""
    if [ "$NETWORK_TYPE" == "NAT" ]; then
        network_desc="Home Network / Behind Router"
    else
        network_desc="Public Server / VPS"
    fi
    
    dialog --clear --backtitle "Network Setup Wizard" \
        --title "Network Detection Results" \
        --msgbox "Network Configuration Detected:\n\n\
Type: $network_desc\n\
Public IP: $PUBLIC_IP\n\
Local IP: $LOCAL_IP\n\
Gateway: $GATEWAY\n\n\
$(if [ "$NETWORK_TYPE" == "NAT" ]; then
    echo "You are behind a router/NAT.\nYou'll need to configure port forwarding OR use Cloudflare Tunnels."
else
    echo "You have a public IP address.\nNo port forwarding needed!"
fi)" 18 70
}

show_port_forwarding_guide() {
    dialog --clear --backtitle "Network Setup Wizard" \
        --title "📡 Port Forwarding Guide" \
        --msgbox "What is Port Forwarding?\n\n\
Port forwarding tells your router to send incoming traffic\nto your server.\n\n\
Required Ports for Pterodactyl:\n\
• 80 (HTTP) - Web traffic\n\
• 443 (HTTPS) - Secure web traffic\n\
• 8080 (Wings API) - Server management\n\
• 2022 (SFTP) - File transfers\n\n\
You'll need to:\n\
1. Log in to your router\n\
2. Find 'Port Forwarding' settings\n\
3. Add rules for each port\n\
4. Point them to your server's local IP\n\n\
We'll guide you through this step by step!" 22 70
}

detect_router_brand() {
    local gateway=$(cat /tmp/network-info | grep GATEWAY | cut -d= -f2)
    
    # Try to detect router brand from gateway
    local router_page=$(curl -s --connect-timeout 3 http://$gateway 2>/dev/null || echo "")
    
    if echo "$router_page" | grep -qi "netgear"; then
        echo "netgear"
    elif echo "$router_page" | grep -qi "linksys"; then
        echo "linksys"
    elif echo "$router_page" | grep -qi "tp-link\|tplink"; then
        echo "tplink"
    elif echo "$router_page" | grep -qi "asus"; then
        echo "asus"
    elif echo "$router_page" | grep -qi "d-link\|dlink"; then
        echo "dlink"
    else
        echo "unknown"
    fi
}

show_router_specific_guide() {
    local router_brand=$1
    local gateway=$(cat /tmp/network-info | grep GATEWAY | cut -d= -f2)
    local local_ip=$(cat /tmp/network-info | grep LOCAL_IP | cut -d= -f2)
    
    case $router_brand in
        "netgear")
            dialog --clear --backtitle "Network Setup Wizard" \
                --title "Netgear Router Setup" \
                --msgbox "Netgear Port Forwarding Setup:\n\n\
1. Open browser and go to: http://$gateway\n\
2. Login (default: admin/password)\n\
3. Click 'Advanced' → 'Advanced Setup'\n\
4. Click 'Port Forwarding / Port Triggering'\n\
5. Click 'Add Custom Service'\n\
6. For each port, enter:\n\
   Service Name: Pterodactyl-[port]\n\
   External Port: [port number]\n\
   Internal Port: [port number]\n\
   Internal IP: $local_ip\n\
   Protocol: TCP\n\
7. Click 'Apply'\n\n\
Repeat for ports: 80, 443, 8080, 2022" 22 70
            ;;
        "tplink")
            dialog --clear --backtitle "Network Setup Wizard" \
                --title "TP-Link Router Setup" \
                --msgbox "TP-Link Port Forwarding Setup:\n\n\
1. Open browser and go to: http://$gateway\n\
2. Login (default: admin/admin)\n\
3. Click 'Forwarding' → 'Virtual Servers'\n\
4. Click 'Add New'\n\
5. For each port, enter:\n\
   Service Port: [port number]\n\
   IP Address: $local_ip\n\
   Protocol: TCP\n\
   Status: Enabled\n\
6. Click 'Save'\n\n\
Repeat for ports: 80, 443, 8080, 2022" 20 70
            ;;
        "asus")
            dialog --clear --backtitle "Network Setup Wizard" \
                --title "ASUS Router Setup" \
                --msgbox "ASUS Router Port Forwarding Setup:\n\n\
1. Open browser and go to: http://$gateway\n\
2. Login (default: admin/admin)\n\
3. Click 'WAN' → 'Virtual Server / Port Forwarding'\n\
4. Enable 'Port Forwarding'\n\
5. For each port, enter:\n\
   Service Name: Pterodactyl-[port]\n\
   Port Range: [port number]\n\
   Local IP: $local_ip\n\
   Protocol: TCP\n\
6. Click 'Add' then 'Apply'\n\n\
Repeat for ports: 80, 443, 8080, 2022" 22 70
            ;;
        "linksys")
            dialog --clear --backtitle "Network Setup Wizard" \
                --title "Linksys Router Setup" \
                --msgbox "Linksys Port Forwarding Setup:\n\n\
1. Open browser and go to: http://$gateway\n\
2. Login (default: admin/admin)\n\
3. Click 'Security' → 'Apps and Gaming'\n\
4. Click 'Single Port Forwarding'\n\
5. For each port, enter:\n\
   Application Name: Pterodactyl-[port]\n\
   External Port: [port number]\n\
   Internal Port: [port number]\n\
   Device IP: $local_ip\n\
   Protocol: TCP\n\
   Enabled: Check\n\
6. Click 'Save Settings'\n\n\
Repeat for ports: 80, 443, 8080, 2022" 22 70
            ;;
        *)
            dialog --clear --backtitle "Network Setup Wizard" \
                --title "Generic Router Setup" \
                --msgbox "Generic Port Forwarding Setup:\n\n\
1. Open browser and go to: http://$gateway\n\
2. Login with your router credentials\n\
3. Look for one of these menu items:\n\
   • Port Forwarding\n\
   • Virtual Server\n\
   • NAT Forwarding\n\
   • Advanced → Port Forwarding\n\
4. Create a new rule for each port:\n\
   External Port: [port number]\n\
   Internal Port: [port number]\n\
   Internal IP: $local_ip\n\
   Protocol: TCP\n\
5. Save/Apply changes\n\n\
Ports needed: 80, 443, 8080, 2022\n\n\
Can't find it? Search '[your router model] port forwarding'" 24 70
            ;;
    esac
}

try_upnp_port_forwarding() {
    dialog --clear --backtitle "Network Setup Wizard" \
        --title "Trying UPnP..." \
        --infobox "Attempting automatic port forwarding via UPnP...\n\nThis may take a moment..." 8 60
    
    # Install miniupnpc if not present
    if ! command -v upnpc &> /dev/null; then
        apt-get update -qq
        apt-get install -y miniupnpc
    fi
    
    local local_ip=$(cat /tmp/network-info | grep LOCAL_IP | cut -d= -f2)
    local success=0
    
    # Try to forward each port
    for port in 80 443 8080 2022; do
        if upnpc -a $local_ip $port $port TCP 2>&1 | grep -q "is redirected"; then
            echo "Port $port forwarded successfully" >> "$WIZARD_LOG"
            ((success++))
        fi
    done
    
    if [ $success -gt 0 ]; then
        dialog --clear --backtitle "Network Setup Wizard" \
            --title "✅ UPnP Success!" \
            --msgbox "Automatically forwarded $success port(s) via UPnP!\n\nPorts configured:\n$(upnpc -l | grep TCP)" 12 60
        return 0
    else
        dialog --clear --backtitle "Network Setup Wizard" \
            --title "❌ UPnP Failed" \
            --msgbox "Automatic port forwarding failed.\n\nPossible reasons:\n• UPnP is disabled on your router\n• Router doesn't support UPnP\n• Firewall blocking UPnP\n\nYou'll need to configure port forwarding manually." 14 60
        return 1
    fi
}

setup_dhcp_reservation() {
    local local_ip=$(cat /tmp/network-info | grep LOCAL_IP | cut -d= -f2)
    local mac_address=$(ip link show | grep -A1 "state UP" | grep "link/ether" | awk '{print $2}' | head -1)
    
    dialog --clear --backtitle "Network Setup Wizard" \
        --title "📌 DHCP Reservation" \
        --msgbox "What is DHCP Reservation?\n\n\
DHCP Reservation ensures your server always gets the same\nlocal IP address, even after reboots.\n\n\
Your current info:\n\
Local IP: $local_ip\n\
MAC Address: $mac_address\n\n\
To set up DHCP reservation:\n\
1. Log in to your router\n\
2. Find 'DHCP Settings' or 'LAN Settings'\n\
3. Look for 'Address Reservation' or 'Static DHCP'\n\
4. Add a new reservation:\n\
   MAC Address: $mac_address\n\
   IP Address: $local_ip\n\
   Name: Pterodactyl-Server\n\
5. Save and reboot router\n\n\
This prevents your port forwarding from breaking!" 24 70
}

offer_cloudflare_tunnel() {
    dialog --clear --backtitle "Network Setup Wizard" \
        --title "🔒 Cloudflare Tunnel Alternative" \
        --yesno "Skip Port Forwarding with Cloudflare Tunnels!\n\n\
Cloudflare Tunnels let you expose services WITHOUT\nport forwarding or public IP!\n\n\
Benefits:\n\
✓ No router configuration needed\n\
✓ Works behind any firewall/NAT\n\
✓ Free SSL certificates\n\
✓ DDoS protection\n\
✓ Hide your home IP address\n\n\
Perfect for:\n\
• Home servers\n\
• Dynamic IP addresses\n\
• Strict firewalls\n\
• No router access\n\n\
Would you like to use Cloudflare Tunnels instead?" 22 70
    
    return $?
}

setup_cloudflare_tunnel_full() {
    # Install cloudflared
    dialog --clear --backtitle "Network Setup Wizard" \
        --title "Installing Cloudflare Tunnel" \
        --infobox "Installing cloudflared client..." 8 50
    
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    dpkg -i cloudflared-linux-amd64.deb
    rm cloudflared-linux-amd64.deb
    
    # Show setup instructions
    dialog --clear --backtitle "Network Setup Wizard" \
        --title "Cloudflare Tunnel Setup" \
        --msgbox "Cloudflare Tunnel Setup Steps:\n\n\
1. Go to https://dash.cloudflare.com\n\
2. Select your domain\n\
3. Go to 'Zero Trust' → 'Access' → 'Tunnels'\n\
4. Click 'Create a tunnel'\n\
5. Name it: pterodactyl-tunnel\n\
6. Choose 'Cloudflared' connector\n\
7. Copy the install command\n\
8. We'll run it in the next step\n\n\
Press OK when you have the tunnel token ready..." 18 70
    
    # Get tunnel token
    local tunnel_token=""
    tunnel_token=$(dialog --clear --backtitle "Network Setup Wizard" \
        --title "Enter Tunnel Token" \
        --inputbox "Paste your Cloudflare Tunnel token:\n\n(It starts with 'eyJ...')" 12 70 \
        3>&1 1>&2 2>&3)
    
    if [ -z "$tunnel_token" ]; then
        return 1
    fi
    
    # Install tunnel
    cloudflared service install "$tunnel_token"
    
    dialog --clear --backtitle "Network Setup Wizard" \
        --title "✅ Tunnel Installed!" \
        --msgbox "Cloudflare Tunnel is now running!\n\n\
Next steps in Cloudflare dashboard:\n\
1. Go to 'Public Hostname' tab\n\
2. Add hostname for Panel:\n\
   Subdomain: panel\n\
   Domain: yourdomain.com\n\
   Service: HTTP\n\
   URL: localhost:80\n\
3. Add hostname for Wings:\n\
   Subdomain: node1\n\
   Domain: yourdomain.com\n\
   Service: HTTP\n\
   URL: localhost:8080\n\n\
No port forwarding needed!" 22 70
    
    return 0
}

test_port_accessibility() {
    local public_ip=$(cat /tmp/network-info | grep PUBLIC_IP | cut -d= -f2)
    
    dialog --clear --backtitle "Network Setup Wizard" \
        --title "Testing Port Accessibility" \
        --infobox "Testing if ports are accessible from internet...\n\nThis may take a moment..." 8 60
    
    local accessible_ports=0
    local test_results=""
    
    for port in 80 443 8080 2022; do
        # Use external port checker
        if timeout 5 bash -c "echo > /dev/tcp/$public_ip/$port" 2>/dev/null; then
            test_results+="✓ Port $port: Accessible\n"
            ((accessible_ports++))
        else
            test_results+="✗ Port $port: Not accessible\n"
        fi
    done
    
    if [ $accessible_ports -eq 4 ]; then
        dialog --clear --backtitle "Network Setup Wizard" \
            --title "✅ All Ports Accessible!" \
            --msgbox "Port Test Results:\n\n$test_results\n\nAll ports are properly forwarded!\nYou're ready to install Pterodactyl." 14 60
        return 0
    else
        dialog --clear --backtitle "Network Setup Wizard" \
            --title "⚠️ Some Ports Not Accessible" \
            --msgbox "Port Test Results:\n\n$test_results\n\nSome ports are not accessible from the internet.\n\nPossible issues:\n• Port forwarding not configured\n• Firewall blocking ports\n• ISP blocking ports\n\nWould you like help troubleshooting?" 18 60
        return 1
    fi
}

show_firewall_setup() {
    dialog --clear --backtitle "Network Setup Wizard" \
        --title "🛡️ Firewall Configuration" \
        --yesno "Configure firewall to allow Pterodactyl ports?\n\nThis will:\n• Allow ports 80, 443, 8080, 2022\n• Enable UFW firewall\n• Block all other incoming traffic\n\nRecommended for security!\n\nConfigure firewall now?" 16 60
    
    if [ $? -eq 0 ]; then
        # Install and configure UFW
        apt-get install -y ufw
        
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow 22/tcp comment 'SSH'
        ufw allow 80/tcp comment 'HTTP'
        ufw allow 443/tcp comment 'HTTPS'
        ufw allow 8080/tcp comment 'Wings API'
        ufw allow 2022/tcp comment 'Wings SFTP'
        ufw --force enable
        
        dialog --clear --backtitle "Network Setup Wizard" \
            --title "✅ Firewall Configured!" \
            --msgbox "Firewall has been configured!\n\nAllowed ports:\n• 22 (SSH)\n• 80 (HTTP)\n• 443 (HTTPS)\n• 8080 (Wings API)\n• 2022 (Wings SFTP)\n\nAll other ports are blocked for security." 16 60
    fi
}

show_isp_port_blocking_info() {
    dialog --clear --backtitle "Network Setup Wizard" \
        --title "⚠️ ISP Port Blocking" \
        --msgbox "Some ISPs block common ports for residential connections.\n\n\
Commonly blocked ports:\n\
• Port 80 (HTTP)\n\
• Port 443 (HTTPS)\n\
• Port 25 (SMTP)\n\n\
If your ports aren't accessible:\n\
1. Contact your ISP to unblock ports\n\
2. Use alternative ports (8080, 8443)\n\
3. Use Cloudflare Tunnels (bypasses ISP blocking)\n\
4. Get a business internet plan\n\n\
Cloudflare Tunnels is the easiest solution!" 18 70
}

create_network_summary() {
    source /tmp/network-info
    
    local summary="/etc/automatic-system/network-summary.txt"
    
    cat > "$summary" << EOF
Pterodactyl Network Configuration Summary
Generated: $(date)

Network Type: $NETWORK_TYPE
Public IP: $PUBLIC_IP
Local IP: $LOCAL_IP
Gateway: $GATEWAY

Required Ports:
- 80 (HTTP)
- 443 (HTTPS)
- 8080 (Wings API)
- 2022 (Wings SFTP)

Configuration Steps Completed:
$(if [ -f /tmp/upnp-success ]; then echo "✓ UPnP port forwarding"; fi)
$(if [ -f /tmp/manual-portforward ]; then echo "✓ Manual port forwarding guide shown"; fi)
$(if [ -f /tmp/cloudflare-tunnel ]; then echo "✓ Cloudflare Tunnel configured"; fi)
$(if [ -f /tmp/firewall-configured ]; then echo "✓ Firewall configured"; fi)

Next Steps:
1. Verify ports are accessible
2. Continue with Pterodactyl installation
3. Configure domain DNS records

For help: cat $summary
EOF
    
    dialog --clear --backtitle "Network Setup Wizard" \
        --title "📋 Network Summary" \
        --textbox "$summary" 24 75
}

main() {
    show_network_intro
    
    # Detect network type
    local network_type=$(detect_network_type)
    show_network_detection
    
    if [ "$network_type" == "PUBLIC" ]; then
        # Public IP - just configure firewall
        show_firewall_setup
        dialog --clear --backtitle "Network Setup Wizard" \
            --title "✅ Network Ready!" \
            --msgbox "You have a public IP address!\n\nNo port forwarding needed.\nFirewall has been configured.\n\nYou're ready to install Pterodactyl!" 12 60
    else
        # Behind NAT - need port forwarding or tunnel
        show_port_forwarding_guide
        
        # Offer Cloudflare Tunnel first
        if offer_cloudflare_tunnel; then
            if setup_cloudflare_tunnel_full; then
                touch /tmp/cloudflare-tunnel
                create_network_summary
                return 0
            fi
        fi
        
        # Try UPnP first
        if dialog --yesno "Try automatic port forwarding via UPnP?" 8 60; then
            if try_upnp_port_forwarding; then
                touch /tmp/upnp-success
                show_firewall_setup
                test_port_accessibility
                create_network_summary
                return 0
            fi
        fi
        
        # Manual port forwarding
        touch /tmp/manual-portforward
        
        # Detect router and show specific guide
        local router_brand=$(detect_router_brand)
        show_router_specific_guide "$router_brand"
        
        # Offer DHCP reservation
        if dialog --yesno "Would you like help setting up DHCP reservation?" 10 60; then
            setup_dhcp_reservation
        fi
        
        # Show ISP blocking info
        if dialog --yesno "Learn about ISP port blocking?" 8 60; then
            show_isp_port_blocking_info
        fi
        
        # Configure firewall
        show_firewall_setup
        
        # Test ports
        dialog --clear --backtitle "Network Setup Wizard" \
            --title "Port Testing" \
            --yesno "Would you like to test if your ports are accessible?\n\n(This requires port forwarding to be set up first)" 10 60
        
        if [ $? -eq 0 ]; then
            test_port_accessibility
        fi
        
        # Create summary
        create_network_summary
    fi
}

main "$@"
