#!/usr/bin/env python3
"""
Pterodactyl Discord Bot - Full Management
Supports server control, monitoring, console commands, and alerts
"""

import discord
from discord.ext import commands, tasks
import aiohttp
import asyncio
import os
from datetime import datetime
import json
import anthropic

# Configuration
DISCORD_TOKEN = os.getenv('DISCORD_TOKEN', '')
PTERODACTYL_URL = os.getenv('PTERODACTYL_URL', 'https://panel.yourdomain.com')
PTERODACTYL_API_KEY = os.getenv('PTERODACTYL_API_KEY', '')
ADMIN_ROLE_ID = int(os.getenv('ADMIN_ROLE_ID', '0'))
ANTHROPIC_API_KEY = os.getenv('ANTHROPIC_API_KEY', '')
ENABLE_VOICE = os.getenv('ENABLE_VOICE', 'true').lower() == 'true'

# P.R.I.S.M AI Client
prism_client = anthropic.Anthropic(api_key=ANTHROPIC_API_KEY) if ANTHROPIC_API_KEY else None

# Bot setup
intents = discord.Intents.default()
intents.message_content = True
intents.members = True
intents.voice_states = True  # Enable voice state tracking

bot = commands.Bot(command_prefix='!', intents=intents)

# Import voice handler
if ENABLE_VOICE:
    try:
        from voice_handler import setup_voice_commands
        VOICE_AVAILABLE = True
    except ImportError:
        VOICE_AVAILABLE = False
        print("⚠️  Voice handler not available")
else:
    VOICE_AVAILABLE = False

# API Headers
headers = {
    'Authorization': f'Bearer {PTERODACTYL_API_KEY}',
    'Accept': 'application/json',
    'Content-Type': 'application/json'
}

# Server status cache
server_cache = {}
last_status = {}

class PterodactylAPI:
    """Pterodactyl API wrapper"""
    
    @staticmethod
    async def get_servers():
        """Get all servers"""
        async with aiohttp.ClientSession() as session:
            async with session.get(
                f'{PTERODACTYL_URL}/api/client',
                headers=headers
            ) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    return data.get('data', [])
                return []
    
    @staticmethod
    async def get_server_status(server_id):
        """Get server status"""
        async with aiohttp.ClientSession() as session:
            async with session.get(
                f'{PTERODACTYL_URL}/api/client/servers/{server_id}/resources',
                headers=headers
            ) as resp:
                if resp.status == 200:
                    return await resp.json()
                return None
    
    @staticmethod
    async def send_power_action(server_id, action):
        """Send power action (start/stop/restart/kill)"""
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f'{PTERODACTYL_URL}/api/client/servers/{server_id}/power',
                headers=headers,
                json={'signal': action}
            ) as resp:
                return resp.status == 204
    
    @staticmethod
    async def send_command(server_id, command):
        """Send console command"""
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f'{PTERODACTYL_URL}/api/client/servers/{server_id}/command',
                headers=headers,
                json={'command': command}
            ) as resp:
                return resp.status == 204

def is_admin():
    """Check if user has admin role"""
    async def predicate(ctx):
        if ADMIN_ROLE_ID == 0:
            return True
        return any(role.id == ADMIN_ROLE_ID for role in ctx.author.roles)
    return commands.check(predicate)

@bot.event
async def on_ready():
    print(f'✅ Bot logged in as {bot.user}')
    print(f'📊 Connected to {len(bot.guilds)} server(s)')
    
    # Setup voice commands
    if VOICE_AVAILABLE:
        setup_voice_commands(bot, prism_client)
        print(f'🎤 Voice commands enabled')
    
    monitor_servers.start()
    await bot.change_presence(activity=discord.Game(name="!help for commands"))

