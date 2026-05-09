#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

AI_URL=""
INSTALL_LOG="/var/log/ai-assisted-install.log"

show_ai_assistant_intro() {
    dialog --clear --backtitle "AI-Assisted Installation" \
        --title "🤖 Welcome to AI-Assisted Installation!" \
        --msgbox "This mode will:\n\n\
1. Install Ollama AI Server (5 minutes)\n\
2. Install Open WebUI (3 minutes)\n\
3. Download a helpful AI model (10-15 minutes)\n\
4. Give you access to an AI assistant at ai.yourdomain.com\n\n\
The AI can then help you with:\n\
• Understanding installation steps\n\
• Troubleshooting errors\n\
• Explaining technical concepts\n\
• Choosing the right configuration\n\
• Writing custom scripts\n\n\
Total time: ~20 minutes\n\n\
After this, you can ask the AI for help with the rest of your installation!" 24 75
}

install_ollama_quick() {
    echo "Installing Ollama..." | tee -a "$INSTALL_LOG"
    
    # Install Ollama
    curl -fsSL https://ollama.com/install.sh | sh
    
    # Start Ollama service
    systemctl enable ollama
    systemctl start ollama
    
    # Wait for Ollama to be ready
    sleep 5
    
    echo "Ollama installed successfully!" | tee -a "$INSTALL_LOG"
}

install_openwebui_quick() {
    echo "Installing Open WebUI..." | tee -a "$INSTALL_LOG"
    
    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com | sh
        systemctl enable docker
        systemctl start docker
    fi
    
    # Run Open WebUI container
    docker run -d \
        --name open-webui \
        --restart always \
        -p 3000:8080 \
        -v open-webui:/app/backend/data \
        -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
        --add-host=host.docker.internal:host-gateway \
        ghcr.io/open-webui/open-webui:main
    
    echo "Open WebUI installed successfully!" | tee -a "$INSTALL_LOG"
}

download_ai_model() {
    local model=$1
    
    dialog --clear --backtitle "AI-Assisted Installation" \
        --title "Downloading AI Model" \
        --infobox "Downloading $model...\n\nThis may take 10-15 minutes depending on your internet speed.\n\nModel size: ~4GB" 10 60
    
    # Pull the model
    ollama pull $model 2>&1 | tee -a "$INSTALL_LOG"
    
    dialog --clear --backtitle "AI-Assisted Installation" \
        --title "✅ Model Downloaded!" \
        --msgbox "AI model '$model' is ready!\n\nYou can now chat with the AI assistant." 10 60
}

choose_ai_model() {
    local model
    model=$(dialog --clear --backtitle "AI-Assisted Installation" \
        --title "Choose AI Model" \
        --menu "Select which AI model to download:" 18 70 6 \
        1 "Llama 3.2 (Recommended) - 2GB, Fast & Smart" \
        2 "Mistral - 4GB, Very Capable" \
        3 "Phi-3 - 2GB, Efficient" \
        4 "CodeLlama - 4GB, Best for Code Help" \
        5 "Gemma 2 - 3GB, Google's Model" \
        6 "Skip for now (install model later)" \
        3>&1 1>&2 2>&3)
    
    case $model in
        1) echo "llama3.2" ;;
        2) echo "mistral" ;;
        3) echo "phi3" ;;
        4) echo "codellama" ;;
        5) echo "gemma2" ;;
        6) echo "" ;;
        *) echo "llama3.2" ;;
    esac
}

setup_ai_domain() {
    if dialog --yesno "Would you like to set up a domain for your AI assistant?\n\nThis will make it accessible at ai.yourdomain.com" 10 60; then
        bash /opt/ptero/setup-domain-wizard.sh --component "AI Assistant" "ai"
        
        if [ $? -eq 0 ]; then
            source /etc/automatic-system/domains.conf
            AI_URL="https://$AI_DOMAIN"
            
            # Setup Nginx reverse proxy
            setup_nginx_proxy "$AI_DOMAIN"
        fi
    else
        # Use localhost
        AI_URL="http://localhost:3000"
    fi
}

