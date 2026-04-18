# P.R.I.S.M Enhanced Guide
## Pterodactyl Resource Intelligence & System Monitor

## Overview

P.R.I.S.M Enhanced is the ultimate AI-powered server management system for Pterodactyl. It combines artificial intelligence with comprehensive automation to provide proactive server management, predictive maintenance, and intelligent problem resolution.

## What's Included

### 🔔 **Webhook Notifications**
Send real-time alerts to Discord, Slack, or custom webhooks
- Critical system alerts
- Performance warnings
- Security notifications
- Daily/weekly summary reports

### 🎮 **Game Server Monitoring**
Monitor individual game servers via Pterodactyl API
- Real-time status tracking
- Resource usage monitoring
- Auto-restart crashed servers
- Performance analytics

### 🔮 **Predictive Maintenance**
AI-powered predictions to prevent issues before they happen
- Disk space predictions ("Disk will be full in 7 days")
- Memory usage trend analysis
- Performance degradation detection
- Proactive alerting

### 💾 **Backup Verification**
Automated backup integrity checking
- Test backup archives
- Verify file integrity
- Alert on corrupted backups
- Backup history tracking

### 🔒 **Security Scanning**
Comprehensive security monitoring
- Failed login attempt detection
- Outdated package scanning
- Open port monitoring
- Vulnerability alerts

### 📊 **Log Analysis**
Intelligent log parsing and pattern detection
- Error pattern recognition
- Common issue identification
- Trend analysis
- Automated insights

### 🌐 **Network Monitoring**
Track network performance and bandwidth
- Bandwidth usage tracking
- DDoS detection
- Latency monitoring
- Traffic analysis

### ⚙️ **Custom Automation Rules**
Create your own automation workflows
- Conditional triggers
- Custom actions
- Flexible rule engine
- User-defined thresholds

### 📈 **Performance Profiling**
Detailed performance analysis
- Resource usage trends
- Bottleneck identification
- Optimization recommendations
- Historical data analysis

### 📋 **Comprehensive Reports**
Automated reporting system
- Daily summaries
- Weekly reports
- Custom time ranges
- Exportable data

## Installation

### Prerequisites

- Basic AI assistant already installed
- Python 3.6+
- Pterodactyl Panel (for API features)
- 2GB+ RAM available

### Quick Install

```bash
# Upgrade from basic assistant
sudo ./prism-upgrade.sh

# Or via main script
sudo ./pteroanyinstall.sh prism-upgrade
```

### Manual Installation

```bash
# 1. Copy files
cp prism-enhanced.py /opt/ptero-assistant/
cp prism-cli.sh /usr/local/bin/prism

# 2. Make executable
chmod +x /opt/ptero-assistant/prism-enhanced.py
chmod +x /usr/local/bin/prism

# 3. Update service
systemctl restart ptero-assistant
```

## Configuration

### Webhook Setup

Add Discord webhook:
```bash
prism webhook add discord https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_TOKEN
```

Add Slack webhook:
```bash
prism webhook add slack https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

Test webhook:
```bash
prism webhook test discord
```

List webhooks:
```bash
prism webhook list
```

### Pterodactyl API Setup

Configure API access:
```bash
prism api setup
```

You'll need:
- Panel URL (e.g., `https://panel.example.com`)
- Application API Key (create in Panel → Application API)

Test connection:
```bash
prism api test
```

### Custom Automation Rules

Create a custom rule:
```bash
prism rules add
```

Example rules:
```python
# Restart Nginx if CPU > 90%
Condition: metrics['cpu_usage'] > 90
Action: systemctl restart nginx

# Alert if memory > 95%
Condition: metrics['memory_usage'] > 95
Action: echo "High memory alert" | mail -s "Alert" admin@example.com

# Clean logs if disk > 80%
Condition: metrics['disk_usage'] > 80
Action: find /var/log -name "*.log" -mtime +7 -delete
```

List rules:
```bash
prism rules list
```

Remove rule:
```bash
prism rules remove <id>
```

## Usage

### Basic Commands

```bash
# View status
chatbot status

# View logs
chatbot logs

# Ask AI
chatbot ask "Why is CPU high?"

# System optimization
chatbot detect
```

### Enhanced Commands

```bash
# Webhook management
prism webhook add <name> <url>
prism webhook list
prism webhook test <name>
prism webhook remove <name>

# API management
prism api setup
prism api test

# Game server monitoring
prism servers list
prism servers health

# Reports
prism report daily
prism report metrics [days]
prism report alerts [days]

# Backup management
prism backup verify
prism backup history

# Predictive maintenance
prism predict

# Security
prism security scan

# Custom rules
prism rules add
prism rules list
prism rules remove <id>
```

## Features in Detail

### 1. Webhook Notifications

**What it does:**
- Sends real-time alerts to Discord/Slack
- Supports multiple webhooks
- Color-coded severity levels
- Rich embed formatting

