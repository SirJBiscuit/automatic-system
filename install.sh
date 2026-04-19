#!/bin/bash

# Quick installer script - downloads and runs automatic-system from GitHub
# Usage: curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/install.sh | sudo bash

set -e

REPO_URL="https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main"
INSTALL_DIR="/opt/ptero"
VERSION_FILE="$INSTALL_DIR/.version"
REMOTE_VERSION_URL="$REPO_URL/VERSION"

# Detect terminal width
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
BOX_WIDTH=$((TERM_WIDTH > 100 ? 100 : TERM_WIDTH - 4))

# Function to create horizontal line
print_line() {
    local char=$1
    printf "${char}%.0s" $(seq 1 $BOX_WIDTH)
    echo ""
}

# Function to print centered text in box
print_box_line() {
    local text="$1"
    local text_len=${#text}
    local padding=$(( (BOX_WIDTH - text_len - 2) / 2 ))
    local right_padding=$(( BOX_WIDTH - text_len - padding - 2 ))
    printf "║%*s%s%*s║\n" $padding "" "$text" $right_padding ""
}

# Function to print section header
print_section() {
    local title="$1"
    printf "┌"; printf "─%.0s" $(seq 1 $((BOX_WIDTH - 2))); printf "┐\n"
    local text_len=${#title}
    local padding=$(( (BOX_WIDTH - text_len - 2) / 2 ))
    local right_padding=$(( BOX_WIDTH - text_len - padding - 2 ))
    printf "│%*s%s%*s│\n" $padding "" "$title" $right_padding ""
    printf "└"; printf "─%.0s" $(seq 1 $((BOX_WIDTH - 2))); printf "┘\n"
}

# Function to print quick start box
print_quick_start_box() {
    printf "╔"; printf "═%.0s" $(seq 1 $((BOX_WIDTH - 2))); printf "╗\n"
    print_box_line "$1"
    printf "╚"; printf "═%.0s" $(seq 1 $((BOX_WIDTH - 2))); printf "╝\n"
}

clear 2>/dev/null || echo -e "\n"
echo ""
printf "╔"; print_line "═"; printf "\b╗\n"
print_box_line ""
print_box_line "🚀 PTERODACTYL UNIVERSAL INSTALLER 🚀"
print_box_line ""
print_box_line "Automated Installation System"
print_box_line "Version 1.3.2 | SirJBiscuit"
print_box_line ""
printf "╚"; print_line "═"; printf "\b╝\n"
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

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "  ⏳ Installing git..."
    apt-get update -qq && apt-get install -y git >/dev/null 2>&1
fi

# Clone or update repository
if [ -d "$INSTALL_DIR/.git" ]; then
    echo ""
    echo "  ℹ️  Existing installation detected!"
    echo "  🔄 Updating from GitHub..."
    echo ""
    
    cd "$INSTALL_DIR"
    git fetch origin >/dev/null 2>&1
    
    # Check for updates
    LOCAL_COMMIT=$(git rev-parse HEAD 2>/dev/null)
    REMOTE_COMMIT=$(git rev-parse origin/main 2>/dev/null)
    
    if [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
        echo "  🆕 New version available! Updating..."
        git reset --hard origin/main >/dev/null 2>&1
        git pull origin main >/dev/null 2>&1
    else
        echo "  ✅ Already up to date!"
    fi
else
    echo "  📥 Cloning repository from GitHub..."
    echo ""
    
    # Remove directory if it exists but isn't a git repo
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
    fi
    
    # Clone the repository
    git clone -q https://github.com/SirJBiscuit/automatic-system.git "$INSTALL_DIR" 2>&1 | grep -v "Cloning into"
    cd "$INSTALL_DIR"
fi

echo ""
echo "  ⏳ Setting permissions..."

# Make all shell scripts executable
find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \;

# Make Python scripts executable
find "$INSTALL_DIR" -type f -name "*.py" -exec chmod +x {} \;

echo "  ✅ Permissions set"

# Save version info
if [ -f "$INSTALL_DIR/VERSION" ]; then
    cp "$INSTALL_DIR/VERSION" "$VERSION_FILE"
else
    git rev-parse --short HEAD > "$VERSION_FILE" 2>/dev/null || echo "1.3.2" > "$VERSION_FILE"
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
print_section "📦 INSTALLATION"
echo ""
echo "  First, navigate to installation directory:"
echo "  $ cd $INSTALL_DIR"
echo ""
echo "  ▸ ./pteroanyinstall.sh install-panel    Install Panel only"
echo "  ▸ ./pteroanyinstall.sh install-wings    Install Wings only"
echo "  ▸ ./pteroanyinstall.sh install-full     Install both (⭐ recommended)"
echo ""
print_section "⚙️  MANAGEMENT & MAINTENANCE"
echo ""
echo "  ▸ ./update.sh                           Update installer scripts"
echo "  ▸ ./pteroanyinstall.sh update           Update Pterodactyl components"
echo "  ▸ ./pteroanyinstall.sh health-check     Check system status"
echo "  ▸ ./pteroanyinstall.sh scan             Scan and fix issues"
echo "  ▸ ./pteroanyinstall.sh backup           Run backup"
echo "  ▸ ./pteroanyinstall.sh clean            Clean cache and logs"
echo ""
print_section "☁️  CLOUD BACKUPS"
echo ""
echo "  ▸ ./cloud-backup.sh                     Interactive backup menu"
echo "  ▸ ./cloud-backup.sh gdrive              Google Drive backup"
echo "  ▸ ./cloud-backup.sh b2                  Backblaze B2 backup"
echo "  ▸ ./cloud-backup.sh mega                Mega.nz backup"
echo ""
print_section "🎨 CUSTOMIZATION"
echo ""
echo "  ▸ ./pteroanyinstall.sh customize        Customize Panel appearance"
echo "  ▸ ./panel-customizer.sh                 Direct customization tool"
echo ""
print_section "🤖 AI ASSISTANT (P.R.I.S.M)"
echo ""
echo "  ▸ ./pteroanyinstall.sh ai-assistant     Install P.R.I.S.M AI"
echo "  ▸ ./pteroanyinstall.sh prism-upgrade    Upgrade to Enhanced"
echo ""
echo "  💬 P.R.I.S.M Commands:"
echo "     chatbot status | ask \"question\" | detect | webhook setup | api setup"
echo ""
print_section "🖥️  ADDITIONAL NODES"
echo ""
echo "  ▸ ./node-installer.sh                   Install Wings on extra servers"
echo ""
print_quick_start_box "🚀 QUICK START GUIDE 🚀"
echo ""
echo "  1️⃣  Pre-check      → cd $INSTALL_DIR && ./pteroanyinstall.sh pre-check"
echo "  2️⃣  Install        → ./pteroanyinstall.sh install-full"
echo "  3️⃣  Quick Setup    → ./pteroanyinstall.sh quick-setup"
echo ""
echo "  📦 Optional: ./ptero-webconsole.sh enable (Web Dashboard)"
echo ""
print_quick_start_box "🎉 Ready to install! Need help? Run: ./pteroanyinstall.sh help"
echo ""
echo ""
echo "  ⏳ Installing update checker service..."
echo ""

# Install update checker
if [ -f "/opt/ptero/ptero-update-checker.sh" ]; then
    cp /opt/ptero/ptero-update-checker.service /etc/systemd/system/ 2>/dev/null
    cp /opt/ptero/ptero-update-checker.timer /etc/systemd/system/ 2>/dev/null
    systemctl daemon-reload 2>/dev/null
    systemctl enable ptero-update-checker.timer 2>/dev/null
    systemctl start ptero-update-checker.timer 2>/dev/null
    echo "  ✅ Update checker installed! Will check for updates daily."
else
    echo "  ⚠️  Update checker not found, skipping..."
fi

echo ""
echo "  Press any key to continue..."
read -n 1 -s
clear 2>/dev/null || echo -e "\n"
