#!/bin/bash

echo "=========================================="
echo "  Ollama + Open WebUI Quick Installer"
echo "=========================================="
echo ""
echo "This will download and run the automated"
echo "Ollama setup script from GitHub."
echo ""

REPO_URL="https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/ollama-setup/ollama-webui-setup.sh"
SCRIPT_NAME="ollama-webui-setup.sh"

echo "Downloading setup script..."
if curl -fsSL "$REPO_URL" -o "$SCRIPT_NAME"; then
    echo "✓ Downloaded successfully"
    chmod +x "$SCRIPT_NAME"
    echo ""
    echo "Starting installation..."
    echo ""
    ./"$SCRIPT_NAME"
else
    echo "✗ Failed to download script"
    echo ""
    echo "Manual installation:"
    echo "  wget https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/ollama-setup/ollama-webui-setup.sh"
    echo "  chmod +x ollama-webui-setup.sh"
    echo "  ./ollama-webui-setup.sh"
    exit 1
fi
