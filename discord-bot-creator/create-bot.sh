#!/bin/bash

# Discord Bot Creator - Interactive Bot Setup Tool
# Creates custom Discord bots with various features

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

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
    while true; do
        read -p "$prompt (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

clear
echo ""
echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║                    DISCORD BOT CREATOR v1.0                            ║"
echo "║              Create Custom Discord Bots in Minutes!                    ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""

# Bot name
echo ""
log_info "Let's create your Discord bot!"
echo ""
read -p "Bot Name: " BOT_NAME
BOT_DIR="/opt/discord-bots/${BOT_NAME// /-}"
BOT_DIR=$(echo "$BOT_DIR" | tr '[:upper:]' '[:lower:]')

# Check if directory exists
if [ -d "$BOT_DIR" ]; then
    log_error "Bot directory already exists: $BOT_DIR"
    if ! prompt_yes_no "Overwrite existing bot?"; then
        exit 0
    fi
    rm -rf "$BOT_DIR"
fi

# Create directory
log_info "Creating bot directory: $BOT_DIR"
mkdir -p "$BOT_DIR"

# Bot type selection
echo ""
log_info "╔════════════════════════════════════════════════════════════════════╗"
log_info "║                      SELECT BOT TYPE                               ║"
log_info "╚════════════════════════════════════════════════════════════════════╝"
echo ""
echo "  1) 🎮 Game Server Manager (Pterodactyl, Minecraft, etc.)"
echo "  2) 🎵 Music Bot (Play music in voice channels)"
echo "  3) 🛡️  Moderation Bot (Auto-mod, warnings, bans)"
echo "  4) 📊 Stats/Analytics Bot (Server stats, user tracking)"
echo "  5) 🤖 AI Chatbot (P.R.I.S.M powered conversations)"
echo "  6) 🎲 Games & Fun Bot (Trivia, games, memes)"
echo "  7) 📢 Announcement Bot (Scheduled messages, alerts)"
echo "  8) 🔧 Custom Bot (Build from scratch)"
echo ""
read -p "Select bot type (1-8): " BOT_TYPE

# Feature selection
echo ""
log_info "╔════════════════════════════════════════════════════════════════════╗"
log_info "║                    SELECT FEATURES                                 ║"
log_info "╚════════════════════════════════════════════════════════════════════╝"
echo ""

FEATURES=()

if prompt_yes_no "Enable P.R.I.S.M AI integration?"; then
    FEATURES+=("prism")
fi

if prompt_yes_no "Enable database (SQLite)?"; then
    FEATURES+=("database")
fi

if prompt_yes_no "Enable web dashboard?"; then
    FEATURES+=("dashboard")
fi

if prompt_yes_no "Enable logging system?"; then
    FEATURES+=("logging")
fi

if prompt_yes_no "Enable slash commands?"; then
    FEATURES+=("slash")
fi

# Configuration
echo ""
log_info "╔════════════════════════════════════════════════════════════════════╗"
log_info "║                    CONFIGURATION                                   ║"
log_info "╚════════════════════════════════════════════════════════════════════╝"
echo ""

read -p "Command Prefix (default: !): " CMD_PREFIX
CMD_PREFIX=${CMD_PREFIX:-!}

read -p "Bot Description: " BOT_DESC

# Generate bot code based on type
log_info "Generating bot code..."

case $BOT_TYPE in
    1)
        generate_game_server_bot
        ;;
    2)
        generate_music_bot
        ;;
    3)
        generate_moderation_bot
        ;;
    4)
        generate_stats_bot
        ;;
    5)
        generate_ai_chatbot
        ;;
    6)
        generate_games_bot
        ;;
    7)
        generate_announcement_bot
        ;;
    8)
        generate_custom_bot
        ;;
esac

# Create requirements.txt
create_requirements

# Create .env template
create_env_template

# Create README
create_readme

# Create systemd service
create_systemd_service

