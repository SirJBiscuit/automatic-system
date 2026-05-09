#!/bin/bash

# Quick Installer for Pterodactyl Automatic System
# This script clones the repo and runs the installer

set -e

echo "=========================================="
echo "  Pterodactyl Automatic System v2.0"
echo "=========================================="
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Installing git..."
    apt-get update -qq
    apt-get install -y git
fi

# Remove old clone if exists
if [ -d "automatic-system" ]; then
    echo "Removing old installation..."
    rm -rf automatic-system
fi

# Clone repository
echo "Downloading installer..."
git clone https://github.com/SirJBiscuit/automatic-system.git

# Enter directory
cd automatic-system

# Make scripts executable
chmod +x *.sh

# Run installer
echo ""
echo "Starting installer..."
echo ""
bash installer.sh
