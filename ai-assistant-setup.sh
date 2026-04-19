#!/bin/bash

# AI Assistant Setup - Ollama with Gemma2 for Pterodactyl Server Management
# Provides intelligent monitoring, problem detection, and automated fixes

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

OLLAMA_DIR="/opt/ollama"
ASSISTANT_DIR="/opt/ptero-assistant"
ASSISTANT_CONFIG="$ASSISTANT_DIR/config.json"
ASSISTANT_LOG="/var/log/ptero-assistant.log"

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

prompt_yes_no() {
    local prompt="$1"
    local response
    
    while true; do
        read -p "$prompt (y/n): " response
        case $response in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

show_ai_banner() {
    cat <<'EOF'

╔════════════════════════════════════════════════════════════════════════╗
║              PTERODACTYL AI ASSISTANT SETUP                            ║
║          Intelligent Server Management with Ollama & Gemma2            ║
╚════════════════════════════════════════════════════════════════════════╝

EOF
}

check_system_resources() {
    log_info "Checking system resources..."
    
    # Check RAM
    TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
    AVAILABLE_RAM=$(free -g | awk '/^Mem:/{print $7}')
    
    # Check disk space
    AVAILABLE_DISK=$(df -BG /opt | awk 'NR==2 {print $4}' | sed 's/G//')
    
    echo ""
    echo "System Resources:"
    echo "  Total RAM: ${TOTAL_RAM}GB"
    echo "  Available RAM: ${AVAILABLE_RAM}GB"
    echo "  Available Disk: ${AVAILABLE_DISK}GB"
    echo ""
    
    # Llama 3.2 1B requires ~1GB RAM, ~2GB disk
    if [ "$AVAILABLE_RAM" -lt 2 ]; then
        log_warning "Low RAM detected. AI assistant may impact performance."
        if ! prompt_yes_no "Continue anyway?"; then
            exit 0
        fi
    fi
    
    if [ "$AVAILABLE_DISK" -lt 5 ]; then
        log_error "Insufficient disk space. Need at least 5GB free."
        exit 1
    fi
    
    log_success "System resources sufficient"
}

ask_llm_usage() {
    log_info "AI Model Selection"
    echo ""
    log_info "EXPLANATION: If you plan to use this panel for hosting LLM game servers,"
    log_info "we'll use the lightweight Llama 3.2 1B model to minimize resource usage."
    log_info "Otherwise, we can use Gemma2 2B for better performance."
    echo ""
    
    if prompt_yes_no "Will this panel be used for hosting LLM-based game servers?"; then
        LLM_HOSTING=true
        AI_MODEL="llama3.2:1b"
        log_info "Using Llama 3.2 1B (lightweight, ~1GB RAM) to preserve resources for game servers"
    else
        LLM_HOSTING=false
        echo ""
        echo "Select AI model:"
        echo "  1) Llama 3.2 1B (Lightweight, ~1GB RAM, faster responses)"
        echo "  2) Gemma2 2B (Better accuracy, ~2GB RAM, good balance)"
        echo ""
        read -p "Select [1-2]: " model_choice
        
        case $model_choice in
            1)
                AI_MODEL="llama3.2:1b"
                log_info "Using Llama 3.2 1B"
                ;;
            2)
                AI_MODEL="gemma2:2b"
                log_info "Using Gemma2 2B"
                ;;
            *)
                AI_MODEL="llama3.2:1b"
                log_info "Defaulting to Llama 3.2 1B"
                ;;
        esac
    fi
}

install_ollama() {
    log_info "Installing Ollama..."
    
    if command -v ollama &> /dev/null; then
        log_success "Ollama already installed"
        return 0
    fi
    
    # Install Ollama
    curl -fsSL https://ollama.com/install.sh | sh
    
    # Start Ollama service
    systemctl enable ollama
    systemctl start ollama
    
    # Wait for Ollama to be ready
    sleep 5
    
    log_success "Ollama installed and running"
}

download_ai_model() {
    log_info "Downloading AI model: $AI_MODEL"
    log_warning "This may take several minutes depending on your connection..."
    
    # Pull the model
    ollama pull $AI_MODEL
    
    log_success "AI model downloaded: $AI_MODEL"
}

create_assistant_service() {
    log_info "Creating AI assistant service..."
    
    mkdir -p "$ASSISTANT_DIR"
    
    # Create main assistant script
    cat > "$ASSISTANT_DIR/assistant.py" <<'EOFPY'
#!/usr/bin/env python3

import json
import subprocess
import time
import requests
import os
import sys
from datetime import datetime

CONFIG_FILE = "/opt/ptero-assistant/config.json"
LOG_FILE = "/var/log/ptero-assistant.log"

def log(message, level="INFO"):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"[{timestamp}] [{level}] {message}"
    print(log_entry)
    with open(LOG_FILE, "a") as f:
        f.write(log_entry + "\n")

def load_config():
    try:
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)
    except:
        return {
            "enabled": True,
            "model": "llama3.2:1b",
            "check_interval": 300,
            "auto_fix": True,
            "notify_admin": True
        }

def save_config(config):
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f, indent=2)

def query_ollama(prompt, model="llama3.2:1b"):
    """Query Ollama API"""
    try:
        response = requests.post(
            "http://localhost:11434/api/generate",
            json={
                "model": model,
                "prompt": prompt,
                "stream": False
            },
            timeout=30
        )
        
        if response.status_code == 200:
            return response.json().get("response", "")
        else:
            log(f"Ollama API error: {response.status_code}", "ERROR")
            return None
    except Exception as e:
        log(f"Failed to query Ollama: {e}", "ERROR")
        return None

def check_service_status(service):
    """Check if a service is running"""
    try:
        result = subprocess.run(
            ["systemctl", "is-active", service],
            capture_output=True,
            text=True
        )
        return result.stdout.strip() == "active"
    except:
        return False

