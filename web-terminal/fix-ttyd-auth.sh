#!/bin/bash

#######################################
# Fix TTYD Proxy Authentication
# Generates proper bcrypt hash and updates service
#######################################

set -e

echo "================================"
echo "TTYD Proxy Authentication Fix"
echo "================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (sudo)"
    exit 1
fi

# Check if ttyd-proxy is installed
if [ ! -f "/opt/ssh-terminal/ttyd-proxy.js" ]; then
    echo "❌ ttyd-proxy not found. Please run setup-ttyd-proxy.sh first"
    exit 1
fi

# Prompt for password
echo "Enter password for Direct Terminal access:"
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

echo "Generating bcrypt hash..."

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

# Update systemd service
echo "Updating systemd service..."

# Generate new session secret
SESSION_SECRET=$(openssl rand -base64 32)

cat > /etc/systemd/system/ttyd-proxy.service << EOF
[Unit]
Description=TTYD Authentication Proxy
After=network.target ttyd.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ssh-terminal
Environment="NODE_ENV=production"
Environment="PORT=8095"
Environment="TTYD_PORT=7681"
Environment="PASSWORD_HASH=$PASSWORD_HASH"
Environment="SESSION_SECRET=$SESSION_SECRET"
ExecStart=/usr/bin/node /opt/ssh-terminal/ttyd-proxy.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Service file updated"
echo ""

# Update ttyd-proxy.js to use HTTPS-friendly settings
echo "Updating ttyd-proxy.js for HTTPS..."

# Backup original
cp /opt/ssh-terminal/ttyd-proxy.js /opt/ssh-terminal/ttyd-proxy.js.bak

# Update cookie settings for HTTPS
sed -i "s/secure: false/secure: true/g" /opt/ssh-terminal/ttyd-proxy.js
sed -i "s/sameSite: 'none'/sameSite: 'lax'/g" /opt/ssh-terminal/ttyd-proxy.js

echo "✅ HTTPS settings updated"
echo ""

# Reload and restart service
echo "Restarting service..."
systemctl daemon-reload
systemctl restart ttyd-proxy

sleep 2

# Check status
if systemctl is-active --quiet ttyd-proxy; then
    echo "✅ Service is running"
else
    echo "❌ Service failed to start. Checking logs..."
    journalctl -u ttyd-proxy -n 20 --no-pager
    exit 1
fi

echo ""
echo "================================"
echo "✅ Authentication Fixed!"
echo "================================"
echo ""
echo "Password has been updated and service restarted"
echo ""
echo "Test the login:"
echo "  https://term.cloudmc.online"
echo ""
echo "Commands:"
echo "  sudo systemctl status ttyd-proxy"
echo "  sudo systemctl restart ttyd-proxy"
echo "  sudo journalctl -u ttyd-proxy -f"
echo ""
echo "To change password again, run:"
echo "  sudo bash fix-ttyd-auth.sh"
echo ""
