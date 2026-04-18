#!/bin/bash

# P.R.I.S.M Enhanced Upgrade Script
# Upgrades the basic AI assistant to the full-featured P.R.I.S.M system

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_banner() {
    cat <<'EOF'

╔════════════════════════════════════════════════════════════════════════╗
║                    P.R.I.S.M ENHANCED UPGRADE                          ║
║        Pterodactyl Resource Intelligence & System Monitor              ║
╚════════════════════════════════════════════════════════════════════════╝

Upgrading to P.R.I.S.M Enhanced adds:
  ✓ Discord/Slack webhook notifications
  ✓ Pterodactyl API integration
  ✓ Game server health monitoring
  ✓ Predictive maintenance
  ✓ Backup verification
  ✓ Security scanning
  ✓ Log analysis & insights
  ✓ Network monitoring
  ✓ Custom automation rules
  ✓ Performance profiling
  ✓ Daily/weekly reports

EOF
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if basic assistant is installed
    if [ ! -f "/opt/ptero-assistant/config.json" ]; then
        log_error "Basic AI assistant not found. Please install it first."
        exit 1
    fi
    
    # Check Python version
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
    if (( $(echo "$PYTHON_VERSION < 3.6" | bc -l) )); then
        log_error "Python 3.6+ required"
        exit 1
    fi
    
    log_success "Prerequisites met"
}

install_dependencies() {
    log_info "Installing Python dependencies..."
    
    pip3 install requests sqlite3 2>/dev/null || true
    
    # Install additional tools
    if [ -f /etc/debian_version ]; then
        apt-get install -y bc jq sqlite3 2>/dev/null || true
    elif [ -f /etc/redhat-release ]; then
        yum install -y bc jq sqlite 2>/dev/null || true
    fi
    
    log_success "Dependencies installed"
}

backup_current_config() {
    log_info "Backing up current configuration..."
    
    BACKUP_DIR="/opt/ptero-assistant/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    cp /opt/ptero-assistant/config.json "$BACKUP_DIR/" 2>/dev/null || true
    cp /opt/ptero-assistant/assistant.py "$BACKUP_DIR/" 2>/dev/null || true
    
    log_success "Backup created at $BACKUP_DIR"
}

install_enhanced_version() {
    log_info "Installing P.R.I.S.M Enhanced..."
    
    # Copy enhanced Python script
    cp prism-enhanced.py /opt/ptero-assistant/
    chmod +x /opt/ptero-assistant/prism-enhanced.py
    
    # Install CLI tool
    cp prism-cli.sh /usr/local/bin/prism
    chmod +x /usr/local/bin/prism
    
    # Update systemd service to use enhanced version
    cat > /etc/systemd/system/ptero-assistant.service <<'EOFSVC'
[Unit]
Description=P.R.I.S.M Enhanced - Pterodactyl AI Assistant
After=network.target ollama.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ptero-assistant
ExecStart=/usr/bin/python3 /opt/ptero-assistant/prism-enhanced.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOFSVC
    
    systemctl daemon-reload
    
    log_success "P.R.I.S.M Enhanced installed"
}

setup_databases() {
    log_info "Initializing databases..."
    
    # The databases will be created automatically on first run
    # Just ensure the directory exists
    mkdir -p /opt/ptero-assistant
    
    log_success "Databases ready"
}

configure_features() {
    log_info "Configuring features..."
    
    echo ""
    echo "Would you like to configure optional features now? (y/n)"
    read -r configure_now
    
    if [[ "$configure_now" =~ ^[Yy]$ ]]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  Discord/Slack Webhooks"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Add a webhook for notifications? (y/n)"
        read -r add_webhook
        
        if [[ "$add_webhook" =~ ^[Yy]$ ]]; then
            read -p "Webhook name (e.g., discord, slack): " webhook_name
            read -p "Webhook URL: " webhook_url
            
            prism webhook add "$webhook_name" "$webhook_url"
            
            echo ""
            echo "Test webhook? (y/n)"
            read -r test_webhook
            if [[ "$test_webhook" =~ ^[Yy]$ ]]; then
                prism webhook test "$webhook_name"
            fi
        fi
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  Pterodactyl API Integration"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Configure Pterodactyl API for game server monitoring? (y/n)"
        read -r setup_api
        
        if [[ "$setup_api" =~ ^[Yy]$ ]]; then
            prism api setup
        fi
    fi
    
    log_success "Configuration complete"
}

restart_service() {
    log_info "Restarting P.R.I.S.M..."
    
    systemctl restart ptero-assistant
    sleep 2
    
    if systemctl is-active --quiet ptero-assistant; then
        log_success "P.R.I.S.M Enhanced is running"
    else
        log_error "Failed to start P.R.I.S.M Enhanced"
        echo "Check logs with: journalctl -u ptero-assistant -f"
        exit 1
    fi
}

show_usage_guide() {
    cat <<'EOF'

╔════════════════════════════════════════════════════════════════════════╗
║                    UPGRADE COMPLETE!                                   ║
╚════════════════════════════════════════════════════════════════════════╝

🤖 P.R.I.S.M Enhanced is now active!

New Commands Available:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Basic Commands (still available):
    chatbot -enable              Enable P.R.I.S.M
    chatbot -disable             Disable P.R.I.S.M
    chatbot status               View status
    chatbot logs                 View logs
    chatbot ask "question"       Ask AI
    chatbot detect               System optimization

  New Enhanced Commands:
    prism webhook add <name> <url>    Add notification webhook
    prism api setup                   Configure Pterodactyl API
    prism servers health              Check game servers
    prism report daily                Daily summary report
    prism predict                     Predictive maintenance
    prism security scan               Security check
    prism backup verify               Verify backups
    prism rules add                   Create automation rule

Quick Start:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  1. Add Discord notifications:
     prism webhook add discord https://discord.com/api/webhooks/YOUR_WEBHOOK

  2. Configure Pterodactyl API:
     prism api setup

  3. View system predictions:
     prism predict

  4. Generate daily report:
     prism report daily

  5. Check game server health:
     prism servers health

Features Now Active:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ✓ Webhook notifications (Discord/Slack)
  ✓ Game server monitoring
  ✓ Predictive maintenance
  ✓ Backup verification
  ✓ Security scanning
  ✓ Log analysis
  ✓ Network monitoring
  ✓ Custom automation rules
  ✓ Daily/weekly reports
  ✓ Performance profiling

Documentation:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  View all commands: prism
  View logs: chatbot logs
  Check status: chatbot status

P.R.I.S.M will now automatically:
  • Monitor all system resources
  • Predict issues before they happen
  • Send alerts to your webhooks
  • Monitor game servers
  • Verify backups
  • Scan for security issues
  • Generate daily reports

EOF
}

main() {
    show_banner
    
    echo "This will upgrade your AI assistant to P.R.I.S.M Enhanced."
    echo "Continue? (y/n)"
    read -r continue_install
    
    if [[ ! "$continue_install" =~ ^[Yy]$ ]]; then
        echo "Upgrade cancelled"
        exit 0
    fi
    
    echo ""
    check_prerequisites
    install_dependencies
    backup_current_config
    install_enhanced_version
    setup_databases
    configure_features
    restart_service
    
    echo ""
    show_usage_guide
    
    echo ""
    log_success "P.R.I.S.M Enhanced upgrade complete!"
}

main "$@"
