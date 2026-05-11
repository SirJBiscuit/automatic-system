#!/bin/bash

# Custom Ports Configuration Guide
# Interactive step-by-step guide for users who changed standard ports

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

HTTP_PORT=${1:-8080}
HTTPS_PORT=${2:-8443}
DOMAIN=${3:-"your-domain.com"}

# Show introduction
show_intro() {
    whiptail --title "Custom Ports Configuration Guide" --msgbox "
🔧 Custom Ports Detected!

You've configured non-standard ports:
• HTTP Port: $HTTP_PORT (instead of 80)
• HTTPS Port: $HTTPS_PORT (instead of 443)

This guide will walk you through the required steps to make
your panel accessible with these custom ports.

We'll cover:
1. Reverse Proxy Configuration
2. DNS/Cloudflare Settings
3. Firewall Rules
4. Access URLs

Press OK to begin..." 20 70
}

# Step 1: Reverse Proxy Configuration
configure_reverse_proxy() {
    local choice=$(whiptail --title "Step 1: Reverse Proxy" --menu "
Do you have a reverse proxy (Nginx, Caddy, Apache)?

A reverse proxy allows users to access your panel on standard
ports (80/443) while your panel runs on custom ports." 16 70 3 \
        "1" "Yes - I have Nginx (Show config)" \
        "2" "Yes - I have Caddy (Show config)" \
        "3" "No - Skip this step" \
        3>&1 1>&2 2>&3)
    
    case $choice in
        1)
            show_nginx_config
            ;;
        2)
            show_caddy_config
            ;;
        3)
            whiptail --title "No Reverse Proxy" --msgbox "
⚠️  Without a reverse proxy, users must access your panel with
the port number in the URL.

Example: http://$DOMAIN:$HTTP_PORT

Consider using Cloudflare Tunnel as an alternative!" 12 70
            ;;
    esac
}

# Show Nginx configuration
show_nginx_config() {
    local nginx_config="server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;

    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Proxy to Panel
    location / {
        proxy_pass http://localhost:$HTTP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
    }
}"

    whiptail --title "Nginx Configuration" --msgbox "
📝 Nginx Reverse Proxy Configuration

Save this to: /etc/nginx/sites-available/$DOMAIN

$nginx_config

After saving, run:
  sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
  sudo nginx -t
  sudo systemctl reload nginx

Press OK to continue..." 30 80
    
    if whiptail --title "Apply Configuration?" --yesno "
Would you like to automatically create this Nginx config?

This will:
• Create the config file
• Enable the site
• Test and reload Nginx" 12 70; then
        apply_nginx_config "$nginx_config"
    fi
}

# Apply Nginx configuration
apply_nginx_config() {
    local config="$1"
    
    echo "Creating Nginx configuration..."
    echo "$config" | sudo tee /etc/nginx/sites-available/"$DOMAIN" > /dev/null
    
    sudo ln -sf /etc/nginx/sites-available/"$DOMAIN" /etc/nginx/sites-enabled/
    
    if sudo nginx -t 2>&1 | grep -q "successful"; then
        sudo systemctl reload nginx
        whiptail --title "Success" --msgbox "
✅ Nginx configuration applied successfully!

Your panel is now accessible at:
  https://$DOMAIN (proxied to port $HTTP_PORT)" 10 60
    else
        whiptail --title "Error" --msgbox "
❌ Nginx configuration test failed!

Please check the configuration manually:
  sudo nginx -t" 10 60
    fi
}

# Show Caddy configuration
show_caddy_config() {
    local caddy_config="$DOMAIN {
    reverse_proxy localhost:$HTTP_PORT
}"

    whiptail --title "Caddy Configuration" --msgbox "
📝 Caddy Reverse Proxy Configuration

Add this to your Caddyfile:

$caddy_config

Caddy will automatically handle:
• SSL certificates (Let's Encrypt)
• HTTP to HTTPS redirect
• Proxy headers

After adding, run:
  sudo systemctl reload caddy

Press OK to continue..." 20 70
}

