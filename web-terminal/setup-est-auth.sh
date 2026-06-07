#!/bin/bash

#######################################
# Enhanced SSH Terminal - Authentication Setup
# Sets up server-side authentication for EST
#######################################

set -e

echo "======================================="
echo "EST Authentication Setup"
echo "======================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (sudo)"
    exit 1
fi

# Install directory
INSTALL_DIR="/var/www/ssh-terminal"
CONFIG_DIR="/etc/automatic-system"
CONFIG_FILE="$CONFIG_DIR/est-auth.conf"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed"
    echo "Install it with: curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs"
    exit 1
fi

# Check if npm packages are installed
echo "Checking dependencies..."
cd "$INSTALL_DIR"

if [ ! -d "node_modules" ]; then
    echo "Installing Node.js dependencies..."
    npm install express express-session bcrypt
fi

echo "✅ Dependencies installed"
echo ""

# Prompt for password
echo "Set password for Enhanced SSH Terminal:"
read -s PASSWORD
echo ""
echo "Confirm password:"
read -s PASSWORD_CONFIRM
echo ""

if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
    echo "❌ Passwords don't match"
    exit 1
fi

if [ -z "$PASSWORD" ]; then
    echo "❌ Password cannot be empty"
    exit 1
fi

if [ ${#PASSWORD} -lt 6 ]; then
    echo "❌ Password must be at least 6 characters"
    exit 1
fi

echo "Generating secure password hash..."

# Generate bcrypt hash using Node.js
PASSWORD_HASH=$(node -e "
const bcrypt = require('bcrypt');
bcrypt.hash('$PASSWORD', 10).then(hash => {
    console.log(hash);
    process.exit(0);
}).catch(err => {
    console.error('Error:', err);
    process.exit(1);
});
")

if [ -z "$PASSWORD_HASH" ]; then
    echo "❌ Failed to generate password hash"
    exit 1
fi

echo "✅ Password hash generated"
echo ""

# Save to config file
echo "Saving configuration..."
cat > "$CONFIG_FILE" << EOF
# Enhanced SSH Terminal Authentication Configuration
# Generated: $(date)

PASSWORD_HASH="$PASSWORD_HASH"
SESSION_SECRET="$(openssl rand -base64 32)"
EOF

chmod 600 "$CONFIG_FILE"
echo "✅ Configuration saved to $CONFIG_FILE"
echo ""

# Copy auth server
echo "Installing authentication server..."
cp est-auth-server.js "$INSTALL_DIR/"
chmod 644 "$INSTALL_DIR/est-auth-server.js"
echo "✅ Auth server installed"
echo ""

# Create systemd service
echo "Creating systemd service..."
cat > /etc/systemd/system/est-auth.service << EOF
[Unit]
Description=Enhanced SSH Terminal Authentication Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
Environment="NODE_ENV=production"
Environment="PORT=8085"
EnvironmentFile=$CONFIG_FILE
ExecStart=/usr/bin/node $INSTALL_DIR/est-auth-server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Service file created"
echo ""

# Reload and start service
echo "Starting service..."
systemctl daemon-reload
systemctl enable est-auth
systemctl restart est-auth

sleep 2

# Check status
if systemctl is-active --quiet est-auth; then
    echo "✅ Service is running"
else
    echo "❌ Service failed to start. Checking logs..."
    journalctl -u est-auth -n 20 --no-pager
    exit 1
fi

echo ""
echo "======================================="
echo "✅ EST Authentication Setup Complete!"
echo "======================================="
echo ""
echo "Service: est-auth"
echo "Port: 8085"
echo "Config: $CONFIG_FILE"
echo ""
echo "Update your Nginx config to proxy to port 8085:"
echo ""
echo "  location / {"
echo "      proxy_pass http://localhost:8085;"
echo "      proxy_http_version 1.1;"
echo "      proxy_set_header Upgrade \$http_upgrade;"
echo "      proxy_set_header Connection 'upgrade';"
echo "      proxy_set_header Host \$host;"
echo "      proxy_cache_bypass \$http_upgrade;"
echo "      proxy_set_header X-Real-IP \$remote_addr;"
echo "      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;"
echo "      proxy_set_header X-Forwarded-Proto \$scheme;"
echo "  }"
echo ""
echo "Then reload Nginx:"
echo "  sudo systemctl reload nginx"
echo ""
echo "Commands:"
echo "  sudo systemctl status est-auth"
echo "  sudo systemctl restart est-auth"
echo "  sudo journalctl -u est-auth -f"
echo ""
echo "To change password:"
echo "  sudo bash setup-est-auth.sh"
echo ""
