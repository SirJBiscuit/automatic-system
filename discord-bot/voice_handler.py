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
        self.wake_words = ['hey prism', 'ok prism', 'prism', 'hey bot']
        
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
    
    async def listen_for_commands(self, ctx, duration=5):
        """Listen for voice commands"""
        if not SPEECH_RECOGNITION_AVAILABLE:
            await ctx.send("❌ Voice recognition not available")
            return None
        
        voice_client = self.voice_clients.get(ctx.guild.id)
        if not voice_client:
            await ctx.send("❌ Not in a voice channel")
            return None
        
        await ctx.send(f"🎤 Listening for {duration} seconds...")
        
        # Record audio
        audio_file = await self.record_audio(voice_client, duration)
        
        if not audio_file:
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
        """Record audio from voice channel"""
        try:
            import discord.sinks
            
            # Create temporary file for recording
            temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.wav')
            temp_file.close()
            
            # Create a sink to record audio
            sink = discord.sinks.WaveSink()
            
            # Start recording
            voice_client.start_recording(
                sink,
                lambda sink, user: None,  # Callback when finished
                sync_start=True
            )
            
            # Wait for duration
            await asyncio.sleep(duration)
            
            # Stop recording
            voice_client.stop_recording()
            
            # Get the recorded audio
            if sink.audio_data:
                # Get first user's audio (or combine all users)
                for user_id, audio in sink.audio_data.items():
                    with open(temp_file.name, 'wb') as f:
                        f.write(audio.file.read())
                    return temp_file.name
            
            return None
            
        except Exception as e:
            print(f"Recording error: {e}")
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
        await ctx.send(f"👂 **Always-on listening activated!**\n\nSay one of these wake words:\n• `Hey PRISM`\n• `OK PRISM`\n• `PRISM`\n\nThen speak your command. Use `!stoplisten` to disable.")
        
        # Start continuous listening loop
        asyncio.create_task(self._continuous_listen_loop(ctx))
    
    async def stop_continuous_listening(self, ctx):
        """Stop always-on listening mode"""
        guild_id = ctx.guild.id
        self.always_listening[guild_id] = False
        await ctx.send("🔇 Always-on listening disabled")
    
    async def _continuous_listen_loop(self, ctx):
        """Background loop for continuous listening"""
        guild_id = ctx.guild.id
        
        while self.always_listening.get(guild_id, False):
            try:
                # Listen for 3 seconds at a time
                command_text = await self.listen_for_commands(ctx, duration=3)
                
                if command_text:
                    # Check if wake word was said
                    command_lower = command_text.lower()
                    wake_word_detected = any(wake in command_lower for wake in self.wake_words)
                    
                    if wake_word_detected:
                        # Remove wake word from command
                        for wake in self.wake_words:
                            command_lower = command_lower.replace(wake, '').strip()
                        
                        if command_lower:  # If there's a command after wake word
                            await ctx.send(f"🎤 Heard: *{command_lower}*")
                            await self.process_voice_command(ctx, command_lower)
                        else:
                            # Just wake word, listen for actual command
                            await self.speak_response(ctx, "Yes?")
                            command_text = await self.listen_for_commands(ctx, duration=5)
                            if command_text:
                                await self.process_voice_command(ctx, command_text)
                
                # Small delay before next listen cycle
                await asyncio.sleep(0.5)
                
            except Exception as e:
                print(f"Continuous listening error: {e}")
                await asyncio.sleep(1)
    
    async def process_voice_command(self, ctx, command_text):
        """Process voice command with P.R.I.S.M AI"""
        if not self.prism_client:
            await ctx.send("❌ P.R.I.S.M AI not configured")
            return None
        
        # Get AI response
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
            await ctx.send(f"🎤 You said: *{command_text}*\n🤖 P.R.I.S.M: {ai_response}")
            
            # Speak response
            await self.speak_response(ctx, ai_response)
            
            return ai_response
            
        except Exception as e:
            await ctx.send(f"❌ AI error: {e}")
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
            await voice_handler.speak_response(ctx, "Hello! I'm ready to help with your servers.")
    
    @bot.command(name='leave', help='Leave voice channel')
    async def leave_voice(ctx):
        """Leave voice channel"""
        if await voice_handler.leave_voice(ctx):
            await ctx.send("👋 Left voice channel")
        else:
            await ctx.send("❌ Not in a voice channel")
    
    @bot.command(name='listen', help='Listen for voice command once')
    async def listen(ctx, duration: int = 5):
        """Listen for voice command"""
        if duration > 30:
            await ctx.send("❌ Maximum duration is 30 seconds")
            return
        
        command_text = await voice_handler.listen_for_commands(ctx, duration)
        
        if command_text:
            await voice_handler.process_voice_command(ctx, command_text)
    
    @bot.command(name='startlisten', help='Enable always-on listening with wake words')
    async def start_listen(ctx):
        """Start continuous listening mode"""
        await voice_handler.start_continuous_listening(ctx)
    
    @bot.command(name='stoplisten', help='Disable always-on listening')
    async def stop_listen(ctx):
        """Stop continuous listening mode"""
        await voice_handler.stop_continuous_listening(ctx)
    
    @bot.command(name='say', help='Make bot speak text')
    async def say(ctx, *, text: str):
        """Make bot speak"""
        await voice_handler.speak_response(ctx, text)
    
    @bot.command(name='voiceask', help='Ask P.R.I.S.M with voice response')
    async def voice_ask(ctx, *, question: str):
        """Ask P.R.I.S.M and get voice response"""
        if not prism_client:
            await ctx.send("❌ P.R.I.S.M AI not configured")
            return
        
        async with ctx.typing():
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
