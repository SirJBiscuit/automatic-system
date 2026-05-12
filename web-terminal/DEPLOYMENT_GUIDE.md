# 🚀 Deployment Guide: termux.cloudmc.online

## 📋 Pre-Deployment Checklist

### ✅ **New Features Added:**
1. ✅ **"Host" Environment** - Added to server environment dropdown
2. ✅ **Pop-out Widgets** - AI Chat and other widgets can be popped out and dragged
3. ✅ **Animated Tooltips** - Beautiful hover tooltips on all important buttons
4. ✅ **Global Context Menu** - Right-click works everywhere
5. ✅ **All Old Features** - Snippets, Command Palette, Zoom, etc.

---

## 🌐 Deployment to termux.cloudmc.online

### **Method 1: Direct File Upload (Recommended)**

#### **Step 1: Backup Current Version**
```bash
# SSH into your server
ssh root@termux.cloudmc.online

# Navigate to web terminal directory
cd /path/to/web-terminal

# Create backup
cp index.html index.html.backup.$(date +%Y%m%d_%H%M%S)
cp auth.py auth.py.backup.$(date +%Y%m%d_%H%M%S)
```

#### **Step 2: Upload New Files**
From your local machine:
```bash
# Upload new index.html
scp C:\Users\Jeremiah Payne\CascadeProjects\pteroanyinstall\web-terminal\index.html root@termux.cloudmc.online:/path/to/web-terminal/

# Or use WinSCP, FileZilla, or similar
```

#### **Step 3: Verify Permissions**
```bash
# SSH into server
ssh root@termux.cloudmc.online

# Set correct permissions
cd /path/to/web-terminal
chmod 644 index.html
chown www-data:www-data index.html  # Or your web server user
```

#### **Step 4: Test**
Open in browser: `https://termux.cloudmc.online`

---

### **Method 2: Git Pull (If Using Git)**

#### **Step 1: Commit and Push**
From your local machine:
```bash
cd C:\Users\Jeremiah Payne\CascadeProjects\pteroanyinstall
git add web-terminal/index.html
git commit -m "DEPLOY: All features ready for production"
git push origin main
```

#### **Step 2: Pull on Server**
```bash
# SSH into server
ssh root@termux.cloudmc.online

# Navigate to project directory
cd /path/to/automatic-system

# Pull latest changes
git pull origin main

# Copy to web terminal location
cp web-terminal/index.html /path/to/web-terminal/
```

---

### **Method 3: Automated Deployment Script**

Create this script on your server:

```bash
#!/bin/bash
# deploy-terminal.sh

echo "🚀 Deploying Enhanced SSH Terminal..."

# Configuration
REPO_URL="https://github.com/SirJBiscuit/automatic-system.git"
REPO_DIR="/tmp/automatic-system-deploy"
WEB_DIR="/path/to/web-terminal"  # Update this path

# Backup current version
echo "📦 Creating backup..."
cp $WEB_DIR/index.html $WEB_DIR/index.html.backup.$(date +%Y%m%d_%H%M%S)

# Clone/pull latest
echo "📥 Fetching latest version..."
if [ -d "$REPO_DIR" ]; then
    cd $REPO_DIR && git pull
else
    git clone $REPO_URL $REPO_DIR
fi

# Copy new files
echo "📋 Copying files..."
cp $REPO_DIR/web-terminal/index.html $WEB_DIR/

# Set permissions
echo "🔒 Setting permissions..."
chmod 644 $WEB_DIR/index.html
chown www-data:www-data $WEB_DIR/index.html

# Restart web server (optional)
# systemctl reload nginx

echo "✅ Deployment complete!"
echo "🌐 Visit: https://termux.cloudmc.online"
```

Make it executable:
```bash
chmod +x deploy-terminal.sh
./deploy-terminal.sh
```

---

## 🧪 Post-Deployment Testing

### **1. Basic Functionality**
- [ ] Page loads without errors
- [ ] Toolbar visible with all buttons
- [ ] Server panel visible on left
- [ ] Can add a new server

### **2. New Features**
- [ ] **Host Environment**: Add server → Environment dropdown shows "🏠 Host"
- [ ] **Animated Tooltips**: Hover over toolbar buttons → Tooltips appear with animation
- [ ] **Pop-out AI Chat**: Open AI chat → Click pop-out icon → Widget becomes draggable
- [ ] **Global Context Menu**: Right-click anywhere → Menu appears

### **3. Old Features**
- [ ] **Snippets**: Press `Ctrl+K` or click Snippets button
- [ ] **Command Palette**: Press `Ctrl+Shift+P` or click Commands button
- [ ] **Zoom**: Click 🔍+ and 🔍- buttons
- [ ] **Pop Out Terminal**: Click "Pop Out" button
- [ ] **Ghost Typing**: Open console, type `demoGhostTyping()`
- [ ] **Command History**: Type `demoHistory()` in console

### **4. Browser Console Check**
- [ ] Open DevTools (F12)
- [ ] No red errors in console
- [ ] No 404 errors in Network tab

