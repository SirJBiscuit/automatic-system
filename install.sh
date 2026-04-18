#!/bin/bash

# Quick installer script - downloads and runs automatic-system from GitHub
# Usage: curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/install.sh | sudo bash

set -e

REPO_URL="https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main"
INSTALL_DIR="/opt/ptero"
VERSION_FILE="$INSTALL_DIR/.version"
REMOTE_VERSION_URL="$REPO_URL/VERSION"

clear
echo ""
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                          ║"
echo "║              🚀 PTERODACTYL UNIVERSAL INSTALLER 🚀                       ║"
echo "║                                                                          ║"
echo "║                    Automated Installation System                         ║"
echo "║                    Version 1.1.0 | SirJBiscuit                          ║"
echo "║                                                                          ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "  📥 Downloading latest scripts from GitHub..."
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

echo "[INFO] Creating installation directory..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Check for existing installation
if [ -f "$INSTALL_DIR/pteroanyinstall.sh" ]; then
    echo "[INFO] Existing installation detected!"
    echo ""
    
    # Check for updates
    if [ -f "$VERSION_FILE" ]; then
        LOCAL_VERSION=$(cat "$VERSION_FILE")
        REMOTE_VERSION=$(curl -sSL "$REMOTE_VERSION_URL" 2>/dev/null || echo "unknown")
        
        echo "[INFO] Local version: $LOCAL_VERSION"
        echo "[INFO] Remote version: $REMOTE_VERSION"
        echo ""
        
        if [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ] && [ "$REMOTE_VERSION" != "unknown" ]; then
            echo "[UPDATE] New version available!"
            echo ""
            read -p "Update to version $REMOTE_VERSION? (y/n): " update_choice
            
            if [[ $update_choice =~ ^[Yy]$ ]]; then
                echo "[INFO] Updating scripts..."
            else
                echo "[INFO] Skipping update. Using existing installation."
                echo ""
                echo "To update later, run: sudo bash $INSTALL_DIR/install.sh"
                exit 0
            fi
        else
            echo "[INFO] Scripts are up to date!"
            echo ""
            read -p "Re-download scripts anyway? (y/n): " redownload_choice
            
            if [[ ! $redownload_choice =~ ^[Yy]$ ]]; then
                echo "[INFO] Using existing installation."
                exit 0
            fi
        fi
    else
        echo "[INFO] Version file not found. Updating scripts..."
    fi
    echo ""
fi

echo "[INFO] Downloading scripts from GitHub..."

# Download main scripts
curl -sSL "$REPO_URL/pteroanyinstall.sh" -o pteroanyinstall.sh
curl -sSL "$REPO_URL/pre-install-checks.sh" -o pre-install-checks.sh
curl -sSL "$REPO_URL/billing-setup.sh" -o billing-setup.sh
curl -sSL "$REPO_URL/panel-customizer.sh" -o panel-customizer.sh
curl -sSL "$REPO_URL/quick-setup.sh" -o quick-setup.sh
curl -sSL "$REPO_URL/ptero-admin.sh" -o ptero-admin.sh
curl -sSL "$REPO_URL/ai-assistant-setup.sh" -o ai-assistant-setup.sh
curl -sSL "$REPO_URL/prism-upgrade.sh" -o prism-upgrade.sh
curl -sSL "$REPO_URL/prism-enhanced.py" -o prism-enhanced.py
curl -sSL "$REPO_URL/prism-cli.sh" -o prism-cli.sh
curl -sSL "$REPO_URL/node-installer.sh" -o node-installer.sh
curl -sSL "$REPO_URL/cloud-backup.sh" -o cloud-backup.sh

# Make executable
chmod +x pteroanyinstall.sh
chmod +x pre-install-checks.sh
chmod +x billing-setup.sh
chmod +x panel-customizer.sh
chmod +x quick-setup.sh
chmod +x ptero-admin.sh
chmod +x ai-assistant-setup.sh
chmod +x prism-upgrade.sh
chmod +x prism-enhanced.py
chmod +x prism-cli.sh
chmod +x node-installer.sh
chmod +x cloud-backup.sh

# Download and save version
curl -sSL "$REMOTE_VERSION_URL" -o "$VERSION_FILE" 2>/dev/null || echo "1.0.0" > "$VERSION_FILE"

clear
echo ""
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                          ║"
echo "║                    ✅ INSTALLATION SUCCESSFUL! ✅                        ║"
echo "║                                                                          ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""
if [ -f "$VERSION_FILE" ]; then
    echo "  📌 Version: $(cat $VERSION_FILE)"
    echo "  📂 Location: $INSTALL_DIR"
    echo ""
