# AI Assistant Guide - Intelligent Server Management

## Overview

The Pterodactyl AI Assistant is a localized, intelligent monitoring system powered by Ollama and Gemma2. It runs directly on your server, providing real-time problem detection, automated fixes, and intelligent assistance without relying on external AI services.

## Features

### 🤖 Intelligent Monitoring
- Continuous system health monitoring
- CPU, memory, and disk usage tracking
- Service status monitoring (Nginx, MySQL, Redis, Wings, Docker)
- AI-powered analysis of system metrics

### 🔧 Automatic Problem Fixing
- Auto-restart stopped services
- Clear cache when memory is high (>90%)
- Clean old logs when disk is full (>85%)
- Intelligent issue detection and resolution

### 💬 Interactive Chatbot
- Ask questions anytime with `chatbot ask`
- Get expert advice on server management
- Troubleshooting assistance
- Configuration recommendations

### 🎛️ Easy Control
- Enable/disable with simple commands
- Configurable monitoring intervals
- Adjustable auto-fix settings
- Full logging for transparency

## Installation

### Quick Install

```bash
sudo ./ai-assistant-setup.sh
```

Or via main script:

```bash
sudo ./pteroanyinstall.sh ai-assistant
```

### System Requirements

**Minimum (Gemma2:1b):**
- 2GB RAM available
- 5GB disk space
- Linux (Ubuntu 20.04+, Debian 11+, CentOS 8+)

**Recommended (Gemma2:4b):**
- 6GB RAM available
- 10GB disk space
- Dedicated CPU cores

### Installation Process

1. **System Resource Check**
   - Verifies sufficient RAM and disk space
   - Warns if resources are limited

2. **Model Selection**
   - Asks if you're hosting LLM game servers
   - If yes: Uses Gemma2:1b (lightweight)
   - If no: Offers choice between 1b and 4b models

3. **Ollama Installation**
   - Installs Ollama if not present
   - Starts Ollama service
   - Configures automatic startup

4. **AI Model Download**
   - Downloads selected Gemma2 model
   - May take 5-15 minutes depending on connection

5. **Assistant Service Setup**
   - Creates Python monitoring script
   - Installs system service
   - Configures automatic startup

6. **CLI Tool Creation**
   - Installs `chatbot` command
   - Enables easy management

## Usage

### Chatbot Commands

```bash
# Enable AI assistant
chatbot -enable

# Disable AI assistant
chatbot -disable

# Check status
chatbot status

# View logs (live)
chatbot logs

# Ask a question
chatbot ask "Why is my server slow?"

# Detect and optimize system (NEW!)
chatbot detect

# Edit configuration
chatbot config

# Restart assistant
chatbot restart
```

### Optimization Detection (NEW!)

The `chatbot detect` command provides intelligent system analysis and interactive optimization:

```bash
chatbot detect
```

**What it does:**
1. Collects comprehensive system information
2. Analyzes with AI for optimization opportunities
3. Provides specific, actionable recommendations
4. Offers to apply automatic fixes interactively

**Checks performed:**
- System resources (CPU, RAM, disk)
- Service status and configuration
- PHP settings (memory_limit, execution time)
- MySQL/MariaDB configuration (InnoDB buffer pool)
- Nginx worker processes
- Redis memory limits
- Security (Fail2ban, firewall, SSL)
- Log rotation
- Swap configuration
- Recent errors

**Interactive fixes:**
- Increase PHP memory_limit (128M → 256M)
- Install and configure Fail2ban
- Set Redis maxmemory limits
- Configure log rotation
- Optimize Nginx workers
- Adjust MySQL InnoDB buffer
- Create swap file if missing

**Example output:**
```
🤖 AI is analyzing your system...

Performance Recommendations:
1. PHP memory_limit is low (128M) - increase to 256M
2. Nginx workers not optimized - set to auto
3. Redis has no memory limit - set maxmemory

Security Recommendations:
1. Fail2ban not installed - install for brute-force protection
2. Log rotation not configured - prevent disk fill

Would you like to apply automatic optimizations? (y/n)
```

### Example Questions

```bash
# Performance troubleshooting
chatbot ask "Why is CPU usage high?"
chatbot ask "How can I optimize MySQL?"
chatbot ask "What's causing memory issues?"

# Configuration help
chatbot ask "How do I configure Nginx caching?"
chatbot ask "What are best practices for Wings?"
chatbot ask "How do I secure my panel?"

# Problem diagnosis
chatbot ask "Why did my server crash?"
chatbot ask "How do I fix database errors?"
chatbot ask "What's wrong with my SSL certificate?"
```

## Configuration

### Config File Location

```
/opt/ptero-assistant/config.json
```

### Configuration Options

```json
{
  "enabled": true,
  "model": "gemma2:1b",
  "check_interval": 300,
  "auto_fix": true,
  "notify_admin": true,
  "llm_hosting_mode": false
}
```

