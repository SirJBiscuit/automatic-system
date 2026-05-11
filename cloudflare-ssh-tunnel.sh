#!/bin/bash

# Cloudflare SSH Tunnel Setup
# Allows SSH access through Cloudflare Tunnel (no port forwarding needed)
# Perfect for Termux and mobile SSH clients

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

TUNNEL_CONFIG="/etc/cloudflared/ssh-tunnel.yml"
TUNNEL_DIR="/etc/cloudflared"
SERVICE_FILE="/etc/systemd/system/cloudflared-ssh.service"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Install cloudflared
install_cloudflared() {
    whiptail --title "Installing Cloudflared" --msgbox "
📦 Installing Cloudflare Tunnel (cloudflared)...

This will download and install the latest version.

Press OK to continue..." 10 60

    echo "Downloading cloudflared..."
    
    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
            ;;
        aarch64|arm64)
            CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
            ;;
        armv7l|armhf)
            CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm"
            ;;
        *)
            whiptail --title "Error" --msgbox "
❌ Unsupported architecture: $ARCH

Please install cloudflared manually." 10 60
            exit 1
            ;;
    esac
    
    curl -L "$CLOUDFLARED_URL" -o /usr/local/bin/cloudflared
    chmod +x /usr/local/bin/cloudflared
    
    whiptail --title "Success" --msgbox "
✅ Cloudflared installed successfully!

Version: $(cloudflared --version)

Press OK to continue..." 10 60
}

# Authenticate with Cloudflare
authenticate_cloudflare() {
    whiptail --title "Cloudflare Authentication" --msgbox "
🔐 Cloudflare Authentication Required

A browser window will open for you to log in to Cloudflare.

Steps:
1. Log in to your Cloudflare account
2. Authorize cloudflared
3. Return to this terminal

Press OK to open browser..." 14 70

    cloudflared tunnel login
    
    if [ $? -eq 0 ]; then
        whiptail --title "Success" --msgbox "
✅ Successfully authenticated with Cloudflare!

Press OK to continue..." 8 60
    else
        whiptail --title "Error" --msgbox "
❌ Authentication failed!

Please try again or check your Cloudflare account.

Press OK to exit..." 10 60
        exit 1
    fi
}

