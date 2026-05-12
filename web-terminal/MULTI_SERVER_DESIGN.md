# Enhanced SSH Terminal - Multi-Server Architecture

## 🎯 Core Concept
Each terminal tab connects to a different server. The entire interface adapts to show which server you're working on.

## 🏗️ Architecture

### Layout with Multi-Server Support
```
┌─────────────────────────────────────────────────────────────────────┐
│ 🖥️ Enhanced SSH Terminal    [Server: 🔴 Production ▼]  [⚙️][🎨]    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│ ┌──────────┐  ┌────────────────────────────────────────────────┐  │
│ │ Servers  │  │ Terminal Tabs                                   │  │
│ │ Panel    │  │ ┌──────────────────────────────────────────┐   │  │
│ │          │  │ │[🔴Prod][🟡Stage][🟢Dev][+] [-][+][⚙️][×] │   │  │
│ │ 🔴 Prod  │  │ ├──────────────────────────────────────────┤   │  │
│ │ 🟡 Stage │  │ │ root@production:~$ systemctl status nginx│   │  │
│ │ 🟢 Dev   │  │ │ ● nginx.service - A high performance...  │   │  │
│ │ 🔵 Test  │  │ │                                          │   │  │
│ │          │  │ │ 👻 AI: sudo systemctl restart nginx     │   │  │
│ │ [+ Add]  │  │ │    [Press Enter to run]                 │   │  │
│ │          │  │ └──────────────────────────────────────────┘   │  │
│ │ History  │  │                                                 │  │
│ │ ┌──────┐ │  │ [Drop files to upload to Production]           │  │
│ │ │🔍    │ │  └─────────────────────────────────────────────────┘  │
│ │ └──────┘ │                                                        │
│ │          │                                                        │
│ │ Commands │                    ┌──────────────────────────────┐   │
│ │ ├ ls -la │                    │ 🤖 AI Assistant         [_][×]│   │
│ │ ├ df -h  │                    ├──────────────────────────────┤   │
│ │ └ htop   │                    │ Context: Production Server   │   │
│ │          │                    │                              │   │
│ │ ⭐Favs   │                    │ User: Check nginx status     │   │
│ │ ├ deploy │                    │ AI: Running on Production... │   │
│ │ └ backup │                    ├──────────────────────────────┤   │
│ └──────────┘                    │ [Ask about this server...]   │   │
│                                  └──────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

## 🔑 Key Changes for Multi-Server

### 1. Server-Aware Tabs
Each tab knows which server it's connected to:
```javascript
{
  tabId: "tab-1",
  serverId: "prod-main",
  serverName: "Production",
  serverColor: "#EF4444",
  serverIcon: "🔴",
  iframeUrl: "https://panel.cloudmc.online:7681",
  active: true
}
```

### 2. Server Panel (Left Side)
Replaces simple history panel with:
- **Server List** - All configured servers
- **Quick Connect** - Click to open new tab
- **Server Status** - Online/Offline indicator
- **Command History** - Filtered by server
- **Favorites** - Per-server favorites

### 3. Context-Aware AI
AI knows which server you're on:
```
User: "Check disk space"
AI: "Running on Production Server..."
AI: "df -h shows 85% usage on /dev/sda1"
```

### 4. Server Dropdown in Toolbar
Quick server switcher:
- Shows current active tab's server
- Click to switch to different server tab
- Or create new tab on selected server

## 📋 Server Configuration

### Server Preset Structure
```javascript
{
  "servers": [
    {
      "id": "prod-main",
      "name": "Production Server",
      "host": "panel.cloudmc.online",
      "port": 7681,
      "protocol": "https",
      "username": "root",
      "environment": "production",
      "color": "#EF4444",
      "icon": "🔴",
      "description": "Main production server",
      "tags": ["web", "database", "critical"],
      "sshKey": "~/.ssh/id_rsa_prod",
      "customCommands": [
        { "name": "Deploy", "command": "./deploy.sh" },
        { "name": "Backup", "command": "./backup.sh" }
      ]
    },
    {
      "id": "staging",
      "name": "Staging Server",
      "host": "staging.cloudmc.online",
      "port": 7681,
      "protocol": "https",
      "username": "root",
      "environment": "staging",
      "color": "#F59E0B",
      "icon": "🟡",
      "description": "Staging environment for testing",
      "tags": ["testing", "qa"],
      "customCommands": [
        { "name": "Test Deploy", "command": "./test-deploy.sh" }
      ]
    },
    {
      "id": "dev-local",
      "name": "Development Server",
      "host": "192.168.1.100",
      "port": 7681,
      "protocol": "http",
      "username": "dev",
      "environment": "development",
      "color": "#10B981",
      "icon": "🟢",
      "description": "Local development machine",
      "tags": ["dev", "local"]
    }
  ]
}
```

### Server Manager Modal
```
┌──────────────────────────────────────────────────┐
│ ⚙️  Manage Servers                          [×]  │
├──────────────────────────────────────────────────┤
│                                                   │
│ [🔴 Production Server]                    [Edit] │
│ └─ panel.cloudmc.online:7681                     │
│                                                   │
│ [🟡 Staging Server]                       [Edit] │
│ └─ staging.cloudmc.online:7681                   │
│                                                   │
│ [🟢 Development Server]                   [Edit] │
│ └─ 192.168.1.100:7681                            │
│                                                   │
│ ─────────────────────────────────────────────    │
│                                                   │
│ [+ Add New Server]                                │
│                                                   │
├──────────────────────────────────────────────────┤
│                         [Import] [Export] [Save] │
└──────────────────────────────────────────────────┘
```

### Add/Edit Server Form
```
┌──────────────────────────────────────────────────┐
│ Add New Server                              [×]  │
├──────────────────────────────────────────────────┤
│                                                   │
│ Server Name: [Production Server____________]     │
│                                                   │
│ Host/IP:     [panel.cloudmc.online_________]     │
│                                                   │
│ Port:        [7681]  Protocol: [HTTPS ▼]         │
│                                                   │
│ Username:    [root_________________________]     │
│                                                   │
│ Environment: [Production ▼]                      │
│              Production / Staging / Dev / Test   │
│                                                   │
│ Color:       [🔴 Red ▼]                          │
│                                                   │
│ Icon:        [🔴▼] 🔴🟡🟢🔵⚪⚫🟣🟠              │
│                                                   │
│ Description: [Main production server______]      │
│                                                   │
│ Tags:        [web, database, critical_____]      │
│                                                   │
│ ─── Custom Commands ───                          │
│                                                   │
│ [+ Add Command]                                   │
│                                                   │
├──────────────────────────────────────────────────┤
│                              [Cancel] [Save]     │
└──────────────────────────────────────────────────┘
```

## 🎨 Visual Indicators

### Tab Colors
Each tab shows server environment:
```
[🔴 Production] [🟡 Staging] [🟢 Dev] [+]
```

### Terminal Header
Shows current server:
```
┌────────────────────────────────────────────────┐
│ 🔴 Production Server  [-][+][↺][⚙️][_][□][✕] │
├────────────────────────────────────────────────┤
```

### Status Bar (Optional)
Bottom status bar shows:
```
┌────────────────────────────────────────────────┐
│ 🔴 Production | root@panel.cloudmc.online | ●  │
└────────────────────────────────────────────────┘
```

## 🔄 Workflows

### Workflow 1: Quick Server Switch
1. Click server dropdown in toolbar
2. Select "Staging Server"
3. New tab opens with staging connection
4. Tab labeled 🟡 Staging
5. AI context switches to staging

### Workflow 2: Compare Across Servers
1. Open tab on Production (🔴)
2. Run `df -h` to check disk
3. Open tab on Staging (🟡)
4. Run same command
5. Compare results side-by-side

### Workflow 3: Deploy Pipeline
1. Test on Dev (🟢)
2. Deploy to Staging (🟡)
3. Verify on Staging
4. Deploy to Production (🔴)
5. All in separate tabs

### Workflow 4: Emergency Response
1. Alert on Production
2. Open Production tab
3. AI suggests diagnostic commands
4. Run commands with ghost typing
5. Fix issue
6. Verify on Staging

## 🔐 Security Features

### Per-Server Authentication
- Each server can have different auth
- SSH keys per server
- Password vault integration
- 2FA support

### Environment Protection
- **Production**: Confirmation prompts for dangerous commands
- **Staging**: Warning for destructive operations
- **Dev**: No restrictions

### Audit Log
- Track which user ran what command
- On which server
- At what time
- Command output

## 📊 Server Panel Features

### Server List
```
┌──────────────┐
│ Servers      │
├──────────────┤
│ 🔴 Prod   ●  │ ← Online
│ 🟡 Stage  ●  │
│ 🟢 Dev    ○  │ ← Offline
│ 🔵 Test   ●  │
│              │
│ [+ Add]      │
└──────────────┘
```

### Per-Server History
```
┌──────────────┐
│ History      │
│ [🔴 Prod ▼]  │ ← Filter by server
├──────────────┤
│ 🔍 Search    │
├──────────────┤
│ systemctl... │
│ docker ps    │
│ tail -f ...  │
└──────────────┘
```

### Per-Server Favorites
```
┌──────────────┐
│ Favorites    │
│ [🔴 Prod ▼]  │
├──────────────┤
│ ⭐ Deploy    │
│ ⭐ Backup    │
│ ⭐ Restart   │
│              │
│ [+ Add Fav]  │
└──────────────┘
```

## 🚀 Implementation Strategy

### Phase 1: Server Management
- Server configuration storage
- Add/Edit/Delete servers
- Import/Export presets
- Validation

### Phase 2: Multi-Tab System
- Tab component with server awareness
- Tab switching
- Server-specific styling
- Tab persistence

### Phase 3: Server Panel
- Server list UI
- Quick connect
- Status indicators
- Per-server history

### Phase 4: AI Integration
- Server context in AI requests
- Server-specific suggestions
- Environment-aware commands
- Safety checks

### Phase 5: File Transfer
- Per-server file upload
- Server-specific download
- Transfer between servers
- Progress tracking

## 💡 Advanced Features (Future)

### Server Groups
```
Production Group:
├─ Web Server 1
├─ Web Server 2
└─ Database Server

Development Group:
├─ Dev Box 1
└─ Dev Box 2
```

### Broadcast Commands
- Run command on multiple servers
- Show results in split view
- Parallel execution

### Server Monitoring
- CPU/RAM/Disk graphs
- Service status
- Alert notifications

### SSH Tunneling
- Port forwarding
- SOCKS proxy
- Jump hosts

This architecture properly handles multiple servers! Ready to implement?
