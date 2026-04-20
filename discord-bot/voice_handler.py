#!/usr/bin/env python3
"""
Voice Handler for Pterodactyl Discord Bot
Supports voice commands and voice responses using P.R.I.S.M AI
"""

import discord
from discord.ext import commands
import asyncio
import os
import anthropic
import io
import wave
import tempfile
from pathlib import Path

# Try to import speech recognition libraries
try:
    import speech_recognition as sr
    SPEECH_RECOGNITION_AVAILABLE = True
except ImportError:
    SPEECH_RECOGNITION_AVAILABLE = False
    print("⚠️  speech_recognition not installed. Voice commands disabled.")

try:
    from gtts import gTTS
    TTS_AVAILABLE = True
except ImportError:
    TTS_AVAILABLE = False
    print("⚠️  gTTS not installed. Voice responses disabled.")

try:
    import pydub
    from pydub import AudioSegment
    AUDIO_PROCESSING_AVAILABLE = True
except ImportError:
    AUDIO_PROCESSING_AVAILABLE = False
    print("⚠️  pydub not installed. Audio processing limited.")

class VoiceHandler:
    """Handle voice commands and responses"""
    
    def __init__(self, bot, prism_client=None):
        self.bot = bot
        self.prism_client = prism_client
        self.recognizer = sr.Recognizer() if SPEECH_RECOGNITION_AVAILABLE else None
        self.voice_clients = {}
        self.listening_channels = set()
        self.always_listening = {}  # guild_id: True/False
        self.status_messages = {}  # guild_id: status_message
        self.wake_words = ['hey prism', 'ok prism', 'prism', 'hey bot']
        self.greetings = {}  # guild_id: custom_greeting
        self.default_greeting = "Hello! I'm ready to help with your servers."
        
    async def join_voice(self, ctx):
        """Join user's voice channel"""
        if not ctx.author.voice:
            await ctx.send("❌ You need to be in a voice channel!")
            return None
        
        channel = ctx.author.voice.channel
        
        # Leave current channel if in one
        if ctx.guild.id in self.voice_clients:
            await self.voice_clients[ctx.guild.id].disconnect()
        
        # Join new channel
        voice_client = await channel.connect()
        self.voice_clients[ctx.guild.id] = voice_client
        
        return voice_client
    
    async def leave_voice(self, ctx):
        """Leave voice channel"""
        if ctx.guild.id in self.voice_clients:
            await self.voice_clients[ctx.guild.id].disconnect()
            del self.voice_clients[ctx.guild.id]
            return True
        return False
    
    async def listen_for_commands(self, ctx, duration=5, silent=False):
        """Listen for voice commands"""
        if not SPEECH_RECOGNITION_AVAILABLE:
            if not silent:
                await ctx.send("❌ Voice recognition not available")
            return None
        
        voice_client = self.voice_clients.get(ctx.guild.id)
        if not voice_client:
            if not silent:
                await ctx.send("❌ Not in a voice channel")
            return None
        
        if not silent:
            await ctx.send(f"🎤 Listening for {duration} seconds...")
        
        # Record audio
        audio_file = await self.record_audio(voice_client, duration)
        
        if not audio_file:
            if not silent:
                await ctx.send("❌ Failed to record audio")
            return None
        
        # Convert to text
        try:
            with sr.AudioFile(audio_file) as source:
                audio = self.recognizer.record(source)
                text = self.recognizer.recognize_google(audio)
                
            os.unlink(audio_file)
            return text
            
        except sr.UnknownValueError:
            await ctx.send("❌ Could not understand audio")
            return None
        except sr.RequestError as e:
            await ctx.send(f"❌ Speech recognition error: {e}")
            return None
    
    async def record_audio(self, voice_client, duration):
        """Record audio from voice channel using discord sinks"""
        try:
            # Check if discord has sinks module
            if not hasattr(discord, 'sinks'):
                print("❌ discord.sinks not available - need discord.py 2.0+")
                return None
            
            # Create a temporary file
            temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.wav', mode='wb')
            temp_filename = temp_file.name
            temp_file.close()
            
            # Create sink for recording
            sink = discord.sinks.WaveSink()
            
            # Callback when recording finishes
            recorded_users = []
            
            def finished_callback(sink, channel, *args):
                recorded_users.extend(sink.audio_data.keys())
            
            # Start recording
            voice_client.start_recording(sink, finished_callback, channel=voice_client.channel)
            
            # Wait for duration
            await asyncio.sleep(duration)
            
            # Stop recording
            voice_client.stop_recording()
            
            # Wait a bit for callback to process
            await asyncio.sleep(0.5)
            
            # Get recorded audio from first user who spoke
            if sink.audio_data:
                for user_id, audio in sink.audio_data.items():
                    # Write audio data to file
                    audio.file.seek(0)
                    with open(temp_filename, 'wb') as f:
                        f.write(audio.file.read())
                    return temp_filename
            
            return None
            
        except AttributeError as e:
            print(f"❌ Voice recording not supported: {e}")
            print("💡 Install: pip install discord.py[voice]")
            return None
        except Exception as e:
            print(f"❌ Recording error: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    async def speak_response(self, ctx, text):
        """Convert text to speech and play in voice channel"""
        if not TTS_AVAILABLE:
            await ctx.send("❌ Text-to-speech not available")
            return False
        
        voice_client = self.voice_clients.get(ctx.guild.id)
        if not voice_client:
            await ctx.send("❌ Not in a voice channel")
            return False
        
        # Generate speech
        try:
            tts = gTTS(text=text, lang='en', slow=False)
            
            # Save to temporary file
            with tempfile.NamedTemporaryFile(delete=False, suffix='.mp3') as fp:
                tts.save(fp.name)
                audio_file = fp.name
            
            # Play audio
            if voice_client.is_playing():
                voice_client.stop()
            
            voice_client.play(
                discord.FFmpegPCMAudio(audio_file),
                after=lambda e: os.unlink(audio_file) if not e else None
            )
            
            return True
            
        except Exception as e:
            await ctx.send(f"❌ TTS error: {e}")
            return False
    
    async def start_continuous_listening(self, ctx):
        """Start always-on listening mode with wake word detection"""
        guild_id = ctx.guild.id
        
        if guild_id in self.always_listening and self.always_listening[guild_id]:
            await ctx.send("⚠️ Already listening continuously!")
            return
        
        voice_client = self.voice_clients.get(guild_id)
        if not voice_client:
            await ctx.send("❌ Not in a voice channel! Use `!join` first.")
            return
        
        self.always_listening[guild_id] = True
        
        # Send persistent status message (won't auto-delete)
        status_msg = await ctx.send(
            "👂 **Always-On Listening: ACTIVE** 🟢\n\n"
            "**Wake words:** `Hey PRISM` • `OK PRISM` • `PRISM`\n"
            "**Status:** Listening...\n\n"
            "Use `!stoplisten` to disable.",
            delete_after=None  # Don't auto-delete this message
        )
        
        # Store status message
        self.status_messages[guild_id] = status_msg
        
        # Start continuous listening loop
        asyncio.create_task(self._continuous_listen_loop(ctx, status_msg))
    
    async def stop_continuous_listening(self, ctx):
        """Stop always-on listening mode"""
        guild_id = ctx.guild.id
        self.always_listening[guild_id] = False
        
        # Delete the status message
        if guild_id in self.status_messages:
            try:
                await self.status_messages[guild_id].delete()
                del self.status_messages[guild_id]
            except:
                pass  # Message might already be deleted
        
        await ctx.send("🔇 Always-on listening disabled")
    
    async def _continuous_listen_loop(self, ctx):
        """Background loop for continuous listening"""
        guild_id = ctx.guild.id
        
        while self.always_listening.get(guild_id, False):
            try:
                # Listen for 3 seconds at a time (silent mode - no spam)
                command_text = await self.listen_for_commands(ctx, duration=3, silent=True)
                
                if command_text:
                    # Check if wake word was said
                    command_lower = command_text.lower()
                    wake_word_detected = any(wake in command_lower for wake in self.wake_words)
                    
                    if wake_word_detected:
                        # Remove wake word from command
                        for wake in self.wake_words:
                            command_lower = command_lower.replace(wake, '').strip()
                        
                        if command_lower:  # If there's a command after wake word
                            await ctx.send(f"🎤 **You said:** *{command_lower}*")
                            await self.process_voice_command(ctx, command_lower)
                        else:
                            # Just wake word, ask what they need
                            await self.speak_response(ctx, "Yes? What's your question?")
                            await ctx.send("🎤 **PRISM:** What's your question?")
                            command_text = await self.listen_for_commands(ctx, duration=8, silent=False)
                            if command_text:
                                await ctx.send(f"🎤 **You asked:** *{command_text}*")
                                await self.process_voice_command(ctx, command_text)
                            else:
                                await self.speak_response(ctx, "I didn't hear anything. Say my name again when you're ready.")
                
                # Small delay before next listen cycle
                await asyncio.sleep(0.5)
                
            except Exception as e:
                print(f"Continuous listening error: {e}")
                await asyncio.sleep(1)
    
    async def process_voice_command(self, ctx, command_text):
        """Process voice command with P.R.I.S.M AI"""
        import subprocess
        
        # Try local chatbot first
        try:
            result = subprocess.run(
                ['chatbot', 'ask', command_text],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0 and result.stdout:
                ai_response = result.stdout.strip()
                
                # Send text response
                await ctx.send(f"🤖 **PRISM:** {ai_response}")
                
                # Speak response
                await self.speak_response(ctx, ai_response)
                
                return ai_response
        except Exception as e:
            print(f"Local chatbot error: {e}")
        
        # Fallback to Anthropic API
        if not self.prism_client:
            error_msg = "I'm not configured yet. Please set up the chatbot or Anthropic API."
            await ctx.send(f"❌ {error_msg}")
            await self.speak_response(ctx, error_msg)
            return None
        
        # Get AI response from Anthropic
        try:
            response = self.prism_client.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=500,
                messages=[{
                    "role": "user",
                    "content": f"""You are P.R.I.S.M, a voice assistant for Pterodactyl server management.

User said (via voice): {command_text}

Respond naturally as if speaking. Keep it concise (1-2 sentences) since this will be spoken aloud.
If they're asking to perform an action, tell them what you're doing."""
                }]
            )
            
            ai_response = response.content[0].text
            
            # Send text response
            await ctx.send(f"🤖 **PRISM:** {ai_response}")
            
            # Speak response
            await self.speak_response(ctx, ai_response)
            
            return ai_response
            
        except Exception as e:
            error_msg = f"Sorry, I encountered an error: {str(e)}"
            await ctx.send(f"❌ {error_msg}")
            await self.speak_response(ctx, error_msg)
            return None

def setup_voice_commands(bot, prism_client=None):
    """Add voice commands to bot"""
    
    voice_handler = VoiceHandler(bot, prism_client)
    
    @bot.command(name='join', help='Join your voice channel')
    async def join_voice(ctx):
        """Join voice channel"""
        voice_client = await voice_handler.join_voice(ctx)
        if voice_client:
            await ctx.send(f"✅ Joined {ctx.author.voice.channel.name}")
            # Use custom greeting if set, otherwise default
            greeting = voice_handler.greetings.get(ctx.guild.id, voice_handler.default_greeting)
            await voice_handler.speak_response(ctx, greeting)
    
    @bot.command(name='leave', help='Leave voice channel')
    async def leave_voice(ctx):
        """Leave voice channel"""
        if await voice_handler.leave_voice(ctx):
            await ctx.send("👋 Left voice channel")
        else:
            await ctx.send("❌ Not in a voice channel")
    
    @bot.command(name='setgreeting', help='Set custom voice join greeting')
    async def set_greeting(ctx, *, greeting: str = None):
        """Set custom greeting when bot joins voice"""
        if greeting is None:
            # Show current greeting
            current = voice_handler.greetings.get(ctx.guild.id, voice_handler.default_greeting)
            await ctx.send(f"**Current greeting:**\n{current}\n\n**Usage:** `!setgreeting <your message>`\n**Example:** `!setgreeting Welcome! Ready to manage your game servers!`\n**Reset:** `!setgreeting reset`")
            return
        
        if greeting.lower() == 'reset':
            # Reset to default
            if ctx.guild.id in voice_handler.greetings:
                del voice_handler.greetings[ctx.guild.id]
            await ctx.send(f"✅ Greeting reset to default:\n*{voice_handler.default_greeting}*")
        else:
            # Set custom greeting
            voice_handler.greetings[ctx.guild.id] = greeting
            await ctx.send(f"✅ Custom greeting set!\n\n**Preview:**")
            await voice_handler.speak_response(ctx, greeting)
    
    @bot.command(name='listen', help='Listen for voice command once')
    async def listen(ctx, duration: int = 5):
        """Listen for voice command"""
        if duration > 30:
            await ctx.send("❌ Maximum duration is 30 seconds")
            return
        
        command_text = await voice_handler.listen_for_commands(ctx, duration)
        
        if command_text:
            await voice_handler.process_voice_command(ctx, command_text)
    
    @bot.command(name='startlisten', help='Enable always-on listening (Coming Soon)')
    async def start_listen(ctx):
        """Start continuous listening mode"""
        await ctx.send("⚠️ **Voice recording coming soon!**\n\n**What works now:**\n✅ Type `!ask <question>` - Bot speaks answer\n✅ `!say <text>` - Bot speaks text\n✅ All server commands work\n\n**Example:**\n`!ask what servers are online?`\nBot will answer AND speak it!")
    
    @bot.command(name='stoplisten', help='Disable always-on listening')
    async def stop_listen(ctx):
        """Stop continuous listening mode"""
        await ctx.send("ℹ️ Voice listening is not currently active")
    
    @bot.command(name='say', help='Make bot speak text')
    async def say(ctx, *, text: str):
        """Make bot speak"""
        await voice_handler.speak_response(ctx, text)
    
    @bot.command(name='prism', help='Ask PRISM anything (general questions, with voice)')
    async def prism_general(ctx, *, question: str):
        """Ask P.R.I.S.M general questions - no server data, just AI chat"""
        import subprocess
        
        async with ctx.typing():
            # Call chatbot without server data
            try:
                print(f"📤 PRISM general question: {question[:100]}...")
                result = subprocess.run(
                    ['chatbot', 'ask', question],
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                
                if result.returncode == 0 and result.stdout:
                    answer = result.stdout.strip()
                    
                    # Remove "Asking AI..." prefix if present
                    if answer.startswith("Asking AI..."):
                        answer = answer.replace("Asking AI...", "").strip()
                    
                    if answer and answer != 'null' and len(answer) > 0:
                        # Send text
                        embed = discord.Embed(
                            title='🤖 P.R.I.S.M',
                            description=answer,
                            color=discord.Color.blue()
                        )
                        await ctx.send(embed=embed)
                        
                        # Speak answer if in voice
                        await voice_handler.speak_response(ctx, answer)
                        return
                        
            except Exception as e:
                print(f"❌ PRISM error: {e}")
            
            await ctx.send("❌ P.R.I.S.M is not responding. Try again later.")
    
    @bot.command(name='voiceask', help='Type question, PRISM speaks answer (RECOMMENDED)')
    async def voice_ask(ctx, *, question: str):
        """Ask P.R.I.S.M and get voice response - includes real server data"""
        import subprocess
        import json
        from bot import PterodactylAPI
        
        async with ctx.typing():
            # Get actual server data first
            servers_data = []
            try:
                servers = await PterodactylAPI.get_servers()
                for server in servers[:5]:  # Limit to 5 servers
                    attrs = server['attributes']
                    server_id = attrs['identifier']
                    status = await PterodactylAPI.get_server_status(server_id)
                    if status:
                        state = status['attributes']['current_state']
                        resources = status['attributes']['resources']
                        servers_data.append({
                            'name': attrs['name'],
                            'id': server_id,
                            'status': state,
                            'cpu': f"{resources.get('cpu_absolute', 0):.1f}%",
                            'memory': f"{resources.get('memory_bytes', 0) / (1024**3):.2f}GB"
                        })
            except Exception as e:
                print(f"Error getting server data: {e}")
            
            # Build enhanced question with context
            enhanced_question = question
            if servers_data:
                # Create a simple text summary
                server_summary = []
                for s in servers_data:
                    server_summary.append(f"{s['name']}: {s['status']} (CPU: {s['cpu']}, RAM: {s['memory']})")
                server_text = "; ".join(server_summary)
                enhanced_question = f"Here is my current Pterodactyl server data: {server_text}. Based on this data, answer: {question}"
            
            # Try local chatbot with enhanced question
            try:
                print(f"📤 Sending to chatbot: {enhanced_question[:100]}...")
                result = subprocess.run(
                    ['chatbot', 'ask', enhanced_question],
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                
                print(f"📥 Chatbot return code: {result.returncode}")
                print(f"📥 Chatbot stdout: {result.stdout[:200] if result.stdout else 'None'}")
                print(f"📥 Chatbot stderr: {result.stderr[:200] if result.stderr else 'None'}")
                
                if result.returncode == 0 and result.stdout:
                    answer = result.stdout.strip()
                    
                    # Remove "Asking AI..." prefix if present
                    if answer.startswith("Asking AI..."):
                        answer = answer.replace("Asking AI...", "").strip()
                    
                    # Check if answer is valid
                    if answer and answer != 'null' and len(answer) > 0:
                        print(f"✅ Valid answer received: {len(answer)} chars")
                        # Send text
                        embed = discord.Embed(
                            title='🎤 P.R.I.S.M Voice Response',
                            description=answer,
                            color=discord.Color.purple()
                        )
                        await ctx.send(embed=embed)
                        
                        # Speak answer
                        await voice_handler.speak_response(ctx, answer)
                        return
                    else:
                        print(f"❌ Chatbot returned empty/null response: '{answer}'")
                    
            except Exception as e:
                print(f"❌ Local chatbot error: {e}")
                import traceback
                traceback.print_exc()
            
            # Fallback to Anthropic
            if not prism_client:
                await ctx.send("❌ P.R.I.S.M not configured. Run: `chatbot api setup`")
                return
            
            try:
                response = prism_client.messages.create(
                    model="claude-3-5-sonnet-20241022",
                    max_tokens=500,
                    messages=[{
                        "role": "user",
                        "content": f"""You are P.R.I.S.M, a voice assistant for Pterodactyl server management.

Question: {question}

Respond naturally as if speaking. Keep it concise since this will be spoken aloud."""
                    }]
                )
                
                answer = response.content[0].text
                
                # Send text
                embed = discord.Embed(
                    title='🎤 P.R.I.S.M Voice Response',
                    description=answer,
                    color=discord.Color.purple()
                )
                await ctx.send(embed=embed)
                
                # Speak answer
                await voice_handler.speak_response(ctx, answer)
                
            except Exception as e:
                await ctx.send(f"❌ Error: {e}")
    
    return voice_handler