**Settings:**

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `enabled` | boolean | true | Enable/disable assistant |
| `model` | string | "gemma2:1b" | AI model to use |
| `check_interval` | integer | 300 | Seconds between checks |
| `auto_fix` | boolean | true | Automatically fix issues |
| `notify_admin` | boolean | true | Send notifications |
| `llm_hosting_mode` | boolean | false | Optimize for LLM hosting |

### Edit Configuration

```bash
# Interactive editor
chatbot config

# Manual edit
nano /opt/ptero-assistant/config.json

# Restart after changes
chatbot restart
```

### Adjust Check Interval

```json
{
  "check_interval": 600  // Check every 10 minutes instead of 5
}
```

### Disable Auto-Fix

```json
{
  "auto_fix": false  // Only detect issues, don't fix automatically
}
```

## What the AI Monitors

### System Resources

- **CPU Usage**: Tracks CPU utilization percentage
- **Memory Usage**: Monitors RAM usage and availability
- **Disk Usage**: Checks disk space on root partition
- **Load Average**: System load over time

### Services

- **Nginx**: Web server status
- **MySQL/MariaDB**: Database server status
- **Redis**: Cache server status
- **Wings**: Pterodactyl Wings daemon
- **Docker**: Container runtime

### Automatic Actions

| Condition | Action | Threshold |
|-----------|--------|-----------|
| Service stopped | Restart service | Any critical service |
| High memory | Clear cache | >90% usage |
| High disk | Clean old logs | >85% usage |
| Critical issue | Notify admin | AI detects severity |

## Logs

### Log Location

```
/var/log/ptero-assistant.log
```

### View Logs

```bash
# Live logs
chatbot logs

# Recent logs
tail -100 /var/log/ptero-assistant.log

# Search logs
grep "ERROR" /var/log/ptero-assistant.log

# Today's logs
grep "$(date +%Y-%m-%d)" /var/log/ptero-assistant.log
```

### Log Format

```
[2024-04-18 10:30:00] [INFO] AI Assistant started
[2024-04-18 10:35:00] [INFO] AI Analysis: OK: All systems normal...
[2024-04-18 10:40:00] [WARNING] Detected stopped service: nginx
[2024-04-18 10:40:01] [SUCCESS] Restarted service: nginx
[2024-04-18 10:40:02] [NOTIFY] NOTIFICATION: Auto-fixed: Restarted nginx
```

## Model Comparison

### Gemma2:1b (Lightweight)

**Pros:**
- ✅ Low resource usage (~1GB RAM)
- ✅ Fast responses (1-3 seconds)
- ✅ Ideal for LLM game server hosting
- ✅ Minimal impact on server performance

**Cons:**
- ❌ Less detailed analysis
- ❌ May miss complex issues
- ❌ Limited context understanding

**Best for:**
- Servers hosting LLM game servers
- Limited RAM (2-4GB)
- Basic monitoring needs

### Gemma2:4b (Advanced)

**Pros:**
- ✅ More accurate analysis
- ✅ Better problem detection
- ✅ Detailed explanations
- ✅ Complex issue diagnosis

**Cons:**
- ❌ Higher resource usage (~4GB RAM)
- ❌ Slower responses (5-10 seconds)
- ❌ May impact game server performance

**Best for:**
- Dedicated panel servers
- Sufficient RAM (8GB+)
- Advanced monitoring needs

## LLM Hosting Mode

When enabled, the assistant optimizes for servers hosting LLM-based game servers:

**Optimizations:**
- Uses Gemma2:1b exclusively
- Reduces check frequency
- Minimizes resource usage
- Prioritizes game server performance

**Enable LLM Hosting Mode:**

```json
{
  "llm_hosting_mode": true,
  "model": "gemma2:1b",
  "check_interval": 600  // Less frequent checks
}
```

## Integration with Admin Panel

The AI assistant integrates with the Ptero Admin Panel:

```bash
sudo ./ptero-admin.sh
```

From the admin panel:
- View AI assistant status
- Enable/disable assistant
- View recent AI analyses
- Configure settings

## Troubleshooting

### Assistant Not Starting

**Check service status:**
```bash
systemctl status ptero-assistant
```

**View service logs:**
```bash
journalctl -u ptero-assistant -f
```

**Restart service:**
```bash
systemctl restart ptero-assistant
```

### Ollama Not Responding

**Check Ollama status:**
```bash
systemctl status ollama
```

**Test Ollama:**
```bash
curl http://localhost:11434/api/tags
```

**Restart Ollama:**
```bash
systemctl restart ollama
```

### Model Not Found

**List installed models:**
```bash
ollama list
```

**Pull model again:**
```bash
ollama pull gemma2:1b
```

### High Resource Usage

**Switch to lighter model:**
```bash
chatbot config
# Change "model": "gemma2:4b" to "gemma2:1b"
chatbot restart
```

**Increase check interval:**
```json
{
  "check_interval": 900  // Check every 15 minutes
}
```

