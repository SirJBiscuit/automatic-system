# 🤖 Pterodactyl Discord Bot with P.R.I.S.M AI

Full-featured Discord bot for managing Pterodactyl game servers with integrated P.R.I.S.M AI intelligence.

## ✨ Features

### 🎮 Server Management
- **!servers** - List all game servers with status
- **!status <server_id>** - Get detailed server status
- **!start <server_id>** - Start a server
- **!stop <server_id>** - Stop a server
- **!restart <server_id>** - Restart a server
- **!kill <server_id>** - Force kill a server
- **!console <server_id> <command>** - Send console command
- **!broadcast <message>** - Broadcast to all servers

### 🧠 P.R.I.S.M AI Integration
- **!ask <question>** - Ask P.R.I.S.M about your servers
- **!analyze** - Get AI analysis of server performance
- **@Bot <message>** - Natural language interaction

### 🎤 Voice Commands
- **!join** - Bot joins your voice channel
- **!leave** - Bot leaves voice channel
- **!say <text>** - Make bot speak text
- **!voiceask <question>** - Ask P.R.I.S.M and get voice response
- **!listen [seconds]** - Listen for voice command (experimental)

### 📊 Monitoring
- Automatic server status monitoring (every 5 minutes)
- Alerts for server state changes
- Real-time resource tracking

### 🔔 Alerts
- Server crash notifications
- State change alerts
- Resource warnings

## 🚀 Quick Start

### 1. Create Discord Bot

1. Go to https://discord.com/developers/applications
2. Click "New Application"
3. Go to "Bot" → "Add Bot"
4. Enable these Privileged Gateway Intents:
   - Message Content Intent
   - Server Members Intent
5. Copy the bot token

### 2. Get Pterodactyl API Key

1. Log into your Pterodactyl panel
2. Go to Account → API Credentials
3. Create new API key with full permissions
4. Copy the key

### 3. Get Anthropic API Key (for P.R.I.S.M)

1. Go to https://console.anthropic.com/
2. Sign up/login
3. Go to API Keys
4. Create new key
5. Copy the key

### 4. Install on Server

```bash
# On your Pterodactyl server
cd /opt/ptero
git clone https://github.com/SirJBiscuit/automatic-system.git
cd automatic-system/discord-bot

# Install Python dependencies
pip3 install -r requirements.txt

# Create .env file
cp .env.example .env
nano .env
```

### 5. Configure .env

```env
DISCORD_BOT_TOKEN=your_discord_bot_token
PTERODACTYL_URL=https://panel.yourdomain.com
PTERODACTYL_API_KEY=ptlc_your_api_key
ADMIN_ROLE_ID=123456789  # Optional: Discord role ID for admin commands
ANTHROPIC_API_KEY=sk-ant-your_key  # For P.R.I.S.M AI
```

### 6. Run the Bot

```bash
# Test run
python3 bot.py

# Run in background with screen
screen -S discord-bot
python3 bot.py
# Press Ctrl+A then D to detach

# Or use systemd service (recommended)
sudo nano /etc/systemd/system/pterodactyl-bot.service
```

### Systemd Service File

```ini
[Unit]
Description=Pterodactyl Discord Bot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ptero/automatic-system/discord-bot
EnvironmentFile=/opt/ptero/automatic-system/discord-bot/.env
ExecStart=/usr/bin/python3 /opt/ptero/automatic-system/discord-bot/bot.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable pterodactyl-bot
sudo systemctl start pterodactyl-bot
sudo systemctl status pterodactyl-bot
```

## 📝 Commands

### Basic Commands

```
!servers                    # List all servers
!status abc123              # Get server status
!ping                       # Check bot latency
!botinfo                    # Bot information
```

### Admin Commands (requires ADMIN_ROLE_ID)

```
!start abc123               # Start server
!stop abc123                # Stop server
!restart abc123             # Restart server
!kill abc123                # Force kill server
!console abc123 say Hello   # Send console command
!broadcast Server restart   # Broadcast to all servers
```

### P.R.I.S.M AI Commands

```
!ask Why is my server lagging?
!ask How do I optimize RAM usage?
!analyze                    # Get AI server analysis
@Bot restart the minecraft server  # Natural language
```

## 🎯 Example Usage

### Check Server Status
```
User: !servers
Bot: [Shows all servers with status, CPU, RAM]

User: !status abc123
Bot: [Shows detailed status for server abc123]
```

### Start/Stop Servers
```
User: !start abc123
Bot: ✅ Starting server `abc123`...

User: !restart abc123
Bot: ✅ Restarting server `abc123`...
```

### P.R.I.S.M AI Interaction
```
User: !ask Why is my Minecraft server using so much RAM?
Bot: 🧠 P.R.I.S.M AI Response
     Your Minecraft server is using 8.5GB RAM. This is normal for:
     - Large player counts (20+ players)
     - Many loaded chunks
     - Plugins/mods
     
     To optimize:
     1. Reduce view distance
     2. Use Paper/Purpur instead of vanilla
     3. Optimize plugins
     
     Use !console abc123 to send commands.

User: @Bot analyze my servers
Bot: 📊 P.R.I.S.M Server Analysis
     Overall Health: Good
     
     Concerns:
     - Server "Survival" has high CPU (85%)
     - Server "Creative" offline for 2 hours
     
     Recommendations:
     - Restart "Survival" during low traffic
     - Check "Creative" for crashes
```

### Natural Language
```
User: @Bot restart the minecraft server
Bot: To restart a server, use: !restart <server_id>
     
     Your Minecraft servers:
     - Survival (abc123)
     - Creative (def456)
     
     Example: !restart abc123

User: @Bot what's the status of all servers?
Bot: Use !servers to see all server statuses, or !status <server_id> for details.
```

## 🔧 Troubleshooting

### Bot not responding
```bash
# Check if bot is running
systemctl status pterodactyl-bot

# View logs
journalctl -u pterodactyl-bot -f
```

### API errors
- Verify PTERODACTYL_API_KEY has correct permissions
- Check PTERODACTYL_URL is correct (no trailing slash)
- Ensure panel is accessible from server

### P.R.I.S.M not working
- Verify ANTHROPIC_API_KEY is valid
- Check API quota/billing
- Bot will work without P.R.I.S.M, just without AI features

## 📊 Monitoring Setup

Create a `#server-alerts` channel in your Discord server for automatic notifications.

The bot will send alerts for:
- Server state changes (online → offline)
- Crashes
- Resource warnings

## 🔐 Security

- Store `.env` file securely
- Use ADMIN_ROLE_ID to restrict admin commands
- API keys should never be shared
- Run bot as non-root user (recommended)

## 📦 Updates

```bash
cd /opt/ptero/automatic-system
git pull
cd discord-bot
pip3 install -r requirements.txt --upgrade
systemctl restart pterodactyl-bot
```

## 🆘 Support

- GitHub Issues: https://github.com/SirJBiscuit/automatic-system/issues
- Discord: [Your Discord Server]

## 📄 License

MIT License - See LICENSE file

---

**Made with ❤️ for Pterodactyl server management**
**Powered by P.R.I.S.M AI (Claude 3.5 Sonnet)**