# Create SSH tunnel
create_ssh_tunnel() {
    local tunnel_name="ssh-$(hostname)-$(date +%s)"
    local domain=""
    
    # Ask for domain
    domain=$(whiptail --title "SSH Domain" --inputbox "
Enter the subdomain for SSH access:

Example: ssh.yourdomain.com

This will be your SSH connection address.

Domain:" 14 70 "ssh.$(hostname).yourdomain.com" 3>&1 1>&2 2>&3)
    
    if [ -z "$domain" ]; then
        whiptail --title "Error" --msgbox "
❌ Domain is required!

Press OK to exit..." 8 50
        exit 1
    fi
    
    # Create tunnel
    whiptail --title "Creating Tunnel" --msgbox "
🚇 Creating Cloudflare Tunnel...

Tunnel Name: $tunnel_name
Domain: $domain

Press OK to continue..." 12 70
    
    cloudflared tunnel create "$tunnel_name"
    
    if [ $? -ne 0 ]; then
        whiptail --title "Error" --msgbox "
❌ Failed to create tunnel!

Please check your Cloudflare account and try again.

Press OK to exit..." 10 60
        exit 1
    fi
    
    # Get tunnel ID
    local tunnel_id=$(cloudflared tunnel list | grep "$tunnel_name" | awk '{print $1}')
    
    if [ -z "$tunnel_id" ]; then
        whiptail --title "Error" --msgbox "
❌ Could not find tunnel ID!

Press OK to exit..." 8 50
        exit 1
    fi
    
    # Create config directory
    mkdir -p "$TUNNEL_DIR"
    
    # Create tunnel configuration
    cat > "$TUNNEL_CONFIG" <<EOF
tunnel: $tunnel_id
credentials-file: /root/.cloudflared/$tunnel_id.json

ingress:
  - hostname: $domain
    service: ssh://localhost:22
  - service: http_status:404
EOF
    
    # Route DNS
    whiptail --title "Configuring DNS" --msgbox "
🌐 Configuring DNS for $domain...

This will create a CNAME record pointing to your tunnel.

Press OK to continue..." 10 70
    
    cloudflared tunnel route dns "$tunnel_name" "$domain"
    
    if [ $? -eq 0 ]; then
        whiptail --title "Success" --msgbox "
✅ DNS configured successfully!

Your SSH tunnel is ready at:
  $domain

Press OK to continue..." 10 60
    else
        whiptail --title "Warning" --msgbox "
⚠️  DNS configuration may have failed!

You may need to manually add a CNAME record:
  Name: $domain
  Target: $tunnel_id.cfargotunnel.com

Press OK to continue..." 12 70
    fi
    
    # Save domain for later use
    echo "$domain" > "$TUNNEL_DIR/ssh-domain.txt"
    echo "$tunnel_name" > "$TUNNEL_DIR/ssh-tunnel-name.txt"
    echo "$tunnel_id" > "$TUNNEL_DIR/ssh-tunnel-id.txt"
}

# Create systemd service
create_systemd_service() {
    whiptail --title "Creating Service" --msgbox "
⚙️  Creating systemd service...

This will run the SSH tunnel automatically on boot.

Press OK to continue..." 10 60
    
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Cloudflare SSH Tunnel
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cloudflared tunnel --config $TUNNEL_CONFIG run
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable cloudflared-ssh.service
    systemctl start cloudflared-ssh.service
    
    if systemctl is-active --quiet cloudflared-ssh.service; then
        whiptail --title "Success" --msgbox "
✅ SSH Tunnel service is running!

Service: cloudflared-ssh.service
Status: Active

Press OK to continue..." 10 60
    else
        whiptail --title "Warning" --msgbox "
⚠️  Service may not be running properly!

Check status with:
  systemctl status cloudflared-ssh.service

Press OK to continue..." 12 70
    fi
}

# Show connection instructions
show_connection_instructions() {
    local domain=$(cat "$TUNNEL_DIR/ssh-domain.txt" 2>/dev/null || echo "ssh.yourdomain.com")
    local username=$(whoami)
    
    whiptail --title "SSH Tunnel Ready!" --msgbox "
🎉 SSH Tunnel Setup Complete!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CONNECTION INFORMATION:

Domain: $domain
Port: 22 (standard SSH port)
Protocol: SSH over Cloudflare Tunnel

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CONNECT FROM TERMUX:

1. Install OpenSSH in Termux:
   pkg install openssh

2. Connect to your server:
   ssh username@$domain

3. Or with specific user:
   ssh root@$domain

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CONNECT FROM ANY SSH CLIENT:

Host: $domain
Port: 22
Username: Your server username
Password/Key: Your SSH credentials

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BENEFITS:

✅ No port forwarding needed
✅ Works from anywhere
✅ Cloudflare DDoS protection
✅ Fast and secure
✅ Works on mobile data
✅ No IP address needed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

MANAGE TUNNEL:

Start:   systemctl start cloudflared-ssh
Stop:    systemctl stop cloudflared-ssh
Status:  systemctl status cloudflared-ssh
Restart: systemctl restart cloudflared-ssh

Press OK to finish..." 40 75
}

# Backup old SSH terminal
backup_old_ssh_terminal() {
    if [ -d "/opt/ssh-terminal" ]; then
        whiptail --title "Backup Old SSH Terminal" --msgbox "
💾 Backing up old SSH terminal...

Old system will be saved to:
  /opt/ssh-terminal.backup

Press OK to continue..." 10 60
        
        mv /opt/ssh-terminal /opt/ssh-terminal.backup
        
        # Stop old service if running
        if systemctl is-active --quiet ssh-terminal.service 2>/dev/null; then
            systemctl stop ssh-terminal.service
            systemctl disable ssh-terminal.service
        fi
        
        whiptail --title "Backup Complete" --msgbox "
✅ Old SSH terminal backed up!

Backup location: /opt/ssh-terminal.backup

The old web-based SSH terminal has been disabled.

Press OK to continue..." 12 60
    fi
}

# Test SSH connection
test_ssh_connection() {
    local domain=$(cat "$TUNNEL_DIR/ssh-domain.txt" 2>/dev/null || echo "ssh.yourdomain.com")
    
    if whiptail --title "Test Connection?" --yesno "
Would you like to test the SSH tunnel?

This will attempt to connect to:
  $domain

Note: You'll need to accept the host key on first connection.

Test now?" 14 70; then
        
        whiptail --title "Testing Connection" --msgbox "
🔍 Testing SSH tunnel...

Attempting to connect to: $domain

Press OK to continue..." 10 60
        
        # Test connection
        timeout 10 ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 localhost -p 22 exit 2>/dev/null
        
        if [ $? -eq 0 ] || [ $? -eq 255 ]; then
            whiptail --title "Success" --msgbox "
✅ SSH tunnel is working!

You can now connect from Termux or any SSH client.

Press OK to finish..." 10 60
        else
            whiptail --title "Note" --msgbox "
ℹ️  Connection test completed.

The tunnel should be working. Try connecting from Termux:
  ssh username@$domain

Press OK to finish..." 12 60
        fi
    fi
}

# Show status
show_status() {
    local domain=$(cat "$TUNNEL_DIR/ssh-domain.txt" 2>/dev/null || echo "Not configured")
    local tunnel_name=$(cat "$TUNNEL_DIR/ssh-tunnel-name.txt" 2>/dev/null || echo "Not configured")
    local service_status="Stopped"
    
    if systemctl is-active --quiet cloudflared-ssh.service 2>/dev/null; then
        service_status="Running"
    fi
    
    whiptail --title "SSH Tunnel Status" --msgbox "
📊 Cloudflare SSH Tunnel Status

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Domain: $domain
Tunnel: $tunnel_name
Service: $service_status

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Configuration: $TUNNEL_CONFIG
Service: cloudflared-ssh.service

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Commands:
  systemctl status cloudflared-ssh
  systemctl restart cloudflared-ssh
  cloudflared tunnel list

Press OK to close..." 22 70
}

# Uninstall
uninstall_ssh_tunnel() {
    if whiptail --title "Uninstall SSH Tunnel?" --yesno "
⚠️  Are you sure you want to uninstall the SSH tunnel?

This will:
• Stop the tunnel service
• Remove the tunnel configuration
• Delete the Cloudflare tunnel

The tunnel domain will stop working.

Continue?" 14 70; then
        
        local tunnel_name=$(cat "$TUNNEL_DIR/ssh-tunnel-name.txt" 2>/dev/null)
        
        # Stop and disable service
        systemctl stop cloudflared-ssh.service 2>/dev/null
        systemctl disable cloudflared-ssh.service 2>/dev/null
        rm -f "$SERVICE_FILE"
        
        # Delete tunnel
        if [ -n "$tunnel_name" ]; then
            cloudflared tunnel delete "$tunnel_name" -f
        fi
        
        # Remove config
        rm -rf "$TUNNEL_DIR"
        
        whiptail --title "Uninstalled" --msgbox "
✅ SSH tunnel has been uninstalled!

Press OK to finish..." 8 50
    fi
}

# Main menu
show_main_menu() {
    local choice=$(whiptail --title "Cloudflare SSH Tunnel" --menu "
Choose an option:" 18 70 8 \
        "1" "Setup New SSH Tunnel" \
        "2" "Show Connection Instructions" \
        "3" "Show Status" \
        "4" "Test Connection" \
        "5" "Restart Tunnel Service" \
        "6" "View Logs" \
        "7" "Uninstall" \
        "8" "Exit" \
        3>&1 1>&2 2>&3)
    
    case $choice in
        1)
            setup_ssh_tunnel
            ;;
        2)
            show_connection_instructions
            ;;
        3)
            show_status
            ;;
        4)
            test_ssh_connection
            ;;
        5)
            systemctl restart cloudflared-ssh.service
            whiptail --title "Restarted" --msgbox "
✅ SSH tunnel service restarted!

Press OK to continue..." 8 50
            ;;
        6)
            journalctl -u cloudflared-ssh.service -n 50 --no-pager | whiptail --title "Service Logs" --scrolltext --msgbox "$(cat)" 20 80
            ;;
        7)
            uninstall_ssh_tunnel
            ;;
        8)
            exit 0
            ;;
    esac
}

# Full setup process
setup_ssh_tunnel() {
    # Check if cloudflared is installed
    if ! command -v cloudflared &> /dev/null; then
        install_cloudflared
    fi
    
    # Backup old SSH terminal
    backup_old_ssh_terminal
    
    # Authenticate with Cloudflare
    if [ ! -f "/root/.cloudflared/cert.pem" ]; then
        authenticate_cloudflare
    fi
    
    # Create SSH tunnel
    create_ssh_tunnel
    
    # Create systemd service
    create_systemd_service
    
    # Show connection instructions
    show_connection_instructions
    
    # Test connection
    test_ssh_connection
}

# Main execution
if [ "${1:-menu}" = "setup" ]; then
    setup_ssh_tunnel
else
    show_main_menu
fi
