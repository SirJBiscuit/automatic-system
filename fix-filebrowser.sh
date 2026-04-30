#!/bin/bash

# Quick fix script to complete the filebrowser installation

set -e

echo "🔧 Completing Filebrowser Installation..."
echo ""

# Set variables
FILEBROWSER_PORT=8090
STORAGE_PATH="/var/filebrowser"
DB_PATH="/etc/filebrowser"
DOMAIN="cloudmc.online"
SUBDOMAIN="share"
FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"

# Ask for admin credentials
read -p "Enter admin username (default: admin): " ADMIN_USER
ADMIN_USER=${ADMIN_USER:-admin}

read -s -p "Enter admin password: " ADMIN_PASS
echo ""

if [ -z "$ADMIN_PASS" ]; then
    echo "Error: Password cannot be empty"
    exit 1
fi

# Create Filebrowser config
echo "Creating Filebrowser configuration..."
cat > ${DB_PATH}/filebrowser.json <<EOF
{
  "port": ${FILEBROWSER_PORT},
  "baseURL": "",
  "address": "127.0.0.1",
  "log": "stdout",
  "database": "${DB_PATH}/filebrowser.db",
  "root": "${STORAGE_PATH}"
}
EOF

# Initialize and configure Filebrowser
filebrowser config init --database="${DB_PATH}/filebrowser.db"
filebrowser config set --address 127.0.0.1 --port ${FILEBROWSER_PORT} --database="${DB_PATH}/filebrowser.db"
filebrowser config set --root "${STORAGE_PATH}" --database="${DB_PATH}/filebrowser.db"
filebrowser config set --log /var/log/filebrowser/access.log --database="${DB_PATH}/filebrowser.db"
filebrowser config set --branding.name "File Share Portal" --database="${DB_PATH}/filebrowser.db"
filebrowser config set --signup false --database="${DB_PATH}/filebrowser.db"

# Create admin user
filebrowser users add "${ADMIN_USER}" "${ADMIN_PASS}" \
    --perm.admin \
    --perm.create \
    --perm.delete \
    --perm.download \
    --perm.execute \
    --perm.modify \
    --perm.rename \
    --perm.share \
    --database="${DB_PATH}/filebrowser.db" 2>/dev/null || echo "User may already exist"

echo "✓ Filebrowser configured"

# Create systemd service
echo "Creating systemd service..."
cat > /etc/systemd/system/filebrowser.service <<EOF
[Unit]
Description=File Browser
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${DB_PATH}
ExecStart=/usr/local/bin/filebrowser -c ${DB_PATH}/filebrowser.json
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable filebrowser
systemctl start filebrowser

echo "✓ Filebrowser service started"

# Update Cloudflare tunnel config
echo "Updating Cloudflare tunnel configuration..."
CLOUDFLARED_CONFIG="$HOME/.cloudflared/config.yml"

# Backup existing config
cp "$CLOUDFLARED_CONFIG" "$CLOUDFLARED_CONFIG.backup"

# Add filebrowser ingress rule (before the 404 rule)
cat > "$CLOUDFLARED_CONFIG" <<EOF
tunnel: 6fdccdd4-1929-4f60-8534-b05363b49e47.cfargotunnel.com
credentials-file: /home/guythatcooks/.cloudflared/cert.pem

ingress:
  - hostname: chat.cloudmc.online
    service: http://localhost:11434
    originRequest:
      httpHostHeader: "localhost:11434"
      noTLSVerify: true
      disableChunkedEncoding: false
  - hostname: ${FULL_DOMAIN}
    service: http://localhost:${FILEBROWSER_PORT}
  - service: http_status:404
EOF

echo "✓ Cloudflare tunnel config updated"

# Restart cloudflared
systemctl restart cloudflared

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Filebrowser installation completed!"
echo ""
echo "🌐 Access your file panel at: https://${FULL_DOMAIN}"
echo "👤 Username: ${ADMIN_USER}"
echo "🔑 Password: (the one you just entered)"
echo ""
echo "📋 Check status:"
echo "   sudo systemctl status filebrowser"
echo "   sudo systemctl status cloudflared"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
