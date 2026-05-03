#!/bin/bash

# Safe Server Shutdown Script
# Gracefully stops all services before shutdown

set -e

echo "🛑 Safe Server Shutdown"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Confirm action
read -p "Are you sure you want to shutdown the server? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Shutdown cancelled."
    exit 0
fi

echo ""
echo "📋 Stopping services gracefully..."
echo ""

# Stop Docker containers
if command -v docker &> /dev/null; then
    echo "🐳 Stopping Docker containers..."
    
    # Stop Pingvin Share
    if [ -d "/opt/pingvin-share" ]; then
        echo "  • Stopping Pingvin Share..."
        cd /opt/pingvin-share
        docker-compose stop || true
    fi
    
    # Stop Nextcloud
    if [ -d "/opt/nextcloud" ]; then
        echo "  • Stopping Nextcloud..."
        cd /opt/nextcloud
        docker-compose stop || true
    fi
    
    # Stop all other containers
    echo "  • Stopping remaining Docker containers..."
    docker stop $(docker ps -q) 2>/dev/null || true
fi

# Stop systemd services
echo ""
echo "⚙️  Stopping systemd services..."

# Stop filebrowser-admin
if systemctl is-active --quiet filebrowser-admin; then
    echo "  • Stopping filebrowser-admin..."
    systemctl stop filebrowser-admin
fi

# Stop filebrowser
if systemctl is-active --quiet filebrowser; then
    echo "  • Stopping filebrowser..."
    systemctl stop filebrowser
fi

# Stop cloudflared
if systemctl is-active --quiet cloudflared; then
    echo "  • Stopping cloudflared..."
    systemctl stop cloudflared
fi

# Stop Wings (Pterodactyl)
if systemctl is-active --quiet wings; then
    echo "  • Stopping Wings (Pterodactyl)..."
    systemctl stop wings
fi

# Sync filesystems
echo ""
echo "💾 Syncing filesystems..."
sync

echo ""
echo "✅ All services stopped gracefully!"
echo ""
echo "🛑 Shutting down in 5 seconds..."
echo "   Press Ctrl+C to cancel"
sleep 5

shutdown -h now
