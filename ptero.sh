#!/bin/bash

# Pterodactyl Management Interface
# Quick access to common commands

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear

show_banner() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${BLUE}PTERODACTYL MANAGEMENT INTERFACE${NC}                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_menu() {
    echo -e "${GREEN}SYSTEM MANAGEMENT:${NC}"
    echo "  1) Update all scripts from GitHub"
    echo "  2) Reinstall scripts only (keeps all data/services)"
    echo "  3) Check service status"
    echo "  4) View logs"
    echo ""
    echo -e "${GREEN}P.R.I.S.M AI ASSISTANT:${NC}"
    echo "  5) Enable P.R.I.S.M"
    echo "  6) Disable P.R.I.S.M"
    echo "  7) Check P.R.I.S.M status"
    echo "  8) Run system optimization"
    echo "  9) Ask P.R.I.S.M a question"
    echo ""
    echo -e "${GREEN}WEB CONSOLE:${NC}"
    echo "  10) Start web console"
    echo "  11) Stop web console"
    echo "  12) Restart web console"
    echo "  13) View web console logs"
    echo ""
    echo -e "${GREEN}CLOUDFLARE TUNNEL:${NC}"
    echo "  14) Start tunnel"
    echo "  15) Stop tunnel"
    echo "  16) Restart tunnel"
    echo "  17) View tunnel logs"
    echo ""
    echo -e "${GREEN}DISCORD BOT:${NC}"
    echo "  18) Start Discord bot"
    echo "  19) Stop Discord bot"
    echo "  20) Restart Discord bot"
    echo "  21) View Discord bot logs"
    echo "  22) Update Discord bot"
    echo ""
    echo -e "${GREEN}OTHER:${NC}"
    echo "  23) Install/Setup P.R.I.S.M"
    echo "  24) Open shell in /opt/ptero"
    echo "  25) Help - What does each option do?"
    echo ""
    echo "  0) Exit"
    echo ""
}

update_scripts() {
    echo -e "${BLUE}[INFO]${NC} Updating scripts from GitHub..."
    cd /opt/ptero
    git reset --hard HEAD
    git pull origin main
    chmod +x *.sh 2>/dev/null || true
    find /opt/ptero -type f -name "*.sh" -exec chmod +x {} \;
    echo -e "${GREEN}[SUCCESS]${NC} Scripts updated!"
    read -e -p "Press Enter to continue..."
}

update_discord_bot() {
    echo -e "${BLUE}[INFO]${NC} Updating Discord bot..."
    echo ""
    
    # Pull latest changes
    cd /opt/ptero
    git pull origin main
    
    # Copy updated bot files
    echo -e "${BLUE}[INFO]${NC} Copying bot files..."
    cp /opt/ptero/discord-bot/bot.py /opt/pterodactyl-bot/
    cp /opt/ptero/discord-bot/voice_handler.py /opt/pterodactyl-bot/ 2>/dev/null || true
    
    # Install/update dependencies
    echo -e "${BLUE}[INFO]${NC} Updating dependencies..."
    /opt/pterodactyl-bot/venv/bin/pip install -q --upgrade -r /opt/ptero/discord-bot/requirements.txt
    
    # Restart bot
    echo -e "${BLUE}[INFO]${NC} Restarting Discord bot..."
    systemctl restart pterodactyl-bot
    
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} Discord bot updated!"
    echo ""
    echo "Check status with option 21 (View Discord bot logs)"
    echo ""
    read -e -p "Press Enter to continue..."
}

clean_install() {
    echo -e "${BLUE}[INFO]${NC} This will reinstall scripts from GitHub."
    echo -e "${GREEN}[SAFE]${NC} Your panel, databases, and services are NOT affected."
    echo -e "${GREEN}[SAFE]${NC} Only the management scripts in /opt/ptero are replaced."
    echo ""
    read -e -p "Are you sure? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}[INFO]${NC} Removing old scripts..."
        rm -rf /opt/ptero
        rm -f /usr/local/bin/chatbot
        echo -e "${BLUE}[INFO]${NC} Running installer..."
        curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/install.sh | bash
        echo -e "${GREEN}[SUCCESS]${NC} Clean install complete!"
    else
        echo "Cancelled."
    fi
    read -e -p "Press Enter to continue..."
}

