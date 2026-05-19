#!/bin/bash

# Feature Manager - Toggle optional features on/off
# Allows users to enable/disable components before installation

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

FEATURE_CONFIG="/etc/automatic-system/features.conf"

# Default feature states (all enabled by default)
declare -A FEATURES=(
    ["DISCORD_BOT"]="enabled"
    ["WEB_CONSOLE"]="enabled"
    ["SSH_TUNNEL"]="disabled"
    ["TERMUX_SSH"]="enabled"
    ["AI_ASSISTANT"]="enabled"
    ["ADMIN_PANEL"]="enabled"
    ["FILE_BROWSER"]="enabled"
    ["PINGVIN_SHARE"]="enabled"
    ["NEXTCLOUD"]="enabled"
    ["MONITORING"]="enabled"
    ["BACKUP_SYSTEM"]="enabled"
    ["IP_MONITOR"]="enabled"
    ["CLOUDFLARE_TUNNEL"]="enabled"
)

# Feature descriptions
declare -A FEATURE_DESCRIPTIONS=(
    ["DISCORD_BOT"]="Discord Bot - Server notifications and management"
    ["WEB_CONSOLE"]="Web Console - Browser-based server console"
    ["SSH_TERMINAL"]="Enhanced SSH Terminal - Modern web-based SSH with AI assistant"
    ["TERMUX_SSH"]="Termux SSH - Mobile SSH with syntax highlighting & auto-complete"
    ["AI_ASSISTANT"]="AI Assistant - Ollama + Open WebUI"
    ["ADMIN_PANEL"]="Admin Panel - Unified management interface"
    ["FILE_BROWSER"]="FileBrowser - Web file management"
    ["PINGVIN_SHARE"]="Pingvin Share - File sharing service"
    ["NEXTCLOUD"]="Nextcloud - Cloud storage platform"
    ["MONITORING"]="Monitoring - Grafana + Prometheus"
    ["BACKUP_SYSTEM"]="Backup System - Automated backups"
    ["IP_MONITOR"]="IP Monitor - Dynamic IP tracking"
    ["CLOUDFLARE_TUNNEL"]="Cloudflare Tunnel - Secure tunneling"
)

# Feature categories
declare -A FEATURE_CATEGORIES=(
    ["DISCORD_BOT"]="Communication"
    ["WEB_CONSOLE"]="Management"
    ["SSH_TUNNEL"]="Management (Deprecated)"
    ["TERMUX_SSH"]="Mobile Access"
    ["AI_ASSISTANT"]="AI & Automation"
    ["ADMIN_PANEL"]="Management"
    ["FILE_BROWSER"]="File Management"
    ["PINGVIN_SHARE"]="File Management"
    ["NEXTCLOUD"]="File Management"
    ["MONITORING"]="Monitoring & Analytics"
    ["BACKUP_SYSTEM"]="Backup & Recovery"
    ["IP_MONITOR"]="Network"
    ["CLOUDFLARE_TUNNEL"]="Network"
)