fi
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                         AVAILABLE COMMANDS                               ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "┌──────────────────────────────────────────────────────────────────────────┐"
echo "│ 📦 INSTALLATION                                                          │"
echo "└──────────────────────────────────────────────────────────────────────────┘"
echo ""
echo "  First, navigate to installation directory:"
echo "  $ cd $INSTALL_DIR"
echo ""
echo "  ▸ ./pteroanyinstall.sh install-panel    Install Panel only"
echo "  ▸ ./pteroanyinstall.sh install-wings    Install Wings only"
echo "  ▸ ./pteroanyinstall.sh install-full     Install both (⭐ recommended)"
echo ""
echo "┌──────────────────────────────────────────────────────────────────────────┐"
echo "│ ⚙️  MANAGEMENT & MAINTENANCE                                             │"
echo "└──────────────────────────────────────────────────────────────────────────┘"
echo ""
echo "  ▸ ./pteroanyinstall.sh update           Update all components"
echo "  ▸ ./pteroanyinstall.sh health-check     Check system status"
echo "  ▸ ./pteroanyinstall.sh scan             Scan and fix issues"
echo "  ▸ ./pteroanyinstall.sh backup           Run backup"
echo "  ▸ ./pteroanyinstall.sh clean            Clean cache and logs"
echo ""
echo "┌──────────────────────────────────────────────────────────────────────────┐"
echo "│ ☁️  CLOUD BACKUPS                                                        │"
echo "└──────────────────────────────────────────────────────────────────────────┘"
echo ""
echo "  ▸ ./cloud-backup.sh                     Interactive backup menu"
echo "  ▸ ./cloud-backup.sh gdrive              Google Drive backup"
echo "  ▸ ./cloud-backup.sh b2                  Backblaze B2 backup"
echo "  ▸ ./cloud-backup.sh mega                Mega.nz backup"
echo ""
echo "┌──────────────────────────────────────────────────────────────────────────┐"
echo "│ 🎨 CUSTOMIZATION                                                         │"
echo "└──────────────────────────────────────────────────────────────────────────┘"
echo ""
echo "  ▸ ./pteroanyinstall.sh customize        Customize Panel appearance"
echo "  ▸ ./panel-customizer.sh                 Direct customization tool"
echo ""
echo "┌──────────────────────────────────────────────────────────────────────────┐"
echo "│ 🤖 AI ASSISTANT (P.R.I.S.M)                                              │"
echo "└──────────────────────────────────────────────────────────────────────────┘"
echo ""
echo "  ▸ ./pteroanyinstall.sh ai-assistant     Install P.R.I.S.M AI"
echo "  ▸ ./pteroanyinstall.sh prism-upgrade    Upgrade to Enhanced version"
echo ""
echo "  After P.R.I.S.M installation:"
echo "    • chatbot status                      Check if running"
echo "    • chatbot ask \"question\"              Ask AI anything"
echo "    • chatbot detect                      Run system analysis"
echo "    • chatbot webhook setup               Set up Discord alerts"
echo "    • chatbot api setup                   Set up API integration"
echo ""
echo "┌──────────────────────────────────────────────────────────────────────────┐"
echo "│ 🖥️  ADDITIONAL NODES                                                     │"
echo "└──────────────────────────────────────────────────────────────────────────┘"
echo ""
echo "  ▸ ./node-installer.sh                   Install Wings on extra servers"
echo ""
echo "┌──────────────────────────────────────────────────────────────────────────┐"
echo "│ 📚 HELP & DOCUMENTATION                                                  │"
echo "└──────────────────────────────────────────────────────────────────────────┘"
echo ""
echo "  ▸ ./pteroanyinstall.sh help             Show all available commands"
echo ""
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                          ║"
echo "║                    🚀 QUICK START GUIDE 🚀                               ║"
echo "║                                                                          ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "  Step 1 │ Run pre-installation checks"
echo "         └─▸ cd $INSTALL_DIR && ./pteroanyinstall.sh pre-check"
echo ""
echo "  Step 2 │ Install Pterodactyl (Panel + Wings)"
echo "         └─▸ ./pteroanyinstall.sh install-full"
echo ""
echo "  Step 3 │ Install P.R.I.S.M AI Assistant (Optional)"
echo "         └─▸ ./pteroanyinstall.sh ai-assistant"
echo ""
echo "  Step 4 │ Run post-installation setup"
echo "         └─▸ ./pteroanyinstall.sh quick-setup"
echo ""
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                          ║"
echo "║  🎉 Ready to install! Follow the steps above to get started.            ║"
echo "║                                                                          ║"
echo "║  💡 Need help? Run: ./pteroanyinstall.sh help                           ║"
echo "║                                                                          ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""