def restart_service(service):
    """Restart a service"""
    try:
        subprocess.run(["systemctl", "restart", service], check=True)
        log(f"Restarted service: {service}", "SUCCESS")
        return True
    except:
        log(f"Failed to restart service: {service}", "ERROR")
        return False

def get_system_metrics():
    """Collect system metrics"""
    metrics = {}
    
    # CPU usage
    try:
        cpu = subprocess.run(
            ["top", "-bn1"],
            capture_output=True,
            text=True
        )
        for line in cpu.stdout.split("\n"):
            if "Cpu(s)" in line:
                idle = float(line.split(",")[3].split()[0])
                metrics["cpu_usage"] = round(100 - idle, 2)
                break
    except:
        metrics["cpu_usage"] = 0
    
    # Memory usage
    try:
        mem = subprocess.run(
            ["free", "-m"],
            capture_output=True,
            text=True
        )
        lines = mem.stdout.split("\n")
        if len(lines) > 1:
            parts = lines[1].split()
            total = int(parts[1])
            used = int(parts[2])
            metrics["memory_usage"] = round((used / total) * 100, 2)
            metrics["memory_total_mb"] = total
            metrics["memory_used_mb"] = used
    except:
        metrics["memory_usage"] = 0
    
    # Disk usage
    try:
        disk = subprocess.run(
            ["df", "-h", "/"],
            capture_output=True,
            text=True
        )
        lines = disk.stdout.split("\n")
        if len(lines) > 1:
            parts = lines[1].split()
            metrics["disk_usage"] = parts[4].replace("%", "")
            metrics["disk_available"] = parts[3]
    except:
        metrics["disk_usage"] = 0
    
    # Service status
    services = ["nginx", "mysql", "redis-server", "wings", "docker"]
    metrics["services"] = {}
    for service in services:
        metrics["services"][service] = check_service_status(service)
    
    return metrics

def analyze_system_health(metrics):
    """Use AI to analyze system health"""
    
    # Build context for AI
    context = f"""You are a Pterodactyl server administrator assistant. Analyze this system status:

CPU Usage: {metrics.get('cpu_usage', 0)}%
Memory Usage: {metrics.get('memory_usage', 0)}% ({metrics.get('memory_used_mb', 0)}MB / {metrics.get('memory_total_mb', 0)}MB)
Disk Usage: {metrics.get('disk_usage', 0)}%
Disk Available: {metrics.get('disk_available', 'unknown')}

Service Status:
"""
    
    for service, status in metrics.get("services", {}).items():
        context += f"  - {service}: {'Running' if status else 'STOPPED'}\n"
    
    context += """
Identify any issues and provide:
1. Problem severity (CRITICAL/WARNING/OK)
2. Brief description of issues
3. Recommended actions

Keep response concise and actionable. Format: SEVERITY: description | actions
"""
    
    return query_ollama(context, load_config().get("model", "llama3.2:1b"))

def auto_fix_issues(metrics, config):
    """Automatically fix common issues"""
    fixed = []
    
    if not config.get("auto_fix", False):
        return fixed
    
    # Restart stopped services
    for service, status in metrics.get("services", {}).items():
        if not status and service in ["nginx", "mysql", "redis-server", "wings"]:
            log(f"Detected stopped service: {service}", "WARNING")
            if restart_service(service):
                fixed.append(f"Restarted {service}")
    
    # Clear cache if memory usage is high
    if metrics.get("memory_usage", 0) > 90:
        try:
            subprocess.run(["sync"], check=True)
            subprocess.run(["echo", "3", ">", "/proc/sys/vm/drop_caches"], shell=True)
            fixed.append("Cleared system cache")
            log("Cleared system cache due to high memory usage", "SUCCESS")
        except:
            pass
    
    # Clean old logs if disk usage is high
    if int(metrics.get("disk_usage", "0")) > 85:
        try:
            subprocess.run([
                "find", "/var/log", "-type", "f", "-name", "*.log",
                "-mtime", "+30", "-delete"
            ], check=True)
            fixed.append("Cleaned old log files")
            log("Cleaned old logs due to high disk usage", "SUCCESS")
        except:
            pass
    
    return fixed

def send_notification(message):
    """Send notification to admin (placeholder for future webhook/email integration)"""
    log(f"NOTIFICATION: {message}", "NOTIFY")
    
    # Future: Send to Discord webhook, email, etc.
    # For now, just log it

def monitor_loop():
    """Main monitoring loop"""
    log("AI Assistant started", "INFO")
    
    while True:
        try:
            config = load_config()
            
            if not config.get("enabled", True):
                log("Assistant is disabled, sleeping...", "INFO")
                time.sleep(60)
                continue
            
            # Collect metrics
            metrics = get_system_metrics()
            
            # Analyze with AI
            analysis = analyze_system_health(metrics)
            
            if analysis:
                log(f"AI Analysis: {analysis[:200]}...", "INFO")
                
                # Check for critical issues
                if "CRITICAL" in analysis.upper():
                    log("CRITICAL issue detected!", "ERROR")
                    if config.get("notify_admin", True):
                        send_notification(f"CRITICAL: {analysis}")
                
                # Auto-fix if enabled
                fixes = auto_fix_issues(metrics, config)
                if fixes:
                    fix_msg = "Auto-fixed: " + ", ".join(fixes)
                    log(fix_msg, "SUCCESS")
                    if config.get("notify_admin", True):
                        send_notification(fix_msg)
            
            # Sleep until next check
            time.sleep(config.get("check_interval", 300))
            
        except KeyboardInterrupt:
            log("AI Assistant stopped by user", "INFO")
            break
        except Exception as e:
            log(f"Error in monitoring loop: {e}", "ERROR")
            time.sleep(60)

