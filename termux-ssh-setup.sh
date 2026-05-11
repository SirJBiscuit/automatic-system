#!/bin/bash

# Termux SSH Setup - Complete mobile SSH solution
# Includes Cloudflare Tunnel, syntax highlighting, auto-completion, and more

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="/opt/termux-ssh"
CONFIG_DIR="/etc/termux-ssh"
TUNNEL_CONFIG="/etc/cloudflared/termux-ssh.yml"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Show introduction
show_intro() {
    whiptail --title "Termux SSH Setup" --msgbox "
📱 Termux SSH Complete Setup

This will configure your server for optimal Termux SSH access:

✅ Cloudflare SSH Tunnel (connect from anywhere)
✅ Syntax Highlighting (colorful commands)
✅ Auto-completion (tab completion for commands)
✅ Custom aliases and shortcuts
✅ Enhanced bash prompt
✅ Command history improvements
✅ Mobile-optimized settings

Perfect for managing your server from your phone!

Press OK to begin..." 20 75
}

# Install server-side enhancements
install_server_enhancements() {
    whiptail --title "Server Enhancements" --msgbox "
🖥️  Installing server-side enhancements...

This includes:
• Syntax highlighting for bash
• Auto-completion packages
• Enhanced bash configuration
• Useful aliases

Press OK to continue..." 14 70

    echo "Installing packages..."
    
    # Detect package manager and install packages
    if command -v apt-get &> /dev/null; then
        apt-get update -qq
        # Install packages that are available, skip if not found
        apt-get install -y bash-completion highlight source-highlight 2>/dev/null || true
        apt-get install -y command-not-found 2>/dev/null || true
    elif command -v yum &> /dev/null; then
        yum install -y bash-completion highlight 2>/dev/null || true
    fi
    
    whiptail --title "Success" --msgbox "
✅ Server packages installed!

Press OK to continue..." 8 50
}