@bot.command(name='servers', help='List all game servers')
async def list_servers(ctx):
    """List all servers with status"""
    servers = await PterodactylAPI.get_servers()
    
    if not servers:
        await ctx.send('❌ No servers found or API error')
        return
    
    embed = discord.Embed(
        title='🎮 Game Servers',
        color=discord.Color.blue(),
        timestamp=datetime.utcnow()
    )
    
    for server in servers:
        attrs = server['attributes']
        server_id = attrs['identifier']
        
        # Get status
        status_data = await PterodactylAPI.get_server_status(server_id)
        if status_data:
            state = status_data['attributes']['current_state']
            status_emoji = '🟢' if state == 'running' else '🔴'
            
            resources = status_data['attributes']['resources']
            cpu = resources.get('cpu_absolute', 0)
            memory = resources.get('memory_bytes', 0) / (1024**3)  # Convert to GB
            
            value = f"{status_emoji} **{state.title()}**\n"
            value += f"CPU: {cpu:.1f}%\n"
            value += f"RAM: {memory:.2f} GB\n"
            value += f"ID: `{server_id}`"
        else:
            value = "❓ Status unknown"
        
        embed.add_field(
            name=attrs['name'],
            value=value,
            inline=True
        )
    
    await ctx.send(embed=embed)

@bot.command(name='status', help='Get detailed server status')
async def server_status(ctx, server_id: str):
    """Get detailed status for a specific server"""
    status_data = await PterodactylAPI.get_server_status(server_id)
    
    if not status_data:
        await ctx.send(f'❌ Server `{server_id}` not found')
        return
    
    attrs = status_data['attributes']
    state = attrs['current_state']
    resources = attrs['resources']
    
    embed = discord.Embed(
        title=f'📊 Server Status: {server_id}',
        color=discord.Color.green() if state == 'running' else discord.Color.red(),
        timestamp=datetime.utcnow()
    )
    
    embed.add_field(name='State', value=f'{"🟢" if state == "running" else "🔴"} {state.title()}', inline=True)
    embed.add_field(name='CPU', value=f'{resources.get("cpu_absolute", 0):.1f}%', inline=True)
    embed.add_field(name='RAM', value=f'{resources.get("memory_bytes", 0) / (1024**3):.2f} GB', inline=True)
    embed.add_field(name='Disk', value=f'{resources.get("disk_bytes", 0) / (1024**3):.2f} GB', inline=True)
    embed.add_field(name='Network (RX)', value=f'{resources.get("network_rx_bytes", 0) / (1024**2):.2f} MB', inline=True)
    embed.add_field(name='Network (TX)', value=f'{resources.get("network_tx_bytes", 0) / (1024**2):.2f} MB', inline=True)
    embed.add_field(name='Uptime', value=f'{resources.get("uptime", 0) // 60} minutes', inline=True)
    
    await ctx.send(embed=embed)

@bot.command(name='start', help='Start a server')
@is_admin()
async def start_server(ctx, server_id: str):
    """Start a server"""
    success = await PterodactylAPI.send_power_action(server_id, 'start')
    
    if success:
        await ctx.send(f'✅ Starting server `{server_id}`...')
    else:
        await ctx.send(f'❌ Failed to start server `{server_id}`')

@bot.command(name='stop', help='Stop a server')
@is_admin()
async def stop_server(ctx, server_id: str):
    """Stop a server"""
    success = await PterodactylAPI.send_power_action(server_id, 'stop')
    
    if success:
        await ctx.send(f'✅ Stopping server `{server_id}`...')
    else:
        await ctx.send(f'❌ Failed to stop server `{server_id}`')

@bot.command(name='restart', help='Restart a server')
@is_admin()
async def restart_server(ctx, server_id: str):
    """Restart a server"""
    success = await PterodactylAPI.send_power_action(server_id, 'restart')
    
    if success:
        await ctx.send(f'✅ Restarting server `{server_id}`...')
    else:
        await ctx.send(f'❌ Failed to restart server `{server_id}`')

@bot.command(name='kill', help='Force kill a server')
@is_admin()
async def kill_server(ctx, server_id: str):
    """Force kill a server"""
    success = await PterodactylAPI.send_power_action(server_id, 'kill')
    
    if success:
        await ctx.send(f'⚠️ Force killing server `{server_id}`...')
    else:
        await ctx.send(f'❌ Failed to kill server `{server_id}`')

@bot.command(name='console', help='Send console command')
@is_admin()
async def send_console_command(ctx, server_id: str, *, command: str):
    """Send command to server console"""
    success = await PterodactylAPI.send_command(server_id, command)
    
    if success:
        await ctx.send(f'✅ Sent command to `{server_id}`: `{command}`')
    else:
        await ctx.send(f'❌ Failed to send command to `{server_id}`')

