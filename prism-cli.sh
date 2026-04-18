#!/bin/bash

# P.R.I.S.M Enhanced CLI - Extended commands for advanced features
# Pterodactyl Resource Intelligence & System Monitor

CONFIG_FILE="/opt/ptero-assistant/config.json"
DB_FILE="/opt/ptero-assistant/prism.db"
API_CONFIG="/opt/ptero-assistant/pterodactyl-api.json"

case "$1" in
    webhook)
        case "$2" in
            add)
                if [ -z "$3" ] || [ -z "$4" ]; then
                    echo "Usage: prism webhook add <name> <url>"
                    exit 1
                fi
                
                NAME="$3"
                URL="$4"
                
                sqlite3 "$DB_FILE" "INSERT INTO webhooks (name, url, enabled) VALUES ('$NAME', '$URL', 1)"
                echo "✓ Webhook '$NAME' added"
                echo ""
                echo "Test it with: prism webhook test $NAME"
                ;;
            
            list)
                echo "Configured Webhooks:"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                sqlite3 "$DB_FILE" "SELECT name, url, enabled FROM webhooks" | while IFS='|' read name url enabled; do
                    status=$([ "$enabled" = "1" ] && echo "✓ Enabled" || echo "✗ Disabled")
                    echo "  $name: $url ($status)"
                done
                ;;
            
            test)
                if [ -z "$3" ]; then
                    echo "Usage: prism webhook test <name>"
                    exit 1
                fi
                
                URL=$(sqlite3 "$DB_FILE" "SELECT url FROM webhooks WHERE name='$3'")
                
                if [ -z "$URL" ]; then
                    echo "Webhook '$3' not found"
                    exit 1
                fi
                
                echo "Sending test message to $3..."
                
                if [[ "$URL" == *"discord"* ]]; then
                    curl -X POST "$URL" -H "Content-Type: application/json" -d '{
                        "embeds": [{
                            "title": "🤖 P.R.I.S.M Test",
                            "description": "This is a test notification from P.R.I.S.M",
                            "color": 65280
                        }]
                    }'
                else
                    curl -X POST "$URL" -H "Content-Type: application/json" -d '{
                        "message": "Test notification from P.R.I.S.M",
                        "severity": "info"
                    }'
                fi
                
                echo ""
                echo "✓ Test message sent"
                ;;
            
            remove)
                if [ -z "$3" ]; then
                    echo "Usage: prism webhook remove <name>"
                    exit 1
                fi
                
                sqlite3 "$DB_FILE" "DELETE FROM webhooks WHERE name='$3'"
                echo "✓ Webhook '$3' removed"
                ;;
            
            *)
                cat <<HELP
P.R.I.S.M Webhook Management

Usage:
  prism webhook add <name> <url>       Add a new webhook
  prism webhook list                   List all webhooks
  prism webhook test <name>            Test a webhook
  prism webhook remove <name>          Remove a webhook

Examples:
  prism webhook add discord https://discord.com/api/webhooks/...
  prism webhook add slack https://hooks.slack.com/services/...
  prism webhook test discord
HELP
                ;;
        esac
        ;;
    
    api)
        case "$2" in
            setup)
                echo "╔════════════════════════════════════════════════════════════════════════╗"
                echo "║              PTERODACTYL API CONFIGURATION                             ║"
                echo "╚════════════════════════════════════════════════════════════════════════╝"
                echo ""
                
                read -p "Panel URL (e.g., https://panel.example.com): " PANEL_URL
                read -p "API Key (Application API Key): " API_KEY
                
                cat > "$API_CONFIG" <<EOF
{
  "panel_url": "$PANEL_URL",
  "api_key": "$API_KEY"
}
EOF
                
                chmod 600 "$API_CONFIG"
                
                echo ""
                echo "✓ API configuration saved"
                echo ""
                echo "Testing connection..."
                
                RESPONSE=$(curl -s -H "Authorization: Bearer $API_KEY" \
                    -H "Accept: application/json" \
                    "$PANEL_URL/api/application/servers" | jq -r '.object' 2>/dev/null)
                
                if [ "$RESPONSE" = "list" ]; then
                    echo "✓ API connection successful!"
                else
                    echo "✗ API connection failed. Please check your credentials."
                fi
                ;;
            
            test)
                if [ ! -f "$API_CONFIG" ]; then
                    echo "API not configured. Run: prism api setup"
                    exit 1
                fi
                
                PANEL_URL=$(jq -r '.panel_url' "$API_CONFIG")
                API_KEY=$(jq -r '.api_key' "$API_CONFIG")
                
                echo "Testing Pterodactyl API connection..."
                
                RESPONSE=$(curl -s -H "Authorization: Bearer $API_KEY" \
                    -H "Accept: application/json" \
                    "$PANEL_URL/api/application/servers")
                
                SERVER_COUNT=$(echo "$RESPONSE" | jq -r '.meta.pagination.total' 2>/dev/null)
                
                if [ -n "$SERVER_COUNT" ]; then
                    echo "✓ Connected successfully!"
                    echo "  Servers found: $SERVER_COUNT"
                else
                    echo "✗ Connection failed"
                    echo "$RESPONSE" | jq '.'
                fi
                ;;
            
            *)
                cat <<HELP
