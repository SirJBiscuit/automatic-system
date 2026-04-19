# 🚀 Complete Setup Guide: Discord Bot + Web Console + P.R.I.S.M AI

## Overview

This guide will walk you through setting up all three optional components for your Pterodactyl installation:

1. **Discord Bot** - Manage servers from Discord
2. **Web Console** - Professional web dashboard
3. **P.R.I.S.M AI** - AI-powered monitoring and assistance

---

## Prerequisites

✅ Pterodactyl Panel and Wings installed and running
✅ Node showing green in Panel
✅ SSH access to your server
✅ Discord account (for Discord bot)
✅ Anthropic API key (for P.R.I.S.M AI - optional)

---

# Part 1: Enable P.R.I.S.M AI

P.R.I.S.M (Pterodactyl Resource Intelligence & System Monitor) is an AI assistant that monitors your server 24/7.

## Step 1: Enable P.R.I.S.M

```bash
cd /opt/ptero
chatbot -enable
```

This will:
- Install Python dependencies
- Set up the monitoring service
- Start P.R.I.S.M

## Step 2: Verify P.R.I.S.M is Running

```bash
chatbot status
```

You should see: `✅ Online and monitoring`

## Step 3: Run First System Analysis

```bash
chatbot detect
```

P.R.I.S.M will analyze your system and suggest optimizations.

## Step 4: Set Up Discord Notifications (Optional but Recommended)

