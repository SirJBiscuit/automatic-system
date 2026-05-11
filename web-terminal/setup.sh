#!/bin/bash
# Enhanced Web Terminal Setup Script

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 Enhanced Web Terminal Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root (use sudo)"
    exit 1
fi

# Install nginx if not installed
if ! command -v nginx &> /dev/null; then
    echo "📦 Installing nginx..."
    apt update
    apt install -y nginx
    echo "✅ nginx installed"
else
    echo "✅ nginx already installed"
fi

# Create directory for enhanced terminal
INSTALL_DIR="/var/www/enhanced-terminal"
echo ""
echo "📁 Creating directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Copy files
echo "📋 Copying enhanced terminal files..."
cp index.html "$INSTALL_DIR/"
echo "✅ Files copied"

# Create nginx config
echo ""
echo "⚙️  Creating nginx configuration..."
cat > /etc/nginx/sites-available/enhanced-terminal <<'EOF'
server {
    listen 8095;
    server_name localhost;
    
    # Serve the enhanced terminal interface
    root /var/www/enhanced-terminal;
    index index.html;

    # Main page
    location / {
        try_files $uri $uri/ =404;
    }

    # Proxy ttyd terminal to /terminal path
    location /terminal {
        proxy_pass http://127.0.0.1:7681;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
    }

    # Proxy WebSocket connections
    location /ws {
        proxy_pass http://127.0.0.1:7681;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400;
    }

    # Proxy token endpoint
    location /token {
        proxy_pass http://127.0.0.1:7681;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
}
EOF

# Enable site
echo "🔗 Enabling nginx site..."
ln -sf /etc/nginx/sites-available/enhanced-terminal /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test nginx config
echo ""
echo "🧪 Testing nginx configuration..."
if nginx -t; then
    echo "✅ nginx configuration is valid"
else
    echo "❌ nginx configuration has errors!"
    exit 1
fi

# Restart nginx
echo ""
echo "🔄 Restarting nginx..."
systemctl restart nginx
systemctl enable nginx

# Check if nginx is running
if systemctl is-active --quiet nginx; then
    echo "✅ nginx is running"
else
    echo "❌ nginx failed to start!"
    systemctl status nginx
    exit 1
fi

# Update Cloudflare tunnel config
echo ""
echo "⚙️  Updating Cloudflare tunnel configuration..."

TUNNEL_ID=$(cat /etc/cloudflared/ssh-tunnel-id.txt 2>/dev/null || echo "")
if [ -z "$TUNNEL_ID" ]; then
    echo "⚠️  Could not find tunnel ID. Please update manually."
else
    cat > /etc/cloudflared/ssh-tunnel.yml <<EOF
tunnel: $TUNNEL_ID
credentials-file: /root/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: termux.cloudmc.online
    service: http://localhost:8095
  - service: http_status:404
EOF
    
    echo "✅ Tunnel config updated"
    
    # Restart cloudflared
    echo "🔄 Restarting Cloudflare tunnel..."
    systemctl restart cloudflared-ssh
    
    sleep 3
    if systemctl is-active --quiet cloudflared-ssh; then
        echo "✅ Cloudflare tunnel is running"
    else
        echo "⚠️  Cloudflare tunnel may not be running"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Enhanced Web Terminal Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Open in your browser:"
echo "   https://termux.cloudmc.online"
echo ""
echo "📊 Service Status:"
echo "   nginx:       $(systemctl is-active nginx)"
echo "   ttyd:        $(systemctl is-active ttyd-ssh)"
echo "   cloudflared: $(systemctl is-active cloudflared-ssh)"
echo ""
echo "🔧 Manage Services:"
echo "   systemctl status nginx"
echo "   systemctl status ttyd-ssh"
echo "   systemctl status cloudflared-ssh"
echo ""
