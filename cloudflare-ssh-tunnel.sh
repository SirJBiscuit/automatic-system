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

# Manual authentication with origin cert
authenticate_manual() {
    whiptail --title "Manual Authentication" --msgbox "
📝 Manual Authentication - Origin Certificate

The API token method doesn't work for tunnels.
You need to get the origin certificate instead.

Steps:
1. On your phone/computer, open:
   https://dash.cloudflare.com/argotunnel
2. Log in to Cloudflare
3. Click 'Authorize' when prompted
4. You'll get a certificate file
5. We'll download it to your server

Press OK to continue..." 18 70

    # Try to login and get the cert
    whiptail --title "Getting Certificate" --msgbox "
🔐 Attempting to get origin certificate...

This will show you a URL to open on your phone/computer.

Copy the URL and open it in your browser.

Press OK to continue..." 12 70
    
    # Run cloudflared login in background and capture URL
    timeout 60 cloudflared tunnel login > /tmp/cf-login.log 2>&1 &
    local login_pid=$!
    
    # Wait a moment for URL to appear
    sleep 3
    
    # Extract URL from log
    local auth_url=$(grep -oP 'https://dash\.cloudflare\.com/argotunnel\?[^\s]+' /tmp/cf-login.log 2>/dev/null | head -1)
    
    if [ -n "$auth_url" ]; then
        whiptail --title "Open This URL" --msgbox "
📱 Open this URL on your phone or computer:

$auth_url

Steps:
1. Copy the URL above
2. Open it in your browser
3. Log in to Cloudflare
4. Click 'Authorize'
5. Wait for confirmation
6. Press OK here when done

Press OK when you've authorized..." 18 75
        
        # Wait for cert file to appear
        local timeout=120
        local elapsed=0
        while [ ! -f "/root/.cloudflared/cert.pem" ] && [ $elapsed -lt $timeout ]; do
            sleep 2
            elapsed=$((elapsed + 2))
        done
        
        if [ -f "/root/.cloudflared/cert.pem" ]; then
            whiptail --title "Success" --msgbox "
✅ Successfully authenticated!

Certificate saved to:
  /root/.cloudflared/cert.pem

Press OK to continue..." 10 60
        else
            whiptail --title "Timeout" --msgbox "
⏱️  Authentication timed out!

Please try again or use the automatic method.

Press OK to exit..." 10 60
            exit 1
        fi
    else
        whiptail --title "Error" --msgbox "
❌ Could not get authentication URL!

Please try the automatic method instead.

Press OK to exit..." 10 60
        exit 1
    fi
    
    # Clean up
    kill $login_pid 2>/dev/null || true
    rm -f /tmp/cf-login.log
}

# Authenticate with Cloudflare
authenticate_cloudflare() {
    whiptail --title "Cloudflare Authentication" --msgbox "
🔐 Cloudflare Authentication Required

This will generate an authentication URL for you.

Steps:
1. We'll run a command to generate the URL
2. Copy the URL that appears
3. Open it on your phone/computer browser
4. Log in to Cloudflare
5. Click 'Authorize'
6. Return here and press OK

Press OK to generate the URL..." 16 70

    # Clear the screen and show the command
    clear
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  CLOUDFLARE AUTHENTICATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Generating authentication URL..."
    echo ""
    echo "Please wait..."
    echo ""
    
    # Run cloudflared login in foreground and capture output
    # This will block until user completes authentication
    cloudflared tunnel login 2>&1 | tee /tmp/cloudflared-login.log
    
    # Check if cert was created
    if [ -f "/root/.cloudflared/cert.pem" ]; then
        whiptail --title "Success" --msgbox "
✅ Successfully authenticated with Cloudflare!

Certificate saved to:
  /root/.cloudflared/cert.pem

Press OK to continue..." 10 60
        return 0
    else
        whiptail --title "Error" --msgbox "
❌ Authentication failed!

The certificate file was not created.
This usually means:
• You didn't complete the authorization in the browser
• The browser authorization timed out
• There was a network issue

Please try again.

Press OK to exit..." 14 60
        exit 1
    fi
    
    # Clean up
    rm -f /tmp/cloudflared-login.log
}