---

## 🔧 Configuration

### **Update Open WebUI URL (if needed)**

Edit line ~2424 in `index.html`:
```javascript
const OPENWEBUI_URL = 'https://ui.cloudmc.online';
```

### **Update SSH Terminal Port (if needed)**

Default port is `7681`. If your ttyd runs on a different port, update in the `connectToServer` function.

---

## 🐛 Troubleshooting

### **Issue: Page shows old version**
**Solution:** Clear browser cache
```
Ctrl+Shift+R (hard refresh)
or
Ctrl+F5
```

### **Issue: Context menu doesn't work**
**Solution:** Check browser console for JavaScript errors
```
F12 → Console tab
```

### **Issue: Tooltips don't appear**
**Solution:** Ensure CSS loaded properly
```
F12 → Network tab → Check for index.html (Status 200)
```

### **Issue: Pop-out doesn't work**
**Solution:** Check if `popoutWidget` function exists
```javascript
// In browser console:
console.log(typeof popoutWidget);
// Should output: "function"
```

---

## 📊 Performance Optimization

### **1. Enable Gzip Compression**

Add to Nginx config:
```nginx
location / {
    gzip on;
    gzip_types text/html text/css application/javascript;
    gzip_min_length 1000;
}
```

### **2. Enable Browser Caching**

Add to Nginx config:
```nginx
location ~* \.(html|css|js)$ {
    expires 1h;
    add_header Cache-Control "public, must-revalidate";
}
```

### **3. CDN for Font Awesome**

Already using CDN in index.html:
```html
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
```

---

## 🔐 Security Considerations

### **1. HTTPS Only**
Ensure `termux.cloudmc.online` uses HTTPS:
```nginx
server {
    listen 80;
    server_name termux.cloudmc.online;
    return 301 https://$server_name$request_uri;
}
```

### **2. Authentication**
The terminal already has authentication via `auth.py`. Ensure it's enabled:
```python
# In auth.py
REQUIRE_AUTH = True
```

### **3. Rate Limiting**
Add to Nginx config:
```nginx
limit_req_zone $binary_remote_addr zone=terminal:10m rate=10r/s;

location / {
    limit_req zone=terminal burst=20;
}
```

---

## 📱 Mobile Testing

After deployment, test on mobile devices:

### **iOS Safari:**
- [ ] Page loads correctly
- [ ] Tooltips work on tap
- [ ] Context menu works
- [ ] AI chat opens and functions

### **Android Chrome:**
- [ ] Page loads correctly
- [ ] Tooltips work on tap
- [ ] Context menu works
- [ ] AI chat opens and functions

---

## 🎯 Feature Verification Checklist

### **Environment Options:**
- [ ] 🏠 Host
- [ ] 🔴 Production
- [ ] 🟡 Staging
- [ ] 🟢 Development
- [ ] 🔵 Test

### **Tooltips on:**
- [ ] Snippets button
- [ ] Commands button
- [ ] Settings button
- [ ] Themes button
- [ ] Pop Out button
- [ ] Zoom In button
- [ ] Zoom Out button
- [ ] Reset Zoom button
- [ ] Add Server button
- [ ] AI Chat toggle button

### **Pop-out Widgets:**
- [ ] AI Chat Widget (has pop-out button)
- [ ] File Transfer Panel (can be made draggable)
- [ ] Command History Panel (can be made draggable)

---

## 📝 Rollback Plan

If something goes wrong:

### **Quick Rollback:**
```bash
# SSH into server
ssh root@termux.cloudmc.online

# Find latest backup
cd /path/to/web-terminal
ls -lt index.html.backup.*

# Restore backup
cp index.html.backup.YYYYMMDD_HHMMSS index.html

# Reload web server
systemctl reload nginx
```

---

## 🎉 Post-Deployment

### **1. Announce Update**
Notify users of new features:
- Host environment option
- Pop-out widgets
- Animated tooltips
- Enhanced context menu

### **2. Monitor Logs**
```bash
# Watch web server logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

### **3. Collect Feedback**
- Test all features yourself
- Ask users to report any issues
- Monitor browser console for errors

---

## 📞 Support

### **If Issues Occur:**

1. **Check browser console** (F12)
2. **Check server logs** (`/var/log/nginx/error.log`)
3. **Verify file permissions** (`ls -la /path/to/web-terminal/`)
4. **Test in incognito mode** (rules out cache issues)
5. **Rollback if necessary** (see Rollback Plan above)

---

## ✅ Deployment Complete!

Once deployed and tested, you'll have:

✅ **18 Total Features** (10 old + 8 new)
✅ **Host Environment** for server categorization
✅ **Pop-out Widgets** for flexible workspace
✅ **Animated Tooltips** for better UX
✅ **Global Context Menu** working everywhere
✅ **Production-Ready** Enhanced SSH Terminal

**Live at:** `https://termux.cloudmc.online`

---

**Last Updated:** May 11, 2026  
**Version:** 2.0.0 (Complete Redesign)  
**Status:** ✅ Ready for Production
