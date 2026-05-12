# 🐛 Debug Guide - Context Menu & Animation Issues

## Quick Troubleshooting Steps

### **1. Check Browser Console for Errors**

**Open Console:**
- Press `F12` or `Ctrl+Shift+I`
- Click "Console" tab
- Look for red error messages

**Common Errors:**
- `Uncaught ReferenceError` - Function not defined
- `Cannot read property of null` - Element not found
- `Syntax Error` - Code issue

---

### **2. Test Context Menus Step-by-Step**

#### **Tab Context Menu (Should Work Immediately):**

**Prerequisites:** NONE - Should work right away

**Steps:**
1. Add a server (click "Add" button)
2. Fill in server details and save
3. Click the server to create a tab
4. **Right-click on the tab** (not in the terminal area)
5. Context menu should appear

**If it doesn't work:**
- Open console (F12)
- Type: `document.getElementById('tabContextMenu')`
- Should show the menu element (not null)
- Try: `showTabContextMenu(new MouseEvent('contextmenu', {clientX: 100, clientY: 100}), 'test')`

---

#### **Terminal Context Menu (Needs Active Tab):**

**Prerequisites:** Must have an active tab first!

**Steps:**
1. Add a server and click it (creates tab)
2. Wait for terminal area to render
3. **Right-click in the terminal area** (the center panel)
4. Context menu should appear

**If it doesn't work:**
- Check console for errors
- Type: `document.getElementById('iframeOverlay')`
- Should show overlay element (not null)
- Type: `document.getElementById('terminalContextMenu')`
- Should show menu element (not null)

---

### **3. Test Animations**

#### **Modal Animation:**
1. Click "Add" button
2. Modal should slide up from bottom
3. Background should fade in

**If it doesn't work:**
- Check if modal appears at all
- Look for CSS errors in console
- Try: `document.getElementById('serverModal').classList.add('active')`

#### **Ghost Typing Animation:**
1. Open console (F12)
2. Type: `demoGhostTyping()`
3. Press Enter
4. Ghost overlay should slide up from bottom

**If it doesn't work:**
- Check console for errors
- Try: `document.getElementById('ghostTyping')`
- Should not be null
- Try: `showGhostCommand('test command', 'Test')`

---

### **4. Common Issues & Fixes**

#### **Issue: Right-click shows browser menu instead**
**Cause:** Event not being prevented
**Fix:** Check if `event.preventDefault()` is being called

**Test in console:**
```javascript
// Should prevent default right-click
document.addEventListener('contextmenu', (e) => {
    console.log('Right-click detected at:', e.clientX, e.clientY);
});
```

---

#### **Issue: Context menu appears but in wrong position**
**Cause:** CSS positioning issue
**Fix:** Check menu CSS

**Test in console:**
```javascript
const menu = document.getElementById('tabContextMenu');
console.log('Menu position:', menu.style.left, menu.style.top);
console.log('Menu classes:', menu.className);
```

---

#### **Issue: Animations don't play**
**Cause:** CSS transitions not working or elements not found
**Fix:** Check element exists and has proper classes

**Test in console:**
```javascript
// Check if element exists
const ghost = document.getElementById('ghostTyping');
console.log('Ghost element:', ghost);
console.log('Ghost classes:', ghost?.className);

// Manually trigger animation
ghost?.classList.add('active');
```

---

#### **Issue: Nothing happens when clicking buttons**
**Cause:** JavaScript not loaded or functions not defined
**Fix:** Check if functions exist

**Test in console:**
```javascript
// Check if functions are defined
console.log('addServer:', typeof addServer);
console.log('demoGhostTyping:', typeof demoGhostTyping);
console.log('toggleAIChat:', typeof toggleAIChat);
```

---

### **5. Manual Testing Commands**

**Open console (F12) and try these:**

```javascript
// 1. Check if all elements exist
console.log('Server Modal:', document.getElementById('serverModal'));
console.log('Tab Context Menu:', document.getElementById('tabContextMenu'));
console.log('Terminal Context Menu:', document.getElementById('terminalContextMenu'));
console.log('Ghost Typing:', document.getElementById('ghostTyping'));
console.log('AI Chat Widget:', document.getElementById('aiChatWidget'));

// 2. Test functions exist
console.log('Functions:', {
    addServer: typeof addServer,
    demoGhostTyping: typeof demoGhostTyping,
    toggleAIChat: typeof toggleAIChat,
    demoHistory: typeof demoHistory
});

// 3. Test modal
document.getElementById('serverModal').classList.add('active');
// Close it:
document.getElementById('serverModal').classList.remove('active');

// 4. Test ghost typing
showGhostCommand('ls -la', 'Test Command');

// 5. Test AI chat
toggleAIChat();

// 6. Check localStorage
console.log('Servers:', localStorage.getItem('ssh_servers'));
console.log('Tabs:', localStorage.getItem('ssh_tabs'));

// 7. Force render
renderServerList();
renderTabs();
renderTerminal();
```

---

### **6. Step-by-Step Verification**

**Run each command and verify output:**