check_status() {
    echo -e "${BLUE}[INFO]${NC} Checking service status..."
    echo ""
    echo -e "${CYAN}=== Pterodactyl Panel ===${NC}"
    systemctl is-active --quiet nginx && echo -e "  Nginx: ${GREEN}Running${NC}" || echo -e "  Nginx: ${RED}Stopped${NC}"
    systemctl is-active --quiet mysql && echo -e "  MySQL: ${GREEN}Running${NC}" || echo -e "  MySQL: ${RED}Stopped${NC}"
    systemctl is-active --quiet redis-server && echo -e "  Redis: ${GREEN}Running${NC}" || echo -e "  Redis: ${RED}Stopped${NC}"
    
    echo ""
    echo -e "${CYAN}=== Wings ===${NC}"
    systemctl is-active --quiet wings && echo -e "  Wings: ${GREEN}Running${NC}" || echo -e "  Wings: ${RED}Stopped${NC}"
    
    echo ""
    echo -e "${CYAN}=== Web Console ===${NC}"
    systemctl is-active --quiet pterodactyl-web-console && echo -e "  Web Console: ${GREEN}Running${NC}" || echo -e "  Web Console: ${RED}Stopped${NC}"
    
    echo ""
    echo -e "${CYAN}=== Cloudflare Tunnel ===${NC}"
    systemctl is-active --quiet cloudflared && echo -e "  Tunnel: ${GREEN}Running${NC}" || echo -e "  Tunnel: ${RED}Stopped${NC}"
    
    echo ""
    echo -e "${CYAN}=== P.R.I.S.M ===${NC}"
    systemctl is-active --quiet ptero-assistant && echo -e "  P.R.I.S.M: ${GREEN}Running${NC}" || echo -e "  P.R.I.S.M: ${RED}Stopped${NC}"
    systemctl is-active --quiet ollama && echo -e "  Ollama: ${GREEN}Running${NC}" || echo -e "  Ollama: ${RED}Stopped${NC}"
    
    echo ""
    read -e -p "Press Enter to continue..."
}

view_logs() {
    echo ""
    echo "Select logs to view:"
    echo "  1) Web Console"
    echo "  2) Cloudflare Tunnel"
    echo "  3) P.R.I.S.M"
    echo "  4) Wings"
    echo "  5) Nginx Error Log"
    echo ""
    read -e -p "Select [1-5]: " log_choice
    
    case $log_choice in
        1) journalctl -u pterodactyl-web-console -f ;;
        2) journalctl -u cloudflared -f ;;
        3) tail -f /var/log/ptero-assistant.log ;;
        4) journalctl -u wings -f ;;
        5) tail -f /var/log/nginx/error.log ;;
        *) echo "Invalid choice" ;;
    esac
}

ask_prism() {
    echo ""
    read -e -p "Ask P.R.I.S.M: " question
    if [ -n "$question" ]; then
        chatbot ask "$question"
    fi
    echo ""
    read -e -p "Press Enter to continue..."
}

show_help() {
    cat << 'HELPEOF' | less -R

╔════════════════════════════════════════════════════════════════════════╗
║                    PTERODACTYL MANAGEMENT HELP                         ║
╚════════════════════════════════════════════════════════════════════════╝

SYSTEM MANAGEMENT:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1) Update all scripts from GitHub
   • Pulls latest code from GitHub repository
   • Resets any local changes to scripts
   • Sets execute permissions automatically
   • Quick way to get bug fixes and new features
   • SAFE: Does not affect your panel, databases, or game servers

2) Reinstall scripts only (keeps all data/services)
   • Deletes /opt/ptero and /usr/local/bin/chatbot
   • Downloads fresh copy from GitHub
   • Preserves ALL services, configs, and data
   • SAFE: Only reinstalls management scripts
   • Your panel, databases, P.R.I.S.M config are untouched
   • Use when scripts are corrupted or you want a fresh start

3) Check service status
   • Shows if all services are running or stopped
   • Checks: Nginx, MySQL, Redis, Wings, Web Console, Tunnel, P.R.I.S.M
   • Color-coded: Green = running, Red = stopped
   • Quick health check of your entire system

4) View logs
   • Opens real-time logs for any service
   • Choose from: Web Console, Tunnel, P.R.I.S.M, Wings, Nginx
   • Press Ctrl+C to exit log view
   • Useful for troubleshooting errors


P.R.I.S.M AI ASSISTANT:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

5) Enable P.R.I.S.M
   • Starts the AI monitoring service
   • Begins 24/7 system monitoring
   • Auto-fixes common issues
   • Same as running: chatbot -enable

6) Disable P.R.I.S.M
   • Stops the AI monitoring service
   • Monitoring pauses until re-enabled
   • Same as running: chatbot -disable

7) Check P.R.I.S.M status
   • Shows if P.R.I.S.M is running
   • Displays current configuration
   • Shows AI model being used
   • Same as running: chatbot status

8) Run system optimization
   • AI analyzes your ENTIRE system
   • Checks: CPU, RAM, disk, services, security
   • Suggests specific optimizations
   • Offers to apply fixes automatically
   • Takes 1-2 minutes to complete
   • Same as running: chatbot detect

9) Ask P.R.I.S.M a question
   • Interactive prompt to ask AI anything
   • Examples:
     - "Why is CPU usage high?"
     - "How do I optimize MySQL?"
     - "What's causing high memory usage?"
   • Get instant expert advice
   • Same as running: chatbot ask "question"


