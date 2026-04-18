# 🤖 P.R.I.S.M Quick Start Guide

## Pterodactyl Resource Intelligence & System Monitor

---

## 🚀 **Essential Commands**

### **Basic Control**
```bash
chatbot -enable          # Turn on P.R.I.S.M
chatbot -disable         # Turn off P.R.I.S.M
chatbot status           # Check if running
chatbot logs             # View live logs
chatbot restart          # Restart service
```

### **AI Interaction**
```bash
chatbot ask "question"   # Ask AI anything
chatbot detect           # Run full system analysis
```

### **Discord Notifications**
```bash
chatbot webhook setup    # Configure Discord
chatbot webhook test     # Send test message
chatbot webhook remove   # Remove webhook
```

### **API Integration**
```bash
chatbot api setup        # Configure Pterodactyl API
chatbot api test         # Test connection
chatbot api remove       # Remove API config
```

### **Help**
```bash
chatbot help             # Show all commands
chatbot                  # Quick help
```

---

## 📋 **Common Tasks**

### **1. Enable P.R.I.S.M**
```bash
chatbot -enable
```

### **2. Set Up Discord Notifications**
```bash
# Get webhook URL from Discord:
# Server Settings → Integrations → Webhooks → New Webhook

chatbot webhook setup
# Paste your webhook URL when prompted
```

### **3. Configure API for Game Server Monitoring**
```bash
# Get API key from Pterodactyl:
# Account → API Credentials → Create API Key

chatbot api setup
# Enter Panel URL and API key when prompted
```

### **4. Run System Optimization**
```bash
chatbot detect
# P.R.I.S.M will analyze your system and suggest fixes
```

### **5. Ask AI for Help**
```bash
chatbot ask "Why is CPU usage high?"
chatbot ask "How do I optimize MySQL?"
chatbot ask "What's causing high memory?"
```

### **6. Check Status**
```bash
chatbot status
```

### **7. View Logs**
```bash
chatbot logs
# Press Ctrl+C to exit
```

---

## 🎯 **Quick Setup (5 Minutes)**

```bash
# Step 1: Enable P.R.I.S.M
chatbot -enable

# Step 2: Set up Discord (optional but recommended)
chatbot webhook setup

# Step 3: Configure API (optional)
chatbot api setup

# Step 4: Run first analysis
chatbot detect

# Done! P.R.I.S.M is now monitoring 24/7
```

---

## 💡 **Pro Tips**

1. **Run `chatbot detect` weekly** - Keeps your server optimized
2. **Set up Discord** - Get instant alerts on your phone
3. **Configure API** - Monitor individual game servers
4. **Ask AI questions** - It knows your Pterodactyl setup
5. **Check logs regularly** - `chatbot logs` shows what P.R.I.S.M is doing

---

## 🔔 **What P.R.I.S.M Monitors**

- ✅ CPU, Memory, Disk usage
- ✅ Service status (Nginx, MySQL, Redis, Wings)
- ✅ Security (failed logins, open ports)
- ✅ Performance issues
- ✅ Game server health (with API)
- ✅ Backup integrity
- ✅ Network bandwidth

---

## 📢 **Discord Notifications**

P.R.I.S.M sends alerts for:
- 🔴 Critical issues (service down, disk full)
- 🟡 Warnings (high CPU, memory issues)
- 🟢 Success (auto-fixes applied)
- 📊 Daily summaries

---

## 🎮 **Game Server Monitoring (with API)**

Once API is configured:
- Track each server's status
- Monitor resource usage per server
- Auto-restart crashed servers
- Get uptime statistics

---

## ❓ **Common Questions**

**Q: How do I get a Discord webhook?**
```
1. Open Discord server
2. Server Settings → Integrations → Webhooks
3. New Webhook → Name it "P.R.I.S.M"
4. Copy Webhook URL
5. Run: chatbot webhook setup
```

**Q: How do I get a Pterodactyl API key?**
```
1. Log into Pterodactyl Panel
2. Account → API Credentials
3. Create API Key
4. Give all permissions
5. Copy the key
6. Run: chatbot api setup
```

**Q: How do I know if P.R.I.S.M is working?**
```bash
chatbot status
# Should show "Online and monitoring"
```

**Q: Where are the logs?**
```bash
chatbot logs
# Or: tail -f /var/log/ptero-assistant.log
```

**Q: How do I disable P.R.I.S.M?**
```bash
chatbot -disable
```

**Q: Can I ask P.R.I.S.M anything?**
```bash
Yes! Try:
chatbot ask "Why is my server slow?"
chatbot ask "How do I add more RAM?"
chatbot ask "What's the best way to backup?"
```

---

## 🆘 **Troubleshooting**

### P.R.I.S.M won't start
```bash
# Check service status
systemctl status ptero-assistant

# View error logs
journalctl -u ptero-assistant -n 50

# Restart service
chatbot restart
```

### Discord webhook not working
```bash
# Test webhook
chatbot webhook test

# Reconfigure
chatbot webhook setup
```

### API connection failed
```bash
# Test API
chatbot api test

# Reconfigure
chatbot api setup
```

---

## 📚 **More Help**

- **Full command list**: `chatbot help`
- **System analysis**: `chatbot detect`
- **View logs**: `chatbot logs`
- **Configuration**: `chatbot config`

---

## 🎉 **You're All Set!**

P.R.I.S.M is now protecting your Pterodactyl server 24/7!

**Next steps:**
1. ✅ Run `chatbot detect` to optimize your system
2. ✅ Set up Discord for instant alerts
3. ✅ Configure API to monitor game servers
4. ✅ Ask AI questions whenever you need help

**P.R.I.S.M will automatically:**
- Monitor system resources
- Detect and fix issues
- Send Discord alerts
- Optimize performance
- Keep your server healthy

---

**Need help?** Run `chatbot help` anytime!
