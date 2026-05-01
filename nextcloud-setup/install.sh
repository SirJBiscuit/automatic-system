#!/bin/bash

# Nextcloud Installation Script
# Full-featured cloud storage with chat, file sharing, and collaboration

set -e

echo "☁️  Installing Nextcloud..."
echo ""

# Create installation directory
INSTALL_DIR="/opt/nextcloud"
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# Create docker-compose.yml
echo "📝 Creating docker-compose configuration..."
cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  nextcloud-db:
    image: mariadb:10.11
    restart: unless-stopped
    command: --transaction-isolation=READ-COMMITTED --log-bin=binlog --binlog-format=ROW
    volumes:
      - ./db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=nextcloud_root_pass_change_me
      - MYSQL_PASSWORD=nextcloud_db_pass_change_me
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MARIADB_AUTO_UPGRADE=1
      - MARIADB_DISABLE_UPGRADE_BACKUP=1

  nextcloud-redis:
    image: redis:alpine
    restart: unless-stopped

  nextcloud:
    image: nextcloud:latest
    restart: unless-stopped
    ports:
      - "5051:80"
    volumes:
      - ./data:/var/www/html
    environment:
      - MYSQL_HOST=nextcloud-db
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_PASSWORD=nextcloud_db_pass_change_me
      - REDIS_HOST=nextcloud-redis
      - NEXTCLOUD_TRUSTED_DOMAINS=next.cloudmc.online localhost
      - OVERWRITEPROTOCOL=https
      - OVERWRITEHOST=next.cloudmc.online
    depends_on:
      - nextcloud-db
      - nextcloud-redis
EOF

# Create data directories
mkdir -p db data

# Pull and start
echo "🐳 Pulling Docker images and starting services..."
docker-compose pull
docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for Nextcloud to initialize (this may take a minute)..."
sleep 30

# Check if running
if docker-compose ps | grep -q "Up"; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "✅ Nextcloud installed successfully!"
    echo ""
    echo "🌐 Access at: http://localhost:5051"
    echo ""
    echo "📋 Next Steps:"
    echo "   1. Add to Cloudflare tunnel (next.cloudmc.online → localhost:5051)"
    echo "   2. Visit https://next.cloudmc.online"
    echo "   3. Create admin account on first visit"
    echo "   4. Install recommended apps:"
    echo "      • Talk (chat & video calls)"
    echo "      • Deck (kanban boards)"
    echo "      • Calendar & Contacts"
    echo ""
    echo "🎨 Features:"
    echo "   ✅ Full file management"
    echo "   ✅ Built-in chat & video calls"
    echo "   ✅ File sharing with users"
    echo "   ✅ Calendar & contacts"
    echo "   ✅ Office document editing"
    echo "   ✅ Mobile apps available"
    echo "   ✅ Extensible with apps"
    echo ""
    echo "📋 Management Commands:"
    echo "   cd $INSTALL_DIR"
    echo "   docker-compose logs -f nextcloud     # View logs"
    echo "   docker-compose restart               # Restart all services"
    echo "   docker-compose stop                  # Stop all services"
    echo "   docker-compose start                 # Start all services"
    echo ""
    echo "🔧 Add to Cloudflare tunnel config:"
    echo "   Edit: /root/.cloudflared/config.yml"
    echo "   Add before the 404 line:"
    echo "     - hostname: next.cloudmc.online"
    echo "       service: http://localhost:5051"
    echo "   Then: sudo systemctl restart cloudflared"
    echo ""
    echo "💡 Tips:"
    echo "   • First login creates admin account"
    echo "   • Install 'Talk' app for chat features"
    echo "   • Enable 2FA in security settings"
    echo "   • Configure email in admin settings"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
else
    echo ""
    echo "❌ Service failed to start. Check logs:"
    echo "   cd $INSTALL_DIR && docker-compose logs"
    exit 1
fi