P.R.I.S.M API Management

Usage:
  prism api setup      Configure Pterodactyl API
  prism api test       Test API connection

Note: You need an Application API key from your Pterodactyl panel.
Create one at: Panel → Application API → Create New
HELP
                ;;
        esac
        ;;
    
    rules)
        case "$2" in
            add)
                echo "Create Custom Automation Rule"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                
                read -p "Rule name: " RULE_NAME
                echo ""
                echo "Condition (Python expression using 'metrics' dict):"
                echo "Examples:"
                echo "  metrics['cpu_usage'] > 80"
                echo "  metrics['memory_usage'] > 90"
                echo "  metrics['disk_usage'] > 85"
                echo ""
                read -p "Condition: " CONDITION
                echo ""
                read -p "Action (shell command to execute): " ACTION
                
                sqlite3 "$DB_FILE" "INSERT INTO custom_rules (name, condition, action, enabled) VALUES ('$RULE_NAME', '$CONDITION', '$ACTION', 1)"
                
                echo ""
                echo "✓ Rule '$RULE_NAME' created"
                ;;
            
            list)
                echo "Custom Automation Rules:"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                sqlite3 "$DB_FILE" "SELECT id, name, condition, enabled FROM custom_rules" | while IFS='|' read id name condition enabled; do
                    status=$([ "$enabled" = "1" ] && echo "✓" || echo "✗")
                    echo "  [$id] $status $name"
                    echo "      Condition: $condition"
                    echo ""
                done
                ;;
            
            remove)
                if [ -z "$3" ]; then
                    echo "Usage: prism rules remove <id>"
                    exit 1
                fi
                
                sqlite3 "$DB_FILE" "DELETE FROM custom_rules WHERE id=$3"
                echo "✓ Rule removed"
                ;;
            
            *)
                cat <<HELP
P.R.I.S.M Custom Rules

Usage:
  prism rules add         Create a new automation rule
  prism rules list        List all rules
  prism rules remove <id> Remove a rule

Custom rules allow you to automate actions based on system metrics.
HELP
                ;;
        esac
        ;;
    
    report)
        case "$2" in
            daily)
                echo "Generating daily report..."
                python3 -c "
from prism_enhanced import PRISMEnhanced
prism = PRISMEnhanced()
print(prism.generate_daily_report())
"
                ;;
            
            metrics)
                DAYS="${3:-7}"
                echo "System Metrics (Last $DAYS days)"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                
                SINCE=$(date -d "$DAYS days ago" +%Y-%m-%d)
                
                echo ""
                echo "CPU Usage:"
                sqlite3 "$METRICS_DB" "SELECT AVG(value), MAX(value), MIN(value) FROM metrics WHERE metric_type='cpu_usage' AND timestamp > '$SINCE'" | while IFS='|' read avg max min; do
                    echo "  Average: ${avg}%"
                    echo "  Peak: ${max}%"
                    echo "  Minimum: ${min}%"
                done
                
                echo ""
                echo "Memory Usage:"
                sqlite3 "$METRICS_DB" "SELECT AVG(value), MAX(value), MIN(value) FROM metrics WHERE metric_type='memory_usage' AND timestamp > '$SINCE'" | while IFS='|' read avg max min; do
                    echo "  Average: ${avg}%"
                    echo "  Peak: ${max}%"
                    echo "  Minimum: ${min}%"
                done
                
                echo ""
                echo "Disk Usage:"
                sqlite3 "$METRICS_DB" "SELECT AVG(value), MAX(value), MIN(value) FROM metrics WHERE metric_type='disk_usage' AND timestamp > '$SINCE'" | while IFS='|' read avg max min; do
                    echo "  Average: ${avg}%"
                    echo "  Peak: ${max}%"
                    echo "  Minimum: ${min}%"
                done
                ;;
            
            alerts)
                DAYS="${3:-7}"
                echo "Recent Alerts (Last $DAYS days)"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                
                SINCE=$(date -d "$DAYS days ago" +%Y-%m-%d)
                
                sqlite3 "$DB_FILE" "SELECT timestamp, severity, message FROM alerts WHERE timestamp > '$SINCE' ORDER BY timestamp DESC LIMIT 50" | while IFS='|' read timestamp severity message; do
                    case $severity in
                        critical) icon="🔴";;
                        warning) icon="🟡";;
                        *) icon="🟢";;
                    esac
                    echo "  $icon [$timestamp] $message"
                done
                ;;
            
            *)
                cat <<HELP
P.R.I.S.M Reports

Usage:
  prism report daily              Generate daily summary
  prism report metrics [days]     Show metrics (default: 7 days)
  prism report alerts [days]      Show recent alerts (default: 7 days)