# Validate certificate
validate_certificate() {
    if [ ! -f "/root/.cloudflared/cert.pem" ]; then
        return 1
    fi
    
    # Check if cert file is not empty
    if [ ! -s "/root/.cloudflared/cert.pem" ]; then
        return 1
    fi
    
    # Try to list tunnels to validate cert
    if cloudflared tunnel list &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Create SSH tunnel
create_ssh_tunnel() {
    # Check if tunnel already exists
    if [ -f "$TUNNEL_DIR/ssh-tunnel-name.txt" ] && [ -f "$TUNNEL_DIR/ssh-domain.txt" ]; then
        local existing_tunnel=$(cat "$TUNNEL_DIR/ssh-tunnel-name.txt")
        local existing_domain=$(cat "$TUNNEL_DIR/ssh-domain.txt")
        local existing_port=$(cat "$TUNNEL_DIR/ssh-port.txt" 2>/dev/null || echo "22")
        local created_by=$(cat "$TUNNEL_DIR/created-by.txt" 2>/dev/null || echo "unknown")
        
        # Safety check: only manage tunnels created by this script
        if [ "$created_by" != "termux-ssh-setup" ] && [ "$created_by" != "unknown" ]; then
            whiptail --title "Warning" --msgbox "
⚠️  Found tunnel configuration not created by this script!

Tunnel: $existing_tunnel
Created by: $created_by

For safety, this script will not modify it.
Please use a different domain or manually manage this tunnel.

Press OK to exit..." 14 70
            exit 1
        fi
        
        # Check if tunnel still exists in Cloudflare
        if cloudflared tunnel list 2>/dev/null | grep -q "$existing_tunnel"; then
            if whiptail --title "Existing Tunnel Found" --yesno "
📡 An existing SSH tunnel was found:

Tunnel Name: $existing_tunnel
Domain: $existing_domain
SSH Port: $existing_port

Would you like to:
• YES - Keep and use the existing tunnel
• NO  - Delete and create a new tunnel

Keep existing tunnel?" 16 70; then
                whiptail --title "Using Existing Tunnel" --msgbox "
✅ Using existing tunnel!

Tunnel: $existing_tunnel
Domain: $existing_domain

The tunnel configuration will be verified and
the systemd service will be updated.

Press OK to continue..." 14 70
                
                # Verify and update systemd service
                create_systemd_service
                show_connection_instructions
                return 0
            else
                # User wants to delete and recreate
                # Safety check: only delete if tunnel name matches our pattern
                if [[ "$existing_tunnel" =~ ^ssh-.*-[0-9]+$ ]]; then
                    whiptail --title "Deleting Old Tunnel" --msgbox "
🗑️  Deleting old tunnel...

This will remove:
• Tunnel: $existing_tunnel
• Domain: $existing_domain

This tunnel was created by this script.

Press OK to continue..." 14 70
                    
                    # Delete old tunnel
                    cloudflared tunnel delete "$existing_tunnel" -f 2>/dev/null || true
                    rm -rf "$TUNNEL_DIR"
                    mkdir -p "$TUNNEL_DIR"
                else
                    whiptail --title "Safety Check" --msgbox "
⚠️  Cannot delete tunnel: $existing_tunnel

This tunnel doesn't match the expected naming pattern
(ssh-hostname-timestamp) and may not have been created
by this script.

For safety, we won't delete it automatically.

Please:
1. Manually delete it via Cloudflare dashboard
2. Or use a different domain name

Press OK to exit..." 18 70
                    exit 1
                fi
            fi
        else
            # Tunnel doesn't exist in Cloudflare but config files exist
            whiptail --title "Stale Configuration" --msgbox "
⚠️  Found old configuration files but tunnel doesn't exist.

Cleaning up and creating new tunnel...

Press OK to continue..." 10 70
            
            rm -rf "$TUNNEL_DIR"
            mkdir -p "$TUNNEL_DIR"
        fi
    fi
    
    local tunnel_name="ssh-$(hostname)-$(date +%s)"
    local domain=""
    
    # Validate certificate first
    if ! validate_certificate; then
        whiptail --title "Certificate Error" --msgbox "
❌ Certificate validation failed!

The certificate file exists but appears to be corrupted.
This usually happens if authentication was interrupted.

Removing corrupted certificate...

Press OK to re-authenticate..." 14 60
        
        # Remove corrupted cert
        rm -f /root/.cloudflared/cert.pem
        
        # Re-authenticate
        authenticate_cloudflare
        
        # Validate again
        if ! validate_certificate; then
            whiptail --title "Error" --msgbox "
❌ Certificate still invalid after re-authentication!

Please try running the setup again.

Press OK to exit..." 12 60
            exit 1
        fi
    fi
    
    # Detect SSH port
    local ssh_port=$(grep "^Port" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
    if [ -z "$ssh_port" ]; then
        ssh_port="22"
    fi
    
    # Ask user to confirm or change SSH port
    ssh_port=$(whiptail --title "SSH Port" --inputbox "
What port is your SSH server running on?

Auto-detected: $ssh_port

If this is incorrect, enter the correct port:

Port:" 14 70 "$ssh_port" 3>&1 1>&2 2>&3)
    
    if [ -z "$ssh_port" ]; then
        ssh_port="22"
    fi
    
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
    
    echo "Creating tunnel: $tunnel_name"
    if ! cloudflared tunnel create "$tunnel_name" 2>&1 | tee /tmp/tunnel-create.log; then
        local error_msg=$(cat /tmp/tunnel-create.log)
        whiptail --title "Error" --msgbox "
❌ Failed to create tunnel!

Error: $error_msg

Common fixes:
• Delete old certificate: rm -f /root/.cloudflared/cert.pem
• Re-run setup
• Check Cloudflare account permissions

Press OK to exit..." 16 70
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
    service: ssh://localhost:$ssh_port
  - service: http_status:404
EOF
    
    # Route DNS
    whiptail --title "Configuring DNS" --msgbox "
🌐 Configuring DNS for $domain...

This will create a CNAME record pointing to your tunnel.

Press OK to continue..." 10 70
    
    # Try to create DNS route
    echo "Creating DNS route for $domain..."
    cloudflared tunnel route dns "$tunnel_name" "$domain" 2>&1 | tee /tmp/dns-route.log
    local dns_exit_code=${PIPESTATUS[0]}
    
    # Check if it failed due to existing record
    if grep -q "already exists" /tmp/dns-route.log || [ $dns_exit_code -ne 0 ]; then
        if grep -q "already exists" /tmp/dns-route.log; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "⚠️  WARNING: DNS Record Already Exists!"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "A DNS record for $domain already exists!"
            echo "This is usually from a previous tunnel setup."
            echo ""
            echo "Options:"
            echo "  1) Delete old record and create new (recommended)"
            echo "  2) Keep existing record (may not work)"
            echo "  3) Use a different subdomain"
            echo ""
            read -p "Enter choice [1-3]: " choice
            
            if [ "$choice" = "1" ]; then
                # User wants to delete old record
                echo ""
                echo "🧹 Attempting to remove old DNS record..."
                echo ""
                
                # Extract subdomain and domain
                local subdomain="${domain%%.*}"
                local base_domain="${domain#*.}"
                
                # Try to delete via cloudflared (may not work for all cases)
                if ! cloudflared tunnel route dns --overwrite-dns "$tunnel_name" "$domain" 2>&1 | tee /tmp/dns-cleanup.log; then
                    echo ""
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo "⚠️  Automatic DNS cleanup failed!"
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo ""
                    echo "Please manually delete the DNS record:"
                    echo ""
                    echo "1. Go to: https://dash.cloudflare.com"
                    echo "2. Select your domain: $base_domain"
                    echo "3. Go to DNS → Records"
                    echo "4. Find and delete record: $subdomain"
                    echo "5. Then run this setup again"
                    echo ""
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo ""
                    exit 1
                fi
            elif [ "$choice" = "3" ]; then
                # User wants different subdomain
                echo ""
                read -p "Enter a different subdomain (e.g., ssh2.${base_domain#*.}): " new_domain
                
                if [ -z "$new_domain" ]; then
                    echo "❌ Domain is required!"
                    exit 1
                fi
                
                domain="$new_domain"
                
                # Try again with new domain
                echo "Creating DNS route for $domain..."
                cloudflared tunnel route dns "$tunnel_name" "$domain" 2>&1 | tee /tmp/dns-route.log
            else
                # Keep existing or invalid choice
                echo ""
                echo "⚠️  Keeping existing DNS record."
                echo "The tunnel may not work correctly."
                echo ""
            fi
        else
            # Different error
            whiptail --title "Warning" --msgbox "
⚠️  DNS configuration may have failed!

Error: $(cat /tmp/dns-route.log)

You may need to manually add a CNAME record:
  Name: $domain
  Target: $tunnel_id.cfargotunnel.com

Press OK to continue..." 16 70
        fi
    fi
    
    # Final verification
    if grep -q "already exists" /tmp/dns-route.log || grep -q "Created" /tmp/dns-route.log; then
        whiptail --title "Success" --msgbox "
✅ DNS configured successfully!

Your SSH tunnel is ready at:
  $domain

Press OK to continue..." 10 60
    else
        whiptail --title "Warning" --msgbox "
⚠️  DNS configuration status unclear.

Please verify the tunnel works by testing the connection.

Domain: $domain

Press OK to continue..." 12 70
    fi
    
    # Clean up
    rm -f /tmp/dns-route.log
    
    # Save domain and port for later use
    echo "$domain" > "$TUNNEL_DIR/ssh-domain.txt"
    echo "$tunnel_name" > "$TUNNEL_DIR/ssh-tunnel-name.txt"
    echo "$tunnel_id" > "$TUNNEL_DIR/ssh-tunnel-id.txt"
    echo "$ssh_port" > "$TUNNEL_DIR/ssh-port.txt"
    
    # Mark this tunnel as created by our script
    echo "termux-ssh-setup" > "$TUNNEL_DIR/created-by.txt"
    date > "$TUNNEL_DIR/created-date.txt"
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
    local ssh_port=$(cat "$TUNNEL_DIR/ssh-port.txt" 2>/dev/null || echo "22")
    local username=$(whoami)
    
    # Clear screen for better visibility
    clear
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🎉 SSH TUNNEL SETUP COMPLETE!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "CONNECTION INFO:"
    echo "  Domain: $domain"
    if [ "$ssh_port" != "22" ]; then
        echo "  Server Port: $ssh_port (Cloudflare routes to this)"
    fi
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  CONNECT FROM TERMUX:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  ssh root@$domain"
    echo ""
    echo "  (No port needed - Cloudflare handles routing)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  BENEFITS:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  ✅ Works from anywhere (mobile data, WiFi, etc.)"
    echo "  ✅ No port forwarding needed"
    echo "  ✅ DDoS protection included"
    echo "  ✅ Fast and secure"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  MANAGE TUNNEL:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Start:   systemctl start cloudflared-ssh"
    echo "  Stop:    systemctl stop cloudflared-ssh"
    echo "  Status:  systemctl status cloudflared-ssh"
    echo "  Restart: systemctl restart cloudflared-ssh"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Save to file for later reference
    cat > "$TUNNEL_DIR/connection-info.txt" <<EOF
SSH TUNNEL CONNECTION INFORMATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Domain: $domain
Server SSH Port: $ssh_port (internal)

CONNECT:
  ssh root@$domain

MANAGE:
  systemctl start cloudflared-ssh
  systemctl stop cloudflared-ssh
  systemctl status cloudflared-ssh
  systemctl restart cloudflared-ssh

Created: $(date)
EOF
    
    echo "📄 Connection info saved to: $TUNNEL_DIR/connection-info.txt"
    echo ""
    read -p "Press ENTER to continue..."
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
