# Web Console - Pterodactyl Console Sync Fix

## Problem
The web-console's server consoles were not syncing with Pterodactyl in real-time. Console output was not displaying, and commands sent through the web interface weren't showing responses.

## Solution
Implemented WebSocket-based console streaming that connects directly to Pterodactyl's WebSocket API for real-time console output and command execution.

## What Was Fixed

### Backend (`app.py`)
1. **Added WebSocket client support** - Imports `websocket` and `threading` modules
2. **Console connection tracking** - `active_console_connections` dictionary to manage active streams
3. **New WebSocket handlers:**
   - `subscribe_console` - Connects to Pterodactyl's WebSocket for a specific server
   - `send_console_command` - Sends commands through WebSocket (with REST API fallback)
   - `disconnect` - Cleans up WebSocket connections when clients disconnect
4. **Console streaming function** - `connect_to_pterodactyl_console()` handles:
   - Authentication with Pterodactyl's WebSocket
   - Forwarding console output to web clients
   - Forwarding server status and stats updates
   - Error handling and reconnection

### Frontend (`dashboard.html`)
1. **Console subscription** - Opens WebSocket connection when server modal is opened
2. **Real-time output display** - Listens for `console_output` events and displays them
3. **Command sending** - Uses WebSocket instead of REST API for instant feedback
4. **Status updates** - Receives real-time server status and resource stats
5. **Error handling** - Displays connection errors and disconnection notices

### Dependencies (`requirements.txt`)
- Added `websocket-client>=1.6.0` for WebSocket connectivity

## How It Works

```
┌─────────────┐         ┌──────────────┐         ┌─────────────────┐
│   Browser   │◄───────►│ Web Console  │◄───────►│   Pterodactyl   │
│  (Client)   │ Socket  │   (Flask)    │ WebSocket│     Panel       │
└─────────────┘  .IO    └──────────────┘         └─────────────────┘
      │                        │                          │
      │  1. Open Server Modal  │                          │
      ├───────────────────────►│                          │
      │                        │  2. Get WS Credentials   │
      │                        ├─────────────────────────►│
      │                        │◄─────────────────────────┤
      │                        │  3. Connect to WS        │
      │                        ├─────────────────────────►│
      │  4. Console Output     │  5. Forward Output       │
      │◄───────────────────────┤◄─────────────────────────┤
      │  6. Send Command       │                          │
      ├───────────────────────►│  7. Forward Command      │
      │                        ├─────────────────────────►│
      │  8. Command Response   │  9. Forward Response     │
      │◄───────────────────────┤◄─────────────────────────┤
```

## Installation

### On Your Server (via SSH)

1. **Update the web-console files:**
   ```bash
   cd /path/to/web-console
   
   # Backup current files
   cp app.py app.py.backup
   cp templates/dashboard.html templates/dashboard.html.backup
   
   # Upload the new files (use scp, git pull, or manual copy)
   ```

2. **Install the new dependency:**
   ```bash
   pip3 install websocket-client
   # Or install all requirements:
   pip3 install -r requirements.txt
   ```

3. **Restart the web-console service:**
   ```bash
   # If running as systemd service:
   sudo systemctl restart ptero-webconsole
   
   # If running manually:
   pkill -f "python.*app.py"
   python3 app.py
   ```

4. **Test the console:**
   - Open the web console in your browser
   - Click on a server to open the console modal
   - You should see "✓ Connected to console"
   - Console output should appear in real-time
   - Commands should execute and show responses immediately

## Features Now Working

✅ **Real-time console output** - See server logs as they happen
✅ **Instant command execution** - Commands execute immediately with visible feedback
✅ **Live server stats** - CPU, RAM updates in real-time
✅ **Status synchronization** - Server status (running/stopped) updates automatically
✅ **Multiple server support** - Can switch between servers without issues
✅ **Automatic reconnection** - Handles connection drops gracefully
✅ **Fallback support** - Uses REST API if WebSocket fails

## Troubleshooting

### Console Not Connecting

**Check WebSocket credentials:**
```bash
# Test API access
curl -H "Authorization: Bearer YOUR_API_KEY" \
     https://your-panel.com/api/client/servers/SERVER_ID/websocket
```

**Check logs:**
```bash
# View web-console logs
journalctl -u ptero-webconsole -f
# Or if running manually, check terminal output
```

**Common issues:**
- **Invalid API key** - Ensure `PTERODACTYL_API_KEY` is set correctly
- **Firewall blocking WebSocket** - Pterodactyl Wings uses port 8080 by default
- **SSL certificate issues** - WebSocket URL must match panel URL scheme (http/https)

### Console Output Not Appearing

1. **Check browser console (F12):**
   - Look for WebSocket connection errors
   - Check for JavaScript errors

2. **Verify Socket.IO connection:**
   ```javascript
   // In browser console:
   socket.connected  // Should return true
   ```

3. **Test with REST API fallback:**
   - If WebSocket fails, commands should still work via REST API
   - Check if you see "> command" in console after sending

### Commands Not Working

1. **Check server status:**
   - Server must be running to accept commands
   - Verify in Pterodactyl panel that server is online

2. **Check API permissions:**
   - API key must have permission to send commands
   - Test with Pterodactyl's built-in console first

3. **Check command syntax:**
   - Some game servers require specific command formats
   - Try simple commands like "help" or "list" first

## Configuration

The console sync uses these environment variables:

```bash
# .env file
PTERODACTYL_URL=https://panel.yourdomain.com
PTERODACTYL_API_KEY=ptlc_your_api_key_here
```

**Important:**
- Use a **Client API Key**, not an Application API Key
- The API key must have access to the servers you want to manage
- WebSocket URL is automatically derived from the API response

## Performance Notes

- Each open console creates one WebSocket connection
- Connections are automatically cleaned up when modal is closed
- Multiple users can connect to the same server simultaneously
- Console output is buffered and sent in real-time (no polling)

## Security Considerations

✅ **Authentication required** - Must be logged into web-console
✅ **Session-based** - WebSocket connections tied to user sessions
✅ **Token-based auth** - Uses Pterodactyl's WebSocket tokens
✅ **Automatic cleanup** - Connections closed on disconnect
✅ **No credential exposure** - API keys never sent to browser

## Testing Checklist

After installation, verify:

- [ ] Web console loads without errors
- [ ] Can open server modal
- [ ] Console shows "✓ Connected to console"
- [ ] See real-time console output
- [ ] Can send commands and see responses
- [ ] Server stats update in real-time
- [ ] Status changes reflect immediately
- [ ] Can switch between servers
- [ ] Console clears when switching servers
- [ ] No errors in browser console (F12)
- [ ] No errors in server logs

## Rollback

If you need to revert to the previous version:

```bash
cd /path/to/web-console
cp app.py.backup app.py
cp templates/dashboard.html.backup templates/dashboard.html
sudo systemctl restart ptero-webconsole
```

## Future Enhancements

Potential improvements:
- Console history persistence
- Console search/filter functionality
- Multiple console tabs
- Console color coding/syntax highlighting
- Command history (up/down arrows)
- Auto-completion for common commands
- Console export/download

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review server logs for errors
3. Test with Pterodactyl's native console first
4. Verify API key permissions
5. Check firewall/network settings

---
**Version:** 1.0.0  
**Last Updated:** 2026-05-11  
**Compatibility:** Pterodactyl Panel v1.x, Wings v1.x
