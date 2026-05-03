# 💻 SSH Web Terminal

Beautiful web-based SSH terminal with AI assistant integration.

## Features

- 🖥️ **Full Terminal Access** - Real PTY-based terminal in your browser
- 🎨 **Beautiful UI** - Modern, customizable interface
- 🤖 **AI Assistant** - Integrated AI helper (Open WebUI ready)
- ⚡ **Quick Commands** - One-click common commands
- 🌐 **Remote Access** - Access from anywhere via ssh.cloudmc.online
- 🔒 **Secure** - Session-based authentication
- 📱 **Responsive** - Works on mobile devices
- 🎨 **Customizable** - Shares settings with admin panel

## Installation

```bash
cd /path/to/ssh-terminal
chmod +x install.sh
sudo ./install.sh
```

## Configuration

### Cloudflare Tunnel Setup

Add to your Cloudflare Tunnel config:

```yaml
ingress:
  - hostname: ssh.cloudmc.online
    service: http://localhost:5003
```

### AI Assistant Integration

To integrate with Open WebUI, update `app.py`:

```python
@app.route('/api/ai/chat', methods=['POST'])
@login_required
def ai_chat():
    # Add your Open WebUI API endpoint
    OPENWEBUI_URL = "http://localhost:8080/api/chat"
    # Implement API call
```

## Default Credentials

- **Username:** admin
- **Password:** admin123

⚠️ Change these immediately after first login!

## Usage

1. Access via `http://localhost:5003` or `https://ssh.cloudmc.online`
2. Login with credentials
3. Use the terminal like a regular SSH session
4. Ask the AI assistant for help
5. Use quick commands for common tasks

## Quick Commands

- 📁 `ls -la` - List files
- 💾 `df -h` - Disk usage
- 🧠 `free -h` - Memory usage
- 📊 `top` - Process monitor
- 🐳 `docker ps` - Docker containers
- ⚙️ `systemctl status` - Service status

## Customization

Customize colors, fonts, and themes via the "Customize" button. Settings are shared with the Unified Admin Panel.

## API Endpoints

- `POST /login` - Authenticate user
- `POST /logout` - End session
- `GET /api/customization/load` - Load theme
- `POST /api/customization/save` - Save theme
- `POST /api/ai/chat` - Chat with AI assistant

## WebSocket Events

- `connect` - Establish terminal session
- `disconnect` - Close terminal session
- `input` - Send input to terminal
- `output` - Receive terminal output
- `resize` - Resize terminal

## Technology Stack

- **Backend:** Python Flask + Flask-SocketIO
- **Frontend:** Xterm.js + Socket.IO
- **Terminal:** PTY (Pseudo-Terminal)
- **Styling:** Custom CSS with CSS variables

## Security Notes

- Runs as root (required for PTY)
- Session-based authentication
- Dangerous commands can be blocked
- HTTPS recommended for production
- Use strong passwords

## Troubleshooting

**Terminal not connecting:**
```bash
systemctl status ssh-terminal
journalctl -u ssh-terminal -f
```

**Permission issues:**
```bash
chmod +x /opt/ssh-terminal/app.py
chown -R root:root /opt/ssh-terminal
```

**Port already in use:**
```bash
lsof -i :5003
# Change port in app.py if needed
```

## Future Features

- ✅ AI command suggestions
- ✅ File upload/download
- ✅ Multiple terminal tabs
- ✅ Session recording/playback
- ✅ Collaborative sessions
- ✅ Command history search
- ✅ Syntax highlighting

## License

MIT License - Feel free to use and modify!
