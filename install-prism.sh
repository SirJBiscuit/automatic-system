#!/bin/bash

# P.R.I.S.M Installation Script
# Pterodactyl Resource Intelligence & System Monitor

set -e

INSTALL_DIR="/opt/ptero-assistant"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║                    P.R.I.S.M INSTALLATION                              ║"
echo "║        Pterodactyl Resource Intelligence & System Monitor              ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] This script must be run as root"
   exit 1
fi

echo "[INFO] Installing P.R.I.S.M Enhanced..."
echo ""

# Install system dependencies
echo "[INFO] Installing system dependencies..."
apt-get update -qq
apt-get install -y python3 python3-pip sqlite3 curl jq bc sysstat net-tools >/dev/null 2>&1

# Create installation directory
echo "[INFO] Creating installation directory..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Copy P.R.I.S.M files
echo "[INFO] Installing P.R.I.S.M files..."
if [ -f "$SCRIPT_DIR/prism-enhanced.py" ]; then
    cp "$SCRIPT_DIR/prism-enhanced.py" "$INSTALL_DIR/assistant.py"
    chmod +x "$INSTALL_DIR/assistant.py"
else
    echo "[ERROR] prism-enhanced.py not found in $SCRIPT_DIR"
    exit 1
fi

# Install Python dependencies
echo "[INFO] Installing Python dependencies..."
cat > requirements.txt <<EOF
anthropic>=0.18.0
requests>=2.31.0
psutil>=5.9.0
python-dotenv>=1.0.0
EOF

pip3 install -r requirements.txt >/dev/null 2>&1

# Create configuration file
echo "[INFO] Creating configuration..."
cat > config.json <<EOF
{
    "enabled": true,
    "check_interval": 300,
    "log_file": "/var/log/ptero-assistant.log",
    "thresholds": {
        "cpu": 80,
        "memory": 85,
        "disk": 90
    }
}
EOF

# Initialize database
echo "[INFO] Initializing database..."
sqlite3 prism.db <<EOF
CREATE TABLE IF NOT EXISTS webhooks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    url TEXT NOT NULL,
    enabled INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL,
    message TEXT NOT NULL,
    severity TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    metric_type TEXT NOT NULL,
    value REAL NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# Create chatbot CLI command
echo "[INFO] Creating chatbot command..."
cat > /usr/local/bin/chatbot <<'EOFCLI'
#!/bin/bash

INSTALL_DIR="/opt/ptero-assistant"
CONFIG_FILE="$INSTALL_DIR/config.json"
DB_FILE="$INSTALL_DIR/prism.db"
LOG_FILE="/var/log/ptero-assistant.log"

