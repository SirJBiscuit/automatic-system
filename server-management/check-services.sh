#!/bin/bash

# Check All Services Status
# Verifies all services are running after boot

echo "🔍 Checking Server Services Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Function to check service status
check_service() {
    local service=$1
    local name=$2
    
    if systemctl is-active --quiet $service; then
        echo "✅ $name - Running"
        return 0
    else
        echo "❌ $name - Stopped"
        return 1
    fi
}

# Function to check Docker container
check_docker() {
    local container=$1
    local name=$2
    
    if docker ps --format '{{.Names}}' | grep -q "$container"; then
        echo "✅ $name - Running"
        return 0
    else
        echo "❌ $name - Stopped"
        return 1
    fi
}

echo "📋 Systemd Services:"
echo ""
check_service cloudflared "Cloudflare Tunnel"
check_service filebrowser "Filebrowser"
check_service filebrowser-admin "Filebrowser Admin Panel"
check_service wings "Wings (Pterodactyl)"
check_service docker "Docker"

echo ""
echo "🐳 Docker Containers:"
echo ""

if command -v docker &> /dev/null; then
    check_docker "pingvin-share" "Pingvin Share"
    check_docker "nextcloud" "Nextcloud"
    check_docker "nextcloud-db" "Nextcloud Database"
    check_docker "nextcloud-redis" "Nextcloud Redis"
else
    echo "⚠️  Docker not installed"
fi

echo ""
echo "💾 Disk Usage:"
echo ""
df -h | grep -E "Filesystem|/$|/mnt|/media" | grep -v tmpfs

echo ""
echo "🌐 Network Ports:"
echo ""
echo "Port 5050: Pingvin Share"
echo "Port 5051: Nextcloud"
echo "Port 5002: Filebrowser Admin"
echo "Port 8090: Filebrowser"
echo "Port 8081: Pterodactyl Console"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
