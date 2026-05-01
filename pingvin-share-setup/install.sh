#!/bin/bash

# Pingvin Share Installation Script
# Modern file sharing platform with no database headaches!

set -e

echo "🚀 Installing Pingvin Share..."
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
apt-get update
apt-get install -y docker.io docker-compose git

# Start Docker
systemctl start docker
systemctl enable docker

# Create installation directory
INSTALL_DIR="/opt/pingvin-share"
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# Create docker-compose.yml
echo "📝 Creating docker-compose configuration..."
cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  pingvin-share:
    image: stonith404/pingvin-share:latest
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - ./data:/opt/app/backend/data
      - ./data/images:/opt/app/frontend/public/img
    environment:
      - APPURL=https://share.cloudmc.online
      - DATABASE_URL=file:/opt/app/backend/data/pingvin-share.db
      - ALLOW_REGISTRATION=false
      - ALLOW_UNAUTHENTICATED_SHARES=false
EOF

# Create data directory
mkdir -p data/images

# Pull and start
echo "🐳 Pulling Docker image and starting service..."
docker-compose pull
docker-compose up -d

# Wait for service to start
echo "⏳ Waiting for Pingvin Share to start..."
sleep 10

# Check if running
if docker-compose ps | grep -q "Up"; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "✅ Pingvin Share installed successfully!"
    echo ""
    echo "🌐 Access at: http://localhost:3000"
    echo ""
    echo "📋 Next Steps:"
    echo "   1. Add to Cloudflare tunnel (share.cloudmc.online → localhost:3000)"
    echo "   2. Create admin account on first visit"
    echo "   3. Start sharing files!"
    echo ""
    echo "🎨 Features:"
    echo "   ✅ Beautiful modern UI"
    echo "   ✅ Share links with expiration"
    echo "   ✅ Password protection"
    echo "   ✅ File upload/download"
    echo "   ✅ User management"
    echo "   ✅ No database corruption issues!"
    echo ""
    echo "📋 Management Commands:"
    echo "   cd $INSTALL_DIR"
    echo "   docker-compose logs -f     # View logs"
    echo "   docker-compose restart     # Restart service"
    echo "   docker-compose stop        # Stop service"
    echo "   docker-compose start       # Start service"
    echo ""
    echo "🔧 Update Cloudflare tunnel:"
    echo "   Edit: /root/.cloudflared/config.yml"
    echo "   Change: service: http://localhost:3000"
    echo "   Then: sudo systemctl restart cloudflared"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
else
    echo ""
    echo "❌ Service failed to start. Check logs:"
    echo "   cd $INSTALL_DIR && docker-compose logs"
    exit 1
fi
