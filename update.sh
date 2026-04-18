#!/bin/bash

# Update script - Re-downloads latest installer from GitHub
# Usage: sudo bash update.sh

set -e

REPO_URL="https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main"
INSTALL_DIR="/opt/ptero"

clear
echo ""
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                          ║"
echo "║              🔄 PTERODACTYL INSTALLER UPDATE 🔄                          ║"
echo "║                                                                          ║"
echo "║                    Checking for updates...                               ║"
echo "║                                                                          ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "  ❌ This script must be run as root"
   echo ""
   echo "  Run: sudo bash update.sh"
   echo ""
   exit 1
fi

# Check if installer exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo "  ⚠️  Installer not found at $INSTALL_DIR"
    echo ""
    echo "  Would you like to install it now?"
    read -p "  ▸ Install Pterodactyl installer? (y/n): " install_choice
    
    if [[ $install_choice =~ ^[Yy]$ ]]; then
        echo ""
        echo "  📥 Running installer..."
        echo ""
        curl -sSL "$REPO_URL/install.sh" | bash
        exit 0
    else
        echo ""
        echo "  ℹ️  Installation cancelled"
        exit 0
    fi
fi

# Run the installer (which will check for updates)
echo "  🔄 Running update check..."
echo ""

cd "$INSTALL_DIR"
curl -sSL "$REPO_URL/install.sh" | bash

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                          ║"
echo "║                    ✅ UPDATE CHECK COMPLETE! ✅                          ║"
echo "║                                                                          ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""