WEB CONSOLE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

10) Start web console
    • Starts the Pterodactyl Web Console service
    • Makes it accessible at https://console.cloudmc.online
    • Use when console is stopped

11) Stop web console
    • Stops the web console service
    • Console becomes inaccessible
    • Use for maintenance or troubleshooting

12) Restart web console
    • Stops then starts the service
    • Use after config changes
    • Use if console is stuck or not responding

13) View web console logs
    • Real-time logs from the web console
    • See login attempts, errors, API calls
    • Press Ctrl+C to exit
    • Useful for debugging connection issues


CLOUDFLARE TUNNEL:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

14) Start tunnel
    • Starts the Cloudflare tunnel service
    • Makes your services accessible via custom domain
    • Required for external access

15) Stop tunnel
    • Stops the tunnel
    • External access via domain stops working
    • Local access still works

16) Restart tunnel
    • Restarts the tunnel service
    • Use after config changes
    • Use if tunnel shows connection errors

17) View tunnel logs
    • Real-time tunnel logs
    • See connection status, errors, requests
    • Press Ctrl+C to exit
    • Useful for debugging 502 errors


DISCORD BOT:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

18) Start Discord bot
    • Starts the Pterodactyl Discord bot service
    • Enables Discord commands for server management
    • Use when bot is stopped

19) Stop Discord bot
    • Stops the Discord bot service
    • Bot goes offline in Discord
    • Use for maintenance or troubleshooting

20) Restart Discord bot
    • Stops then starts the bot service
    • Use after updating bot code
    • Use if bot is stuck or not responding

21) View Discord bot logs
    • Real-time logs from the Discord bot
    • See command usage, errors, connections
    • Press Ctrl+C to exit
    • Useful for debugging bot issues

22) Update Discord bot
    • Pulls latest bot code from GitHub
    • Updates bot.py and voice_handler.py
    • Installs/updates Python dependencies
    • Automatically restarts the bot
    • Use when new features are added


OTHER:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

23) Install/Setup P.R.I.S.M
    • Runs the full P.R.I.S.M installation script
    • Use for first-time setup
    • Use to reinstall if P.R.I.S.M is broken
    • Downloads AI model (takes 5-10 minutes)

24) Open shell in /opt/ptero
    • Opens a bash shell in the scripts directory
    • For advanced users who want to run custom commands
    • Type 'exit' to return to menu
    • Be careful - you can break things here!

25) Help - What does each option do?
    • Shows this help screen
    • Use arrow keys or Page Up/Down to scroll
    • Press 'q' to exit help

0) Exit
   • Closes the menu interface
   • Returns to normal terminal


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TIP: Use arrow keys or Page Up/Down to scroll. Press 'q' to exit help.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

HELPEOF
}

# Main loop
while true; do
    show_banner
    show_menu
    read -e -p "Select option: " choice
    echo ""
    
    case $choice in
        1) update_scripts ;;
        2) clean_install ;;
        3) check_status ;;
        4) view_logs ;;
        5) chatbot -enable; read -e -p "Press Enter to continue..." ;;
        6) chatbot -disable; read -e -p "Press Enter to continue..." ;;
        7) chatbot status; read -e -p "Press Enter to continue..." ;;
        8) chatbot detect ;;
        9) ask_prism ;;
        10) systemctl start pterodactyl-web-console; echo "Web console started"; read -e -p "Press Enter to continue..." ;;
        11) systemctl stop pterodactyl-web-console; echo "Web console stopped"; read -e -p "Press Enter to continue..." ;;
        12) systemctl restart pterodactyl-web-console; echo "Web console restarted"; read -e -p "Press Enter to continue..." ;;
        13) journalctl -u pterodactyl-web-console -f ;;
        14) systemctl start cloudflared; echo "Tunnel started"; read -e -p "Press Enter to continue..." ;;
        15) systemctl stop cloudflared; echo "Tunnel stopped"; read -e -p "Press Enter to continue..." ;;
        16) systemctl restart cloudflared; echo "Tunnel restarted"; read -e -p "Press Enter to continue..." ;;
        17) journalctl -u cloudflared -f ;;
        18) systemctl start pterodactyl-bot; echo "Discord bot started"; read -e -p "Press Enter to continue..." ;;
        19) systemctl stop pterodactyl-bot; echo "Discord bot stopped"; read -e -p "Press Enter to continue..." ;;
        20) systemctl restart pterodactyl-bot; echo "Discord bot restarted"; read -e -p "Press Enter to continue..." ;;
        21) journalctl -u pterodactyl-bot -f ;;
        22) update_discord_bot ;;
        23) cd /opt/ptero && ./ai-assistant-setup.sh ;;
        24) cd /opt/ptero && bash ;;
        25) show_help ;;
        0) echo "Goodbye!"; exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
    esac
    
    clear
done