### Python Errors

**Install dependencies:**
```bash
pip3 install requests
```

**Check Python version:**
```bash
python3 --version  # Should be 3.6+
```

## Security Considerations

### Local Processing
- All AI processing happens locally
- No data sent to external services
- Complete privacy and control

### Service Permissions
- Runs as root (required for system management)
- Can restart services and modify system
- Review auto-fix actions in logs

### Network Access
- Ollama listens on localhost:11434 only
- Not exposed to external network
- No inbound connections required

## Performance Impact

### Gemma2:1b
- **RAM**: ~1GB constant
- **CPU**: <5% during analysis
- **Disk**: ~2GB for model
- **Network**: None (local only)

### Gemma2:4b
- **RAM**: ~4GB constant
- **CPU**: 10-20% during analysis
- **Disk**: ~8GB for model
- **Network**: None (local only)

## Advanced Usage

### Custom Prompts

Edit the assistant script to customize AI prompts:

```bash
nano /opt/ptero-assistant/assistant.py
```

### Webhook Notifications

Add webhook support for Discord/Slack notifications:

```python
def send_notification(message):
    webhook_url = "https://discord.com/api/webhooks/..."
    requests.post(webhook_url, json={"content": message})
```

### Email Alerts

Configure email notifications:

```python
import smtplib
from email.mime.text import MIMEText

def send_email(subject, body):
    msg = MIMEText(body)
    msg['Subject'] = subject
    msg['From'] = 'assistant@yourserver.com'
    msg['To'] = 'admin@yourserver.com'
    
    s = smtplib.SMTP('localhost')
    s.send_message(msg)
    s.quit()
```

### Custom Auto-Fix Rules

Add custom auto-fix logic:

```python
def auto_fix_issues(metrics, config):
    fixed = []
    
    # Custom rule: Restart Wings if CPU is high
    if metrics.get("cpu_usage", 0) > 80:
        if not check_service_status("wings"):
            restart_service("wings")
            fixed.append("Restarted Wings due to high CPU")
    
    return fixed
```

## Uninstallation

```bash
# Stop and disable service
systemctl stop ptero-assistant
systemctl disable ptero-assistant

# Remove service file
rm /etc/systemd/system/ptero-assistant.service

# Remove assistant files
rm -rf /opt/ptero-assistant

# Remove CLI tool
rm /usr/local/bin/chatbot

# Remove Ollama (optional)
systemctl stop ollama
systemctl disable ollama
rm -rf /opt/ollama
rm /usr/local/bin/ollama

# Remove logs
rm /var/log/ptero-assistant.log

# Reload systemd
systemctl daemon-reload
```

## FAQ

**Q: Does this send data to external AI services?**  
A: No, everything runs locally on your server using Ollama.

**Q: Can I use a different AI model?**  
A: Yes, edit the config and use any Ollama-compatible model.

**Q: Will this slow down my game servers?**  
A: Minimal impact with Gemma2:1b. Enable LLM hosting mode for optimization.

**Q: Can I disable auto-fix and only get alerts?**  
A: Yes, set `"auto_fix": false` in the config.

**Q: How do I update the AI model?**  
A: Run `ollama pull gemma2:1b` to get the latest version.

**Q: Can multiple admins use the chatbot?**  
A: Yes, the `chatbot` command works for any user with sudo access.

**Q: Does it work offline?**  
A: Yes, once installed, no internet connection is needed.

**Q: How much does it cost?**  
A: Free! Ollama and Gemma2 are open-source.

## Best Practices

1. **Start with Gemma2:1b** - Test with the lightweight model first
2. **Monitor logs regularly** - Review what the AI is doing
3. **Test auto-fix** - Verify fixes work correctly for your setup
4. **Adjust intervals** - Find the right balance for your needs
5. **Ask questions** - Use the chatbot to learn and troubleshoot
6. **Keep updated** - Update Ollama and models periodically
7. **Backup config** - Save your configuration settings

## Support

**View status:**
```bash
chatbot status
```

**Check logs:**
```bash
chatbot logs
```

**Ask for help:**
```bash
chatbot ask "I need help with..."
```

**Community:**
- GitHub Issues
- Pterodactyl Discord
- Project documentation

## Summary

The AI Assistant provides:
- ✅ **24/7 Monitoring**: Continuous system health checks
- ✅ **Intelligent Analysis**: AI-powered problem detection
- ✅ **Auto-Fix**: Automatic resolution of common issues
- ✅ **Interactive Help**: Ask questions anytime
- ✅ **Privacy**: All processing happens locally
- ✅ **Easy Control**: Simple enable/disable commands
- ✅ **Low Impact**: Optimized for LLM hosting

**Installation time:** 10-20 minutes  
**Ongoing maintenance:** Minimal (automated)  
**Value:** Proactive server management with AI intelligence

Install the AI assistant for intelligent, automated server management!
