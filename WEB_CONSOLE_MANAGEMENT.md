# 🌐 Web Console Management Guide

## 📋 **Overview**

The Pterodactyl Web Console is an **optional component** that provides a professional web dashboard for managing your game servers. You can enable or disable it at any time.

---

## ⚡ **Quick Commands**

```bash
# Enable/Install Web Console
sudo ./ptero-webconsole.sh enable

# Check Status
sudo ./ptero-webconsole.sh status

# Disable Web Console
sudo ./ptero-webconsole.sh disable

# Reinstall Web Console
sudo ./ptero-webconsole.sh reinstall

# Completely Remove
sudo ./ptero-webconsole.sh uninstall
```

---

## 🚀 **Installation**

### **Step 1: Install Pterodactyl First**

The web console requires Pterodactyl to be installed:

```bash
cd /opt/ptero
sudo ./pteroanyinstall.sh install-full
```

### **Step 2: Enable Web Console**

After Pterodactyl is installed:

```bash
sudo ./ptero-webconsole.sh enable
```

### **Step 3: Follow Interactive Prompts**

The installer will ask for:
- **Pterodactyl Panel URL** (e.g., `https://panel.example.com`)
- **Pterodactyl API Key** (get from `/account/api`)
- **Admin Username** (default: `admin`)
- **Admin Password** (minimum 8 characters)

### **Step 4: Access Web Console**

Open in your browser:
```
http://YOUR_SERVER_IP:8080
```

---

## 📊 **Management Commands**

### **Enable (Install)**

Installs and starts the web console:

```bash
sudo ./ptero-webconsole.sh enable
```

**What it does:**
- Installs system dependencies
- Downloads web console files
- Prompts for configuration
- Creates systemd service
- Configures Nginx
- Starts the service

**Output:**
```
╔════════════════════════════════════════════════════════════╗
║          Enable Web Console                                ║
╚════════════════════════════════════════════════════════════╝

Running web console installer...
```

---

### **Status**

Check if web console is installed and running:

```bash
sudo ./ptero-webconsole.sh status
```

**Output if installed:**
```
╔════════════════════════════════════════════════════════════╗
║          Web Console Status                                ║
╚════════════════════════════════════════════════════════════╝

✓ Web Console is installed

✓ Service is running

Access URL: http://192.168.1.100:8080

Service Status:
● pterodactyl-web-console.service - Pterodactyl Web Console
   Loaded: loaded
   Active: active (running)
```

**Output if not installed:**
```
╔════════════════════════════════════════════════════════════╗
║          Web Console Status                                ║
╚════════════════════════════════════════════════════════════╝

⚠ Web Console is not installed

Install with: ./ptero-webconsole.sh enable
```

---

### **Disable**

Stops the web console but keeps it installed:

```bash
sudo ./ptero-webconsole.sh disable
```

**What it does:**
- Stops the service
- Disables auto-start
- Keeps all files and configuration

**To re-enable:**
```bash
sudo systemctl start pterodactyl-web-console
sudo systemctl enable pterodactyl-web-console
```

Or just run:
```bash
sudo ./ptero-webconsole.sh enable
```

---

### **Reinstall**

Reinstalls the web console (useful for updates):

```bash
sudo ./ptero-webconsole.sh reinstall
```

**What it does:**
- Runs the installer again
- Prompts for new configuration
- Overwrites existing installation
- Preserves or updates settings

---

### **Uninstall**

Completely removes the web console:

```bash
sudo ./ptero-webconsole.sh uninstall
```

**What it does:**
- Stops the service
- Removes systemd service file
- Removes Nginx configuration
- Deletes all web console files
- Removes `/opt/pterodactyl-web-console/`

**Warning:** This is permanent! You'll need to reinstall to use it again.

---

## 🔧 **Manual Service Management**

If you prefer to manage the service manually:

### **Start Service**
```bash
sudo systemctl start pterodactyl-web-console
```

### **Stop Service**
```bash
sudo systemctl stop pterodactyl-web-console
```

### **Restart Service**
```bash
sudo systemctl restart pterodactyl-web-console
```

### **Enable Auto-Start**
```bash
sudo systemctl enable pterodactyl-web-console
```

### **Disable Auto-Start**
```bash
sudo systemctl disable pterodactyl-web-console
```

### **View Logs**
```bash
sudo journalctl -u pterodactyl-web-console -f
```

### **Check Status**
```bash
sudo systemctl status pterodactyl-web-console
```

---

## 📁 **File Locations**

### **Installation Directory**
```
/opt/pterodactyl-web-console/
├── app.py                 # Main application
├── requirements.txt       # Python dependencies
├── .env                   # Configuration (credentials)
└── templates/            # HTML templates
    ├── dashboard.html
    └── login.html
```

### **Configuration File**
```
/opt/pterodactyl-web-console/.env
```

### **Service File**
```
/etc/systemd/system/pterodactyl-web-console.service
```

### **Nginx Configuration**
```
/etc/nginx/sites-available/pterodactyl-web-console
/etc/nginx/sites-enabled/pterodactyl-web-console
```

