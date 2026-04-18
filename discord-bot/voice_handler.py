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
        # This is a simplified version - actual implementation would need
        # to capture audio from Discord voice channel
        # For now, we'll use a placeholder
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
    
    @bot.command(name='listen', help='Listen for voice command')
    async def listen(ctx, duration: int = 5):
        """Listen for voice command"""
        if duration > 30:
            await ctx.send("❌ Maximum duration is 30 seconds")
            return
        
        command_text = await voice_handler.listen_for_commands(ctx, duration)
        
        if command_text:
            await voice_handler.process_voice_command(ctx, command_text)
    
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