if __name__ == "__main__":
    monitor_loop()
EOFPY
    
    chmod +x "$ASSISTANT_DIR/assistant.py"
    
    # Create virtual environment and install dependencies
    log_info "Setting up Python virtual environment..."
    
    # Install python3-venv if not present
    if ! python3 -m venv --help &> /dev/null; then
        if [ -f /etc/debian_version ]; then
            apt-get install -y python3-venv python3-full
        elif [ -f /etc/redhat-release ]; then
            yum install -y python3-virtualenv
        fi
    fi
    
    # Create virtual environment
    python3 -m venv "$ASSISTANT_DIR/venv"
    
    # Install requests in venv
    "$ASSISTANT_DIR/venv/bin/pip" install --upgrade pip >/dev/null 2>&1
    "$ASSISTANT_DIR/venv/bin/pip" install requests >/dev/null 2>&1
    
    log_success "Python environment configured"
    
    # Create systemd service
    cat > /etc/systemd/system/ptero-assistant.service <<EOFSVC
[Unit]
Description=Pterodactyl AI Assistant
After=network.target ollama.service

[Service]
Type=simple
User=root
WorkingDirectory=$ASSISTANT_DIR
ExecStart=$ASSISTANT_DIR/venv/bin/python $ASSISTANT_DIR/assistant.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOFSVC
    
    # Set assistant name to P.R.I.S.M
    # P.R.I.S.M = Pterodactyl Resource Intelligence & System Monitor
    ASSISTANT_NAME="P.R.I.S.M"
    
    # Create initial config
    cat > "$ASSISTANT_CONFIG" <<EOFCFG
{
  "enabled": true,
  "model": "$AI_MODEL",
  "check_interval": 300,
  "auto_fix": true,
  "notify_admin": true,
  "llm_hosting_mode": $LLM_HOSTING,
  "assistant_name": "$ASSISTANT_NAME"
}
EOFCFG
    
    systemctl daemon-reload
    systemctl enable ptero-assistant
    systemctl start ptero-assistant
    
    log_success "AI Assistant service created and started"
    
    # Prompt for Discord webhook setup
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  📢 NOTIFICATION SETUP (Optional)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "P.R.I.S.M can send notifications to Discord when issues are detected."
    echo ""
    echo "To set up Discord notifications:"
    echo "  1. Open your Discord server"
    echo "  2. Go to Server Settings → Integrations → Webhooks"
    echo "  3. Click 'New Webhook'"
    echo "  4. Name it 'P.R.I.S.M' and choose a channel"
    echo "  5. Copy the webhook URL"
    echo ""
    
    if prompt_yes_no "Would you like to set up Discord notifications now?"; then
        echo ""
        read -p "Enter your Discord webhook URL: " DISCORD_WEBHOOK
        
        if [ -n "$DISCORD_WEBHOOK" ]; then
            # Save webhook to config
            jq --arg webhook "$DISCORD_WEBHOOK" '.discord_webhook = $webhook' "$ASSISTANT_CONFIG" > "$ASSISTANT_CONFIG.tmp" && mv "$ASSISTANT_CONFIG.tmp" "$ASSISTANT_CONFIG"
            
            # Test webhook
            echo ""
            echo "Testing Discord webhook..."
            
            WEBHOOK_TEST=$(curl -s -X POST "$DISCORD_WEBHOOK" \
                -H "Content-Type: application/json" \
                -d '{
                    "embeds": [{
                        "title": "🤖 P.R.I.S.M Connected",
                        "description": "P.R.I.S.M is now online and will send notifications to this channel!",
                        "color": 65280,
                        "footer": {
                            "text": "Pterodactyl Resource Intelligence & System Monitor"
                        }
                    }]
                }' 2>&1)
            
            if [ $? -eq 0 ]; then
                log_success "Discord webhook configured and tested successfully!"
                echo "  Check your Discord channel for the test message."
            else
                log_warning "Discord webhook may not be working. Check the URL and try again."
                echo "  You can reconfigure it later with: chatbot webhook setup"
            fi
        fi
    else
        echo ""
        echo "Skipping Discord setup. You can configure it later with:"
        echo "  chatbot webhook setup"
    fi
    
    # Prompt for Pterodactyl API setup
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🔌 PTERODACTYL API SETUP (Optional)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "P.R.I.S.M can monitor individual game servers via the Pterodactyl API."
    echo ""
    echo "To set up API access:"
    echo "  1. Log into your Pterodactyl Panel"
    echo "  2. Go to Account → API Credentials"
    echo "  3. Click 'Create API Key'"
    echo "  4. Give it a description (e.g., 'P.R.I.S.M')"
    echo "  5. Select all permissions"
    echo "  6. Copy the API key"
    echo ""
    
    if prompt_yes_no "Would you like to set up Pterodactyl API access now?"; then
        echo ""
        read -p "Enter your Pterodactyl Panel URL (e.g., https://panel.example.com): " PANEL_URL
        read -p "Enter your Pterodactyl API Key: " API_KEY
        
        if [ -n "$PANEL_URL" ] && [ -n "$API_KEY" ]; then
            # Save API config
            cat > /opt/ptero-assistant/pterodactyl-api.json <<EOFAPI
{
  "panel_url": "$PANEL_URL",
  "api_key": "$API_KEY"
}
EOFAPI
            chmod 600 /opt/ptero-assistant/pterodactyl-api.json
            
            # Test API connection
            echo ""
            echo "Testing API connection..."
            
            API_TEST=$(curl -s -H "Authorization: Bearer $API_KEY" \
                -H "Accept: application/json" \
                "$PANEL_URL/api/client/account" 2>&1)
            
            if echo "$API_TEST" | grep -q "email"; then
                log_success "Pterodactyl API configured successfully!"
            else
                log_warning "API connection may not be working. Check your credentials."
                echo "  You can reconfigure it later with: chatbot api setup"
            fi
        fi
    else
        echo ""
        echo "Skipping API setup. You can configure it later with:"
        echo "  chatbot api setup"
    fi
    
    # Create chatbot CLI tool
    create_chatbot_cli() {
    log_info "Creating chatbot CLI tool..."
    
    cat > /usr/local/bin/chatbot <<'EOFCLI'
#!/bin/bash

CONFIG_FILE="/opt/ptero-assistant/config.json"
LOG_FILE="/var/log/ptero-assistant.log"

case "$1" in
    -disable|disable)
        jq '.enabled = false' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        systemctl stop ptero-assistant
        echo "✓ AI Assistant disabled"
        ;;
    
    -enable|enable)
        # Check if assistant already has a name assigned
        EXISTING_NAME=$(jq -r '.assistant_name // empty' "$CONFIG_FILE" 2>/dev/null)
        
        if [ -z "$EXISTING_NAME" ]; then
            # Set assistant name to P.R.I.S.M if not already assigned
            # P.R.I.S.M = Pterodactyl Resource Intelligence & System Monitor
            COOL_NAME="P.R.I.S.M"
            
            # Save the name to config for consistency
            jq --arg name "$COOL_NAME" '.enabled = true | .assistant_name = $name' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        else
            # Use existing name
            COOL_NAME="$EXISTING_NAME"
            jq '.enabled = true' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        fi
        
        systemctl start ptero-assistant
        
        echo ""
        echo "╔════════════════════════════════════════════════════════════════════════╗"
        echo "║                    AI ASSISTANT ACTIVATED                              ║"
        echo "╚════════════════════════════════════════════════════════════════════════╝"
        echo ""
        echo "  🤖  $COOL_NAME is activated and listening, ready to help!"
        echo ""
        echo "  Your AI assistant is now monitoring your Pterodactyl server 24/7."
        echo "  Ask me anything with: chatbot ask \"your question\""
        echo "  Run system analysis: chatbot detect"
        echo ""
        ;;
    
    status)
        if systemctl is-active --quiet ptero-assistant; then
            ASSISTANT_NAME=$(jq -r '.assistant_name // "AI Assistant"' "$CONFIG_FILE")
            echo "╔════════════════════════════════════════════════════════════════════════╗"
            echo "║                    AI ASSISTANT STATUS                                 ║"
            echo "╚════════════════════════════════════════════════════════════════════════╝"
            echo ""
            echo "  🤖  $ASSISTANT_NAME: Online and monitoring"
            echo ""
            echo "Configuration:"
            jq '.' "$CONFIG_FILE"
        else
            echo "AI Assistant: Stopped"
            echo ""
            echo "Run 'chatbot -enable' to activate"
        fi
        ;;
    
    logs)
        tail -f "$LOG_FILE"
        ;;
    
    ask)
        if [ -z "$2" ]; then
            echo "Usage: chatbot ask \"your question\""
            exit 1
        fi
        
        QUESTION="$2"
        MODEL=$(jq -r '.model' "$CONFIG_FILE")
        
        echo "Asking AI..."
        curl -s http://localhost:11434/api/generate -d "{
            \"model\": \"$MODEL\",
            \"prompt\": \"You are a Pterodactyl server administrator assistant. Answer this question concisely: $QUESTION\",
            \"stream\": false
        }" | jq -r '.response'
        ;;
    
    detect)
        echo "╔════════════════════════════════════════════════════════════════════════╗"
        echo "║              SYSTEM OPTIMIZATION DETECTION                             ║"
        echo "╚════════════════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Analyzing your Pterodactyl server for optimization opportunities..."
        echo ""
        
        MODEL=$(jq -r '.model' "$CONFIG_FILE")
        
        # Collect comprehensive system info
        SYSTEM_INFO="System Analysis for Pterodactyl Server:

=== SYSTEM RESOURCES ===
$(free -h | head -2)
$(df -h / | tail -1)
CPU Cores: $(nproc)
Load Average: $(uptime | awk -F'load average:' '{print $2}')

=== SERVICE STATUS ===
Nginx: $(systemctl is-active nginx 2>/dev/null || echo "not found")
MySQL: $(systemctl is-active mysql 2>/dev/null || systemctl is-active mariadb 2>/dev/null || echo "not found")
Redis: $(systemctl is-active redis-server 2>/dev/null || systemctl is-active redis 2>/dev/null || echo "not found")
Wings: $(systemctl is-active wings 2>/dev/null || echo "not installed")
Docker: $(systemctl is-active docker 2>/dev/null || echo "not found")
Fail2ban: $(systemctl is-active fail2ban 2>/dev/null || echo "not installed")

=== PHP CONFIGURATION ===
$(php -v 2>/dev/null | head -1 || echo "PHP not found")
PHP Memory Limit: $(php -r "echo ini_get('memory_limit');" 2>/dev/null || echo "unknown")
PHP Max Execution Time: $(php -r "echo ini_get('max_execution_time');" 2>/dev/null || echo "unknown")

=== MYSQL/MARIADB ===
$(mysql -V 2>/dev/null || echo "MySQL not accessible")
InnoDB Buffer Pool: $(mysql -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';" 2>/dev/null | tail -1 | awk '{print $2}' || echo "unknown")

=== NGINX ===
$(nginx -v 2>&1 || echo "Nginx not found")
Worker Processes: $(grep worker_processes /etc/nginx/nginx.conf 2>/dev/null | head -1 || echo "unknown")

=== REDIS ===
$(redis-cli --version 2>/dev/null || echo "Redis CLI not found")
Max Memory: $(redis-cli config get maxmemory 2>/dev/null | tail -1 || echo "unknown")

=== SECURITY ===
Firewall: $(systemctl is-active ufw 2>/dev/null || systemctl is-active firewalld 2>/dev/null || echo "not configured")
SSL Certificates: $(ls -la /etc/letsencrypt/live/ 2>/dev/null | grep -c "^d" || echo "0")

=== DISK USAGE ===
$(du -sh /var/www/pterodactyl 2>/dev/null || echo "Panel not found")
$(du -sh /var/lib/pterodactyl 2>/dev/null || echo "Wings data not found")
$(du -sh /var/log 2>/dev/null)

=== RECENT ERRORS ===
Panel Errors (last 24h): $(grep -c ERROR /var/www/pterodactyl/storage/logs/laravel-$(date +%Y-%m-%d).log 2>/dev/null || echo "0")
Nginx Errors (last 24h): $(grep -c error /var/log/nginx/error.log 2>/dev/null || echo "0")
"

        # Ask AI for analysis
        echo "🤖 AI is analyzing your system..."
        echo ""
        
        ANALYSIS=$(curl -s http://localhost:11434/api/generate -d "{
            \"model\": \"$MODEL\",
            \"prompt\": \"You are a Pterodactyl server optimization expert. Analyze this system and provide specific, actionable optimization recommendations. Format your response as numbered items with clear categories (Performance, Security, Maintenance, Configuration). Be specific about what to change and why. Here's the system info:\n\n$SYSTEM_INFO\",
            \"stream\": false
        }" | jq -r '.response')
        
        echo "$ANALYSIS"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        # Interactive optimization prompts
        echo "Would you like to apply automatic optimizations? (y/n)"
        read -r apply_auto
        
        if [[ "$apply_auto" =~ ^[Yy]$ ]]; then
            echo ""
            echo "Applying automatic optimizations..."
            echo ""
            
            # PHP Optimization
            if command -v php &> /dev/null; then
                CURRENT_MEM=$(php -r "echo ini_get('memory_limit');" 2>/dev/null)
                if [[ "$CURRENT_MEM" == "128M" ]]; then
                    echo "📝 PHP memory_limit is low (128M)"
                    echo "   Recommendation: Increase to 256M for better performance"
                    read -p "   Apply this fix? (y/n): " fix_php_mem
                    if [[ "$fix_php_mem" =~ ^[Yy]$ ]]; then
                        PHP_INI=$(php -i 2>/dev/null | grep "Loaded Configuration File" | awk '{print $5}')
                        if [ -f "$PHP_INI" ]; then
                            sed -i 's/memory_limit = 128M/memory_limit = 256M/' "$PHP_INI"
                            systemctl restart php*-fpm 2>/dev/null || true
                            echo "   ✓ PHP memory_limit increased to 256M"
                        fi
                    fi
                fi
            fi
            
            # Fail2ban Installation
            if ! systemctl is-active --quiet fail2ban 2>/dev/null; then
                echo ""
                echo "🛡️  Fail2ban is not installed"
                echo "   Recommendation: Install for brute-force protection"
                read -p "   Install Fail2ban now? (y/n): " install_f2b
                if [[ "$install_f2b" =~ ^[Yy]$ ]]; then
                    if [ -f /etc/debian_version ]; then
                        apt-get update && apt-get install -y fail2ban
                    elif [ -f /etc/redhat-release ]; then
                        yum install -y fail2ban
                    fi
                    echo "   ✓ Fail2ban installed (run quick-setup.sh to configure)"
                fi
            fi
            
            # Redis Optimization
            if systemctl is-active --quiet redis-server 2>/dev/null || systemctl is-active --quiet redis 2>/dev/null; then
                REDIS_MEM=$(redis-cli config get maxmemory 2>/dev/null | tail -1)
                if [[ "$REDIS_MEM" == "0" ]]; then
                    echo ""
                    echo "💾 Redis has no memory limit set"
                    echo "   Recommendation: Set maxmemory to prevent OOM issues"
                    read -p "   Set Redis maxmemory to 256MB? (y/n): " fix_redis
                    if [[ "$fix_redis" =~ ^[Yy]$ ]]; then
                        redis-cli config set maxmemory 268435456 2>/dev/null
                        redis-cli config set maxmemory-policy allkeys-lru 2>/dev/null
                        echo "   ✓ Redis maxmemory set to 256MB with LRU eviction"
                    fi
                fi
            fi
            
            # Log Rotation
            if [ ! -f /etc/logrotate.d/pterodactyl ]; then
                echo ""
                echo "📋 Pterodactyl log rotation not configured"
                echo "   Recommendation: Configure logrotate to prevent disk fill"
                read -p "   Configure log rotation? (y/n): " fix_logrotate
                if [[ "$fix_logrotate" =~ ^[Yy]$ ]]; then
                    cat > /etc/logrotate.d/pterodactyl <<'EOFLOG'
/var/www/pterodactyl/storage/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
    sharedscripts
}
EOFLOG
                    echo "   ✓ Log rotation configured (14 day retention)"
                fi
            fi
            
            # Nginx Worker Optimization
            if command -v nginx &> /dev/null; then
                WORKERS=$(grep -E "^worker_processes" /etc/nginx/nginx.conf 2>/dev/null | awk '{print $2}' | tr -d ';')
                CPU_CORES=$(nproc)
                if [[ "$WORKERS" != "auto" ]] && [[ "$WORKERS" != "$CPU_CORES" ]]; then
                    echo ""
                    echo "⚡ Nginx worker processes not optimized"
                    echo "   Current: $WORKERS | Recommended: $CPU_CORES (auto)"
                    read -p "   Optimize Nginx workers? (y/n): " fix_nginx
                    if [[ "$fix_nginx" =~ ^[Yy]$ ]]; then
                        sed -i "s/worker_processes.*/worker_processes auto;/" /etc/nginx/nginx.conf
                        nginx -t && systemctl reload nginx
                        echo "   ✓ Nginx workers set to auto"
                    fi
                fi
            fi
            
            # MySQL/MariaDB Optimization
            if command -v mysql &> /dev/null; then
                INNODB_BUFFER=$(mysql -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';" 2>/dev/null | tail -1 | awk '{print $2}')
                TOTAL_RAM=$(free -b | awk '/^Mem:/{print $2}')
                RECOMMENDED_BUFFER=$((TOTAL_RAM * 70 / 100))
                
                if [ -n "$INNODB_BUFFER" ] && [ "$INNODB_BUFFER" -lt "$RECOMMENDED_BUFFER" ]; then
                    echo ""
                    echo "🗄️  MySQL InnoDB buffer pool is small"
                    echo "   Current: $((INNODB_BUFFER / 1024 / 1024))MB | Recommended: $((RECOMMENDED_BUFFER / 1024 / 1024))MB"
                    read -p "   Optimize MySQL configuration? (y/n): " fix_mysql
                    if [[ "$fix_mysql" =~ ^[Yy]$ ]]; then
                        echo "   Note: Edit /etc/mysql/my.cnf or /etc/my.cnf.d/server.cnf"
                        echo "   Add: innodb_buffer_pool_size = $((RECOMMENDED_BUFFER / 1024 / 1024))M"
                        echo "   Then: systemctl restart mysql"
                        read -p "   Press Enter to continue..."
                    fi
                fi
            fi
            
            # Swap Configuration
            SWAP_TOTAL=$(free -m | awk '/^Swap:/{print $2}')
            if [ "$SWAP_TOTAL" -eq 0 ]; then
                echo ""
                echo "💿 No swap space configured"
                echo "   Recommendation: Add 2GB swap for memory buffer"
                read -p "   Create swap file? (y/n): " create_swap
                if [[ "$create_swap" =~ ^[Yy]$ ]]; then
                    fallocate -l 2G /swapfile
                    chmod 600 /swapfile
                    mkswap /swapfile
                    swapon /swapfile
                    echo '/swapfile none swap sw 0 0' >> /etc/fstab
                    echo "   ✓ 2GB swap file created and enabled"
                fi
            fi
            
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "✓ Automatic optimizations complete!"
            echo ""
            echo "Additional recommendations from AI analysis above may require manual configuration."
        else
            echo "Skipped automatic optimizations. Review AI recommendations above."
        fi
        
        echo ""
        echo "💡 Tip: Run 'chatbot detect' regularly to keep your server optimized!"
        ;;
    
    webhook)
        case "$2" in
            setup)
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "  📢 DISCORD WEBHOOK SETUP"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                echo "How to create a Discord webhook:"
                echo "  1. Open your Discord server"
                echo "  2. Go to Server Settings → Integrations → Webhooks"
                echo "  3. Click 'New Webhook'"
                echo "  4. Name it 'P.R.I.S.M' and choose a channel"
                echo "  5. Click 'Copy Webhook URL'"
                echo ""
                read -p "Enter your Discord webhook URL: " WEBHOOK_URL
                
                if [ -n "$WEBHOOK_URL" ]; then
                    jq --arg webhook "$WEBHOOK_URL" '.discord_webhook = $webhook' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
                    
                    echo ""
                    echo "Testing webhook..."
                    curl -s -X POST "$WEBHOOK_URL" \
                        -H "Content-Type: application/json" \
                        -d '{
                            "embeds": [{
                                "title": "🤖 P.R.I.S.M Webhook Test",
                                "description": "Webhook configured successfully! You will receive notifications here.",
                                "color": 65280
                            }]
                        }' > /dev/null
                    
                    echo "✓ Discord webhook configured!"
                    echo "  Check your Discord channel for the test message."
                else
                    echo "✗ No webhook URL provided"
                fi
                ;;
            
            test)
                WEBHOOK_URL=$(jq -r '.discord_webhook // empty' "$CONFIG_FILE")
                if [ -z "$WEBHOOK_URL" ]; then
                    echo "✗ No webhook configured. Run: chatbot webhook setup"
                    exit 1
                fi
                
                echo "Sending test message..."
                curl -s -X POST "$WEBHOOK_URL" \
                    -H "Content-Type: application/json" \
                    -d '{
                        "embeds": [{
                            "title": "🤖 P.R.I.S.M Test Alert",
                            "description": "This is a test notification from P.R.I.S.M",
                            "color": 16776960,
                            "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%S)'.000Z"
                        }]
                    }' > /dev/null
                
                echo "✓ Test message sent! Check your Discord channel."
                ;;
            
            remove)
                jq 'del(.discord_webhook)' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
                echo "✓ Discord webhook removed"
                ;;
            
            *)
                cat <<WEBHOOKHELP