---

## ⚙️ **Configuration**

### **View Configuration**
```bash
sudo cat /opt/pterodactyl-web-console/.env
```

### **Edit Configuration**
```bash
sudo nano /opt/pterodactyl-web-console/.env
```

### **Configuration Options**

```env
# Pterodactyl Panel
PTERODACTYL_URL=https://panel.example.com
PTERODACTYL_API_KEY=ptlc_your_api_key_here

# Web Console Login
WEB_USERNAME=admin
WEB_PASSWORD=your_password_here

# Security
SECRET_KEY=auto_generated_key
```

### **After Editing**
```bash
sudo systemctl restart pterodactyl-web-console
```

---

## 🔍 **Troubleshooting**

### **Web Console Won't Start**

1. **Check logs:**
   ```bash
   sudo journalctl -u pterodactyl-web-console -n 50
   ```

2. **Verify Python installation:**
   ```bash
   python3 --version
   pip3 --version
   ```

3. **Check dependencies:**
   ```bash
   cd /opt/pterodactyl-web-console
   sudo pip3 install -r requirements.txt
   ```

### **Can't Access Web Console**

1. **Check if service is running:**
   ```bash
   sudo ./ptero-webconsole.sh status
   ```

2. **Check firewall:**
   ```bash
   sudo ufw status
   sudo ufw allow 8080/tcp
   ```

3. **Check Nginx:**
   ```bash
   sudo systemctl status nginx
   sudo nginx -t
   ```

### **Login Fails**

1. **Verify credentials:**
   ```bash
   sudo cat /opt/pterodactyl-web-console/.env | grep WEB_
   ```

2. **Reset password:**
   ```bash
   sudo nano /opt/pterodactyl-web-console/.env
   # Edit WEB_PASSWORD
   sudo systemctl restart pterodactyl-web-console
   ```

### **Can't Connect to Pterodactyl**

1. **Verify API key:**
   ```bash
   sudo cat /opt/pterodactyl-web-console/.env | grep PTERODACTYL
   ```

2. **Test API key:**
   ```bash
   curl -H "Authorization: Bearer YOUR_API_KEY" \
        -H "Accept: Application/vnd.pterodactyl.v1+json" \
        https://your-panel-url.com/api/client
   ```

---

## 🎯 **Use Cases**

### **Scenario 1: Try It Out**

```bash
# Install and try
sudo ./ptero-webconsole.sh enable

# Don't like it? Remove it
sudo ./ptero-webconsole.sh uninstall
```

### **Scenario 2: Temporary Disable**

```bash
# Disable for maintenance
sudo ./ptero-webconsole.sh disable

# Re-enable later
sudo systemctl start pterodactyl-web-console
sudo systemctl enable pterodactyl-web-console
```

### **Scenario 3: Update Configuration**

```bash
# Reinstall with new settings
sudo ./ptero-webconsole.sh reinstall
```

---

## 📊 **Comparison**

### **With Web Console**
- ✅ Beautiful web dashboard
- ✅ Real-time monitoring
- ✅ Performance graphs
- ✅ File manager
- ✅ Scheduled actions
- ✅ Mobile-friendly
- ✅ 60+ features

### **Without Web Console**
- ✅ Lighter system resources
- ✅ One less service to manage
- ✅ Use Pterodactyl panel directly
- ✅ Simpler setup

**Choose what works best for you!**

---

## 💡 **Tips**

### **1. Try Before You Commit**
The web console is completely optional. Install it, try it out, and if you don't like it, just uninstall it.

### **2. Easy Updates**
To update the web console to the latest version:
```bash
cd /opt/ptero
git pull
sudo ./ptero-webconsole.sh reinstall
```

### **3. Multiple Access Methods**
You can use:
- Pterodactyl Panel (official)
- Web Console (optional)
- Discord Bot (optional)
- All of the above!

### **4. Resource Usage**
The web console uses minimal resources:
- ~50MB RAM
- Negligible CPU
- Port 8080

---

## 🎉 **Summary**

The web console is:
- ✅ **Optional** - Install only if you want it
- ✅ **Easy** - One command to enable/disable
- ✅ **Flexible** - Can be removed anytime
- ✅ **Powerful** - 60+ professional features
- ✅ **Safe** - Doesn't affect Pterodactyl

**Commands to remember:**
```bash
sudo ./ptero-webconsole.sh enable      # Install it
sudo ./ptero-webconsole.sh status      # Check it
sudo ./ptero-webconsole.sh disable     # Pause it
sudo ./ptero-webconsole.sh uninstall   # Remove it
```

---

## 📚 **Additional Documentation**

- [Installation Guide](web-console/INSTALLATION_GUIDE.md) - Detailed setup instructions
- [Features Guide](WEB_CONSOLE_FEATURES_COMPLETE.md) - Complete feature list
- [Feature Summary](WEB_CONSOLE_SUMMARY.md) - Quick overview

---

**The choice is yours! Install it when you're ready.** 🚀✨
