#!/bin/bash

# Social Filebrowser Installation Script

set -e

echo "🚀 Installing Social Filebrowser..."
echo ""

# Install Python dependencies
echo "📦 Installing Python packages..."
apt-get update
apt-get install -y python3 python3-pip python3-venv

# Create application directory
APP_DIR="/opt/social-filebrowser"
mkdir -p $APP_DIR

# Copy files
echo "📁 Copying application files..."
cp app.py $APP_DIR/
cp requirements.txt $APP_DIR/
cp -r templates $APP_DIR/

# Create virtual environment
cd $APP_DIR
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Create systemd service
echo "⚙️  Creating systemd service..."
cat > /etc/systemd/system/social-filebrowser.service <<EOF
[Unit]
Description=Social Filebrowser
After=network.target filebrowser.service

[Service]
Type=simple
User=root
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/venv/bin/python app.py
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable social-filebrowser
systemctl start social-filebrowser

# Update Cloudflare tunnel config
echo "🌐 Updating Cloudflare tunnel..."
CONFIG_FILE="/root/.cloudflared/config.yml"

# Backup existing config
cp $CONFIG_FILE ${CONFIG_FILE}.backup

# Read existing config and add new route
python3 <<PYTHON
import yaml

with open('$CONFIG_FILE', 'r') as f:
    config = yaml.safe_load(f)

# Add social filebrowser route before the 404 rule
ingress = config['ingress']
new_route = {
    'hostname': 'share.cloudmc.online',
    'service': 'http://localhost:5001'
}

# Insert before last item (404 rule)
ingress.insert(-1, new_route)

with open('$CONFIG_FILE', 'w') as f:
    yaml.dump(config, f, default_flow_style=False)

print("✓ Cloudflare config updated")
PYTHON

# Restart cloudflared
systemctl restart cloudflared

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Social Filebrowser installed successfully!"
echo ""
echo "🌐 Access at: https://share.cloudmc.online"
echo ""
echo "Features:"
echo "  ✅ Friends sidebar with online/offline status"
echo "  ✅ Right-click friends to send files"
echo "  ✅ Real-time notifications"
echo "  ✅ File transfers work even when offline"
echo "  ✅ Embedded Filebrowser interface"
echo ""
echo "📋 Service commands:"
echo "  sudo systemctl status social-filebrowser"
echo "  sudo systemctl restart social-filebrowser"
echo "  sudo journalctl -u social-filebrowser -f"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