# Step 2: DNS/Cloudflare Configuration
configure_dns() {
    whiptail --title "Step 2: DNS Configuration" --msgbox "
🌐 DNS Configuration

You need to create DNS records pointing to your server.

Required DNS Records:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Type    Name              Value
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
A       $DOMAIN           Your Server IP
A       *.$DOMAIN         Your Server IP (wildcard)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Press OK to continue..." 18 70
    
    local dns_choice=$(whiptail --title "DNS Provider" --menu "
Which DNS provider are you using?" 14 70 3 \
        "1" "Cloudflare (Recommended)" \
        "2" "Other DNS Provider" \
        "3" "Skip DNS Configuration" \
        3>&1 1>&2 2>&3)
    
    case $dns_choice in
        1)
            configure_cloudflare
            ;;
        2)
            show_generic_dns
            ;;
        3)
            whiptail --title "Skipped" --msgbox "
⚠️  DNS configuration skipped.

Remember to configure your DNS records manually!" 10 60
            ;;
    esac
}

# Configure Cloudflare
configure_cloudflare() {
    whiptail --title "Cloudflare Configuration" --msgbox "
☁️  Cloudflare Setup

Step-by-step instructions:

1. Log in to Cloudflare Dashboard
   https://dash.cloudflare.com

2. Select your domain

3. Go to DNS → Records

4. Add A Record:
   • Type: A
   • Name: @ (or your subdomain)
   • IPv4 address: Your Server IP
   • Proxy status: DNS only (gray cloud)
   • TTL: Auto

5. Add Wildcard A Record (optional):
   • Type: A
   • Name: *
   • IPv4 address: Your Server IP
   • Proxy status: DNS only
   • TTL: Auto

Press OK to continue..." 26 70
    
    if whiptail --title "Cloudflare Tunnel?" --yesno "
💡 Alternative: Cloudflare Tunnel

Instead of port forwarding, you can use Cloudflare Tunnel:

Benefits:
• No port forwarding needed
• No need to expose your IP
• Free SSL certificates
• DDoS protection
• Works behind any firewall

Would you like instructions for Cloudflare Tunnel?" 16 70; then
        show_cloudflare_tunnel
    fi
}

# Show Cloudflare Tunnel instructions
show_cloudflare_tunnel() {
    whiptail --title "Cloudflare Tunnel Setup" --msgbox "
🚇 Cloudflare Tunnel Setup

1. Install cloudflared:
   curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared
   chmod +x /usr/local/bin/cloudflared

2. Authenticate:
   cloudflared tunnel login

3. Create tunnel:
   cloudflared tunnel create pterodactyl

4. Configure tunnel:
   Create /etc/cloudflared/config.yml:
   
   tunnel: <TUNNEL-ID>
   credentials-file: /root/.cloudflared/<TUNNEL-ID>.json
   
   ingress:
     - hostname: $DOMAIN
       service: http://localhost:$HTTP_PORT
     - service: http_status:404

5. Route DNS:
   cloudflared tunnel route dns pterodactyl $DOMAIN

6. Run tunnel:
   cloudflared tunnel run pterodactyl

See CLOUDFLARE_GUIDE.md for detailed instructions." 30 75
}

# Show generic DNS instructions
show_generic_dns() {
    whiptail --title "Generic DNS Configuration" --msgbox "
📋 DNS Configuration Steps

For any DNS provider:

1. Log in to your DNS provider's dashboard

2. Find DNS Management / DNS Records section

3. Add an A Record:
   • Host/Name: @ (or subdomain)
   • Type: A
   • Value/Points to: Your Server IP
   • TTL: 3600 (or Auto)

4. Save the record

5. Wait for DNS propagation (5-30 minutes)

6. Test with:
   ping $DOMAIN

Press OK to continue..." 22 70
}