Discord Webhook Commands:

  chatbot webhook setup     Configure Discord webhook
  chatbot webhook test      Send test message
  chatbot webhook remove    Remove webhook

P.R.I.S.M will send notifications for:
  • Critical system alerts
  • High resource usage warnings
  • Service failures
  • Security issues
  • Daily summary reports
WEBHOOKHELP
                ;;
        esac
        ;;
    
    api)
        case "$2" in
            setup)
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "  🔌 PTERODACTYL API SETUP"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                echo "How to create an API key:"
                echo "  1. Log into your Pterodactyl Panel"
                echo "  2. Go to Account → API Credentials"
                echo "  3. Click 'Create API Key'"
                echo "  4. Give it a description (e.g., 'P.R.I.S.M')"
                echo "  5. Select all permissions"
                echo "  6. Click 'Create' and copy the key"
                echo ""
                read -p "Enter your Panel URL (e.g., https://panel.example.com): " PANEL_URL
                read -p "Enter your API Key: " API_KEY
                
                if [ -n "$PANEL_URL" ] && [ -n "$API_KEY" ]; then
                    cat > /opt/ptero-assistant/pterodactyl-api.json <<EOFAPI
{
  "panel_url": "$PANEL_URL",
  "api_key": "$API_KEY"
}
EOFAPI
                    chmod 600 /opt/ptero-assistant/pterodactyl-api.json
                    
                    echo ""
                    echo "Testing API connection..."
                    API_TEST=$(curl -s -H "Authorization: Bearer $API_KEY" \
                        -H "Accept: application/json" \
                        "$PANEL_URL/api/client/account")
                    
                    if echo "$API_TEST" | grep -q "email"; then
                        echo "✓ API configured successfully!"
                    else
                        echo "✗ API connection failed. Check your credentials."
                    fi
                else
                    echo "✗ Missing Panel URL or API Key"
                fi
                ;;
            
            test)
                if [ ! -f /opt/ptero-assistant/pterodactyl-api.json ]; then
                    echo "✗ API not configured. Run: chatbot api setup"
                    exit 1
                fi
                
                PANEL_URL=$(jq -r '.panel_url' /opt/ptero-assistant/pterodactyl-api.json)
                API_KEY=$(jq -r '.api_key' /opt/ptero-assistant/pterodactyl-api.json)
                
                echo "Testing API connection..."
                API_TEST=$(curl -s -H "Authorization: Bearer $API_KEY" \
                    -H "Accept: application/json" \
                    "$PANEL_URL/api/client/account")
                
                if echo "$API_TEST" | grep -q "email"; then
                    EMAIL=$(echo "$API_TEST" | jq -r '.attributes.email')
                    echo "✓ API connection successful!"
                    echo "  Connected as: $EMAIL"
                else
                    echo "✗ API connection failed"
                fi
                ;;
            
            remove)
                rm -f /opt/ptero-assistant/pterodactyl-api.json
                echo "✓ API configuration removed"
                ;;
            
            *)
                cat <<APIHELP
