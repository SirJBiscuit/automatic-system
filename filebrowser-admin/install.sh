#!/bin/bash

# Filebrowser Admin Panel Installer

set -e

echo "🚀 Installing Filebrowser Admin Panel..."
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv

# Create app directory
APP_DIR="/opt/filebrowser-admin"
mkdir -p $APP_DIR

# Copy files
echo "📁 Copying files..."
cp admin.py $APP_DIR/
cp -r templates $APP_DIR/

# Create virtual environment
cd $APP_DIR
python3 -m venv venv
source venv/bin/activate
pip install Flask

# Create systemd service
echo "⚙️  Creating service..."
cat > /etc/systemd/system/filebrowser-admin.service <<EOF
[Unit]
Description=Filebrowser Admin Panel
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/venv/bin/python admin.py
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
systemctl daemon-reload
systemctl enable filebrowser-admin
systemctl start filebrowser-admin

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Filebrowser Admin Panel installed!"
echo ""
echo "🌐 Access at: http://YOUR_SERVER_IP:5002"
echo ""
echo "Features:"
echo "  ✅ User management (add, delete, change passwords)"
echo "  ✅ Database reset tool"
echo "  ✅ Service control (restart filebrowser)"
echo "  ✅ Social plugin installer"
echo "  ✅ Status monitoring"
echo ""
echo "📋 Service commands:"
echo "  sudo systemctl status filebrowser-admin"
echo "  sudo systemctl restart filebrowser-admin"
echo ""
echo "⚠️  Security: This runs on port 5002 without authentication."
echo "   Consider adding Cloudflare tunnel or firewall rules."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
