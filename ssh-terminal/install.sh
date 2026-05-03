#!/bin/bash

# SSH Web Terminal Installer

set -e

echo "💻 Installing SSH Web Terminal..."
echo ""

# Install dependencies
echo "Installing dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv

# Create app directory
APP_DIR="/opt/ssh-terminal"
mkdir -p $APP_DIR

# Copy files
echo "📁 Copying files..."
cp app.py $APP_DIR/
cp requirements.txt $APP_DIR/
cp -r templates $APP_DIR/

# Create virtual environment
echo "🐍 Setting up Python environment..."
cd $APP_DIR
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Create systemd service
echo "⚙️  Creating systemd service..."
cat > /etc/systemd/system/ssh-terminal.service << 'EOF'
[Unit]
Description=SSH Web Terminal
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ssh-terminal
Environment="PATH=/opt/ssh-terminal/venv/bin"
ExecStart=/opt/ssh-terminal/venv/bin/python app.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable ssh-terminal
systemctl start ssh-terminal

echo ""
echo "✅ SSH Web Terminal installed successfully!"
echo ""
echo "📋 Service Information:"
echo "   • Service: ssh-terminal"
echo "   • Port: 5003"
echo "   • Location: /opt/ssh-terminal"
echo ""
echo "🔐 Default Credentials:"
echo "   • Username: admin"
echo "   • Password: admin123"
echo ""
echo "🌐 Access via:"
echo "   • http://localhost:5003"
echo "   • Configure Cloudflare Tunnel for ssh.cloudmc.online"
echo ""
echo "📝 Useful Commands:"
echo "   • Status: systemctl status ssh-terminal"
echo "   • Restart: systemctl restart ssh-terminal"
echo "   • Logs: journalctl -u ssh-terminal -f"
echo ""
