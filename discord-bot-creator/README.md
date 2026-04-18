# 🤖 Discord Bot Creator

**Create custom Discord bots in minutes with an interactive wizard!**

## ✨ Features

### 🎯 Bot Types
1. **🎮 Game Server Manager** - Manage Pterodactyl, Minecraft, etc.
2. **🎵 Music Bot** - Play music in voice channels
3. **🛡️ Moderation Bot** - Auto-mod, warnings, bans
4. **📊 Stats/Analytics Bot** - Server stats, user tracking
5. **🤖 AI Chatbot** - P.R.I.S.M powered conversations
6. **🎲 Games & Fun Bot** - Trivia, games, memes
7. **📢 Announcement Bot** - Scheduled messages, alerts
8. **🔧 Custom Bot** - Build from scratch

### 🔧 Optional Features
- ✅ P.R.I.S.M AI integration
- ✅ SQLite database
- ✅ Web dashboard
- ✅ Advanced logging
- ✅ Slash commands

## 🚀 Quick Start

```bash
# Download and run
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/discord-bot-creator/create-bot.sh -o create-bot.sh
chmod +x create-bot.sh
sudo ./create-bot.sh
```

## 📋 Interactive Setup

The wizard will ask you:

1. **Bot Name** - What to call your bot
2. **Bot Type** - Choose from 8 templates
3. **Features** - Select optional features
4. **Configuration** - Command prefix, description
5. **Installation** - Auto-install dependencies

## 🎯 Example Usage

```bash
$ sudo ./create-bot.sh

╔════════════════════════════════════════════════════════════════════════╗
║                    DISCORD BOT CREATOR v1.0                            ║
║              Create Custom Discord Bots in Minutes!                    ║
╚════════════════════════════════════════════════════════════════════════╝

Bot Name: My Awesome Bot

╔════════════════════════════════════════════════════════════════════╗
║                      SELECT BOT TYPE                               ║
╚════════════════════════════════════════════════════════════════════╝

  1) 🎮 Game Server Manager
  2) 🎵 Music Bot
  3) 🛡️  Moderation Bot
  4) 📊 Stats/Analytics Bot
  5) 🤖 AI Chatbot
  6) 🎲 Games & Fun Bot
  7) 📢 Announcement Bot
  8) 🔧 Custom Bot

Select bot type (1-8): 5

Enable P.R.I.S.M AI integration? (y/n): y
Enable database (SQLite)? (y/n): n
Enable web dashboard? (y/n): n
Enable logging system? (y/n): y
Enable slash commands? (y/n): y

Command Prefix (default: !): !
Bot Description: An AI-powered chatbot for my Discord server

✅ Bot created successfully! 🎉

Bot Location: /opt/discord-bots/my-awesome-bot

Next Steps:
  1. Edit configuration: nano /opt/discord-bots/my-awesome-bot/.env
  2. Add your Discord bot token
  3. Configure other API keys if needed
  4. Start bot: cd /opt/discord-bots/my-awesome-bot && python3 bot.py
```

## 📁 Generated Structure

```
/opt/discord-bots/your-bot-name/
├── bot.py              # Main bot code
├── requirements.txt    # Python dependencies
├── .env               # Configuration (tokens, keys)
├── .env.example       # Template
├── README.md          # Bot documentation
└── bot.service        # Systemd service file
```

## 🎮 Bot Templates

### Game Server Manager
```python
!servers              # List all servers
!status <id>          # Server status
!start <id>           # Start server
!stop <id>            # Stop server
!restart <id>         # Restart server
```

### Music Bot
```python
!play <song>          # Play music
!pause                # Pause
!resume               # Resume
!stop                 # Stop
!queue                # Show queue
```

### Moderation Bot
```python
!warn <user> <reason> # Warn user
!kick <user> <reason> # Kick user
!ban <user> <reason>  # Ban user
!mute <user>          # Mute user
!clear <amount>       # Clear messages
```

### AI Chatbot
```python
!ask <question>       # Ask P.R.I.S.M
!chat <message>       # Chat with AI
!analyze <topic>      # Get AI analysis
```

### Games Bot
```python
!roll <dice>          # Roll dice (2d6)
!8ball <question>     # Magic 8-ball
!trivia               # Start trivia
!coinflip             # Flip coin
```

## ⚙️ Configuration

Edit `.env` file:

```env
# Discord Bot Token (required)
DISCORD_TOKEN=your_bot_token_here

# Command Prefix
COMMAND_PREFIX=!

# P.R.I.S.M AI (optional)
ANTHROPIC_API_KEY=your_key_here

# Other API keys as needed
```

## 🔧 Running Your Bot

### Method 1: Direct Run
```bash
cd /opt/discord-bots/your-bot-name
python3 bot.py
```

### Method 2: Systemd Service
```bash
# Install service
sudo cp bot.service /etc/systemd/system/your-bot-name.service
sudo systemctl daemon-reload

# Start bot
sudo systemctl start your-bot-name
sudo systemctl enable your-bot-name

# View logs
journalctl -u your-bot-name -f
```

### Method 3: Screen/Tmux
```bash
screen -S my-bot
cd /opt/discord-bots/your-bot-name
python3 bot.py
# Press Ctrl+A then D to detach
```

## 📊 Managing Multiple Bots

Create as many bots as you want:

```bash
# Create bot 1
./create-bot.sh
# Name: Music Bot

# Create bot 2
./create-bot.sh
# Name: Moderation Bot

# Create bot 3
./create-bot.sh
# Name: Game Manager

# All stored in /opt/discord-bots/
```

## 🔐 Getting Discord Bot Token

1. Go to https://discord.com/developers/applications
2. Click "New Application"
3. Go to "Bot" → "Add Bot"
4. Enable Privileged Gateway Intents:
   - Message Content Intent
   - Server Members Intent (if needed)
5. Copy token under "TOKEN"

## 🎨 Customization

All generated bots are fully customizable:

```bash
# Edit bot code
nano /opt/discord-bots/your-bot-name/bot.py

# Add new commands
# Modify existing features
# Integrate with APIs
# Add database functionality
```

## 🆘 Troubleshooting

### Bot not starting
```bash
# Check logs
journalctl -u your-bot-name -f

# Verify token
nano /opt/discord-bots/your-bot-name/.env

# Test manually
cd /opt/discord-bots/your-bot-name
python3 bot.py
```

### Missing dependencies
```bash
cd /opt/discord-bots/your-bot-name
pip3 install -r requirements.txt
```

### Permission errors
```bash
# Make sure bot has proper Discord permissions
# Check role hierarchy in Discord server
```

## 📦 Updates

```bash
# Re-download creator
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/discord-bot-creator/create-bot.sh -o create-bot.sh
chmod +x create-bot.sh
```

## 🌟 Examples

### Create AI Chatbot
```bash
./create-bot.sh
# Name: P.R.I.S.M Assistant
# Type: 5 (AI Chatbot)
# Enable P.R.I.S.M: Yes
# Prefix: !
```

### Create Moderation Bot
```bash
./create-bot.sh
# Name: Server Guardian
# Type: 3 (Moderation Bot)
# Enable logging: Yes
# Prefix: !
```

### Create Game Server Manager
```bash
./create-bot.sh
# Name: Server Control
# Type: 1 (Game Server Manager)
# Enable P.R.I.S.M: Yes
# Enable database: Yes
# Prefix: !
```

## 📄 License

MIT License

---

**Made with ❤️ for Discord bot creators**
**Powered by discord.py and P.R.I.S.M AI**
