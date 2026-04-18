#!/bin/bash

# Quick installer script - downloads and runs automatic-system from GitHub
# Usage: curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/install.sh | sudo bash

set -e

REPO_URL="https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main"
INSTALL_DIR="/opt/ptero"

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

echo "[INFO] Downloading scripts from GitHub..."

# Download main scripts
curl -sSL "$REPO_URL/automatic-system.sh" -o automatic-system.sh
curl -sSL "$REPO_URL/pre-install-checks.sh" -o pre-install-checks.sh
curl -sSL "$REPO_URL/billing-setup.sh" -o billing-setup.sh
curl -sSL "$REPO_URL/panel-customizer.sh" -o panel-customizer.sh
curl -sSL "$REPO_URL/quick-setup.sh" -o quick-setup.sh
curl -sSL "$REPO_URL/ptero-admin.sh" -o ptero-admin.sh
curl -sSL "$REPO_URL/ai-assistant-setup.sh" -o ai-assistant-setup.sh
curl -sSL "$REPO_URL/prism-upgrade.sh" -o prism-upgrade.sh
curl -sSL "$REPO_URL/prism-enhanced.py" -o prism-enhanced.py
curl -sSL "$REPO_URL/prism-cli.sh" -o prism-cli.sh

# Make executable
chmod +x automatic-system.sh
chmod +x pre-install-checks.sh
chmod +x billing-setup.sh
chmod +x panel-customizer.sh
chmod +x quick-setup.sh
chmod +x ptero-admin.sh
chmod +x ai-assistant-setup.sh
chmod +x prism-upgrade.sh
chmod +x prism-enhanced.py
chmod +x prism-cli.sh

echo "[SUCCESS] Scripts downloaded successfully!"
echo ""
echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║                      AVAILABLE COMMANDS                                ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "📦 INSTALLATION:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  cd $INSTALL_DIR"
echo ""
echo "  ./automatic-system.sh install-panel      # Install Panel only"
echo "  ./automatic-system.sh install-wings      # Install Wings only"
echo "  ./automatic-system.sh install-full       # Install both (recommended)"
echo ""
echo "⚙️  MANAGEMENT:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ./automatic-system.sh update             # Update all components"
echo "  ./automatic-system.sh health-check       # Check system status"
echo "  ./automatic-system.sh scan               # Scan and fix issues"
echo "  ./automatic-system.sh backup             # Run backup"
echo "  ./automatic-system.sh clean              # Clean cache and logs"
echo ""
echo "🎨 CUSTOMIZATION:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ./automatic-system.sh customize          # Customize Panel appearance"
echo "  ./panel-customizer.sh                   # Direct customization"
echo ""
echo "🤖 AI ASSISTANT (P.R.I.S.M):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ./automatic-system.sh ai-assistant       # Install P.R.I.S.M"
echo "  ./automatic-system.sh prism-upgrade      # Upgrade to Enhanced"
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
echo "  ./automatic-system.sh pre-check          # Run pre-checks"
echo "  ./automatic-system.sh quick-setup        # Post-install essentials"
echo "  ./automatic-system.sh admin              # Launch admin panel"
echo ""
echo "📚 HELP:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ./automatic-system.sh help               # Show all commands"
echo ""
echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║                     RECOMMENDED INSTALLATION                           ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "1️⃣  Run pre-checks:"
echo "   cd $INSTALL_DIR && ./automatic-system.sh pre-check"
echo ""
echo "2️⃣  Install Pterodactyl:"
echo "   ./automatic-system.sh install-full"
echo ""
echo "3️⃣  Install P.R.I.S.M AI:"
echo "   ./automatic-system.sh ai-assistant"
echo ""
echo "4️⃣  Run quick setup:"
echo "   ./automatic-system.sh quick-setup"
echo ""
echo "🎉 You're ready to go!"
echo ""
