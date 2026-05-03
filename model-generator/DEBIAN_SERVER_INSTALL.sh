#!/bin/bash
# 3D Model Generator - Debian 12 Server Installation
# This script installs the app in an isolated environment to avoid conflicts

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════╗"
echo "║    3D Model Generator - Debian 12 Installation        ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Configuration - ISOLATED from pteroanyinstall (/opt/ptero)
APP_DIR="/opt/model-generator"  # Different from /opt/ptero
APP_USER="modelgen"              # Different from pterodactyl user
VENV_DIR="$APP_DIR/venv"
PORT=5050  # Different from pterodactyl ports (80, 443, 8080)

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root (use sudo)"
    exit 1
fi

echo "📋 Installation Configuration:"
echo "   Install Directory: $APP_DIR"
echo "   User: $APP_USER"
echo "   Port: $PORT"
echo "   Python: 3.11"
echo ""
read -p "Continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Step 1: Install system dependencies
echo ""
echo "📦 Step 1/6: Installing system dependencies..."
apt-get update
apt-get install -y \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    python3-pip \
    git \
    wget \
    curl \
    build-essential \
    libgl1-mesa-glx \
    libglib2.0-0 \
    nginx \
    supervisor

echo "✅ System dependencies installed"

# Step 2: Create dedicated user (isolated from other services)
echo ""
echo "👤 Step 2/6: Creating dedicated user..."
if ! id "$APP_USER" &>/dev/null; then
    useradd -r -m -d "$APP_DIR" -s /bin/bash "$APP_USER"
    echo "✅ User '$APP_USER' created"
else
    echo "ℹ️  User '$APP_USER' already exists"
fi

# Step 3: Create application directory
echo ""
echo "📁 Step 3/6: Setting up application directory..."
mkdir -p "$APP_DIR"
cd "$APP_DIR"

# Copy application files (you'll need to upload these)
echo "ℹ️  Upload your application files to: $APP_DIR"
echo "   Required files:"
echo "   - app.py"
echo "   - model_generator.py"
echo "   - prompt_generator.py"
echo "   - triposr_integration.py"
echo "   - requirements.txt"
echo "   - templates/"
echo "   - .env"

# Step 4: Create Python virtual environment (isolated)
echo ""
echo "🐍 Step 4/6: Creating isolated Python environment..."
python3.11 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

# Upgrade pip
pip install --upgrade pip setuptools wheel

echo "✅ Virtual environment created at: $VENV_DIR"

# Step 5: Install Python dependencies
echo ""
echo "📚 Step 5/6: Installing Python packages..."
if [ -f "$APP_DIR/requirements.txt" ]; then
    pip install -r "$APP_DIR/requirements.txt"
    echo "✅ Python packages installed"
else
    echo "⚠️  requirements.txt not found. Install manually later."
fi

# Create necessary directories
mkdir -p "$APP_DIR/outputs"
mkdir -p "$APP_DIR/models"
mkdir -p "$APP_DIR/logs"

# Set permissions
chown -R "$APP_USER:$APP_USER" "$APP_DIR"
chmod 755 "$APP_DIR"

# Step 6: Configure systemd service (isolated service)
echo ""
echo "⚙️  Step 6/6: Configuring systemd service..."

cat > /etc/systemd/system/model-generator.service << EOF
[Unit]
Description=3D Model Generator Service
After=network.target

[Service]
Type=simple
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_DIR
Environment="PATH=$VENV_DIR/bin"
ExecStart=$VENV_DIR/bin/python app.py
Restart=always
RestartSec=10

# Security settings (isolated from other services)
PrivateTmp=true
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$APP_DIR/outputs $APP_DIR/logs $APP_DIR/models

# Resource limits
MemoryLimit=8G
CPUQuota=200%

[Install]
WantedBy=multi-user.target
EOF

# Configure Nginx reverse proxy (separate from other services)
echo ""
echo "🌐 Configuring Nginx reverse proxy..."

cat > /etc/nginx/sites-available/model-generator << EOF
server {
    listen 80;
    server_name _;  # Change to your domain

    client_max_body_size 100M;

    location /model-generator/ {
        proxy_pass http://127.0.0.1:$PORT/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Timeout settings for long-running generation
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
    }
}
EOF

# Enable Nginx site (won't conflict with existing sites)
ln -sf /etc/nginx/sites-available/model-generator /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# Update app.py to use correct port
if [ -f "$APP_DIR/app.py" ]; then
    sed -i "s/app.run(debug=True)/app.run(host='127.0.0.1', port=$PORT, debug=False)/" "$APP_DIR/app.py"
fi

# Enable and start service
systemctl daemon-reload
systemctl enable model-generator
systemctl start model-generator

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║              Installation Complete! 🎉                 ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Service Status:"
systemctl status model-generator --no-pager || true
echo ""
echo "🌐 Access your app at:"
echo "   http://your-server-ip/model-generator/"
echo ""
echo "📝 Useful Commands:"
echo "   Start:   sudo systemctl start model-generator"
echo "   Stop:    sudo systemctl stop model-generator"
echo "   Restart: sudo systemctl restart model-generator"
echo "   Logs:    sudo journalctl -u model-generator -f"
echo "   Status:  sudo systemctl status model-generator"
echo ""
echo "📁 Application Directory: $APP_DIR"
echo "👤 Service User: $APP_USER"
echo "🔌 Port: $PORT (proxied through Nginx)"
echo ""
echo "⚠️  Next Steps:"
echo "   1. Upload your application files to: $APP_DIR"
echo "   2. Create .env file with your settings"
echo "   3. Restart service: sudo systemctl restart model-generator"
echo "   4. Check logs: sudo journalctl -u model-generator -f"
echo ""