# Install dependencies
if prompt_yes_no "Install Python dependencies now?"; then
    log_info "Installing dependencies..."
    cd "$BOT_DIR"
    pip3 install -r requirements.txt
fi

# Setup systemd service
if prompt_yes_no "Install as systemd service?"; then
    log_info "Installing systemd service..."
    sudo cp "${BOT_DIR}/bot.service" "/etc/systemd/system/${BOT_NAME// /-}.service"
    sudo systemctl daemon-reload
    log_success "Service installed: ${BOT_NAME// /-}.service"
fi

echo ""
log_success "╔════════════════════════════════════════════════════════════════════╗"
log_success "║                  BOT CREATED SUCCESSFULLY! 🎉                      ║"
log_success "╚════════════════════════════════════════════════════════════════════╝"
echo ""
log_info "Bot Location: $BOT_DIR"
echo ""
log_info "Next Steps:"
echo "  1. Edit configuration: nano $BOT_DIR/.env"
echo "  2. Add your Discord bot token"
echo "  3. Configure other API keys if needed"
echo "  4. Start bot: cd $BOT_DIR && python3 bot.py"
echo ""
if [ -f "/etc/systemd/system/${BOT_NAME// /-}.service" ]; then
    echo "  Or use systemd:"
    echo "    sudo systemctl start ${BOT_NAME// /-}"
    echo "    sudo systemctl enable ${BOT_NAME// /-}"
    echo ""
fi
log_info "Documentation: $BOT_DIR/README.md"
echo ""

# Function definitions
generate_game_server_bot() {
    cat > "$BOT_DIR/bot.py" <<'EOF'
#!/usr/bin/env python3
import discord
from discord.ext import commands
import os

TOKEN = os.getenv('DISCORD_TOKEN')
PREFIX = os.getenv('COMMAND_PREFIX', '!')

intents = discord.Intents.default()
intents.message_content = True
bot = commands.Bot(command_prefix=PREFIX, intents=intents)

@bot.event
async def on_ready():
    print(f'✅ {bot.user} is online!')
    await bot.change_presence(activity=discord.Game(name=f"{PREFIX}help"))

@bot.command(name='servers')
async def list_servers(ctx):
    """List all game servers"""
    embed = discord.Embed(title='🎮 Game Servers', color=discord.Color.blue())
    embed.add_field(name='Server 1', value='🟢 Online', inline=False)
    await ctx.send(embed=embed)

@bot.command(name='status')
async def server_status(ctx, server_id: str):
    """Get server status"""
    await ctx.send(f'📊 Status for server: {server_id}')

if __name__ == '__main__':
    bot.run(TOKEN)
EOF
}

generate_music_bot() {
    cat > "$BOT_DIR/bot.py" <<'EOF'
#!/usr/bin/env python3
import discord
from discord.ext import commands
import os

TOKEN = os.getenv('DISCORD_TOKEN')
PREFIX = os.getenv('COMMAND_PREFIX', '!')

intents = discord.Intents.default()
intents.message_content = True
bot = commands.Bot(command_prefix=PREFIX, intents=intents)

@bot.event
async def on_ready():
    print(f'✅ {bot.user} is online!')

@bot.command(name='play')
async def play(ctx, *, query: str):
    """Play music"""
    await ctx.send(f'🎵 Playing: {query}')

@bot.command(name='stop')
async def stop(ctx):
    """Stop music"""
    await ctx.send('⏹️ Stopped')

if __name__ == '__main__':
    bot.run(TOKEN)
EOF
}

