# Enhanced SSH Terminal - Final Design

## 🎯 Complete Feature Set

### Layout Overview
```
┌─────────────────────────────────────────────────────────────────────┐
│ 🖥️ Enhanced SSH Terminal    [Update][Snippets][Settings][Themes]   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│ ┌──────────┐  ┌────────────────────────────────────────────────┐  │
│ │ History  │  │ Terminal Window (Draggable/Resizable)          │  │
│ │ Panel    │  │ ┌────────────────────────────────────────────┐ │  │
│ │          │  │ │ [Tab 1][Tab 2][+]  [-][+][↺][⚙️][_][□][✕] │ │  │
│ │ 🔍Search │  │ ├────────────────────────────────────────────┤ │  │
│ │          │  │ │ root@server:~$ ls -la                      │ │  │
│ │ Commands │  │ │ drwxr-xr-x  5 root root 4096 May 11 19:00 │ │  │
│ │ ├ ls -la │  │ │                                            │ │  │
│ │ ├ df -h  │  │ │ 👻 AI: df -h [Press Enter to run]         │ │  │
│ │ ├ top    │  │ │                                            │ │  │
│ │ └ htop   │  │ └────────────────────────────────────────────┘ │  │
│ │          │  │                                                 │  │
│ │ ⭐Favs   │  │ [Drop files here to upload]                    │  │
│ │ ├ backup │  └─────────────────────────────────────────────────┘  │
│ │ └ deploy │                                                        │
│ └──────────┘                                                        │
│                                                                      │
│                                    ┌──────────────────────────────┐ │
│                                    │ 🤖 AI Assistant         [_][×]│ │
│                                    ├──────────────────────────────┤ │
│                                    │ How can I help with your     │ │
│                                    │ terminal tasks?              │ │
│                                    ├──────────────────────────────┤ │
│                                    │ [Ask me anything...]    [📎] │ │
│                                    └──────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## ✨ Features

### 1. AI Chat Widget (Bottom-Right)
- **Connects to**: `https://ui.cloudmc.online` (your existing Open WebUI)
- **Model**: Qwen2.5 7B (already running)
- **Features**:
  - Ask questions about terminal commands
  - Get command suggestions with ghost typing
  - Error troubleshooting
  - Code explanations
  - System administration help

### 2. Ghost Typing System
```javascript
// When AI suggests a command:
User: "How do I check disk space?"
AI: "Use df -h"
Terminal shows: 👻 df -h [Press Enter to run, Esc to cancel]
User presses Enter → Command executes
```

### 3. Terminal Tabs
- Multiple terminal sessions
- Switch between tabs
- Close/rename tabs
- New session button (+)
- Each tab maintains its own state

### 4. Command History Panel (Left Side)
- **Search bar** - Filter commands
- **Recent commands** - Click to re-run
- **Favorites** - Star important commands
- **Export** - Save history to file
- **Clear** - Reset history

### 5. File Upload/Download
- **Drag & drop** files onto terminal
- **Upload progress** indicator
- **Download** via right-click context menu
- **Multiple files** support
- **SCP/SFTP** backend

### 6. Draggable/Resizable Terminal
- **Drag** from header to move
- **Resize** from edges/corners
- **Minimize/Maximize** buttons
- **Proper zoom** with CSS transform
- **Grid snapping** (optional)

### 7. Widget Panels
- **Collapsible** history panel
- **Floating** AI chat
- **Quick actions** toolbar
- **Theme switcher** (16 themes)
- **Settings** modal

## 🎨 Theme System
All 16 gradient themes apply to:
- Toolbar
- Terminal header
- Widget panels
- Scrollbars
- Buttons

## 🔧 Technical Stack

### Frontend
- Pure HTML/CSS/JavaScript
- Font Awesome icons
- CSS Grid/Flexbox layout
- CSS transforms for zoom
- LocalStorage for settings

### Backend Integration
- **Terminal**: ttyd (existing)
- **AI**: Open WebUI API at `ui.cloudmc.online`
- **File Transfer**: SCP/SFTP endpoints
- **Auth**: JWT (existing auth.py)

### API Endpoints Needed
```javascript
// AI Chat
POST /api/ai/chat
Body: { message: "user question", context: "terminal state" }
Response: { reply: "AI response", command: "suggested command" }

// File Upload
POST /api/files/upload
Body: FormData with files
Response: { success: true, files: [...] }

// File Download
GET /api/files/download?path=/path/to/file
Response: File stream

// Command History
GET /api/history
Response: { commands: [...] }

POST /api/history/favorite
Body: { command: "ls -la" }
```

## 🚀 Implementation Plan

### Phase 1: Container System ✅
- Workspace layout
- Draggable terminal window
- Resize handles
- Grid system

### Phase 2: Terminal Tabs ✅
- Tab bar component
- Session management
- Tab switching
- New/close tabs

### Phase 3: History Panel ✅
- Left sidebar
- Command list
- Search functionality
- Favorites system

### Phase 4: AI Widget ✅
- Floating chat box
- Open WebUI iframe/API
- Message handling
- Ghost typing trigger

### Phase 5: Ghost Typing ✅
- Command preview overlay
- Typing animation
- Accept/reject controls
- Terminal injection

### Phase 6: File Transfer ✅
- Drag-drop zone
- Upload progress
- Download context menu
- Transfer status

## 📱 Responsive Design
- **Desktop**: Full layout with all panels
- **Tablet**: Collapsible panels, larger targets
- **Mobile**: Single terminal, panels as overlays

## 🎯 User Workflows

### Workflow 1: AI-Assisted Command
1. User asks AI: "How do I find large files?"
2. AI responds with explanation
3. AI suggests: `find / -type f -size +100M`
4. Ghost typing appears in terminal
5. User presses Enter to execute

### Workflow 2: Command History
1. User searches history for "docker"
2. Clicks on previous `docker ps -a` command
3. Command runs in active terminal tab
4. User stars it as favorite

### Workflow 3: File Upload
1. User drags file from desktop
2. Drops on terminal window
3. Upload progress shows
4. File appears in current directory
5. Notification confirms success

## 🔐 Security
- All AI requests authenticated
- File uploads size-limited
- Command injection prevented
- XSS protection
- CSRF tokens

## 📊 Performance
- Lazy load AI widget
- Virtual scrolling for history
- Debounced search
- Optimized animations
- Minimal re-renders

This is the complete vision! Ready to implement?
