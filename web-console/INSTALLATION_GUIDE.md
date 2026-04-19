# 🚀 Web Console Installation Guide

## 📋 **Overview**

This guide explains how to install the Pterodactyl Web Console after installing Pterodactyl with pteroanyinstall.

---

## ⚡ **Quick Start**

### **Step 1: Install Pterodactyl**

First, install Pterodactyl using pteroanyinstall:

```bash
cd /path/to/pteroanyinstall
sudo bash install.sh
```

### **Step 2: Get Your API Key**

1. Log into your Pterodactyl Panel
2. Go to: **Account Settings** → **API Credentials**
3. Click **Create API Key**
4. Give it a description (e.g., "Web Console")
5. **Copy the API key** (you'll need this in Step 3)

**URL Format:** `https://your-panel-domain.com/account/api`

### **Step 3: Install Web Console**

```bash
cd /path/to/pteroanyinstall/web-console
sudo bash install.sh
```

---

## 🎯 **Interactive Installation**

The installer will ask you for the following information:

### **1. Installation Confirmation**
```
Do you want to install the Pterodactyl Web Console? (y/n)
```
- Press **y** to continue
- Press **n** to cancel

### **2. Pterodactyl Panel URL**
```
Enter your Pterodactyl Panel URL (e.g., https://panel.example.com):
```
- Enter the **full URL** of your Pterodactyl panel
- Example: `https://panel.example.com`
- Example: `https://pterodactyl.mydomain.com`
- **Do NOT include trailing slash**

### **3. Pterodactyl API Key**
```
Enter your Pterodactyl API Key:
```
- Paste the API key you created in Step 2
- The key will be hidden as you type (for security)
- Example: `ptlc_1234567890abcdefghijklmnopqrstuvwxyz`

### **4. Admin Username**
```
Enter admin username (default: admin):
```
- Press **Enter** to use default (`admin`)
- Or type a custom username
- This is for logging into the web console

### **5. Admin Password**
```
Enter admin password:
Confirm admin password:
```
- Enter a password (minimum 8 characters)
- Password is hidden as you type
- You'll need to confirm it
- **Remember this password!**

---

## ✅ **What Gets Installed**

### **System Packages**
- Python 3
- pip (Python package manager)
- Nginx (reverse proxy)

### **Python Packages**
- Flask (web framework)
- Flask-SocketIO (real-time updates)
- psutil (system monitoring)
- requests (API calls)
- python-dotenv (configuration)

### **Services**
- **pterodactyl-web-console** - Main web console service
- **Nginx** - Reverse proxy on port 8080

### **Files Created**
- `/opt/pterodactyl-web-console/` - Installation directory
  - `app.py` - Main application
  - `requirements.txt` - Python dependencies
  - `.env` - Configuration file (your credentials)
  - `templates/` - HTML templates
- `/etc/systemd/system/pterodactyl-web-console.service` - Systemd service
- `/etc/nginx/sites-available/pterodactyl-web-console` - Nginx config

---

## 🌐 **Accessing the Web Console**

### **URL**
```
http://YOUR_SERVER_IP:8080
```

The installer will show you the exact URL at the end.

### **Login**
- **Username:** The username you set during installation
- **Password:** The password you set during installation

---

## 🔧 **Configuration**

### **View Configuration**
```bash
cat /opt/pterodactyl-web-console/.env
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

### **After Editing Configuration**
```bash
sudo systemctl restart pterodactyl-web-console
```

---

## 🛠️ **Service Management**

### **Check Status**
```bash
sudo systemctl status pterodactyl-web-console
```

### **View Logs**
```bash
sudo journalctl -u pterodactyl-web-console -f
```

### **Restart Service**
```bash
sudo systemctl restart pterodactyl-web-console
```

### **Stop Service**
```bash
sudo systemctl stop pterodactyl-web-console
```

### **Start Service**
```bash
sudo systemctl start pterodactyl-web-console
```

### **Disable Auto-Start**
```bash
sudo systemctl disable pterodactyl-web-console
```

### **Enable Auto-Start**
```bash
sudo systemctl enable pterodactyl-web-console
```

---

## 🔒 **Security Recommendations**

### **1. Use Strong Passwords**
- Minimum 12 characters
- Mix of uppercase, lowercase, numbers, symbols
- Don't use common words

### **2. Change Default Port (Optional)**

Edit Nginx config:
```bash
sudo nano /etc/nginx/sites-available/pterodactyl-web-console
```

Change `listen 8080;` to your preferred port.

Then reload Nginx:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

### **3. Use HTTPS (Recommended)**

For production, set up SSL/TLS:
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d console.yourdomain.com
```

### **4. Firewall Rules**

Allow web console port:
```bash
sudo ufw allow 8080/tcp
```

Or for custom port:
```bash
sudo ufw allow YOUR_PORT/tcp
```

### **5. Keep API Key Secure**
- Never share your API key
- Don't commit `.env` to version control
- Rotate keys periodically

---

## 🐛 **Troubleshooting**

### **Can't Access Web Console**

1. **Check if service is running:**
   ```bash
   sudo systemctl status pterodactyl-web-console
   ```

2. **Check Nginx:**
   ```bash
   sudo systemctl status nginx
   ```

3. **Check firewall:**
   ```bash
   sudo ufw status
   ```

4. **View logs:**
   ```bash
   sudo journalctl -u pterodactyl-web-console -n 50
   ```

### **Login Fails**

1. **Verify credentials in .env:**
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

1. **Verify URL in .env:**
   ```bash
   sudo cat /opt/pterodactyl-web-console/.env | grep PTERODACTYL_URL
   ```

2. **Test API key:**
   ```bash
   curl -H "Authorization: Bearer YOUR_API_KEY" \
        -H "Accept: Application/vnd.pterodactyl.v1+json" \
        https://your-panel-url.com/api/client
   ```

3. **Check API key permissions:**
   - Log into Pterodactyl Panel
   - Go to Account → API
   - Verify key exists and has correct permissions

### **Service Won't Start**

1. **Check Python installation:**
   ```bash
   python3 --version
   pip3 --version
   ```

2. **Reinstall dependencies:**
   ```bash
   cd /opt/pterodactyl-web-console
   sudo pip3 install -r requirements.txt
   ```

3. **Check for port conflicts:**
   ```bash
   sudo netstat -tulpn | grep :5000
   sudo netstat -tulpn | grep :8080
   ```

---

## 🔄 **Updating**

### **Update Web Console**

```bash
cd /path/to/pteroanyinstall
git pull
cd web-console
sudo systemctl stop pterodactyl-web-console
sudo cp app.py /opt/pterodactyl-web-console/
sudo cp templates/* /opt/pterodactyl-web-console/templates/
sudo systemctl start pterodactyl-web-console
```

### **Update Dependencies**

```bash
cd /opt/pterodactyl-web-console
sudo pip3 install -r requirements.txt --upgrade
sudo systemctl restart pterodactyl-web-console
```

---

## 🗑️ **Uninstallation**

### **Remove Web Console**

```bash
# Stop and disable service
sudo systemctl stop pterodactyl-web-console
sudo systemctl disable pterodactyl-web-console

# Remove service file
sudo rm /etc/systemd/system/pterodactyl-web-console.service
sudo systemctl daemon-reload

# Remove Nginx config
sudo rm /etc/nginx/sites-enabled/pterodactyl-web-console
sudo rm /etc/nginx/sites-available/pterodactyl-web-console
sudo systemctl reload nginx

# Remove installation directory
sudo rm -rf /opt/pterodactyl-web-console

# Optional: Remove Python packages
sudo pip3 uninstall flask flask-socketio psutil requests python-dotenv
```

---

## 📚 **Additional Resources**

### **Documentation**
- [WEB_CONSOLE_FEATURES_COMPLETE.md](../WEB_CONSOLE_FEATURES_COMPLETE.md) - Complete feature list
- [WEB_CONSOLE_SUMMARY.md](../WEB_CONSOLE_SUMMARY.md) - Feature overview
- [README.md](README.md) - Quick start guide

### **Support**
- Check logs: `journalctl -u pterodactyl-web-console -f`
- Pterodactyl Documentation: https://pterodactyl.io/
- GitHub Issues: Report bugs and request features

---

## ✨ **Features**

Once installed, you'll have access to:

- ✅ Real-time server monitoring
- ✅ Performance graphs (CPU, RAM, Network)
- ✅ File manager with editor
- ✅ Scheduled actions
- ✅ GPU monitoring (NVIDIA)
- ✅ Server groups/categories
- ✅ Feature toggles
- ✅ Theme customization
- ✅ Mobile-responsive design
- ✅ And 50+ more features!

---

## 🎉 **You're All Set!**

Your Pterodactyl Web Console is now installed and ready to use!

**Access it at:** `http://YOUR_SERVER_IP:8080`

**Enjoy managing your game servers!** 🚀✨
