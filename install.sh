#!/bin/bash

# Quick installer script - downloads and runs automatic-system from GitHub
# Usage: curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/install.sh | sudo bash

set -e

REPO_URL="https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main"
INSTALL_DIR="/opt/ptero"
VERSION_FILE="$INSTALL_DIR/.version"
REMOTE_VERSION_URL="$REPO_URL/VERSION"

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║              Pterodactyl Universal Installer (automatic-system)         ║"
echo "║                    Quick Install from GitHub                           ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
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

echo "[SUCCESS] Scripts downloaded successfully!"
if [ -f "$VERSION_FILE" ]; then
    echo "[INFO] Version: $(cat $VERSION_FILE)"
fi
echo ""
echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║                      AVAILABLE COMMANDS                                ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "📦 INSTALLATION:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  cd $INSTALL_DIR"
echo ""
echo "  ./pteroanyinstall.sh install-panel      # Install Panel only"
echo "  ./pteroanyinstall.sh install-wings      # Install Wings only"
echo "  ./pteroanyinstall.sh install-full       # Install both (recommended)"
echo ""
echo "⚙️  MANAGEMENT:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ./pteroanyinstall.sh update             # Update all components"
echo "  ./pteroanyinstall.sh health-check       # Check system status"
echo "  ./pteroanyinstall.sh scan               # Scan and fix issues"
echo "  ./pteroanyinstall.sh backup             # Run backup"
echo "  ./pteroanyinstall.sh clean              # Clean cache and logs"
echo ""
echo "☁️  CLOUD BACKUPS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ./cloud-backup.sh                       # Backup menu (Google Drive/Mega)"
echo "  ./cloud-backup.sh gdrive                # Backup to Google Drive"
echo "  ./cloud-backup.sh mega                  # Backup to Mega.nz"
echo ""
echo "🎨 CUSTOMIZATION:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ./pteroanyinstall.sh customize          # Customize Panel appearance"
echo "  ./panel-customizer.sh                   # Direct customization"
echo ""
echo "🤖 AI ASSISTANT (P.R.I.S.M):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ./pteroanyinstall.sh ai-assistant       # Install P.R.I.S.M"
echo "  ./pteroanyinstall.sh prism-upgrade      # Upgrade to Enhanced"
echo ""
echo "  After installation:"
echo "    chatbot status                        # Check if running"
echo "    chatbot ask \"question\"                # Ask AI anything"
echo "    chatbot detect                        # Run system analysis"
echo "    chatbot webhook setup                 # Set up Discord"
echo "    chatbot api setup                     # Set up API"
echo "    chatbot help                          # Show all commands"
echo ""
echo "🚀 QUICK START:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ./pteroanyinstall.sh pre-check          # Run pre-checks"
echo "  ./pteroanyinstall.sh quick-setup        # Post-install essentials"
echo "  ./pteroanyinstall.sh admin              # Launch admin panel"
echo ""
echo "🖥️  ADDITIONAL NODES:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ./node-installer.sh                      # Install Wings on extra servers"
echo ""
echo "📚 HELP:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ./pteroanyinstall.sh help               # Show all commands"
echo ""
echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║                     RECOMMENDED INSTALLATION                           ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "1️⃣  Run pre-checks:"
echo "   cd $INSTALL_DIR && ./pteroanyinstall.sh pre-check"
echo ""
echo "2️⃣  Install Pterodactyl:"
echo "   ./pteroanyinstall.sh install-full"
echo ""
echo "3️⃣  Install P.R.I.S.M AI:"
echo "   ./pteroanyinstall.sh ai-assistant"
echo ""
echo "4️⃣  Run quick setup:"
echo "   ./pteroanyinstall.sh quick-setup"
echo ""
echo "🎉 You're ready to go!"
echo ""
