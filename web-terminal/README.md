# 🚀 Enhanced Web Terminal

A beautiful, feature-rich web interface for your SSH terminal with animations, custom context menus, and mobile support!

## ✨ Features

### 🎨 Visual Enhancements
- **Animated toolbar** with gradient background
- **Custom right-click context menu** with smooth animations
- **Settings modal** with slide-in effects
- **Modern UI** with glassmorphism effects
- **Responsive design** for mobile and desktop

### ⚙️ Settings & Customization
- **Zoom controls** (50% - 150%)
- **Font size adjustment** (10px - 24px)
- **Theme colors** (6 beautiful gradients)
- **Real-time updates**

### 📋 Context Menu Features
- ✂️ Copy
- 📄 Paste
- 🔲 Select All
- ✖️ Clear Selection
- 🗑️ Clear Terminal
- ⚙️ Settings

### 📱 Mobile Support
- Touch-optimized interface
- Swipe gesture detection
- Responsive toolbar
- Mobile-friendly buttons

## 🚀 Quick Start

### On Your Server:

1. **Upload the files:**
   ```bash
   cd /var/www
   mkdir enhanced-terminal
   cd enhanced-terminal
   ```

2. **Copy the index.html file to the server**

3. **Update Cloudflare tunnel config:**
   ```bash
   # Edit /etc/cloudflared/ssh-tunnel.yml
   cat > /etc/cloudflared/ssh-tunnel.yml <<EOF
   tunnel: YOUR_TUNNEL_ID
   credentials-file: /root/.cloudflared/YOUR_TUNNEL_ID.json

   ingress:
     - hostname: termux.cloudmc.online
       service: http://localhost:8080
     - service: http_status:404
   EOF
   ```

4. **Serve the enhanced interface:**
   ```bash
   # Option 1: Python server
   cd /var/www/enhanced-terminal
   python3 -m http.server 8080

   # Option 2: Node.js server
   npx http-server -p 8080

   # Option 3: nginx (recommended for production)
   # Configure nginx to serve on port 8080
   ```

5. **Restart Cloudflare tunnel:**
   ```bash
   systemctl restart cloudflared-ssh
   ```

## 🎯 Usage

1. Open `https://termux.cloudmc.online` in your browser
2. Right-click anywhere for the context menu
3. Click the **Settings** button in the toolbar to customize
4. Use **Zoom** buttons to adjust size
5. Works on phone, tablet, and desktop!

## 🎨 Customization

### Change Colors
Click the Settings button and choose from 6 beautiful theme colors:
- 💜 Purple Gradient (default)
- 🌸 Pink Gradient
- 💙 Blue Gradient
- 💚 Green Gradient
- ❤️ Red Gradient
- 💛 Yellow Gradient

### Adjust Zoom
- Click 🔍+ to zoom in
- Click 🔍- to zoom out
- Click ↺ to reset to 100%

### Font Size
Open Settings and drag the Font Size slider (10px - 24px)

## 📱 Mobile Features

- **Touch-optimized** buttons and controls
- **Swipe gestures** for navigation
- **Responsive layout** adapts to screen size
- **No pinch-zoom** for better terminal experience

## 🔧 Technical Details

- Pure HTML/CSS/JavaScript (no dependencies!)
- Embeds ttyd terminal in iframe
- Custom context menu with animations
- CSS animations for smooth transitions
- Mobile-first responsive design

## 🚀 Advanced Setup

For production use, serve this with nginx for better performance:

```nginx
server {
    listen 8080;
    server_name localhost;
    root /var/www/enhanced-terminal;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location /ws {
        proxy_pass http://localhost:7681;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## 📝 License

MIT License - Feel free to customize and use!

---

**Enjoy your enhanced terminal experience!** 🎉