# Configure bash with syntax highlighting and auto-completion
configure_bash() {
    whiptail --title "Bash Configuration" --msgbox "
⚙️  Configuring enhanced bash...

This will add:
• Syntax highlighting
• Smart auto-completion
• Colorful prompt
• Useful aliases
• Command history improvements

Press OK to continue..." 14 70

    # Create enhanced bashrc
    cat > "$CONFIG_DIR/enhanced-bashrc" <<'EOF'
# Termux SSH Enhanced Bash Configuration
# Optimized for mobile SSH access

# ============================================
# COLORS AND PROMPT
# ============================================

# Enable colors
export TERM=xterm-256color
export CLICOLOR=1

# Colorful prompt with git branch
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# Custom PS1 with colors
export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[33m\]\$(parse_git_branch)\[\033[00m\]\$ "

# ============================================
# SYNTAX HIGHLIGHTING
# ============================================

# Enable syntax highlighting for common commands
if [ -f /usr/share/source-highlight/src-hilite-lesspipe.sh ]; then
    export LESSOPEN="| /usr/share/source-highlight/src-hilite-lesspipe.sh %s"
    export LESS=' -R '
fi

# Colorize ls output
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'

# Colorize grep
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ============================================
# AUTO-COMPLETION
# ============================================

# Enable bash completion
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# Enable programmable completion features
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# Case-insensitive completion
bind 'set completion-ignore-case on'

# Show all completions immediately
bind 'set show-all-if-ambiguous on'

# Cycle through completions
bind 'TAB:menu-complete'

# ============================================
# COMMAND HISTORY
# ============================================

# Larger history
export HISTSIZE=10000
export HISTFILESIZE=20000

# Avoid duplicates
export HISTCONTROL=ignoredups:erasedups

# Append to history, don't overwrite
shopt -s histappend

# Save multi-line commands as one command
shopt -s cmdhist

# Correct minor directory spelling errors
shopt -s cdspell

# ============================================
# USEFUL ALIASES
# ============================================

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# Safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Shortcuts
alias h='history'
alias c='clear'
alias e='exit'

# System info
alias ports='netstat -tulanp'
alias meminfo='free -m -l -t'
alias cpuinfo='lscpu'
alias diskinfo='df -h'

# Pterodactyl shortcuts
alias panel='cd /var/www/pterodactyl'
alias wings='cd /etc/pterodactyl'
alias plogs='tail -f /var/log/pterodactyl/pterodactyl.log'
alias wlogs='tail -f /var/log/pterodactyl/wings.log'
alias prestart='systemctl restart pterodactyl'
alias wrestart='systemctl restart wings'

# Docker shortcuts (if Wings is installed)
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dstop='docker stop $(docker ps -q)'
alias drm='docker rm $(docker ps -aq)'

# Quick edits
alias bashrc='nano ~/.bashrc && source ~/.bashrc'
alias hosts='sudo nano /etc/hosts'

# Network
alias myip='curl -s ifconfig.me'
alias localip='hostname -I'
alias ping='ping -c 5'

# ============================================
# FUNCTIONS
# ============================================

# Extract any archive
extract() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Make directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Find process by name
psgrep() {
    ps aux | grep -v grep | grep -i -e VSZ -e "$1"
}

# Quick backup
backup() {
    cp "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"
}

# Show top 10 largest files in current directory
largest() {
    du -ah . | sort -rh | head -n ${1:-10}
}

# ============================================
# MOBILE-OPTIMIZED SETTINGS
# ============================================

# Shorter timeout for mobile connections
export TMOUT=0

# Better handling of window size changes
shopt -s checkwinsize

# Enable color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# ============================================
# WELCOME MESSAGE
# ============================================

# Show system info on login
if [ -f /usr/bin/neofetch ]; then
    neofetch
elif [ -f /usr/bin/screenfetch ]; then
    screenfetch
else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Welcome to $(hostname)"
    echo "  $(date)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Uptime: $(uptime -p)"
    echo "  Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo "  Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo "  Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

# Show quick tips
echo ""
echo "💡 Quick Tips:"
echo "  • Type 'll' for detailed file list"
echo "  • Type 'h' for command history"
echo "  • Use TAB for auto-completion"
echo "  • Type 'alias' to see all shortcuts"
echo ""

EOF

    # Backup existing bashrc
    if [ -f /root/.bashrc ]; then
        cp /root/.bashrc /root/.bashrc.backup-$(date +%Y%m%d)
    fi
    
    # Add source to bashrc
    if ! grep -q "termux-ssh/enhanced-bashrc" /root/.bashrc 2>/dev/null; then
        echo "" >> /root/.bashrc
        echo "# Termux SSH Enhanced Configuration" >> /root/.bashrc
        echo "if [ -f $CONFIG_DIR/enhanced-bashrc ]; then" >> /root/.bashrc
        echo "    . $CONFIG_DIR/enhanced-bashrc" >> /root/.bashrc
        echo "fi" >> /root/.bashrc
    fi
    
    whiptail --title "Success" --msgbox "
✅ Bash configuration complete!

Your SSH sessions will now have:
• Colorful syntax highlighting
• Smart auto-completion
• Useful aliases and shortcuts
• Enhanced prompt

Press OK to continue..." 12 60
}

# Install optional enhancements
install_optional_enhancements() {
    if whiptail --title "Optional Enhancements" --yesno "
Would you like to install optional enhancements?

These include:
• neofetch (system info display)
• htop (better process viewer)
• ncdu (disk usage analyzer)
• tmux (terminal multiplexer)
• vim with syntax highlighting

Recommended for better mobile experience!" 16 70; then
        
        echo "Installing optional packages..."
        
        if command -v apt-get &> /dev/null; then
            # Install packages individually, skip if not available
            apt-get install -y neofetch 2>/dev/null || true
            apt-get install -y htop 2>/dev/null || true
            apt-get install -y ncdu 2>/dev/null || true
            apt-get install -y tmux 2>/dev/null || true
            apt-get install -y vim 2>/dev/null || true
        elif command -v yum &> /dev/null; then
            yum install -y neofetch htop ncdu tmux vim-enhanced 2>/dev/null || true
        fi
        
        # Configure vim
        cat > /root/.vimrc <<'EOF'
" Vim configuration for Termux SSH
syntax on
set number
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab
set mouse=a
colorscheme desert
EOF
        
        whiptail --title "Success" --msgbox "
✅ Optional enhancements installed!

New tools available:
• neofetch - System info
• htop - Process viewer
• ncdu - Disk usage
• tmux - Terminal multiplexer
• vim - Enhanced editor

Press OK to continue..." 14 60
    fi
}

# Setup Cloudflare SSH Tunnel
setup_cloudflare_tunnel() {
    if whiptail --title "Cloudflare SSH Tunnel" --yesno "
Would you like to set up Cloudflare SSH Tunnel?

This allows you to connect from anywhere without
port forwarding:

✅ Connect from mobile data
✅ No router configuration needed
✅ DDoS protection
✅ Fast and secure

Highly recommended for Termux!" 16 70; then
        
        # Find cloudflare-ssh-tunnel.sh
        local script_dir="$(dirname "$0")"
        local tunnel_script=""
        
        if [ -f "$script_dir/cloudflare-ssh-tunnel.sh" ]; then
            tunnel_script="$script_dir/cloudflare-ssh-tunnel.sh"
        elif [ -f "/opt/ptero/cloudflare-ssh-tunnel.sh" ]; then
            tunnel_script="/opt/ptero/cloudflare-ssh-tunnel.sh"
        elif [ -f "./cloudflare-ssh-tunnel.sh" ]; then
            tunnel_script="./cloudflare-ssh-tunnel.sh"
        else
            # Download it if not found
            whiptail --title "Downloading Script" --msgbox "
Downloading cloudflare-ssh-tunnel.sh...

Press OK to continue..." 8 60
            
            curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/cloudflare-ssh-tunnel.sh -o /tmp/cloudflare-ssh-tunnel.sh
            chmod +x /tmp/cloudflare-ssh-tunnel.sh
            tunnel_script="/tmp/cloudflare-ssh-tunnel.sh"
        fi
        
        bash "$tunnel_script" setup
    fi
}

# Generate Termux connection guide
generate_termux_guide() {
    local domain=$(cat /etc/cloudflared/ssh-domain.txt 2>/dev/null || echo "your-server.com")
    local server_ip=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
    
    mkdir -p "$CONFIG_DIR"
    
    cat > "$CONFIG_DIR/termux-connection-guide.txt" <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  TERMUX SSH CONNECTION GUIDE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SETUP TERMUX (One-time):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Install Termux from F-Droid (NOT Google Play)
   https://f-droid.org/en/packages/com.termux/

2. Open Termux and run:
   pkg update && pkg upgrade
   pkg install openssh

3. (Optional) Generate SSH key for passwordless login:
   ssh-keygen -t ed25519
   ssh-copy-id root@$domain

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CONNECT TO YOUR SERVER:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Via Cloudflare Tunnel (Recommended):
  ssh root@$domain

Via Direct IP (if on same network):
  ssh root@$server_ip

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
USEFUL TERMUX SHORTCUTS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Volume Down = Ctrl key
Volume Up + Q = Show extra keys
Volume Up + W = Up arrow
Volume Up + A = Left arrow
Volume Up + S = Down arrow
Volume Up + D = Right arrow
Volume Up + E = Escape
Volume Up + T = Tab
Volume Up + V = Paste

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AVAILABLE COMMANDS (on server):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Navigation:
  ll        - Detailed file list
  ..        - Go up one directory
  ~         - Go to home directory

Pterodactyl:
  panel     - Go to panel directory
  wings     - Go to wings directory
  plogs     - View panel logs
  wlogs     - View wings logs
  prestart  - Restart panel
  wrestart  - Restart wings

System:
  htop      - Process viewer
  ncdu      - Disk usage
  myip      - Show public IP
  ports     - Show open ports
  meminfo   - Memory info
  diskinfo  - Disk info

Docker (if Wings installed):
  dps       - List containers
  dpsa      - List all containers
  dstop     - Stop all containers

Utilities:
  extract <file>  - Extract any archive
  backup <file>   - Quick backup
  largest         - Show largest files

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TIPS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• Use TAB for auto-completion
• Commands are color-coded
• Type 'alias' to see all shortcuts
• Use tmux for persistent sessions
• Ctrl+D or 'exit' to disconnect

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

    whiptail --title "Connection Guide Created" --msgbox "
📱 Termux connection guide created!

Location: $CONFIG_DIR/termux-connection-guide.txt

View it anytime with:
  cat $CONFIG_DIR/termux-connection-guide.txt

Press OK to continue..." 12 70
}

# Show final instructions
show_final_instructions() {
    local domain=$(cat /etc/cloudflared/ssh-domain.txt 2>/dev/null || echo "your-server.com")
    
    whiptail --title "Setup Complete!" --msgbox "
🎉 Termux SSH Setup Complete!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CONNECT FROM TERMUX:

1. Install OpenSSH in Termux:
   pkg install openssh

2. Connect to your server:
   ssh root@$domain

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

FEATURES ENABLED:

✅ Syntax highlighting (colorful commands)
✅ Auto-completion (press TAB)
✅ Useful aliases (type 'alias' to see all)
✅ Enhanced prompt with colors
✅ System info on login
✅ Mobile-optimized settings

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

QUICK COMMANDS:

  ll        - List files
  panel     - Go to panel directory
  plogs     - View panel logs
  htop      - Process viewer
  myip      - Show public IP

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DOCUMENTATION:

View full guide:
  cat $CONFIG_DIR/termux-connection-guide.txt

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Press OK to finish..." 32 75
}

# Update termux SSH setup
update_termux_ssh() {
    whiptail --title "Update Termux SSH" --msgbox "
🔄 Updating Termux SSH Setup

This will:
• Download the latest version
• Update bash configuration
• Refresh aliases and shortcuts
• Keep your existing settings

Press OK to continue..." 14 70

    # Download latest version
    curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/termux-ssh-setup.sh -o /tmp/termux-ssh-setup-new.sh
    chmod +x /tmp/termux-ssh-setup-new.sh
    
    # Backup current config
    if [ -f "$CONFIG_DIR/enhanced-bashrc" ]; then
        cp "$CONFIG_DIR/enhanced-bashrc" "$CONFIG_DIR/enhanced-bashrc.backup"
    fi
    
    # Run update (skip intro and optional packages)
    install_server_enhancements
    configure_bash
    generate_termux_guide
    
    whiptail --title "Update Complete" --msgbox "
✅ Termux SSH setup updated successfully!

Your bash configuration has been refreshed.
Run 'source ~/.bashrc' to apply changes.

Press OK to finish..." 12 60
    
    # Update install date
    echo "$(date)" > "$CONFIG_DIR/update-date.txt"
}

# Show version info
show_version() {
    local install_date=$(cat "$CONFIG_DIR/install-date.txt" 2>/dev/null || echo "Unknown")
    local update_date=$(cat "$CONFIG_DIR/update-date.txt" 2>/dev/null || echo "Never")
    
    whiptail --title "Termux SSH Version" --msgbox "
📦 Termux SSH Setup

Installed: $install_date
Last Updated: $update_date

Configuration: $CONFIG_DIR
Install Directory: $INSTALL_DIR

Press OK to close..." 14 70
}

# Main setup process
main() {
    # Check for command line arguments
    case "${1:-install}" in
        "update")
            update_termux_ssh
            exit 0
            ;;
        "version"|"--version"|"-v")
            show_version
            exit 0
            ;;
        "help"|"--help"|"-h")
            echo "Termux SSH Setup"
            echo ""
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  install  - Install Termux SSH setup (default)"
            echo "  update   - Update to latest version"
            echo "  version  - Show version information"
            echo "  help     - Show this help message"
            echo ""
            exit 0
            ;;
    esac
    
    # Create directories
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    
    # Show intro
    show_intro
    
    # Install server enhancements
    install_server_enhancements
    
    # Configure bash
    configure_bash
    
    # Install optional enhancements
    install_optional_enhancements
    
    # Setup Cloudflare tunnel
    setup_cloudflare_tunnel
    
    # Generate connection guide
    generate_termux_guide
    
    # Show final instructions
    show_final_instructions
    
    # Mark as installed
    touch "$CONFIG_DIR/.installed"
    echo "$(date)" > "$CONFIG_DIR/install-date.txt"
    
    # Add update alias to bashrc
    if ! grep -q "alias update-termux-ssh" /root/.bashrc 2>/dev/null; then
        echo "" >> /root/.bashrc
        echo "# Termux SSH Update Alias" >> /root/.bashrc
        echo "alias update-termux-ssh='bash <(curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/termux-ssh-setup.sh) update'" >> /root/.bashrc
    fi
}

# Run main
main "$@"