Examples:
  prism report daily
  prism report metrics 30
  prism report alerts 7
HELP
                ;;
        esac
        ;;
    
    servers)
        if [ ! -f "$API_CONFIG" ]; then
            echo "API not configured. Run: prism api setup"
            exit 1
        fi
        
        case "$2" in
            list)
                echo "Game Servers Status:"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                
                sqlite3 "$DB_FILE" "SELECT server_id, name, status, last_check FROM game_servers ORDER BY last_check DESC" | while IFS='|' read id name status last_check; do
                    case $status in
                        running) icon="🟢";;
                        offline) icon="🔴";;
                        starting) icon="🟡";;
                        *) icon="⚪";;
                    esac
                    echo "  $icon $name ($id)"
                    echo "     Status: $status | Last check: $last_check"
                    echo ""
                done
                ;;
            
            health)
                echo "Running game server health check..."
                python3 -c "
from prism_enhanced import PRISMEnhanced
prism = PRISMEnhanced()
issues = prism.monitor_game_servers()
if issues:
    print('Issues found:')
    for issue in issues:
        print(f\"  ⚠️  {issue['server']}: {issue['issue']}\")
else:
    print('✓ All game servers healthy')
"
                ;;
            
            *)
                cat <<HELP
P.R.I.S.M Game Server Management

Usage:
  prism servers list      List all game servers
  prism servers health    Run health check on all servers

Requires Pterodactyl API to be configured.
HELP
                ;;
        esac
        ;;
    
    backup)
        case "$2" in
            verify)
                echo "Verifying backup integrity..."
                python3 -c "
from prism_enhanced import PRISMEnhanced
prism = PRISMEnhanced()
issues = prism.verify_backups()
if issues:
    print('Backup issues found:')
    for issue in issues:
        print(f\"  ⚠️  {issue['message']}\")
else:
    print('✓ All backups verified successfully')
"
                ;;
            
            history)
                echo "Backup Verification History:"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                
                sqlite3 "$DB_FILE" "SELECT timestamp, backup_file, status, details FROM backup_verifications ORDER BY timestamp DESC LIMIT 20" | while IFS='|' read timestamp file status details; do
                    case $status in
                        valid) icon="✓";;
                        corrupted) icon="✗";;
                        *) icon="?";;
                    esac
                    echo "  $icon [$timestamp] $(basename $file)"
                    echo "     Status: $status | $details"
                    echo ""
                done
                ;;
            
            *)
                cat <<HELP
P.R.I.S.M Backup Management

Usage:
  prism backup verify     Verify backup integrity
  prism backup history    Show verification history
HELP
                ;;
        esac
        ;;
    
    predict)
        echo "Running predictive maintenance analysis..."
        python3 -c "
from prism_enhanced import PRISMEnhanced
prism = PRISMEnhanced()
predictions = prism.predictive_maintenance()
if predictions:
    print('Predictions:')
    for pred in predictions:
        severity = pred['severity']
        icon = '🔴' if severity == 'critical' else '🟡'
        print(f\"{icon} {pred['message']}\")
else:
    print('✓ No issues predicted')
"
        ;;
    
    security)
        case "$2" in
            scan)
                echo "Running security scan..."
                python3 -c "
from prism_enhanced import PRISMEnhanced
prism = PRISMEnhanced()
issues = prism.security_scan()
if issues:
    print('Security issues found:')
    for issue in issues:
        severity = issue['severity']
        icon = '🔴' if severity == 'critical' else '🟡' if severity == 'warning' else '🟢'
        print(f\"{icon} {issue['message']}\")
else:
    print('✓ No security issues detected')
"
                ;;
            
            *)
                cat <<HELP
P.R.I.S.M Security

Usage:
  prism security scan     Run security scan
HELP
                ;;
        esac
        ;;
    
    *)
        cat <<HELP
╔════════════════════════════════════════════════════════════════════════╗
║                    P.R.I.S.M ENHANCED CLI                              ║
║        Pterodactyl Resource Intelligence & System Monitor              ║
╚════════════════════════════════════════════════════════════════════════╝

Advanced Commands:

  📢 Notifications:
    prism webhook <add|list|test|remove>    Manage webhooks

  🔌 API Integration:
    prism api <setup|test>                  Configure Pterodactyl API

  ⚙️  Automation:
    prism rules <add|list|remove>           Custom automation rules

  📊 Reports:
    prism report <daily|metrics|alerts>     Generate reports

  🎮 Game Servers:
    prism servers <list|health>             Monitor game servers

  💾 Backups:
    prism backup <verify|history>           Backup management

  🔮 Predictions:
    prism predict                           Predictive maintenance

  🔒 Security:
    prism security scan                     Security scanning

For basic commands, use: chatbot --help

Examples:
  prism webhook add discord https://discord.com/api/webhooks/...
  prism api setup
  prism report daily
  prism servers health
  prism predict
HELP
        ;;
esac