case "$1" in
    -enable|enable)
        echo "✓ Enabling P.R.I.S.M..."
        systemctl enable ptero-assistant >/dev/null 2>&1
        systemctl start ptero-assistant
        echo "✓ P.R.I.S.M is now running"
        echo ""
        echo "Check status: chatbot status"
        ;;
    
    -disable|disable)
        echo "✓ Disabling P.R.I.S.M..."
        systemctl stop ptero-assistant
        systemctl disable ptero-assistant >/dev/null 2>&1
        echo "✓ P.R.I.S.M has been stopped"
        ;;
    
    status)
        if systemctl is-active --quiet ptero-assistant; then
            echo "✅ P.R.I.S.M Status: Online and monitoring"
            echo ""
            systemctl status ptero-assistant --no-pager -l | head -15
        else
            echo "❌ P.R.I.S.M Status: Offline"
            echo ""
            echo "Start with: chatbot -enable"
        fi
        ;;
    
    logs)
        echo "📋 P.R.I.S.M Logs (Ctrl+C to exit)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        journalctl -u ptero-assistant -f
        ;;
    
    restart)
        echo "🔄 Restarting P.R.I.S.M..."
        systemctl restart ptero-assistant
        echo "✓ P.R.I.S.M restarted"
        ;;
    
    detect)
        echo "🔍 Running P.R.I.S.M system analysis..."
        echo ""
        python3 "$INSTALL_DIR/assistant.py" --detect
        ;;
    
    ask)
        if [ -z "$2" ]; then
            echo "Usage: chatbot ask \"your question\""
            exit 1
        fi
        shift
        python3 "$INSTALL_DIR/assistant.py" --ask "$*"
        ;;
    
    webhook)
        case "$2" in
            setup)
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "  Discord Webhook Setup"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                echo "To get a Discord webhook URL:"
                echo "1. Open Discord server"
                echo "2. Server Settings → Integrations → Webhooks"
                echo "3. New Webhook → Name it 'P.R.I.S.M'"
                echo "4. Copy Webhook URL"
                echo ""
                read -p "Enter webhook URL: " webhook_url
                
                if [ -z "$webhook_url" ]; then
                    echo "❌ No URL provided"
                    exit 1
                fi
                
                sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO webhooks (id, name, url, enabled) VALUES (1, 'default', '$webhook_url', 1)"
                echo ""
                echo "✓ Webhook configured!"
                echo ""
                echo "Test it with: chatbot webhook test"
                ;;
            
            test)
                webhook_url=$(sqlite3 "$DB_FILE" "SELECT url FROM webhooks WHERE id=1" 2>/dev/null)
                
                if [ -z "$webhook_url" ]; then
                    echo "❌ No webhook configured"
                    echo "Set up with: chatbot webhook setup"
                    exit 1
                fi
                
                echo "📤 Sending test message..."
                
                curl -X POST "$webhook_url" \
                    -H "Content-Type: application/json" \
                    -d "{\"content\":\"🤖 **P.R.I.S.M Test Message**\n\nWebhook is working correctly! ✅\"}" \
                    >/dev/null 2>&1
                
                if [ $? -eq 0 ]; then
                    echo "✓ Test message sent successfully!"
                    echo "Check your Discord channel."
                else
                    echo "❌ Failed to send message"
                    echo "Check your webhook URL"
                fi
                ;;
            
            remove)
                sqlite3 "$DB_FILE" "DELETE FROM webhooks WHERE id=1"
                echo "✓ Webhook removed"
                ;;
            
            *)
                echo "Webhook commands:"
                echo "  chatbot webhook setup   - Configure Discord webhook"
                echo "  chatbot webhook test    - Send test message"
                echo "  chatbot webhook remove  - Remove webhook"
                ;;
        esac
        ;;
    
    api)
        case "$2" in
            setup)
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "  Pterodactyl API Setup"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                echo "To get an API key:"
                echo "1. Log into Pterodactyl Panel"
                echo "2. Account → API Credentials"
                echo "3. Create API Key with full permissions"
                echo "4. Copy the key (starts with ptlc_)"
                echo ""
                read -p "Enter Panel URL (e.g., https://panel.example.com): " panel_url
                read -p "Enter API Key: " api_key
                
                if [ -z "$panel_url" ] || [ -z "$api_key" ]; then
                    echo "❌ Missing information"
                    exit 1
                fi
                
                cat > "$INSTALL_DIR/pterodactyl-api.json" <<EOF
{
    "panel_url": "$panel_url",
    "api_key": "$api_key"
}
EOF
                
                echo ""
                echo "✓ API configured!"
                echo ""
                echo "Test it with: chatbot api test"
                ;;
            
            test)
                if [ ! -f "$INSTALL_DIR/pterodactyl-api.json" ]; then
                    echo "❌ API not configured"
                    echo "Set up with: chatbot api setup"
                    exit 1
                fi
                
                panel_url=$(jq -r '.panel_url' "$INSTALL_DIR/pterodactyl-api.json")
                api_key=$(jq -r '.api_key' "$INSTALL_DIR/pterodactyl-api.json")
                
                echo "🔌 Testing API connection..."
                
                response=$(curl -s -o /dev/null -w "%{http_code}" \
                    -H "Authorization: Bearer $api_key" \
                    -H "Accept: Application/vnd.pterodactyl.v1+json" \
                    "$panel_url/api/client")
                
                if [ "$response" = "200" ]; then
                    echo "✓ API connection successful!"
                else
                    echo "❌ API connection failed (HTTP $response)"
                    echo "Check your Panel URL and API key"
                fi
                ;;
            
            remove)
                rm -f "$INSTALL_DIR/pterodactyl-api.json"
                echo "✓ API configuration removed"
                ;;
            
            *)
                echo "API commands:"
                echo "  chatbot api setup   - Configure Pterodactyl API"
                echo "  chatbot api test    - Test API connection"
                echo "  chatbot api remove  - Remove API config"
                ;;
        esac
        ;;
    
    help|--help|-h|"")
        echo "P.R.I.S.M - Pterodactyl Resource Intelligence & System Monitor"
        echo ""
        echo "Basic Commands:"
        echo "  chatbot -enable          Enable P.R.I.S.M"
        echo "  chatbot -disable         Disable P.R.I.S.M"
        echo "  chatbot status           Check status"
        echo "  chatbot logs             View live logs"
        echo "  chatbot restart          Restart service"
        echo ""
        echo "AI Commands:"
        echo "  chatbot ask \"question\"   Ask P.R.I.S.M anything"
        echo "  chatbot detect           Run system analysis"
        echo ""
        echo "Discord Webhooks:"
        echo "  chatbot webhook setup    Configure Discord notifications"
        echo "  chatbot webhook test     Send test message"
        echo "  chatbot webhook remove   Remove webhook"
        echo ""
        echo "Pterodactyl API:"
        echo "  chatbot api setup        Configure API access"
        echo "  chatbot api test         Test API connection"
        echo "  chatbot api remove       Remove API config"
        echo ""
        echo "Help:"
        echo "  chatbot help             Show this help"
        ;;
    
    *)
        echo "Unknown command: $1"
        echo "Run 'chatbot help' for available commands"
        exit 1
        ;;
esac
EOFCLI

chmod +x /usr/local/bin/chatbot

# Create systemd service
echo "[INFO] Creating systemd service..."
cat > /etc/systemd/system/ptero-assistant.service <<EOF
[Unit]
Description=P.R.I.S.M - Pterodactyl AI Assistant
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/python3 $INSTALL_DIR/assistant.py --daemon
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reload

echo ""
echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║                    ✅ INSTALLATION COMPLETE                            ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "P.R.I.S.M has been installed successfully!"
echo ""
echo "Quick Start:"
echo "  1. Enable P.R.I.S.M:        chatbot -enable"
echo "  2. Check status:            chatbot status"
echo "  3. Run analysis:            chatbot detect"
echo "  4. Set up Discord:          chatbot webhook setup"
echo "  5. Configure API:           chatbot api setup"
echo ""
echo "For help:                     chatbot help"
echo ""
