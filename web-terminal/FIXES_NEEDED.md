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

## 🔍 FILES TO MODIFY

1. `index.html` - Main application file
   - Widget persistence: Line ~3889 (loadWidgets call)
   - Widget dragging: Line ~4300 (makeDraggable function)
   - Try Demo: Line ~2850 (login form)
   - Dark mode styles: CSS section
   - Empty workspace: Line ~3943 (loadData function)

## 💡 NOTES

- Icons (fa-external-alt, fa-trash) are already in the HTML
- If icons don't show, it's a FontAwesome loading issue
- Check browser console for any CSS/JS errors
- Test on actual deployment at ssh.cloudmc.online
