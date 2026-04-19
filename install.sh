#!/bin/bash

# Quick installer script - downloads and runs automatic-system from GitHub
# Usage: curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/install.sh | sudo bash
# Force update: curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/install.sh | sudo bash -s -- --force

set -e

REPO_URL="https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main"
INSTALL_DIR="/opt/ptero"
VERSION_FILE="$INSTALL_DIR/.version"
REMOTE_VERSION_URL="$REPO_URL/VERSION"
FORCE_UPDATE=false

# Check for force flag
if [[ "$1" == "--force" ]] || [[ "$1" == "-f" ]]; then
    FORCE_UPDATE=true
fi

clear 2>/dev/null || echo -e "\n"
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

echo "  ⏳ Creating installation directory..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Always download latest version
if [ -f "$INSTALL_DIR/pteroanyinstall.sh" ]; then
    echo ""
    echo "  ℹ️  Existing installation detected!"
    
    # Check for updates
    if [ -f "$VERSION_FILE" ]; then
        LOCAL_VERSION=$(cat "$VERSION_FILE" | tr -d '\n\r')
        REMOTE_VERSION=$(curl -sSL "$REMOTE_VERSION_URL" 2>/dev/null | tr -d '\n\r' || echo "unknown")
        
        echo "  📌 Local version:  $LOCAL_VERSION"
        echo "  🌐 Remote version: $REMOTE_VERSION"
        echo ""
        
        if [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ] && [ "$REMOTE_VERSION" != "unknown" ]; then
            echo "  🆕 New version available! Auto-updating..."
        else
            echo "  🔄 Re-downloading latest scripts..."
        fi
    else
        echo "  🔄 Downloading latest scripts..."
    fi
    
    echo ""
    echo "  ⏳ Removing old files..."
    rm -f pteroanyinstall.sh pre-install-checks.sh billing-setup.sh panel-customizer.sh \
          quick-setup.sh ptero-admin.sh ai-assistant-setup.sh prism-upgrade.sh \
          prism-enhanced.py prism-cli.sh node-installer.sh cloud-backup.sh update.sh
fi

echo "  📥 Downloading scripts from GitHub..."
echo ""

# Progress indicator function
show_progress() {
    local current=$1
    local total=$2
    local name=$3
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r  [%-50s] %3d%% - %s" \
        "$(printf '#%.0s' $(seq 1 $filled))$(printf ' %.0s' $(seq 1 $empty))" \
        "$percent" \
        "$name"
}

# Download main scripts with progress
TOTAL_FILES=13
CURRENT=0

download_file() {
    local url=$1
    local output=$2
    local name=$3
    CURRENT=$((CURRENT + 1))
    show_progress $CURRENT $TOTAL_FILES "$name"
    curl -sSL "$url" -o "$output" 2>/dev/null
}

download_file "$REPO_URL/pteroanyinstall.sh" "pteroanyinstall.sh" "Main installer"
download_file "$REPO_URL/pre-install-checks.sh" "pre-install-checks.sh" "Pre-checks"
download_file "$REPO_URL/billing-setup.sh" "billing-setup.sh" "Billing setup"
download_file "$REPO_URL/panel-customizer.sh" "panel-customizer.sh" "Customizer"
download_file "$REPO_URL/quick-setup.sh" "quick-setup.sh" "Quick setup"
download_file "$REPO_URL/ptero-admin.sh" "ptero-admin.sh" "Admin tools"
download_file "$REPO_URL/ai-assistant-setup.sh" "ai-assistant-setup.sh" "AI assistant"
download_file "$REPO_URL/prism-upgrade.sh" "prism-upgrade.sh" "PRISM upgrade"
download_file "$REPO_URL/prism-enhanced.py" "prism-enhanced.py" "PRISM core"
download_file "$REPO_URL/prism-cli.sh" "prism-cli.sh" "PRISM CLI"
download_file "$REPO_URL/node-installer.sh" "node-installer.sh" "Node installer"
download_file "$REPO_URL/cloud-backup.sh" "cloud-backup.sh" "Cloud backup"
download_file "$REPO_URL/update.sh" "update.sh" "Update script"

echo ""
echo ""
echo "  ⏳ Setting permissions..."

# Make executable
chmod +x pteroanyinstall.sh pre-install-checks.sh billing-setup.sh panel-customizer.sh \
         quick-setup.sh ptero-admin.sh ai-assistant-setup.sh prism-upgrade.sh \
         prism-enhanced.py prism-cli.sh node-installer.sh cloud-backup.sh update.sh

echo "  ⏳ Downloading version file..."

# Download and save version - ensure it's saved correctly
if curl -sSL "$REMOTE_VERSION_URL" -o "$VERSION_FILE" 2>/dev/null; then
    # Clean up the version file (remove any whitespace/newlines)
    VERSION_CONTENT=$(cat "$VERSION_FILE" | tr -d '\n\r\t ' | head -c 10)
    echo "$VERSION_CONTENT" > "$VERSION_FILE"
else
    echo "1.2.0" > "$VERSION_FILE"
fi

show_commands() {
    cat << 'EOF'

╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║                    ✅ INSTALLATION SUCCESSFUL! ✅                        ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝

EOF
    if [ -f "$VERSION_FILE" ]; then
        echo "  📌 Version: $(cat $VERSION_FILE)"
        echo "  📂 Location: $INSTALL_DIR"
        echo ""
    fi
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════╗
║                         AVAILABLE COMMANDS                               ║
╚══════════════════════════════════════════════════════════════════════════╝
EOF
}
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
echo "  ▸ ./update.sh                           Update installer scripts"
echo "  ▸ ./pteroanyinstall.sh update           Update Pterodactyl components"
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
echo "║                    📦 OPTIONAL COMPONENTS                                ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "  🌐 Web Console │ Professional web dashboard for server management"
echo "                 └─▸ ./ptero-webconsole.sh enable"
echo ""
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                          ║"
echo "║  🎉 Ready to install! Follow the steps above to get started.            ║"
echo "║                                                                          ║"
echo "║  💡 Need help? Run: ./pteroanyinstall.sh help                           ║"
echo "║                                                                          ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "  Press any key to continue..."
read -n 1 -s
clear 2>/dev/null || echo -e "\n"