# Load feature configuration
load_features() {
    if [ -f "$FEATURE_CONFIG" ]; then
        while IFS='=' read -r key value; do
            if [[ ! "$key" =~ ^# ]] && [ -n "$key" ]; then
                FEATURES[$key]="$value"
            fi
        done < "$FEATURE_CONFIG"
    fi
}

# Save feature configuration
save_features() {
    mkdir -p "$(dirname "$FEATURE_CONFIG")"
    
    echo "# Feature Configuration" > "$FEATURE_CONFIG"
    echo "# Generated: $(date)" >> "$FEATURE_CONFIG"
    echo "" >> "$FEATURE_CONFIG"
    
    for feature in "${!FEATURES[@]}"; do
        echo "$feature=${FEATURES[$feature]}" >> "$FEATURE_CONFIG"
    done
}

# Check if feature is enabled
is_enabled() {
    local feature=$1
    load_features
    
    if [ "${FEATURES[$feature]}" = "enabled" ]; then
        return 0
    else
        return 1
    fi
}

# Enable feature
enable_feature() {
    local feature=$1
    FEATURES[$feature]="enabled"
    save_features
}

# Disable feature
disable_feature() {
    local feature=$1
    FEATURES[$feature]="disabled"
    save_features
}

# Toggle feature
toggle_feature() {
    local feature=$1
    
    if [ "${FEATURES[$feature]}" = "enabled" ]; then
        FEATURES[$feature]="disabled"
    else
        FEATURES[$feature]="enabled"
    fi
    
    save_features
}

# Show feature toggle menu
show_feature_menu() {
    load_features
    
    # Build checklist items
    local items=()
    
    for feature in "${!FEATURES[@]}"; do
        local desc="${FEATURE_DESCRIPTIONS[$feature]}"
        local state="OFF"
        
        if [ "${FEATURES[$feature]}" = "enabled" ]; then
            state="ON"
        fi
        
        items+=("$feature" "$desc" "$state")
    done
    
    # Sort items alphabetically
    IFS=$'\n' sorted_items=($(sort <<<"${items[*]}"))
    unset IFS
    
    local selected=$(whiptail --title "Feature Selection" --checklist \
        "\nSelect features to install:\n\nUse SPACE to toggle, ENTER to confirm" 24 78 12 \
        "${sorted_items[@]}" \
        3>&1 1>&2 2>&3)
    
    # Update feature states based on selection
    for feature in "${!FEATURES[@]}"; do
        if echo "$selected" | grep -q "\"$feature\""; then
            FEATURES[$feature]="enabled"
        else
            FEATURES[$feature]="disabled"
        fi
    done
    
    save_features
}

# Show feature presets menu
show_preset_menu() {
    local choice=$(whiptail --title "Feature Presets" --menu "\nChoose a feature preset:\n\nYou can customize after selecting a preset." 20 78 6 \
        "1" "Minimal - Panel + Wings only" \
        "2" "Standard - Panel + Wings + Admin + SSH" \
        "3" "Full Stack - All features enabled" \
        "4" "AI Focus - Panel + Wings + AI Assistant" \
        "5" "File Server - Panel + Wings + File Management" \
        "6" "Custom - Choose features manually" \
        3>&1 1>&2 2>&3)
    
    case $choice in
        1)
            # Minimal preset
            for feature in "${!FEATURES[@]}"; do
                FEATURES[$feature]="disabled"
            done
            ;;
        
        2)
            # Standard preset
            for feature in "${!FEATURES[@]}"; do
                FEATURES[$feature]="disabled"
            done
            FEATURES["ADMIN_PANEL"]="enabled"
            FEATURES["TERMUX_SSH"]="enabled"
            FEATURES["WEB_CONSOLE"]="enabled"
            FEATURES["IP_MONITOR"]="enabled"
            ;;
        
        3)
            # Full stack preset
            for feature in "${!FEATURES[@]}"; do
                FEATURES[$feature]="enabled"
            done
            ;;
        
        4)
            # AI focus preset
            for feature in "${!FEATURES[@]}"; do
                FEATURES[$feature]="disabled"
            done
            FEATURES["AI_ASSISTANT"]="enabled"
            FEATURES["ADMIN_PANEL"]="enabled"
            FEATURES["TERMUX_SSH"]="enabled"
            FEATURES["WEB_CONSOLE"]="enabled"
            ;;
        
        5)
            # File server preset
            for feature in "${!FEATURES[@]}"; do
                FEATURES[$feature]="disabled"
            done
            FEATURES["FILE_BROWSER"]="enabled"
            FEATURES["PINGVIN_SHARE"]="enabled"
            FEATURES["NEXTCLOUD"]="enabled"
            FEATURES["ADMIN_PANEL"]="enabled"
            ;;
        
        6)
            # Custom - show feature menu
            show_feature_menu
            return
            ;;
    esac
    
    save_features
    
    # Ask if user wants to customize
    if whiptail --title "Customize Preset?" --yesno "\nWould you like to customize this preset?\n\nYou can enable/disable individual features." 10 60; then
        show_feature_menu
    fi
}