# Step 3: Firewall Configuration
configure_firewall() {
    whiptail --title "Step 3: Firewall Configuration" --msgbox "
🔥 Firewall Configuration

You need to open your custom ports in the firewall.

Ports to open:
• $HTTP_PORT (HTTP)
• $HTTPS_PORT (HTTPS)

Press OK to see the commands..." 14 70
    
    local fw_commands="# UFW (Ubuntu/Debian)
sudo ufw allow $HTTP_PORT/tcp comment 'Panel HTTP'
sudo ufw allow $HTTPS_PORT/tcp comment 'Panel HTTPS'
sudo ufw reload

# Firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-port=$HTTP_PORT/tcp
sudo firewall-cmd --permanent --add-port=$HTTPS_PORT/tcp
sudo firewall-cmd --reload

# iptables (Manual)
sudo iptables -A INPUT -p tcp --dport $HTTP_PORT -j ACCEPT
sudo iptables -A INPUT -p tcp --dport $HTTPS_PORT -j ACCEPT
sudo iptables-save > /etc/iptables/rules.v4"

    whiptail --title "Firewall Commands" --msgbox "
📝 Firewall Commands

Choose the appropriate commands for your system:

$fw_commands

Press OK to continue..." 24 75
    
    if whiptail --title "Apply Firewall Rules?" --yesno "
Would you like to automatically configure UFW?

This will:
• Allow port $HTTP_PORT
• Allow port $HTTPS_PORT
• Reload firewall" 12 70; then
        apply_firewall_rules
    fi
}

# Apply firewall rules
apply_firewall_rules() {
    echo "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        sudo ufw allow "$HTTP_PORT/tcp" comment "Panel HTTP"
        sudo ufw allow "$HTTPS_PORT/tcp" comment "Panel HTTPS"
        sudo ufw reload
        
        whiptail --title "Success" --msgbox "
✅ Firewall rules applied!

Ports opened:
• $HTTP_PORT/tcp
• $HTTPS_PORT/tcp" 10 50
    else
        whiptail --title "UFW Not Found" --msgbox "
⚠️  UFW not found on this system.

Please configure your firewall manually using the
commands shown in the previous screen." 10 60
    fi
}

# Step 4: Access URLs
show_access_urls() {
    local with_proxy="https://$DOMAIN"
    local without_proxy="http://$DOMAIN:$HTTP_PORT"
    
    whiptail --title "Step 4: Accessing Your Panel" --msgbox "
🌐 Access URLs

Depending on your configuration:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

WITH Reverse Proxy or Cloudflare Tunnel:
  $with_proxy

Users access normally without port numbers!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

WITHOUT Reverse Proxy:
  $without_proxy

Users MUST include the port number in the URL.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 Tip: Use a reverse proxy or Cloudflare Tunnel for
better user experience!

Press OK to continue..." 24 70
}

# Port forwarding guide
show_port_forwarding() {
    whiptail --title "Port Forwarding" --msgbox "
🔌 Port Forwarding (If Behind Router)

If your server is behind a router, you need to forward ports:

Ports to forward:
• $HTTP_PORT → Your Server's Local IP
• $HTTPS_PORT → Your Server's Local IP

Steps:
1. Find your router's IP (usually 192.168.1.1)
2. Log in to router admin panel
3. Find Port Forwarding / Virtual Servers section
4. Add rules for ports $HTTP_PORT and $HTTPS_PORT
5. Point to your server's local IP

Or run the network setup wizard:
  sudo bash network-setup-wizard.sh

Press OK to continue..." 20 70
}

# Summary and next steps
show_summary() {
    whiptail --title "Configuration Complete!" --msgbox "
✅ Custom Ports Configuration Guide Complete!

Summary of your configuration:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• HTTP Port: $HTTP_PORT
• HTTPS Port: $HTTPS_PORT
• Domain: $DOMAIN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Next Steps:
1. ✓ Configure reverse proxy (if applicable)
2. ✓ Set up DNS records
3. ✓ Configure firewall rules
4. ✓ Test access to your panel

Testing:
• Check if ports are open:
  nc -zv $DOMAIN $HTTP_PORT

• Access your panel:
  http://$DOMAIN:$HTTP_PORT

Need Help?
• Network Setup: ./network-setup-wizard.sh
• Cloudflare Guide: cat CLOUDFLARE_GUIDE.md
• Documentation: cat INSTALLATION_STEPS.md

Press OK to finish..." 28 70
}

# Main execution
main() {
    show_intro
    configure_reverse_proxy
    configure_dns
    configure_firewall
    show_access_urls
    show_port_forwarding
    show_summary
}

# Run main
main "$@"