```javascript
// Step 1: Verify page loaded
console.log('Page loaded:', document.readyState);

// Step 2: Verify global state
console.log('Servers:', servers);
console.log('Tabs:', tabs);
console.log('Active Tab:', activeTabId);

// Step 3: Add test server manually
servers.push({
    id: 'test_server',
    name: 'Test Server',
    host: 'localhost',
    port: 7681,
    protocol: 'https',
    environment: 'Development',
    icon: '🟢',
    online: true,
    uptime: '1d 2h 30m',
    diskUsage: '45%',
    cpuUsage: '23%',
    memUsage: '67%'
});
renderServerList();

// Step 4: Create test tab
tabs.push({
    id: 'test_tab',
    serverId: 'test_server',
    serverName: 'Test Server',
    serverIcon: '🟢',
    url: 'https://localhost:7681'
});
activeTabId = 'test_tab';
renderTabs();
renderTerminal();

// Step 5: Test context menu
const tabElement = document.querySelector('.tab');
if (tabElement) {
    console.log('Tab element found, try right-clicking it');
} else {
    console.log('ERROR: No tab element found!');
}
```

---

### **7. Expected Console Output**

**When page loads successfully:**
```
Page loaded: complete
Servers: []
Tabs: []
Active Tab: null
```

**After adding a server:**
```
Servers: [{id: "server_...", name: "...", ...}]
```

**After clicking server:**
```
Tabs: [{id: "tab_...", serverId: "...", ...}]
Active Tab: tab_...
```

---

### **8. Browser Compatibility Check**

**Test in different browsers:**
- ✅ Chrome/Edge (Recommended)
- ✅ Firefox
- ⚠️ Safari (may have issues)
- ❌ IE11 (not supported)

**Check browser version:**
```javascript
console.log('User Agent:', navigator.userAgent);
```

---

### **9. Network Issues**

**Check if files loaded:**
1. Open DevTools (F12)
2. Click "Network" tab
3. Refresh page
4. Look for:
   - `index.html` - Status 200
   - Font Awesome CSS - Status 200
   - No 404 errors

---

### **10. Quick Fix: Force Reload**

**If nothing works:**
1. Press `Ctrl+Shift+R` (hard refresh)
2. Clear browser cache
3. Close and reopen browser
4. Try incognito/private mode

---

## 🔍 Specific Issue Checks

### **Context Menu Not Appearing:**

```javascript
// Check if context menu HTML exists
const tabMenu = document.getElementById('tabContextMenu');
const termMenu = document.getElementById('terminalContextMenu');

console.log('Tab Menu:', tabMenu);
console.log('Term Menu:', termMenu);

// Check if they have content
console.log('Tab Menu HTML:', tabMenu?.innerHTML);
console.log('Term Menu HTML:', termMenu?.innerHTML);

// Try to show manually
tabMenu?.classList.add('active');
tabMenu.style.left = '100px';
tabMenu.style.top = '100px';
```

### **Animations Not Working:**

```javascript
// Check CSS animations
const ghost = document.getElementById('ghostTyping');
const styles = window.getComputedStyle(ghost);

console.log('Display:', styles.display);
console.log('Transition:', styles.transition);
console.log('Animation:', styles.animation);

// Force animation
ghost.classList.add('active');
```

### **Buttons Not Responding:**

```javascript
// Check if onclick handlers exist
const addBtn = document.querySelector('.add-server-btn');
console.log('Add button:', addBtn);
console.log('Onclick:', addBtn?.onclick);
console.log('getAttribute:', addBtn?.getAttribute('onclick'));

// Try clicking programmatically
addBtn?.click();
```

---

## 📝 Report Template

**If issues persist, provide this info:**

```
Browser: [Chrome/Firefox/Safari/Edge]
Version: [Check in browser settings]
OS: [Windows/Mac/Linux]

Console Errors:
[Paste any red errors here]

What doesn't work:
[ ] Context menus
[ ] Animations
[ ] Buttons
[ ] Modals
[ ] Other: ___________

What DOES work:
[ ] Page loads
[ ] Can see UI
[ ] Console opens
[ ] Other: ___________

Console output from verification:
[Paste output from Step 6 commands]
```

---

## 🚀 Quick Test Script

**Copy and paste this entire block into console:**

```javascript
console.log('=== ENHANCED SSH TERMINAL DEBUG ===');
console.log('1. Page State:', document.readyState);
console.log('2. Elements:', {
    serverModal: !!document.getElementById('serverModal'),
    tabContextMenu: !!document.getElementById('tabContextMenu'),
    terminalContextMenu: !!document.getElementById('terminalContextMenu'),
    ghostTyping: !!document.getElementById('ghostTyping'),
    aiChatWidget: !!document.getElementById('aiChatWidget')
});
console.log('3. Functions:', {
    addServer: typeof addServer,
    demoGhostTyping: typeof demoGhostTyping,
    toggleAIChat: typeof toggleAIChat
});
console.log('4. State:', {
    servers: servers.length,
    tabs: tabs.length,
    activeTab: activeTabId
});
console.log('5. Testing ghost typing...');
demoGhostTyping();
console.log('=== If ghost appeared, animations work! ===');
```

---

**Good luck debugging! 🐛**
