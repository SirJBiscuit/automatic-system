# Remaining Fixes for Enhanced SSH Terminal

## ✅ COMPLETED
1. **AI Demo Mode** - Removed demo mode message, shows proper error
2. **Trash Button** - Fixed delete server function to accept serverId parameter

## 🔧 TO DO

### 5. Widget Persistence After Refresh
**Issue**: Widgets don't persist after page refresh
**Solution**: Widgets are saved to localStorage but not loaded on app start
**Fix**: Ensure `loadWidgets()` is called in `showMainApp()` function

### 6. Widget Dragging Positioning
**Issue**: Dragging widgets uses incorrect positioning
**Solution**: Update `makeDraggable()` function to use correct offset calculations
**Fix**: 
```javascript
// In makeDraggable function, fix the drag calculation:
const onMouseMove = (e) => {
    const newX = e.clientX - offsetX;
    const newY = e.clientY - offsetY;
    element.style.left = newX + 'px';
    element.style.top = newY + 'px';
};
```

### 7. Try Demo Button
**Issue**: Try Demo button doesn't work
**Location**: Login screen
**Fix**: Implement demo login that bypasses authentication or creates demo session

### 8. Create Widget GUI Dark Mode
**Issue**: Widget creation modal doesn't respect dark mode
**Fix**: Add dark mode styles to widget modal:
```css
#widgetModal .modal-content {
    background: #1a1a1a;
    color: #fff;
}
#widgetModal .form-input,
#widgetModal .form-select,
#widgetModal textarea {
    background: #2a2a2a;
    color: #fff;
    border-color: #444;
}
```

### 9. Script Widget Dark Mode Text
**Issue**: New script widget text doesn't respect dark mode
**Fix**: Add dark mode styles to script editor:
```css
#scriptContent {
    background: #2a2a2a;
    color: #fff;
    border-color: #444;
}
```

### 10. Empty Workspace Until Persist
**Issue**: Workspace shows content even without persisted connections
**Solution**: Only restore tabs for servers with `persistSession: true`
**Current Code**: Already implemented in `loadData()` function
**Verify**: Check if it's working correctly

## 📋 TESTING CHECKLIST

- [ ] Widgets persist after refresh
- [ ] Widget dragging works smoothly with correct positioning
- [ ] Try Demo button creates demo session
- [ ] Widget creation modal is dark
- [ ] Script editor text is visible in dark mode
- [ ] Workspace is empty on fresh load
- [ ] Only persisted connections restore on refresh
- [ ] Icons show correctly in server list
- [ ] Icons show correctly in View menu

### 11. Host Discovery Implementation
**Issue**: Network host discovery uses simulated data instead of real scanning
**Current**: Shows 4 fake example hosts
**Solution**: Implement real network scanning backend
**Requirements**:
- Create `/api/scan-network` endpoint
- Use `nmap` for port scanning (detect SSH port 22, ttyd port 7681)
- Use `arp-scan` for MAC address discovery
- Use `avahi-browse` for mDNS/Bonjour service discovery
- Require admin password before scanning (security)
- Return JSON: `{ hosts: [{ ip, hostname, mac, ports, type, online }] }`
**Security**:
- Ask for admin password confirmation before scanning
- Rate limiting to prevent abuse
- Only scan local network (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
- User permission/consent required

### 12. Right-Click Context Menu System
**Issue**: Context menus not properly implemented across entire website
**Current**: Only works in specific areas (servers, tabs, workspace)
**Solution**: Implement comprehensive context menu system
**Areas Needing Context Menus**:
- **Server Panel**: Add server, scan network, refresh list
- **Tab Bar**: New tab, close all tabs, close others
- **Terminal Area**: Copy, paste, clear, find, select all
- **Widgets**: Edit, delete, duplicate, bring to front
- **Sidebar**: Collapse/expand, hide/show panels
- **Toolbar**: Customize toolbar, reset layout
- **Empty State**: Quick actions, help, settings
**Implementation**:
```javascript
// Global context menu handler
document.addEventListener('contextmenu', (e) => {
    const target = e.target.closest('[data-context-menu]');
    if (target) {
        e.preventDefault();
        const menuType = target.dataset.contextMenu;
        showContextMenu(menuType, e.pageX, e.pageY, target);
    }
});
```

### 13. Overlay/Bounding Box System
**Issue**: No visual feedback for interactive areas and their specific functions
**Solution**: Implement overlay system with bounding boxes for each component
**Components Needing Overlays**:
- **Server Panel**: Settings, filters, sort options
- **Terminal Window**: Font size, theme, encoding, bell
- **Tab Bar**: Tab management, session options
- **Widgets**: Resize handles, opacity, z-index
- **Sidebar Panels**: Pin/unpin, resize, collapse
- **Toolbar**: Customize, show/hide buttons
**Features**:
- Hover to show bounding box outline
- Click to show settings overlay
- Right-click for context menu
- Drag handles for resizable components
**Implementation**:
```css
.component-overlay {
    position: absolute;
    border: 2px dashed rgba(102, 126, 234, 0.5);
    pointer-events: none;
    transition: opacity 0.2s;
}
.component-overlay.active {
    opacity: 1;
    pointer-events: all;
}
```

## 🔍 FILES TO MODIFY

1. `index.html` - Main application file
   - Widget persistence: Line ~3889 (loadWidgets call)
   - Widget dragging: Line ~4300 (makeDraggable function)
   - Try Demo: Line ~2850 (login form)
   - Dark mode styles: CSS section
   - Empty workspace: Line ~3943 (loadData function)
   - Host discovery: Line ~5200 (scanNetwork function)
   - Context menus: Line ~4800 (context menu handlers)
   - Overlay system: New CSS and JS sections

2. **Backend API** (needs to be created)
   - `/api/scan-network` - Network scanning endpoint
   - Requires: nmap, arp-scan, avahi-browse installed
   - Authentication: Admin password verification
   - Rate limiting: Max 1 scan per minute

## 💡 NOTES

- Icons (fa-external-alt, fa-trash) are already in the HTML
- If icons don't show, it's a FontAwesome loading issue
- Check browser console for any CSS/JS errors
- Test on actual deployment at ssh.cloudmc.online
- Host discovery requires backend implementation (not just frontend)
- Context menus should be consistent across all areas
- Overlay system should be toggleable (show/hide with keyboard shortcut)
