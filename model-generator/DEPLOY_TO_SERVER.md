# 🚀 Deploy to Debian 12 Server

## 📋 Overview

This guide helps you deploy the 3D Model Generator to your Debian 12 server **without conflicts** with pterodactyl or other services.

## 🎯 Isolation Strategy

The installation is **completely isolated**:
- ✅ Separate user (`modelgen`)
- ✅ Separate directory (`/opt/model-generator`)
- ✅ Separate Python virtual environment
- ✅ Separate systemd service
- ✅ Separate port (5050)
- ✅ Nginx reverse proxy at `/model-generator/`
- ✅ No interference with pterodactyl

---

## 📦 Quick Install (3 Steps)

### **Step 1: Upload Files to Server**

From your Windows machine:

```bash
# Create zip of your project (exclude venv and outputs)
# On Windows PowerShell:
cd C:\Users\Jeremiah Payne\CascadeProjects\ModelGenerator
Compress-Archive -Path app.py,model_generator.py,prompt_generator.py,triposr_integration.py,requirements.txt,templates,.env -DestinationPath model-generator.zip

# Upload to server (use SCP, SFTP, or your preferred method)
scp model-generator.zip user@your-server:/tmp/
```

### **Step 2: Run Installation Script**

On your Debian server:

```bash
# Download and run the install script
cd /tmp
wget https://raw.githubusercontent.com/your-repo/model-generator/main/DEBIAN_SERVER_INSTALL.sh
chmod +x DEBIAN_SERVER_INSTALL.sh
sudo ./DEBIAN_SERVER_INSTALL.sh
```

Or manually:

```bash
# Extract files
cd /opt/model-generator
sudo unzip /tmp/model-generator.zip
sudo chown -R modelgen:modelgen /opt/model-generator

# Install dependencies
sudo -u modelgen /opt/model-generator/venv/bin/pip install -r requirements.txt

# Start service
sudo systemctl restart model-generator
```

### **Step 3: Access Your App**

```
http://your-server-ip/model-generator/
```

---

## 🔧 Manual Installation

If you prefer manual setup:

### 1. Install System Dependencies

```bash
sudo apt update
sudo apt install -y python3.11 python3.11-venv python3.11-dev \
    git wget curl build-essential libgl1-mesa-glx libglib2.0-0 \
    nginx supervisor
```

### 2. Create Application User

```bash
sudo useradd -r -m -d /opt/model-generator -s /bin/bash modelgen
```

### 3. Setup Application

```bash
sudo mkdir -p /opt/model-generator
cd /opt/model-generator

# Upload your files here
sudo chown -R modelgen:modelgen /opt/model-generator
```

### 4. Create Virtual Environment

```bash
sudo -u modelgen python3.11 -m venv /opt/model-generator/venv
sudo -u modelgen /opt/model-generator/venv/bin/pip install -r requirements.txt
```

### 5. Create Systemd Service

```bash
sudo nano /etc/systemd/system/model-generator.service
```

Paste:

```ini
[Unit]
Description=3D Model Generator Service
After=network.target

[Service]
Type=simple
User=modelgen
Group=modelgen
WorkingDirectory=/opt/model-generator
Environment="PATH=/opt/model-generator/venv/bin"
ExecStart=/opt/model-generator/venv/bin/python app.py
Restart=always
RestartSec=10
PrivateTmp=true
NoNewPrivileges=true
MemoryLimit=8G

[Install]
WantedBy=multi-user.target
```

### 6. Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/model-generator
```

Paste:

```nginx
server {
    listen 80;
    server_name your-domain.com;  # Change this

    client_max_body_size 100M;

    location /model-generator/ {
        proxy_pass http://127.0.0.1:5050/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
    }
}
```

Enable:

```bash
sudo ln -s /etc/nginx/sites-available/model-generator /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 7. Update app.py

Edit `/opt/model-generator/app.py`, change the last line to:

```python
if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5050, debug=False)
```

### 8. Start Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable model-generator
sudo systemctl start model-generator
sudo systemctl status model-generator
```

---

## 🔍 Troubleshooting

### Check Service Status

```bash
sudo systemctl status model-generator
```

### View Logs

```bash
# Real-time logs
sudo journalctl -u model-generator -f

# Last 100 lines
sudo journalctl -u model-generator -n 100
```

### Check if Port is in Use

```bash
sudo netstat -tlnp | grep 5050
```

### Test Nginx Config

```bash
sudo nginx -t
```

### Restart Everything

```bash
sudo systemctl restart model-generator
sudo systemctl reload nginx
```

---

## 🛡️ Security Considerations

### Firewall (if using UFW)

```bash
# Allow Nginx
sudo ufw allow 'Nginx Full'

# Port 5050 should NOT be exposed (only localhost)
```

### SSL/HTTPS (Recommended)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com
```

---

## 📊 Resource Requirements

**Minimum:**
- CPU: 2 cores
- RAM: 4GB
- Disk: 20GB
- GPU: Optional (CUDA-capable for faster generation)

**Recommended:**
- CPU: 4+ cores
- RAM: 8GB+
- Disk: 50GB+
- GPU: NVIDIA with 4GB+ VRAM

---

## 🔄 Updates

To update the application:

```bash
# Stop service
sudo systemctl stop model-generator

# Update files
cd /opt/model-generator
sudo -u modelgen git pull  # if using git
# or upload new files

# Update dependencies
sudo -u modelgen /opt/model-generator/venv/bin/pip install -r requirements.txt --upgrade

# Restart service
sudo systemctl start model-generator
```

---

## ❌ Uninstall

```bash
# Stop and disable service
sudo systemctl stop model-generator
sudo systemctl disable model-generator
sudo rm /etc/systemd/system/model-generator.service

# Remove Nginx config
sudo rm /etc/nginx/sites-enabled/model-generator
sudo rm /etc/nginx/sites-available/model-generator
sudo systemctl reload nginx

# Remove application
sudo userdel -r modelgen
sudo rm -rf /opt/model-generator

# Reload systemd
sudo systemctl daemon-reload
```

---

## 📞 Support

Check logs for errors:
```bash
sudo journalctl -u model-generator -f
```

Common issues:
- **Port already in use**: Change port in app.py and systemd service
- **Permission denied**: Check file ownership (`chown -R modelgen:modelgen /opt/model-generator`)
- **Module not found**: Reinstall requirements (`pip install -r requirements.txt`)
- **GPU not detected**: Install CUDA drivers if using NVIDIA GPU

---

## ✅ Verification Checklist

- [ ] Service running: `systemctl status model-generator`
- [ ] Nginx configured: `nginx -t`
- [ ] Port listening: `netstat -tlnp | grep 5050`
- [ ] Logs clean: `journalctl -u model-generator -n 50`
- [ ] Web accessible: `http://your-server-ip/model-generator/`
- [ ] No conflicts with pterodactyl or other services

---

**Your app will be completely isolated and won't interfere with any existing services!** 🎉