Pterodactyl API Commands:

  chatbot api setup      Configure API access
  chatbot api test       Test API connection
  chatbot api remove     Remove API config

With API access, P.R.I.S.M can:
  • Monitor individual game servers
  • Track server status and uptime
  • Auto-restart crashed servers
  • Monitor resource usage per server
APIHELP
                ;;
        esac
        ;;
    
    config)
        nano "$CONFIG_FILE"
        systemctl restart ptero-assistant
        echo "✓ Configuration updated and service restarted"
        ;;
    
    restart)
        systemctl restart ptero-assistant
        echo "✓ AI Assistant restarted"
        ;;
    
    help|--help|-h)
        cat <<HELP
╔════════════════════════════════════════════════════════════════════════╗
║                    P.R.I.S.M COMMAND REFERENCE                         ║
║        Pterodactyl Resource Intelligence & System Monitor              ║
╚════════════════════════════════════════════════════════════════════════╝

BASIC COMMANDS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  chatbot -enable              Enable P.R.I.S.M
  chatbot -disable             Disable P.R.I.S.M
  chatbot status               Show current status
  chatbot logs                 View live logs
  chatbot restart              Restart P.R.I.S.M service
  chatbot config               Edit configuration

AI INTERACTION:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  chatbot ask "question"       Ask AI anything
  chatbot detect               Run system analysis & optimization