@bot.command(name='broadcast', help='Broadcast message to all servers')
@is_admin()
async def broadcast_message(ctx, *, message: str):
    """Broadcast message to all servers"""
    servers = await PterodactylAPI.get_servers()
    
    success_count = 0
    for server in servers:
        server_id = server['attributes']['identifier']
        # Send as 'say' command (works for most game servers)
        if await PterodactylAPI.send_command(server_id, f'say {message}'):
            success_count += 1
    
    await ctx.send(f'✅ Broadcast sent to {success_count}/{len(servers)} servers')

@tasks.loop(minutes=5)
async def monitor_servers():
    """Monitor servers and send alerts"""
    global last_status
    
    servers = await PterodactylAPI.get_servers()
    
    for server in servers:
        server_id = server['attributes']['identifier']
        server_name = server['attributes']['name']
        
        status_data = await PterodactylAPI.get_server_status(server_id)
        if not status_data:
            continue
        
        current_state = status_data['attributes']['current_state']
        
        # Check for state changes
        if server_id in last_status:
            if last_status[server_id] != current_state:
                # Server state changed - send alert
                for guild in bot.guilds:
                    # Find alerts channel
                    channel = discord.utils.get(guild.text_channels, name='server-alerts')
                    if channel:
                        embed = discord.Embed(
                            title=f'🔔 Server State Changed',
                            description=f'**{server_name}** (`{server_id}`)',
                            color=discord.Color.orange(),
                            timestamp=datetime.utcnow()
                        )
                        embed.add_field(name='Previous State', value=last_status[server_id], inline=True)
                        embed.add_field(name='Current State', value=current_state, inline=True)
                        
                        await channel.send(embed=embed)
        
        last_status[server_id] = current_state

@monitor_servers.before_loop
async def before_monitor():
    await bot.wait_until_ready()

@bot.command(name='ping', help='Check bot latency')
async def ping(ctx):
    """Check bot latency"""
    latency = round(bot.latency * 1000)
    await ctx.send(f'🏓 Pong! Latency: {latency}ms')

@bot.command(name='botinfo', help='Show bot information')
async def bot_info(ctx):
    """Show bot information"""
    embed = discord.Embed(
        title='🤖 Pterodactyl Bot Info',
        color=discord.Color.blue(),
        timestamp=datetime.utcnow()
    )
    
    embed.add_field(name='Bot Version', value='1.0.0', inline=True)
    embed.add_field(name='Servers', value=len(bot.guilds), inline=True)
    embed.add_field(name='Latency', value=f'{round(bot.latency * 1000)}ms', inline=True)
    embed.add_field(name='Panel URL', value=PTERODACTYL_URL, inline=False)
    embed.add_field(name='P.R.I.S.M AI', value='✅ Enabled' if prism_client else '❌ Disabled', inline=True)
    
    await ctx.send(embed=embed)

@bot.command(name='ask', help='Ask P.R.I.S.M AI about your servers')
async def ask_prism(ctx, *, question: str):
    """Ask P.R.I.S.M AI about server management"""
    if not prism_client:
        await ctx.send('❌ P.R.I.S.M AI is not configured. Set ANTHROPIC_API_KEY environment variable.')
        return
    
    async with ctx.typing():
        # Get current server status
        servers = await PterodactylAPI.get_servers()
        server_info = []
        
        for server in servers:
            attrs = server['attributes']
            server_id = attrs['identifier']
            status_data = await PterodactylAPI.get_server_status(server_id)
            
            if status_data:
                state = status_data['attributes']['current_state']
                resources = status_data['attributes']['resources']
                server_info.append({
                    'name': attrs['name'],
                    'id': server_id,
                    'state': state,
                    'cpu': resources.get('cpu_absolute', 0),
                    'memory_gb': resources.get('memory_bytes', 0) / (1024**3)
                })
        
        # Build context for P.R.I.S.M
        context = f"""You are P.R.I.S.M, an AI assistant for Pterodactyl game server management.

Current Server Status:
{json.dumps(server_info, indent=2)}

Panel URL: {PTERODACTYL_URL}

User Question: {question}

Provide helpful, concise answers about server management, troubleshooting, and optimization.
If the user asks to perform an action, explain what command they should use (e.g., !start <server_id>).
"""
        
        try:
            response = prism_client.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=1024,
                messages=[{
                    "role": "user",
                    "content": context
                }]
            )
            
            answer = response.content[0].text
            
            # Split long responses
            if len(answer) > 2000:
                chunks = [answer[i:i+2000] for i in range(0, len(answer), 2000)]
                for chunk in chunks:
                    await ctx.send(chunk)
            else:
                embed = discord.Embed(
                    title='🧠 P.R.I.S.M AI Response',
                    description=answer,
                    color=discord.Color.purple(),
                    timestamp=datetime.utcnow()
                )
                await ctx.send(embed=embed)
                
        except Exception as e:
            await ctx.send(f'❌ P.R.I.S.M AI Error: {str(e)}')