setup_nginx_proxy() {
    local domain=$1
    
    # Install Nginx if not present
    if ! command -v nginx &> /dev/null; then
        apt-get update
        apt-get install -y nginx
    fi
    
    # Create Nginx config
    cat > /etc/nginx/sites-available/open-webui << EOF
server {
    listen 80;
    server_name $domain;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/open-webui /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
    
    # Install SSL with Certbot
    if command -v certbot &> /dev/null; then
        certbot --nginx -d $domain --non-interactive --agree-tos --email admin@$domain
    fi
}

create_installation_assistant_prompt() {
    local prompt_file="/opt/ptero/ai-install-assistant.txt"
    
    cat > "$prompt_file" << 'EOF'
You are an expert Linux system administrator and Pterodactyl installation assistant. You are helping a user install and configure Pterodactyl Panel and Wings on their server.

Your role:
- Explain technical concepts in simple terms
- Help troubleshoot installation errors
- Suggest best practices for server configuration
- Answer questions about domains, DNS, SSL, and networking
- Provide step-by-step guidance when needed
- Write scripts and commands when requested

Current installation context:
- OS: Ubuntu 22.04 LTS
- Pterodactyl Panel version: 1.11.5
- Pterodactyl Wings version: 1.11.5
- Installation method: Automatic installation script

Available components to install:
1. Pterodactyl Panel (web interface)
2. Pterodactyl Wings (game server daemon)
3. FileBrowser (file management)
4. Pingvin Share (file sharing)
5. Nextcloud (cloud storage)
6. Admin Panel (unified control panel)
7. SSH Terminal (web-based terminal)

Common tasks you can help with:
- Domain and DNS setup
- Cloudflare configuration
- SSL certificate installation
- Firewall configuration
- Database setup
- Troubleshooting connection issues
- Performance optimization

Be friendly, patient, and thorough in your explanations. If you don't know something, say so and suggest where to find the information.
EOF
    
    echo "$prompt_file"
}

show_ai_access_info() {
    local access_url=$1
    local model=$2
    
    dialog --clear --backtitle "AI-Assisted Installation" \
        --title "🎉 AI Assistant Ready!" \
        --msgbox "Your AI assistant is now running!\n\n\
Access URL: $access_url\n\
AI Model: $model\n\n\
First-time setup:\n\
1. Open $access_url in your browser\n\
2. Create an admin account\n\
3. Start chatting with the AI!\n\n\
Example questions to ask:\n\
• 'How do I set up a domain for Pterodactyl Panel?'\n\
• 'What's the difference between Panel and Wings?'\n\
• 'Help me troubleshoot a DNS issue'\n\
• 'Explain how to configure SSL certificates'\n\
• 'Write a script to backup my database'\n\n\
The AI has been configured to help with your installation!" 24 75
}

offer_continue_installation() {
    if dialog --yesno "Would you like to continue with the main installation now?\n\nYou can:\n• Keep the AI assistant open in another tab\n• Ask it questions as you go\n• Get help if you encounter errors\n\nContinue to main installer?" 14 65; then
        return 0
    else
        dialog --clear --backtitle "AI-Assisted Installation" \
            --title "Installation Paused" \
            --msgbox "Installation paused.\n\nYour AI assistant is running at:\n$AI_URL\n\nTo continue installation later, run:\nbash install-interactive.sh\n\nThe AI will still be available to help!" 14 65
        return 1
    fi
}

main() {
    # Show intro
    show_ai_assistant_intro
    
    # Install Ollama
    (
        echo "10"
        install_ollama_quick
        echo "30"
        sleep 1
    ) | dialog --clear --backtitle "AI-Assisted Installation" \
        --title "Installing Ollama" \
        --gauge "Installing Ollama AI Server..." 10 70 0
    
    # Install Open WebUI
    (
        echo "40"
        install_openwebui_quick
        echo "60"
        sleep 1
    ) | dialog --clear --backtitle "AI-Assisted Installation" \
        --title "Installing Open WebUI" \
        --gauge "Installing Open WebUI interface..." 10 70 0
    
    # Setup domain (optional)
    setup_ai_domain
    
    # Choose and download model
    local model=$(choose_ai_model)
    
    if [ -n "$model" ]; then
        download_ai_model "$model"
    else
        model="(none - install later)"
    fi
    
    # Create assistant prompt
    create_installation_assistant_prompt
    
    # Show access info
    show_ai_access_info "$AI_URL" "$model"
    
    # Offer to continue
    if offer_continue_installation; then
        # Return to main installer
        exec bash /opt/ptero/install-interactive.sh
    fi
}

main "$@"