NOTIFICATIONS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  chatbot webhook setup        Configure Discord webhook
  chatbot webhook test         Test webhook
  chatbot webhook remove       Remove webhook

API INTEGRATION:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  chatbot api setup            Configure Pterodactyl API
  chatbot api test             Test API connection
  chatbot api remove           Remove API config

EXAMPLES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # Enable P.R.I.S.M
  chatbot -enable

  # Run system optimization
  chatbot detect

  # Ask AI for help
  chatbot ask "Why is CPU usage high?"
  chatbot ask "How do I optimize MySQL?"
  chatbot ask "What's causing high memory usage?"

  # Set up Discord notifications
  chatbot webhook setup

  # Configure API for game server monitoring
  chatbot api setup

  # Check status
  chatbot status

  # View logs
  chatbot logs

WHAT P.R.I.S.M DOES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✓ 24/7 system monitoring
  ✓ AI-powered problem detection
  ✓ Automatic issue resolution
  ✓ Discord notifications
  ✓ Game server health monitoring
  ✓ Performance optimization
  ✓ Security scanning
  ✓ Predictive maintenance

For more help: chatbot help
HELP
        ;;
    
    *)
        cat <<SHORTHELP
P.R.I.S.M - Pterodactyl Resource Intelligence & System Monitor

Quick Commands:
  chatbot -enable          Enable P.R.I.S.M
  chatbot status           Show status
  chatbot detect           Run system analysis
  chatbot ask "question"   Ask AI anything
  chatbot webhook setup    Configure Discord
  chatbot api setup        Configure API
  chatbot help             Show all commands

Examples:
  chatbot detect
  chatbot ask "Why is nginx using high CPU?"
  chatbot webhook setup

For detailed help: chatbot help
SHORTHELP
        ;;
esac
EOFCLI
    
    chmod +x /usr/local/bin/chatbot
    
    # Install jq if not present
    if ! command -v jq &> /dev/null; then
        if [ -f /etc/debian_version ]; then
            apt-get install -y jq
        elif [ -f /etc/redhat-release ]; then
            yum install -y jq
        fi
    fi
    
    log_success "Chatbot CLI tool created"
    }
    
    create_chatbot_cli
}

show_usage_examples() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                    AI ASSISTANT ACTIVATED                              ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  🤖  $ASSISTANT_NAME is activated and listening, ready to help!"
    echo ""
    echo "  Your AI assistant is now monitoring your Pterodactyl server 24/7."
    echo ""
    
    cat <<'EOF'
