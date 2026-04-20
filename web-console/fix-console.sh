#!/bin/bash
# Fix Web Console Bad Gateway Issues
# This script diagnoses and fixes common web console problems

set -e

echo "🔧 P.R.I.S.M Web Console Fix Tool"
echo "=================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Please run as root (use sudo)${NC}"
    exit 1
fi

INSTALL_DIR="/opt/pterodactyl-web-console"

echo "📋 Diagnostic Check..."
echo ""

# 1. Check if directory exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${RED}❌ Web console not installed at $INSTALL_DIR${NC}"
    echo "Run: cd /opt/ptero && ./ptero.sh (option 19)"
    exit 1
fi

cd "$INSTALL_DIR"

# 2. Check if service exists
if ! systemctl list-unit-files | grep -q "pterodactyl-web-console.service"; then
    echo -e "${YELLOW}⚠️  Service not found, creating...${NC}"
    
    cat > /etc/systemd/system/pterodactyl-web-console.service << 'EOF'
[Unit]
Description=Pterodactyl Web Console
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/pterodactyl-web-console
Environment="PATH=/usr/bin:/usr/local/bin"
ExecStart=/usr/bin/python3 /opt/pterodactyl-web-console/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    echo -e "${GREEN}✅ Service created${NC}"
fi

# 3. Check Python dependencies
echo "📦 Checking Python dependencies..."
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt -q
    echo -e "${GREEN}✅ Dependencies installed${NC}"
fi

# 4. Check .env file
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  No .env file found, creating from example...${NC}"
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${GREEN}✅ Created .env file${NC}"
        echo -e "${YELLOW}⚠️  Please edit .env with your settings!${NC}"
    fi
fi

# 5. Check if app.py is executable and has proper shebang
if [ -f "app.py" ]; then
    if ! head -n 1 app.py | grep -q "#!/usr/bin/env python3"; then
        echo -e "${YELLOW}⚠️  Adding shebang to app.py...${NC}"
        sed -i '1i#!/usr/bin/env python3' app.py
    fi
    chmod +x app.py
    echo -e "${GREEN}✅ app.py configured${NC}"
fi

# 6. Check port 8080
echo "🔍 Checking port 8080..."
if netstat -tuln | grep -q ":8080 "; then
    echo -e "${YELLOW}⚠️  Port 8080 is in use${NC}"
    echo "Processes using port 8080:"
    lsof -i :8080 || netstat -tulnp | grep :8080
    echo ""
    read -p "Kill existing process and restart? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        fuser -k 8080/tcp 2>/dev/null || true
        sleep 2
        echo -e "${GREEN}✅ Port cleared${NC}"
    fi
else
    echo -e "${GREEN}✅ Port 8080 available${NC}"
fi

# 7. Restart service
echo ""
echo "🔄 Restarting web console service..."
systemctl stop pterodactyl-web-console 2>/dev/null || true
sleep 2
systemctl start pterodactyl-web-console
systemctl enable pterodactyl-web-console
sleep 3

# 8. Check service status
if systemctl is-active --quiet pterodactyl-web-console; then
    echo -e "${GREEN}✅ Service is running${NC}"
else
    echo -e "${RED}❌ Service failed to start${NC}"
    echo "Checking logs..."
    journalctl -u pterodactyl-web-console -n 20 --no-pager
    exit 1
fi

# 9. Test local connection
echo ""
echo "🧪 Testing local connection..."
sleep 2
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|302"; then
    echo -e "${GREEN}✅ Local connection working${NC}"
else
    echo -e "${RED}❌ Local connection failed${NC}"
    echo "Checking logs..."
    journalctl -u pterodactyl-web-console -n 30 --no-pager
fi

# 10. Check Cloudflare Tunnel
echo ""
echo "🌐 Checking Cloudflare Tunnel..."
if systemctl list-unit-files | grep -q "cloudflared.service"; then
    if systemctl is-active --quiet cloudflared; then
        echo -e "${GREEN}✅ Cloudflare Tunnel is running${NC}"
    else
        echo -e "${YELLOW}⚠️  Cloudflare Tunnel is not running${NC}"
        read -p "Start Cloudflare Tunnel? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            systemctl start cloudflared
            systemctl enable cloudflared
            echo -e "${GREEN}✅ Cloudflare Tunnel started${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  Cloudflare Tunnel not configured${NC}"
    echo "To set up Cloudflare Tunnel, run: ./setup-access.sh"
fi

# 11. Show access information
echo ""
echo "=================================="
echo -e "${GREEN}🎉 Web Console Status${NC}"
echo "=================================="
echo ""
echo "📍 Local Access:"
echo "   http://$(hostname -I | awk '{print $1}'):8080"
echo "   http://localhost:8080"
echo ""

if systemctl is-active --quiet cloudflared 2>/dev/null; then
    echo "🌐 Remote Access:"
    echo "   https://console.cloudmc.online"
    echo "   (or your configured domain)"
    echo ""
fi

echo "🔑 Default Credentials:"
echo "   Username: admin"
echo "   Password: changeme"
echo "   (Change in .env file)"
echo ""
echo "📊 Service Status:"
systemctl status pterodactyl-web-console --no-pager -l | head -n 10
echo ""
echo "📝 View Logs:"
echo "   journalctl -u pterodactyl-web-console -f"
echo ""
echo "🔧 Troubleshooting:"
echo "   1. Check .env file has correct API key"
echo "   2. Ensure Pterodactyl panel is accessible"
echo "   3. Check firewall allows port 8080"
echo "   4. Review logs for errors"
echo ""
echo -e "${GREEN}✅ Fix complete!${NC}"