**Use cases:**
- Get notified of server issues on your phone
- Team collaboration in Discord
- Centralized alert management
- Integration with existing workflows

**Example Discord notification:**
```
🤖 P.R.I.S.M Alert
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 CRITICAL: Disk will be full in 3 days

Current usage: 92%
Predicted full: 2024-04-21
Action required: Clean old files or expand storage

Pterodactyl Resource Intelligence & System Monitor
```

### 2. Game Server Monitoring

**What it does:**
- Monitors all game servers via Pterodactyl API
- Tracks status (running/offline/starting)
- Monitors resource usage per server
- Auto-restart crashed servers
- Historical uptime tracking

**Use cases:**
- Ensure game servers stay online
- Monitor resource usage per server
- Identify problematic servers
- Track server performance

**Example:**
```bash
$ prism servers health

Game Servers Status:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🟢 Minecraft-Survival (abc123)
   Status: running | Uptime: 48h 23m
   Memory: 2.1GB / 4GB (52%)

🔴 Rust-Server (def456)
   Status: offline | Last seen: 2h ago
   ⚠️  Server crashed - auto-restart attempted

🟢 ARK-Island (ghi789)
   Status: running | Uptime: 120h 15m
   Memory: 7.8GB / 8GB (97%) ⚠️  High memory usage
```

### 3. Predictive Maintenance

**What it does:**
- Analyzes historical metrics
- Predicts future issues
- Provides early warnings
- Suggests preventive actions

**Predictions:**
- Disk space exhaustion
- Memory usage trends
- Performance degradation
- Service failures

**Example:**
```bash
$ prism predict

Predictive Maintenance Analysis:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🟡 WARNING: Disk will be full in approximately 7 days
   Current usage: 85%
   Daily growth: 2.1%
   Recommendation: Clean old logs or expand storage

🟡 WARNING: Memory usage trending high (avg 87.3% over last 10 checks)
   Recommendation: Investigate memory leaks or add more RAM

✓ No critical predictions
```

### 4. Backup Verification

**What it does:**
- Tests backup file integrity
- Verifies archives can be extracted
- Checks file sizes
- Maintains verification history

**Use cases:**
- Ensure backups are usable
- Detect corrupted backups early
- Compliance requirements
- Peace of mind

**Example:**
```bash
$ prism backup verify

Verifying backup integrity...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ panel-20240418-020000.tar.gz
  Size: 125MB | Status: Valid | Files: 15,234

✓ database-20240418-020000.sql.gz
  Size: 15MB | Status: Valid

✓ wings-config-20240418-020000.yml
  Size: 2.1KB | Status: Valid

All backups verified successfully!
```

### 5. Security Scanning

**What it does:**
- Scans for security issues
- Monitors failed login attempts
- Checks for outdated packages
- Detects suspicious ports

**Checks performed:**
- Failed SSH login attempts
- Open suspicious ports (Telnet, FTP, etc.)
- Outdated system packages
- Firewall status

**Example:**
```bash
$ prism security scan

Security Scan Results:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🟡 WARNING: 15 failed login attempts detected in auth.log
   Recommendation: Review /var/log/auth.log and consider Fail2ban

🟢 INFO: 23 packages have updates available
   Run: apt update && apt upgrade

✓ No suspicious ports detected
✓ Firewall is active
```

### 6. Log Analysis

**What it does:**
- Parses system and application logs
- Detects error patterns
- Identifies common issues
- Provides insights

**Patterns detected:**
- Database errors
- Memory errors
- Disk errors
- Network errors

**Example:**
```bash
Detected 12 database_error occurrences in laravel.log
Detected 3 memory_error occurrences in syslog

Common issues:
  • Database connection timeouts (increase max_connections)
  • Out of memory errors (add swap or increase RAM)
```

### 7. Network Monitoring

**What it does:**
- Tracks bandwidth usage
- Monitors network performance
- Detects unusual traffic
- Alerts on high usage

**Metrics tracked:**
- Bytes transmitted/received
- Bandwidth usage over time
- Traffic spikes
- Network errors

### 8. Performance Profiling

**What it does:**
- Analyzes system performance
- Identifies bottlenecks
- Tracks resource usage trends
- Provides optimization recommendations

**Metrics analyzed:**
- CPU usage patterns
- Memory allocation
- Disk I/O
- Network throughput

### 9. Daily Reports

**What it does:**
- Generates comprehensive summaries
- Tracks key metrics
- Highlights issues
- Sent via webhook

**Example report:**
```
📊 P.R.I.S.M Daily Report - 2024-04-18

System Performance (24h Average):
• CPU Usage: 23.4%
• Memory Usage: 67.8%
• Disk Usage: 45.2%

Alerts:
• Critical: 0
• Warnings: 2

Game Servers:
• Total: 15
• Online: 14
• Offline: 1

Backups:
• Last backup: 2024-04-18 02:00
• Status: ✓ Verified

Status: ✅ All systems operational
```