╔════════════════════════════════════════════════════════════════════════╗
║                         USAGE EXAMPLES                                 ║
╚════════════════════════════════════════════════════════════════════════╝

Quick Start Commands:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  BASIC:
    chatbot -enable              Enable P.R.I.S.M
    chatbot -disable             Disable P.R.I.S.M
    chatbot status               View current status
    chatbot logs                 View live logs
    chatbot restart              Restart service
    chatbot help                 Show all commands

  AI INTERACTION:
    chatbot ask "question"       Ask AI anything
    chatbot detect               Run system analysis & optimization

  NOTIFICATIONS:
    chatbot webhook setup        Configure Discord notifications
    chatbot webhook test         Test Discord webhook
    
  API INTEGRATION:
    chatbot api setup            Configure Pterodactyl API
    chatbot api test             Test API connection

Examples:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  # Run full system optimization
  chatbot detect

  # Ask AI for help
  chatbot ask "Why is my server slow?"
  chatbot ask "How do I optimize MySQL?"
  chatbot ask "What's causing high memory usage?"
  
  # Set up Discord notifications
  chatbot webhook setup
  
  # Configure API for game server monitoring
  chatbot api setup
  
  # Check status
  chatbot status
  
  # View logs
  chatbot logs
  
  # Get help
  chatbot help

What the AI Does Automatically:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ✓ Monitors system resources every 5 minutes
  ✓ Detects stopped services and restarts them
  ✓ Clears cache when memory is high (>90%)
  ✓ Cleans old logs when disk is full (>85%)
  ✓ Analyzes issues with AI intelligence
  ✓ Logs all actions for review

Configuration:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Location: /opt/ptero-assistant/config.json
  
  Settings:
    - enabled: true/false
    - model: llama3.2:1b or gemma2:2b
    - check_interval: seconds between checks (default: 300)
    - auto_fix: automatically fix issues (default: true)
    - notify_admin: send notifications (default: true)

Logs:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Location: /var/log/ptero-assistant.log
  
  View live: chatbot logs
  View recent: tail -100 /var/log/ptero-assistant.log

EOF
}

main() {
    show_ai_banner
    
    log_info "This will install an AI-powered assistant for your Pterodactyl server."
    echo ""
    log_info "Features:"
    echo "  • Intelligent system monitoring"
    echo "  • Automatic problem detection"
    echo "  • Auto-fix common issues"
    echo "  • Ask questions anytime with 'chatbot ask'"
    echo "  • Easy enable/disable with 'chatbot -enable/-disable'"
    echo ""
    
    if ! prompt_yes_no "Install AI assistant?"; then
        log_info "Installation cancelled"
        exit 0
    fi
    
    echo ""
    check_system_resources
    ask_llm_usage
    install_ollama
    download_ai_model
    create_assistant_service
    create_chatbot_cli
    
    log_success "AI Assistant installation complete!"
    echo ""
    
    # Auto-enable chatbot
    log_info "Enabling P.R.I.S.M..."
    chatbot -enable
    
    echo ""
    show_usage_examples
    
    # Interactive tutorial
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🎓 QUICK TUTORIAL"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if prompt_yes_no "Would you like a quick interactive tutorial?"; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  LESSON 1: Check Status"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Let's check if P.R.I.S.M is running:"
        echo ""
        read -p "Press Enter to run: chatbot status"
        chatbot status
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  LESSON 2: Ask P.R.I.S.M a Question"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "You can ask P.R.I.S.M anything about your server:"
        echo ""
        read -p "Press Enter to run: chatbot ask \"Introduce yourself\""
        chatbot ask "Introduce yourself as P.R.I.S.M and briefly explain what you can do for this Pterodactyl server in 2-3 sentences"
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  LESSON 3: System Analysis"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "P.R.I.S.M can analyze your entire system and suggest optimizations:"
        echo ""
        if prompt_yes_no "Run system analysis now? (This will take 1-2 minutes)"; then
            chatbot detect
        else
            echo "You can run it anytime with: chatbot detect"
        fi
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  LESSON 4: Set Up Notifications (Optional)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Get instant alerts on Discord when issues are detected!"
        echo ""
        if prompt_yes_no "Set up Discord notifications now?"; then
            chatbot webhook setup
        else
            echo "You can set it up later with: chatbot webhook setup"
        fi
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  LESSON 5: API Integration (Optional)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Monitor individual game servers with Pterodactyl API!"
        echo ""
        if prompt_yes_no "Set up API integration now?"; then
            chatbot api setup
        else
            echo "You can set it up later with: chatbot api setup"
        fi
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  🎉 TUTORIAL COMPLETE!"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "You're all set! Here are some things to try:"
        echo ""
        echo "  💬 Ask questions:"
        echo "     chatbot ask \"Why is CPU usage high?\""
        echo "     chatbot ask \"How do I optimize MySQL?\""
        echo ""
        echo "  🔍 Run analysis:"
        echo "     chatbot detect"
        echo ""
        echo "  📊 Check status:"
        echo "     chatbot status"
        echo ""
        echo "  📖 Get help:"
        echo "     chatbot help"
        echo ""
        echo "  📝 View logs:"
        echo "     chatbot logs"
        echo ""
    else
        echo ""
        echo "No problem! Here's a quick reference:"
        echo ""
        echo "  chatbot status           # Check if running"
        echo "  chatbot ask \"question\"   # Ask anything"
        echo "  chatbot detect           # Run system analysis"
        echo "  chatbot webhook setup    # Set up Discord"
        echo "  chatbot api setup        # Set up API"
        echo "  chatbot help             # Show all commands"
        echo ""
    fi
    
    echo ""
    log_success "P.R.I.S.M is now protecting your server 24/7! 🚀"
    echo ""
}

main "$@"
