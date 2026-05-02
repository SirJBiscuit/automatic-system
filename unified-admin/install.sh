#!/bin/bash

# Unified Admin Panel Installer
# Complete server control center

set -e

echo "🛠️  Installing Unified Admin Panel..."
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv

# Create app directory
APP_DIR="/opt/unified-admin"
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
cat > /etc/systemd/system/unified-admin.service <<EOF
[Unit]
Description=Unified Server Admin Panel
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
systemctl enable unified-admin
systemctl start unified-admin

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Unified Admin Panel installed successfully!"
echo ""
echo "🌐 Access at: http://localhost:5002"
echo ""
echo "🔐 Default Login:"
echo "   Username: admin"
echo "   Password: ChangeMe123!"
echo "   ⚠️  CHANGE THESE IMMEDIATELY AFTER FIRST LOGIN!"
echo ""
echo "📋 Add to Cloudflare tunnel:"
echo "   Edit: /root/.cloudflared/config.yml"
echo "   Add before the 404 line:"
echo "     - hostname: admin.cloudmc.online"
echo "       service: http://localhost:5002"
echo "   Then: sudo systemctl restart cloudflared"
echo ""
echo "🎨 Features:"
echo "   ✅ System monitoring (CPU, memory, disk)"
echo "   ✅ Service management (restart, status)"
echo "   ✅ Filebrowser user management"
echo "   ✅ Quick shortcuts to all panels"
echo "   ✅ Quick actions (restart all, fix database)"
echo "   ✅ View service logs"
echo "   ✅ Storage configuration"
echo "   ✅ Safe reboot/shutdown"
echo "   ✅ Secure login with password protection"
echo ""
echo "📋 Service commands:"
echo "   sudo systemctl status unified-admin"
echo "   sudo systemctl restart unified-admin"
echo "   sudo systemctl logs -f unified-admin"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
