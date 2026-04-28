# Ollama + Open WebUI + Cloudflared - Automated Setup

Complete automated installation script for running your own AI chatbot with GPU acceleration and secure cloud access.

## 🚀 What This Does

This script automatically installs and configures:

- **Ollama** - AI model server with GPU support
- **Open WebUI** - Beautiful web interface (like ChatGPT)
- **Cloudflared** - Secure tunnel for external access
- **Auto-configuration** - Everything set up and ready to use

## ✨ Features

✅ **One-command installation** - Just run the script  
✅ **GPU auto-detection** - Uses NVIDIA GPU if available  
✅ **Secure tunnels** - Access from anywhere via HTTPS  
✅ **Model selection** - Choose from recommended models  
✅ **Auto-start services** - Runs on boot automatically  
✅ **Comprehensive logging** - Track installation progress  
✅ **Error handling** - Validates each step  

## 📋 Prerequisites

- Ubuntu/Debian Linux server
- Sudo access
- Cloudflare account (free)
- Domain name (managed by Cloudflare)
- Optional: NVIDIA GPU for faster inference

## 🎯 Quick Start

### 1. Download the Script

```bash
wget https://your-server/ollama-webui-setup.sh
# Or copy from your local machine
```

### 2. Make it Executable

```bash
chmod +x ollama-webui-setup.sh
```

### 3. Run the Script

```bash
./ollama-webui-setup.sh
```

### 4. Follow the Prompts

The script will ask you for:
- Your domain name (e.g., `cloudmc.online`)
- Subdomain for Ollama API (default: `chat`)
- Subdomain for Open WebUI (default: `ui`)
- Port for local access (default: `3000`)
- Which model to install

### 5. Authenticate with Cloudflare

When prompted, a browser will open for Cloudflare authentication. Log in and authorize the tunnel.

### 6. Done!

Access your AI chatbot at:
- **https://ui.yourdomain.com** (or your chosen subdomain)
- Create your admin account (first user)
- Start chatting!

## 🎨 What You'll Get

After installation:

```
Access Points:
  🌐 Ollama API:     https://chat.yourdomain.com
  🌐 Open WebUI:     https://ui.yourdomain.com
  🏠 Local WebUI:    http://your-server-ip:3000
  🏠 Local API:      http://localhost:11434
```

## 🤖 Recommended Models

The script will recommend models based on your hardware:

### With GPU (NVIDIA):
- **qwen2.5:7b** (4.7GB) - Fast & intelligent, great for problem-solving
- **gemma2:9b** (5.4GB) - High quality responses
- **deepseek-coder:6.7b** (3.8GB) - Excellent for coding
- **llama3.2:3b** (2GB) - Small & fast

### CPU Only:
- **qwen2.5:3b** (2GB) - Best balance for CPU
- **llama3.2:3b** (2GB) - Fast on CPU
- **phi3:mini** (2.3GB) - Microsoft's efficient model

## 📝 Post-Installation

### Managing Models

```bash
# List installed models
ollama list

# Pull a new model
ollama pull mistral:7b

# Remove a model
ollama rm llama3.2:1b

# Test a model
ollama run qwen2.5:7b
```

### Managing Services

```bash
# Check Ollama status
sudo systemctl status ollama

# Restart Ollama
sudo systemctl restart ollama

# Check Cloudflared tunnel
sudo systemctl status cloudflared

# Restart Open WebUI
docker restart open-webui

# View WebUI logs
docker logs -f open-webui
```

### Configuration Files

- **Ollama service:** `/etc/systemd/system/ollama.service.d/override.conf`
- **Cloudflared config:** `~/.cloudflared/config.yml`
- **Setup log:** `/tmp/ollama-setup-YYYYMMDD-HHMMSS.log`

## 🔧 Troubleshooting

### Models Don't Appear in WebUI

```bash
# Restart Open WebUI
docker restart open-webui

# Hard refresh browser
# Press Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)

# Check connection in WebUI
# Settings → Admin Settings → Connections
```

### Tunnel Not Working

```bash
# Check Cloudflared status
sudo systemctl status cloudflared

# Restart Cloudflared
sudo systemctl restart cloudflared

# Check DNS (may take a few minutes to propagate)
nslookup chat.yourdomain.com

# Verify in Cloudflare dashboard
# Zero Trust → Networks → Tunnels
```

### GPU Not Detected

```bash
# Check if NVIDIA drivers are installed
nvidia-smi

# Check Ollama logs
sudo journalctl -u ollama -n 50

# Verify GPU is being used
# Look for "offloaded X/X layers to GPU" in logs
```

### Open WebUI Won't Start

```bash
# Check Docker logs
docker logs open-webui

# Verify port is available
sudo netstat -tulpn | grep 3000

# Restart container
docker restart open-webui
```

## 🎓 Usage Tips

### Enable User Registration

1. Log into Open WebUI as admin
2. Go to **Settings** → **Admin Settings** → **General**
3. Enable **"Allow User Registration"**
4. Users can now create accounts at the login page

### Add Multiple Models

You can have multiple models installed:

```bash
ollama pull qwen2.5:7b
ollama pull gemma2:9b
ollama pull deepseek-coder:6.7b
```

Switch between them in the Open WebUI dropdown!

### Optimize for Your GPU

For RTX 3060 (12GB VRAM):
- Can run 1x 7-9B model comfortably
- Or multiple smaller models (1-3B)
- Larger models (13B+) may need quantization

### API Access

Use the Ollama API programmatically:

```bash
# Generate text
curl https://chat.yourdomain.com/api/generate -d '{
  "model": "qwen2.5:7b",
  "prompt": "Explain quantum computing"
}'

# List models
curl https://chat.yourdomain.com/api/tags
```

## 🔐 Security Notes

- First user becomes admin automatically
- Enable user registration only if needed
- Cloudflared provides encrypted tunnels (HTTPS)
- Open WebUI has built-in authentication
- Consider setting up firewall rules for local ports

## 📊 System Requirements

### Minimum:
- 2 CPU cores
- 8GB RAM
- 20GB disk space
- Ubuntu 20.04+ or Debian 11+

### Recommended:
- 4+ CPU cores
- 16GB+ RAM
- NVIDIA GPU with 8GB+ VRAM
- 50GB+ disk space (for models)
- Fast internet connection

## 🆘 Support

If you encounter issues:

1. Check the setup log: `/tmp/ollama-setup-*.log`
2. Review service status: `sudo systemctl status ollama cloudflared`
3. Check Docker logs: `docker logs open-webui`
4. Verify Cloudflare tunnel in dashboard

## 📚 Additional Resources

- [Ollama Documentation](https://github.com/ollama/ollama)
- [Open WebUI Documentation](https://github.com/open-webui/open-webui)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Model Library](https://ollama.com/library)

## 🎉 What's Next?

After setup:

1. **Explore models** - Try different AI models for various tasks
2. **Customize settings** - Configure Open WebUI to your liking
3. **Share access** - Enable registration for friends/team
4. **Integrate** - Use the API in your applications
5. **Monitor** - Keep an eye on GPU usage and performance

Enjoy your personal AI assistant! 🚀