# Show feature summary
show_summary() {
    load_features
    
    local enabled_features=""
    local disabled_features=""
    local enabled_count=0
    local disabled_count=0
    
    for feature in "${!FEATURES[@]}"; do
        local desc="${FEATURE_DESCRIPTIONS[$feature]}"
        
        if [ "${FEATURES[$feature]}" = "enabled" ]; then
            enabled_features+="  ✅ $desc\n"
            ((enabled_count++))
        else
            disabled_features+="  ❌ $desc\n"
            ((disabled_count++))
        fi
    done
    
    local summary="Feature Configuration Summary

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ENABLED FEATURES ($enabled_count):

$enabled_features
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DISABLED FEATURES ($disabled_count):

$disabled_features
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Configuration saved to:
  $FEATURE_CONFIG"
    
    whiptail --title "Feature Summary" --msgbox "$summary" 30 75
}

# List enabled features
list_enabled() {
    load_features
    
    for feature in "${!FEATURES[@]}"; do
        if [ "${FEATURES[$feature]}" = "enabled" ]; then
            echo "$feature"
        fi
    done
}

# List disabled features
list_disabled() {
    load_features
    
    for feature in "${!FEATURES[@]}"; do
        if [ "${FEATURES[$feature]}" = "disabled" ]; then
            echo "$feature"
        fi
    done
}

# Export features for use in installer
export_features() {
    load_features
    
    for feature in "${!FEATURES[@]}"; do
        local var_name="FEATURE_${feature}"
        export "$var_name"="${FEATURES[$feature]}"
    done
}

# Main execution
case "${1:-menu}" in
    "menu")
        show_preset_menu
        show_summary
        ;;
    
    "toggle")
        show_feature_menu
        show_summary
        ;;
    
    "preset")
        show_preset_menu
        show_summary
        ;;
    
    "enable")
        if [ -z "$2" ]; then
            echo "Usage: $0 enable <feature>"
            exit 1
        fi
        enable_feature "$2"
        echo "Enabled: $2"
        ;;
    
    "disable")
        if [ -z "$2" ]; then
            echo "Usage: $0 disable <feature>"
            exit 1
        fi
        disable_feature "$2"
        echo "Disabled: $2"
        ;;
    
    "is-enabled")
        if [ -z "$2" ]; then
            echo "Usage: $0 is-enabled <feature>"
            exit 1
        fi
        if is_enabled "$2"; then
            echo "enabled"
            exit 0
        else
            echo "disabled"
            exit 1
        fi
        ;;
    
    "list")
        load_features
        echo "Enabled Features:"
        list_enabled
        echo ""
        echo "Disabled Features:"
        list_disabled
        ;;
    
    "summary")
        show_summary
        ;;
    
    "export")
        export_features
        ;;
    
    "reset")
        for feature in "${!FEATURES[@]}"; do
            FEATURES[$feature]="enabled"
        done
        save_features
        echo "All features reset to enabled"
        ;;
    
    *)
        echo "Usage: $0 {menu|toggle|preset|enable|disable|is-enabled|list|summary|export|reset}"
        echo ""
        echo "Commands:"
        echo "  menu              - Show preset menu and feature selection"
        echo "  toggle            - Toggle individual features"
        echo "  preset            - Choose from feature presets"
        echo "  enable <feature>  - Enable a specific feature"
        echo "  disable <feature> - Disable a specific feature"
        echo "  is-enabled <feat> - Check if feature is enabled"
        echo "  list              - List all features and their states"
        echo "  summary           - Show feature configuration summary"
        echo "  export            - Export features as environment variables"
        echo "  reset             - Reset all features to enabled"
        exit 1
        ;;
esac