## Advanced Features

### Database Storage

P.R.I.S.M uses SQLite databases to store:
- Historical metrics
- Alert history
- Webhook configurations
- Custom rules
- Backup verifications
- Game server data

**Database locations:**
- `/opt/ptero-assistant/prism.db` - Main database
- `/opt/ptero-assistant/metrics.db` - Metrics history

### API Integration

Full Pterodactyl API integration allows:
- Server management
- Resource monitoring
- Automated actions
- Custom workflows

### Extensibility

P.R.I.S.M is designed to be extended:
- Add custom monitoring modules
- Create new automation rules
- Integrate with external services
- Build custom reports

## Troubleshooting

### P.R.I.S.M not starting

```bash
# Check service status
systemctl status ptero-assistant

# View logs
journalctl -u ptero-assistant -f

# Check Python errors
python3 /opt/ptero-assistant/prism-enhanced.py
```

### Webhooks not working

```bash
# Test webhook manually
prism webhook test <name>

# Check webhook URL
prism webhook list

# Verify network connectivity
curl -I https://discord.com
```

### API connection failed

```bash
# Test API
prism api test

# Verify credentials
cat /opt/ptero-assistant/pterodactyl-api.json

# Check panel URL
curl -I https://panel.example.com
```

### Database errors

```bash
# Check database file
ls -lah /opt/ptero-assistant/*.db

# Verify permissions
chmod 644 /opt/ptero-assistant/*.db

# Rebuild database (will lose history)
rm /opt/ptero-assistant/*.db
systemctl restart ptero-assistant
```

## Best Practices

1. **Configure webhooks** - Get instant notifications
2. **Set up API** - Enable game server monitoring
3. **Review daily reports** - Stay informed
4. **Create custom rules** - Automate your workflows
5. **Monitor predictions** - Prevent issues proactively
6. **Verify backups** - Ensure data safety
7. **Run security scans** - Stay secure

## Performance Impact

**Resource Usage:**
- CPU: <5% average
- RAM: ~500MB (with Gemma2:1b)
- Disk: ~100MB for databases
- Network: Minimal (only for webhooks/API)

**Optimizations:**
- Efficient database queries
- Cached metrics
- Asynchronous operations
- Configurable check intervals

## Security Considerations

- All data stored locally
- API keys encrypted at rest
- Webhook URLs protected
- No external data transmission (except webhooks)
- Root access required for system management

## Comparison: Basic vs Enhanced

| Feature | Basic Assistant | P.R.I.S.M Enhanced |
|---------|----------------|-------------------|
| System monitoring | ✓ | ✓ |
| Auto-fix issues | ✓ | ✓ |
| AI analysis | ✓ | ✓ |
| Webhooks | ✗ | ✓ |
| Game server monitoring | ✗ | ✓ |
| Predictive maintenance | ✗ | ✓ |
| Backup verification | ✗ | ✓ |
| Security scanning | ✗ | ✓ |
| Log analysis | ✗ | ✓ |
| Network monitoring | ✗ | ✓ |
| Custom rules | ✗ | ✓ |
| Daily reports | ✗ | ✓ |
| API integration | ✗ | ✓ |
| Historical data | ✗ | ✓ |

## FAQ

**Q: Will this slow down my server?**  
A: No, P.R.I.S.M uses <5% CPU and ~500MB RAM on average.

**Q: Can I use it without Pterodactyl API?**  
A: Yes, most features work without API. Game server monitoring requires API.

**Q: How long is historical data kept?**  
A: Indefinitely, but you can configure retention policies.

**Q: Can I export data?**  
A: Yes, databases are SQLite format and easily exportable.

**Q: Does it work offline?**  
A: Yes, except for webhooks which require internet.

**Q: Can I add more webhooks?**  
A: Yes, unlimited webhooks supported.

**Q: Is it compatible with the basic assistant?**  
A: Yes, it's an upgrade that maintains all basic features.

**Q: Can I downgrade back to basic?**  
A: Yes, restore from backup or reinstall basic assistant.

## Support

- View logs: `chatbot logs`
- Check status: `chatbot status`
- Test features: `prism <command> test`
- Documentation: This guide
- Community: GitHub Issues

## Summary

P.R.I.S.M Enhanced transforms your Pterodactyl server management with:
- ✅ **Proactive monitoring** - Prevent issues before they happen
- ✅ **Intelligent automation** - AI-powered problem resolution
- ✅ **Comprehensive insights** - Detailed analytics and reports
- ✅ **Easy management** - Simple CLI commands
- ✅ **Extensible** - Custom rules and integrations

**Installation time:** 10-15 minutes  
**Configuration time:** 5-10 minutes  
**Ongoing maintenance:** Fully automated  
**Value:** Enterprise-grade server management

Upgrade to P.R.I.S.M Enhanced today!