@bot.command(name='analyze', help='Get AI analysis of server performance')
@is_admin()
async def analyze_servers(ctx):
    """Get P.R.I.S.M AI analysis of all servers"""
    if not prism_client:
        await ctx.send('❌ P.R.I.S.M AI is not configured.')
        return
    
    async with ctx.typing():
        servers = await PterodactylAPI.get_servers()
        server_data = []
        
        for server in servers:
            attrs = server['attributes']
            server_id = attrs['identifier']
            status_data = await PterodactylAPI.get_server_status(server_id)
            
            if status_data:
                state = status_data['attributes']['current_state']
                resources = status_data['attributes']['resources']
                server_data.append({
                    'name': attrs['name'],
                    'id': server_id,
                    'state': state,
                    'cpu_percent': resources.get('cpu_absolute', 0),
                    'memory_gb': resources.get('memory_bytes', 0) / (1024**3),
                    'disk_gb': resources.get('disk_bytes', 0) / (1024**3),
                    'uptime_minutes': resources.get('uptime', 0) // 60
                })
        
        prompt = f"""Analyze these Pterodactyl game servers and provide insights:

{json.dumps(server_data, indent=2)}

Provide:
1. Overall health assessment
2. Performance issues or concerns
3. Resource optimization recommendations
4. Any servers that need attention

Be concise and actionable."""
        
        try:
            response = prism_client.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=1500,
                messages=[{
                    "role": "user",
                    "content": prompt
                }]
            )
            
            analysis = response.content[0].text
            
            embed = discord.Embed(
                title='📊 P.R.I.S.M Server Analysis',
                description=analysis,
                color=discord.Color.gold(),
                timestamp=datetime.utcnow()
            )
            
            await ctx.send(embed=embed)
            
        except Exception as e:
            await ctx.send(f'❌ Analysis Error: {str(e)}')

@bot.event
async def on_message(message):
    """Handle natural language commands with P.R.I.S.M"""
    if message.author.bot:
        return
    
    # Process normal commands first
    await bot.process_commands(message)
    
    # Check if bot is mentioned and P.R.I.S.M is enabled
    if bot.user.mentioned_in(message) and prism_client:
        # Remove bot mention from message
        content = message.content.replace(f'<@{bot.user.id}>', '').strip()
        
        if not content:
            return
        
        async with message.channel.typing():
            # Get server context
            servers = await PterodactylAPI.get_servers()
            server_list = [{'name': s['attributes']['name'], 'id': s['attributes']['identifier']} for s in servers]
            
            prompt = f"""You are P.R.I.S.M, a Discord bot for Pterodactyl server management.

Available servers:
{json.dumps(server_list, indent=2)}

Available commands:
- !servers - List all servers
- !status <server_id> - Get server status
- !start <server_id> - Start server
- !stop <server_id> - Stop server
- !restart <server_id> - Restart server
- !console <server_id> <command> - Send console command
- !ask <question> - Ask P.R.I.S.M a question
- !analyze - Get AI server analysis

User said: {content}

If they're asking to perform an action, tell them the exact command to use.
If they're asking a question, answer it helpfully and concisely.
Be friendly and professional."""
            
            try:
                response = prism_client.messages.create(
                    model="claude-3-5-sonnet-20241022",
                    max_tokens=500,
                    messages=[{
                        "role": "user",
                        "content": prompt
                    }]
                )
                
                reply = response.content[0].text
                await message.reply(reply)
                
            except Exception as e:
                await message.reply(f'❌ Error: {str(e)}')

if __name__ == '__main__':
    if not DISCORD_TOKEN:
        print('❌ Error: DISCORD_BOT_TOKEN not set!')
        exit(1)
    
    if not PTERODACTYL_API_KEY:
        print('❌ Error: PTERODACTYL_API_KEY not set!')
        exit(1)
    
    print('🚀 Starting Pterodactyl Discord Bot...')
    bot.run(DISCORD_TOKEN)