### Get Discord Webhook URL:
1. Open your Discord server
2. Go to **Server Settings** → **Integrations** → **Webhooks**
3. Click **New Webhook**
4. Name it "P.R.I.S.M"
5. Select a channel (e.g., #server-alerts)
6. Click **Copy Webhook URL**

### Configure in P.R.I.S.M:
```bash
chatbot webhook setup
```

Paste your webhook URL when prompted.

### Test the Webhook:
```bash
chatbot webhook test
```

You should receive a test message in Discord!

## Step 5: Configure Pterodactyl API (Optional)

This allows P.R.I.S.M to monitor individual game servers.

### Get API Key from Panel:
1. Log into Panel: `https://panel.cloudmc.online`
2. Go to **Account** → **API Credentials**
3. Click **Create API Key**
4. Give it a description (e.g., "P.R.I.S.M")
5. Select **All permissions**
6. Click **Create**
7. **Copy the API key** (starts with `ptlc_`)

### Configure in P.R.I.S.M:
```bash
chatbot api setup
```

Enter:
- **Panel URL:** `https://panel.cloudmc.online`
- **API Key:** Paste your API key

### Test API Connection:
```bash
chatbot api test
```

## P.R.I.S.M Commands Reference

```bash
chatbot -enable              # Enable P.R.I.S.M
chatbot -disable             # Disable P.R.I.S.M
chatbot status               # Check status
chatbot logs                 # View live logs
chatbot detect               # Run system analysis
chatbot ask "question"       # Ask AI anything
chatbot webhook setup        # Configure Discord
chatbot webhook test         # Test Discord webhook
chatbot api setup            # Configure Pterodactyl API
chatbot help                 # Show all commands
```

---

# Part 2: Install Web Console

The Web Console provides a professional dashboard for managing your servers.

## Step 1: Install Web Console

```bash
cd /opt/ptero
sudo ./ptero-webconsole.sh enable
```

## Step 2: Follow Interactive Prompts

You'll be asked for:

### Pterodactyl Panel URL
```
Enter Pterodactyl Panel URL: https://panel.cloudmc.online
```

### Pterodactyl API Key
Use the same API key you created for P.R.I.S.M, or create a new one:

1. Panel → Account → API Credentials → Create API Key
2. Copy the key
3. Paste when prompted

### Admin Username
```
Enter admin username [admin]: admin
```
(Press Enter to use default, or type your own)

### Admin Password
```
Enter admin password (min 8 characters): YourSecurePassword123
```

## Step 3: Access Web Console

The installer will show you the access URL:

```
Web Console is now running at: http://YOUR_SERVER_IP:8080
```

Open this in your browser and log in with the credentials you just created.

## Step 4: Configure Firewall (if needed)

If you can't access the web console:

```bash
sudo ufw allow 8080/tcp
sudo ufw reload
```

## Web Console Management Commands

```bash
sudo ./ptero-webconsole.sh status      # Check status
sudo ./ptero-webconsole.sh disable     # Temporarily disable
sudo ./ptero-webconsole.sh enable      # Re-enable
sudo ./ptero-webconsole.sh reinstall   # Update/reinstall
sudo ./ptero-webconsole.sh uninstall   # Completely remove
```

## Web Console Features

Once logged in, you can:
- ✅ View all servers in a dashboard
- ✅ Start/stop/restart servers
- ✅ Access server consoles
- ✅ View real-time resource usage
- ✅ Manage files
- ✅ Schedule tasks
- ✅ View performance graphs
- ✅ And 60+ more features!

---

# Part 3: Set Up Discord Bot

The Discord bot lets you manage servers directly from Discord.

## Step 1: Create Discord Bot Application

1. Go to https://discord.com/developers/applications
2. Click **New Application**
3. Name it "Pterodactyl Bot" (or whatever you like)
4. Click **Create**

## Step 2: Configure Bot

1. Go to **Bot** tab (left sidebar)
2. Click **Add Bot** → **Yes, do it!**
3. Under **Privileged Gateway Intents**, enable:
   - ✅ **Message Content Intent**
   - ✅ **Server Members Intent**
4. Click **Reset Token** → **Copy** the token
   - ⚠️ **Save this token somewhere safe!** You'll need it later

## Step 3: Invite Bot to Your Discord Server

1. Go to **OAuth2** → **URL Generator** (left sidebar)
2. Under **Scopes**, select:
   - ✅ `bot`
3. Under **Bot Permissions**, select:
   - ✅ Send Messages
   - ✅ Embed Links
   - ✅ Read Message History
   - ✅ Use Slash Commands
   - ✅ Connect (for voice)
   - ✅ Speak (for voice)
4. Copy the generated URL at the bottom
5. Open the URL in your browser
6. Select your Discord server
7. Click **Authorize**

## Step 4: Get Anthropic API Key (for P.R.I.S.M AI in Discord)

1. Go to https://console.anthropic.com/
2. Sign up or log in
3. Go to **API Keys**
4. Click **Create Key**
5. Copy the key (starts with `sk-ant-`)

## Step 5: Install Discord Bot on Server

```bash
cd /opt/ptero
git pull  # Make sure you have latest code

cd discord-bot

# Install Python dependencies
pip3 install -r requirements.txt
```

## Step 6: Configure Discord Bot

```bash
# Create configuration file
cp .env.example .env
nano .env
```

Fill in the following:

```env
# Discord Bot Token (from Step 2)
DISCORD_BOT_TOKEN=your_discord_bot_token_here

# Pterodactyl Panel URL
PTERODACTYL_URL=https://panel.cloudmc.online

# Pterodactyl API Key (same one you used for Web Console/P.R.I.S.M)
PTERODACTYL_API_KEY=ptlc_your_api_key_here

# Anthropic API Key (from Step 4)
ANTHROPIC_API_KEY=sk-ant-your_key_here

# Optional: Discord Role ID for admin commands
# Get this by right-clicking a role in Discord (Developer Mode must be on)
ADMIN_ROLE_ID=123456789
```

Save: `Ctrl+O`, `Enter`, `Ctrl+X`

## Step 7: Test the Bot

```bash
python3 bot.py
```

You should see:
```
Logged in as: Pterodactyl Bot#1234
Bot is ready!
```

If it works, press `Ctrl+C` to stop it.

## Step 8: Set Up Bot as a Service (Run 24/7)

```bash
sudo nano /etc/systemd/system/pterodactyl-bot.service
```

Paste this configuration:

```ini
[Unit]
Description=Pterodactyl Discord Bot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ptero/discord-bot
EnvironmentFile=/opt/ptero/discord-bot/.env
ExecStart=/usr/bin/python3 /opt/ptero/discord-bot/bot.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Save: `Ctrl+O`, `Enter`, `Ctrl+X`

## Step 9: Start the Bot Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable pterodactyl-bot
sudo systemctl start pterodactyl-bot
sudo systemctl status pterodactyl-bot
```

You should see: `active (running)`

## Step 10: Test Discord Bot Commands

In your Discord server, try these commands:

```
!ping              # Check if bot is online
!servers           # List all game servers
!botinfo           # Bot information
!help              # Show all commands
```

### With P.R.I.S.M AI:
```
!ask Why is my server lagging?
!analyze           # Get AI analysis of all servers
@Bot what's the status of my servers?
```

## Discord Bot Commands Reference

### Basic Commands (Everyone)
```
!servers                    # List all servers
!status <server_id>         # Get server details
!ping                       # Check bot latency
!botinfo                    # Bot information
!help                       # Show commands
```

### Admin Commands (Requires ADMIN_ROLE_ID)
```
!start <server_id>          # Start server
!stop <server_id>           # Stop server
!restart <server_id>        # Restart server
!kill <server_id>           # Force kill server
!console <server_id> <cmd>  # Send console command
!broadcast <message>        # Broadcast to all servers
```

### P.R.I.S.M AI Commands
```
!ask <question>             # Ask P.R.I.S.M anything
!analyze                    # AI server analysis
@Bot <message>              # Natural language
```

### Voice Commands (Experimental)
```
!join                       # Join your voice channel
!leave                      # Leave voice channel
!say <text>                 # Text-to-speech
!voiceask <question>        # Ask P.R.I.S.M with voice response
```

## Discord Bot Management

```bash
# Check status
sudo systemctl status pterodactyl-bot

# View logs
sudo journalctl -u pterodactyl-bot -f

# Restart bot
sudo systemctl restart pterodactyl-bot

# Stop bot
sudo systemctl stop pterodactyl-bot

# Update bot
cd /opt/ptero
git pull
cd discord-bot
pip3 install -r requirements.txt --upgrade
sudo systemctl restart pterodactyl-bot
```

---

# Summary: What You Now Have

## ✅ P.R.I.S.M AI
- 24/7 system monitoring
- AI-powered assistance
- Discord notifications
- Automatic issue detection
- Performance optimization

**Access:** `chatbot` command on server

## ✅ Web Console
- Professional web dashboard
- Real-time server management
- Performance graphs
- File manager
- 60+ features

**Access:** `http://YOUR_SERVER_IP:8080`

## ✅ Discord Bot
- Manage servers from Discord
- P.R.I.S.M AI integration
- Voice commands
- Automatic alerts
- Natural language control

**Access:** Discord commands in your server

---

# Quick Reference Card

## P.R.I.S.M Commands
```bash
chatbot status               # Check P.R.I.S.M
chatbot detect               # Run analysis
chatbot ask "question"       # Ask AI
chatbot logs                 # View logs
```

## Web Console
```bash
sudo ./ptero-webconsole.sh status      # Check status
sudo ./ptero-webconsole.sh enable      # Start
sudo ./ptero-webconsole.sh disable     # Stop
```

**URL:** `http://YOUR_SERVER_IP:8080`

## Discord Bot
```bash
sudo systemctl status pterodactyl-bot  # Check status
sudo systemctl restart pterodactyl-bot # Restart
sudo journalctl -u pterodactyl-bot -f  # View logs
```

**Discord Commands:**
- `!servers` - List servers
- `!start <id>` - Start server
- `!ask <question>` - Ask P.R.I.S.M

---

# Troubleshooting

## P.R.I.S.M Not Working

```bash
# Check status
chatbot status

# View logs
chatbot logs

# Restart
chatbot -disable
chatbot -enable
```

## Web Console Not Accessible

```bash
# Check if running
sudo ./ptero-webconsole.sh status

# Check firewall
sudo ufw allow 8080/tcp

# View logs
sudo journalctl -u pterodactyl-web-console -f

# Restart
sudo systemctl restart pterodactyl-web-console
```

## Discord Bot Not Responding

```bash
# Check if running
sudo systemctl status pterodactyl-bot

# View logs
sudo journalctl -u pterodactyl-bot -f

# Restart
sudo systemctl restart pterodactyl-bot

# Check configuration
cat /opt/ptero/discord-bot/.env
```

---

# Next Steps

1. **Test Everything**
   - Run `chatbot detect` to optimize your system
   - Log into Web Console and explore features
   - Try Discord bot commands

2. **Set Up Alerts**
   - Configure Discord webhooks for P.R.I.S.M
   - Create #server-alerts channel for bot notifications

3. **Create Your First Server**
   - Use Panel, Web Console, or Discord bot
   - Test server management from all interfaces

4. **Customize**
   - Adjust P.R.I.S.M monitoring intervals
   - Customize Web Console appearance
   - Set up Discord bot permissions

---

# Support

- **P.R.I.S.M:** `chatbot help`
- **Web Console:** Check WEB_CONSOLE_MANAGEMENT.md
- **Discord Bot:** Check discord-bot/README.md
- **General:** WINGS_SETUP_GUIDE.md

---

**🎉 Congratulations! You now have a fully-featured Pterodactyl setup with AI assistance, web dashboard, and Discord integration!**
