#!/bin/bash

# TTYD Proxy Setup Script
# Sets up authentication proxy for ttyd terminal

set -e

echo "================================"
echo "TTYD Proxy Setup"
echo "================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (sudo)"
    exit 1
fi

# Install dependencies
echo "Installing dependencies..."
cd /tmp/automatic-system/web-terminal
npm install express express-session bcrypt http-proxy-middleware

# Set password
echo ""
echo "Set terminal password:"
read -s -p "Enter password: " PASSWORD
echo ""
read -s -p "Confirm password: " PASSWORD_CONFIRM
echo ""

if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
    echo "Passwords do not match!"
    exit 1
fi

# Generate password hash
echo "Generating password hash..."
PASSWORD_HASH=$(node -e "const bcrypt = require('bcrypt'); bcrypt.hash('$PASSWORD', 10).then(hash => console.log(hash));")

# Create systemd service
echo "Creating systemd service..."
cat > /etc/systemd/system/ttyd-proxy.service << EOF
[Unit]
Description=TTYD Authentication Proxy
After=network.target ttyd.service

[Service]
Type=simple
User=root
WorkingDirectory=/tmp/automatic-system/web-terminal
Environment="PORT=8095"
Environment="TTYD_PORT=7681"
Environment="PASSWORD_HASH=$PASSWORD_HASH"
Environment="SESSION_SECRET=$(openssl rand -base64 32)"
ExecStart=/usr/bin/node ttyd-proxy.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
echo "Starting service..."
systemctl daemon-reload
systemctl enable ttyd-proxy
systemctl start ttyd-proxy

# Check status
sleep 2
systemctl status ttyd-proxy --no-pager

echo ""
echo "================================"
echo "✅ TTYD Proxy Setup Complete!"
echo "================================"
echo ""
echo "Service: ttyd-proxy"
echo "Port: 8095"
echo "Proxies to: ttyd (port 7681)"
echo ""
echo "Commands:"
echo "  sudo systemctl status ttyd-proxy"
echo "  sudo systemctl restart ttyd-proxy"
echo "  sudo journalctl -u ttyd-proxy -f"
echo ""
echo "Update cloudflared config:"
echo "  - hostname: term.cloudmc.online"
echo "    service: http://localhost:8095"
echo ""
