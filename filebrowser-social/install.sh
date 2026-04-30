#!/bin/bash

# Filebrowser Social Plugin Installer
# Adds friends, chat, and file sharing features to filebrowser

set -e

echo "🚀 Installing Filebrowser Social Plugin..."
echo ""

# Check if filebrowser is installed
if ! command -v filebrowser &> /dev/null; then
    echo "❌ Filebrowser not found. Please install filebrowser first."
    exit 1
fi

# Check if filebrowser is running
if ! systemctl is-active --quiet filebrowser; then
    echo "⚠️  Filebrowser service is not running. Starting it..."
    systemctl start filebrowser
fi

# Create branding directory
BRANDING_DIR="/etc/filebrowser/branding"
echo "📁 Creating branding directory..."
mkdir -p $BRANDING_DIR

# Copy custom files
echo "📄 Installing social plugin files..."
cp custom.js $BRANDING_DIR/
cp custom.css $BRANDING_DIR/

# Set permissions
chmod 644 $BRANDING_DIR/custom.js
chmod 644 $BRANDING_DIR/custom.css

# Configure filebrowser to use custom branding
echo "⚙️  Configuring filebrowser..."
filebrowser config set --branding.files $BRANDING_DIR --database=/etc/filebrowser/filebrowser.db

# Restart filebrowser
echo "🔄 Restarting filebrowser..."
systemctl restart filebrowser

# Wait for service to start
sleep 2

# Check if service is running
if systemctl is-active --quiet filebrowser; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "✅ Filebrowser Social Plugin installed successfully!"
    echo ""
    echo "🎨 Features Added:"
    echo "   ✅ Friends sidebar (left side of screen)"
    echo "   ✅ Online/offline status indicators"
    echo "   ✅ Chat panel (click 💬 Chat button)"
    echo "   ✅ File sharing (right-click files)"
    echo "   ✅ Context menu enhancements"
    echo ""
    echo "📋 How to Use:"
    echo "   1. Access your filebrowser at https://share.cloudmc.online"
    echo "   2. Click the ➕ button to add friends"
    echo "   3. Right-click files to share with friends"
    echo "   4. Click 💬 Chat to open chat panel"
    echo "   5. See who's online in the friends sidebar"
    echo ""
    echo "💡 Tips:"
    echo "   • Friends are stored locally in browser"
    echo "   • Online status updates every 30 seconds"
    echo "   • Chat messages are saved in browser storage"
    echo "   • File transfers show as notifications"
    echo ""
    echo "🔧 Service Status:"
    echo "   sudo systemctl status filebrowser"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
else
    echo ""
    echo "❌ Installation completed but filebrowser failed to start."
    echo "   Check logs: sudo journalctl -u filebrowser -n 50"
    exit 1
fi
