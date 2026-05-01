#!/bin/bash

# Pingvin Share Uninstall Script

set -e

echo "🗑️  Uninstalling Pingvin Share..."
echo ""

INSTALL_DIR="/opt/pingvin-share"

if [ -d "$INSTALL_DIR" ]; then
    cd $INSTALL_DIR
    
    # Stop and remove containers
    echo "Stopping containers..."
    docker-compose down
    
    # Ask about data
    read -p "Delete all data? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing data..."
        rm -rf data
    else
        echo "Data preserved in $INSTALL_DIR/data"
    fi
    
    # Remove installation
    cd /
    rm -rf $INSTALL_DIR
    
    echo ""
    echo "✅ Pingvin Share uninstalled!"
else
    echo "Pingvin Share not found at $INSTALL_DIR"
fi