generate_moderation_bot() {
    cat > "$BOT_DIR/bot.py" <<'EOF'
#!/usr/bin/env python3
import discord
from discord.ext import commands
import os

TOKEN = os.getenv('DISCORD_TOKEN')
PREFIX = os.getenv('COMMAND_PREFIX', '!')

intents = discord.Intents.default()
intents.message_content = True
intents.members = True
bot = commands.Bot(command_prefix=PREFIX, intents=intents)

@bot.event
async def on_ready():
    print(f'✅ {bot.user} is online!')

@bot.command(name='warn')
@commands.has_permissions(manage_messages=True)
async def warn(ctx, member: discord.Member, *, reason: str):
    """Warn a member"""
    await ctx.send(f'⚠️ {member.mention} has been warned: {reason}')

@bot.command(name='ban')
@commands.has_permissions(ban_members=True)
async def ban(ctx, member: discord.Member, *, reason: str):
    """Ban a member"""
    await member.ban(reason=reason)
    await ctx.send(f'🔨 {member.mention} has been banned: {reason}')

if __name__ == '__main__':
    bot.run(TOKEN)
EOF
}

generate_stats_bot() {
    cat > "$BOT_DIR/bot.py" <<'EOF'
#!/usr/bin/env python3
import discord
from discord.ext import commands
import os

TOKEN = os.getenv('DISCORD_TOKEN')
PREFIX = os.getenv('COMMAND_PREFIX', '!')

intents = discord.Intents.default()
intents.message_content = True
intents.members = True
bot = commands.Bot(command_prefix=PREFIX, intents=intents)

@bot.event
async def on_ready():
    print(f'✅ {bot.user} is online!')

@bot.command(name='stats')
async def stats(ctx):
    """Server statistics"""
    embed = discord.Embed(title='📊 Server Stats', color=discord.Color.blue())
    embed.add_field(name='Members', value=ctx.guild.member_count, inline=True)
    embed.add_field(name='Channels', value=len(ctx.guild.channels), inline=True)
    await ctx.send(embed=embed)

if __name__ == '__main__':
    bot.run(TOKEN)
EOF
}

generate_ai_chatbot() {
    cat > "$BOT_DIR/bot.py" <<'EOF'
#!/usr/bin/env python3
import discord
from discord.ext import commands
import anthropic
import os

TOKEN = os.getenv('DISCORD_TOKEN')
ANTHROPIC_KEY = os.getenv('ANTHROPIC_API_KEY')
PREFIX = os.getenv('COMMAND_PREFIX', '!')

intents = discord.Intents.default()
intents.message_content = True
bot = commands.Bot(command_prefix=PREFIX, intents=intents)
ai = anthropic.Anthropic(api_key=ANTHROPIC_KEY) if ANTHROPIC_KEY else None

@bot.event
async def on_ready():
    print(f'✅ {bot.user} is online!')

@bot.command(name='ask')
async def ask(ctx, *, question: str):
    """Ask P.R.I.S.M AI"""
    if not ai:
        await ctx.send('❌ AI not configured')
        return
    
    async with ctx.typing():
        response = ai.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=1024,
            messages=[{"role": "user", "content": question}]
        )
        await ctx.send(response.content[0].text)

if __name__ == '__main__':
    bot.run(TOKEN)
EOF
}

generate_games_bot() {
    cat > "$BOT_DIR/bot.py" <<'EOF'
#!/usr/bin/env python3
import discord
from discord.ext import commands
import random
import os

TOKEN = os.getenv('DISCORD_TOKEN')
PREFIX = os.getenv('COMMAND_PREFIX', '!')

intents = discord.Intents.default()
intents.message_content = True
bot = commands.Bot(command_prefix=PREFIX, intents=intents)

@bot.event
async def on_ready():
    print(f'✅ {bot.user} is online!')

@bot.command(name='roll')
async def roll(ctx, dice: str = '1d6'):
    """Roll dice (e.g., 2d6)"""
    try:
        rolls, sides = map(int, dice.split('d'))
        results = [random.randint(1, sides) for _ in range(rolls)]
        await ctx.send(f'🎲 Rolled {dice}: {results} = {sum(results)}')
    except:
        await ctx.send('❌ Invalid dice format (use: 2d6)')

@bot.command(name='8ball')
async def eightball(ctx, *, question: str):
    """Magic 8-ball"""
    responses = ['Yes', 'No', 'Maybe', 'Ask again later', 'Definitely']
    await ctx.send(f'🎱 {random.choice(responses)}')

if __name__ == '__main__':
    bot.run(TOKEN)
EOF
}

generate_announcement_bot() {
    cat > "$BOT_DIR/bot.py" <<'EOF'
#!/usr/bin/env python3
import discord
from discord.ext import commands, tasks
import os

TOKEN = os.getenv('DISCORD_TOKEN')
PREFIX = os.getenv('COMMAND_PREFIX', '!')

intents = discord.Intents.default()
intents.message_content = True
bot = commands.Bot(command_prefix=PREFIX, intents=intents)

@bot.event
async def on_ready():
    print(f'✅ {bot.user} is online!')

@bot.command(name='announce')
@commands.has_permissions(manage_messages=True)
async def announce(ctx, channel: discord.TextChannel, *, message: str):
    """Send announcement"""
    embed = discord.Embed(title='📢 Announcement', description=message, color=discord.Color.gold())
    await channel.send(embed=embed)
    await ctx.send(f'✅ Announcement sent to {channel.mention}')

if __name__ == '__main__':
    bot.run(TOKEN)
EOF
}

generate_custom_bot() {
    cat > "$BOT_DIR/bot.py" <<'EOF'
#!/usr/bin/env python3
import discord
from discord.ext import commands
import os

TOKEN = os.getenv('DISCORD_TOKEN')
PREFIX = os.getenv('COMMAND_PREFIX', '!')

intents = discord.Intents.default()
intents.message_content = True
bot = commands.Bot(command_prefix=PREFIX, intents=intents)

@bot.event
async def on_ready():
    print(f'✅ {bot.user} is online!')
    await bot.change_presence(activity=discord.Game(name=f"{PREFIX}help"))

@bot.command(name='ping')
async def ping(ctx):
    """Check bot latency"""
    await ctx.send(f'🏓 Pong! {round(bot.latency * 1000)}ms')

# Add your custom commands here

if __name__ == '__main__':
    bot.run(TOKEN)
EOF
}

create_requirements() {
    cat > "$BOT_DIR/requirements.txt" <<EOF
discord.py>=2.3.0
python-dotenv>=1.0.0
EOF

    if [[ " ${FEATURES[@]} " =~ " prism " ]]; then
        echo "anthropic>=0.18.0" >> "$BOT_DIR/requirements.txt"
    fi
    
    if [[ " ${FEATURES[@]} " =~ " database " ]]; then
        echo "aiosqlite>=0.19.0" >> "$BOT_DIR/requirements.txt"
    fi
}

create_env_template() {
    cat > "$BOT_DIR/.env.example" <<EOF
# Discord Bot Token
DISCORD_TOKEN=your_bot_token_here

# Command Prefix
COMMAND_PREFIX=$CMD_PREFIX

# P.R.I.S.M AI (if enabled)
ANTHROPIC_API_KEY=your_anthropic_key_here
EOF

    cp "$BOT_DIR/.env.example" "$BOT_DIR/.env"
}

create_readme() {
    cat > "$BOT_DIR/README.md" <<EOF
# $BOT_NAME

$BOT_DESC

## Features

- Command prefix: \`$CMD_PREFIX\`
- Bot type: Type $BOT_TYPE
$(for feature in "${FEATURES[@]}"; do echo "- $feature enabled"; done)

## Setup

1. Edit \`.env\` file with your tokens
2. Install dependencies: \`pip3 install -r requirements.txt\`
3. Run bot: \`python3 bot.py\`

## Commands

Use \`${CMD_PREFIX}help\` to see all commands.

Created with Discord Bot Creator v1.0
EOF
}

create_systemd_service() {
    cat > "$BOT_DIR/bot.service" <<EOF
[Unit]
Description=$BOT_NAME Discord Bot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$BOT_DIR
EnvironmentFile=$BOT_DIR/.env
ExecStart=/usr/bin/python3 $BOT_DIR/bot.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
}
