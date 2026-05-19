# 🚀 Deploy Enhanced SSH Terminal to ssh.cloudmc.online

## Current Status
- **Old SSH Terminal**: Running on port 5000 (Flask-based)
- **New Enhanced Terminal**: Ready to deploy on port 8095
- **Domain**: ssh.cloudmc.online
- **Cloudflare Tunnel**: Currently pointing to old terminal

---

## 📋 Pre-Deployment Checklist

- [ ] SSH access to the server running ssh.cloudmc.online
- [ ] Root/sudo privileges
- [ ] Backup of current installation
- [ ] Cloudflare tunnel credentials

---

## 🔧 Step-by-Step Deployment

### **Step 1: SSH to Your Server**

```bash
# SSH to your server (replace with your actual server)
ssh root@your-server-ip

# Or if using a specific user
ssh your-user@your-server-ip
```

---

### **Step 2: Backup Current Installation**

```bash
# Create backup directory
sudo mkdir -p /var/backups/ssh-terminal-old

# Backup old SSH terminal
sudo tar -czf /var/backups/ssh-terminal-old/backup_$(date +%Y%m%d_%H%M%S).tar.gz \
    -C /opt ssh-terminal 2>/dev/null || echo "Old terminal not in /opt"

# Backup any existing new installation
if [ -d "/var/www/ssh-terminal" ]; then
    sudo tar -czf /var/backups/ssh-terminal-old/backup_new_$(date +%Y%m%d_%H%M%S).tar.gz \
        -C /var/www ssh-terminal
fi

echo "✅ Backups created in /var/backups/ssh-terminal-old/"
```

---

### **Step 3: Upload New Terminal Files**

**Option A: Using Git (Recommended)**

```bash
# Clone the repository
cd /tmp
git clone https://github.com/SirJBiscuit/automatic-system.git

# Or if already cloned, pull latest
cd /tmp/automatic-system
git pull origin main
```

**Option B: Using SCP (from your local machine)**

```bash
# From your Windows machine (PowerShell/CMD)
cd C:\Users\Jeremiah Payne\CascadeProjects\pteroanyinstall

# Upload web-terminal folder
scp -r web-terminal root@your-server-ip:/tmp/

# Or upload just the necessary files
scp web-terminal/index.html root@your-server-ip:/tmp/
scp web-terminal/ai-context.json root@your-server-ip:/tmp/
```

---

### **Step 4: Run Installation Script**

```bash
# If using Git method
cd /tmp/automatic-system
sudo bash install-ssh-terminal.sh

# If using SCP method, run deployment manually
cd /tmp
sudo bash web-terminal/deploy.sh
```

**The script will:**
- ✅ Install dependencies (nginx, ttyd)
- ✅ Create ttyd systemd service
- ✅ Deploy files to /var/www/ssh-terminal
- ✅ Configure Nginx on port 8095
- ✅ Set up firewall rules
- ✅ Verify installation

---

### **Step 5: Update Cloudflare Tunnel**

```bash
# Stop the old tunnel
sudo systemctl stop cloudflared-ssh

# Edit tunnel configuration
sudo nano /etc/cloudflared/ssh-tunnel.yml
```

**Update the configuration:**

```yaml
# Change this:
ingress:
  - hostname: ssh.cloudmc.online
    service: http://localhost:5000  # OLD

# To this:
ingress:
  - hostname: ssh.cloudmc.online
    service: http://localhost:8095  # NEW
  - service: http_status:404
```

**Save and exit** (Ctrl+X, Y, Enter)

```bash
# Restart tunnel
sudo systemctl restart cloudflared-ssh

# Verify tunnel is running
sudo systemctl status cloudflared-ssh
```

---

### **Step 6: Stop Old SSH Terminal**

```bash
# Stop old SSH terminal service
sudo systemctl stop ssh-terminal 2>/dev/null || echo "Old service not running"
sudo systemctl disable ssh-terminal 2>/dev/null || echo "Old service not enabled"

# Optional: Remove old installation (after verifying new one works)
# sudo rm -rf /opt/ssh-terminal
```

---

### **Step 7: Verify Deployment**

```bash
# Check if new terminal is accessible locally
curl -I http://localhost:8095

# Should return: HTTP/1.1 200 OK

# Check Nginx status
sudo systemctl status nginx

# Check ttyd service
sudo systemctl status ttyd

# Check Cloudflare tunnel
sudo systemctl status cloudflared-ssh
```

---

### **Step 8: Test in Browser**

1. Open browser
2. Navigate to: **https://ssh.cloudmc.online**
3. You should see the new Enhanced SSH Terminal login screen
4. Create admin password (first time setup)
5. Login and verify all features work

---

## 🔍 Troubleshooting

### **Issue: Port 8095 already in use**

```bash
# Check what's using port 8095
sudo lsof -i :8095

# Kill the process if needed
sudo kill -9 <PID>

# Restart nginx
sudo systemctl restart nginx
```

### **Issue: Cloudflare tunnel not updating**

```bash
# Check tunnel logs
sudo journalctl -u cloudflared-ssh -n 50

# Restart tunnel
sudo systemctl restart cloudflared-ssh

# Verify configuration
sudo cloudflared tunnel info
```

### **Issue: 502 Bad Gateway**

```bash
# Check if ttyd is running
sudo systemctl status ttyd

# Check if nginx is running
sudo systemctl status nginx

# Check nginx error logs
sudo tail -f /var/log/nginx/error.log
```

### **Issue: Login screen not appearing**

```bash
# Check file permissions
ls -la /var/www/ssh-terminal/

# Should be owned by www-data
sudo chown -R www-data:www-data /var/www/ssh-terminal
sudo chmod -R 755 /var/www/ssh-terminal
```

---

## 🔄 Rollback Procedure

**If something goes wrong:**

```bash
# Stop new services
sudo systemctl stop nginx
sudo systemctl stop ttyd

# Restore old terminal
sudo systemctl start ssh-terminal

# Revert Cloudflare tunnel config
sudo nano /etc/cloudflared/ssh-tunnel.yml
# Change port back to 5000

sudo systemctl restart cloudflared-ssh
```

---

## ✅ Post-Deployment Checklist

- [ ] https://ssh.cloudmc.online loads successfully
- [ ] Login screen appears
- [ ] Can create admin password
- [ ] Can login successfully
- [ ] Terminal sessions work
- [ ] AI assistant accessible
- [ ] Widgets can be created
- [ ] Scripts can be saved
- [ ] Mobile responsive works
- [ ] Old terminal stopped

---

## 📊 Service Status Commands

```bash
# Check all services
sudo systemctl status nginx
sudo systemctl status ttyd
sudo systemctl status cloudflared-ssh

# View logs
sudo journalctl -u nginx -n 50
sudo journalctl -u ttyd -n 50
sudo journalctl -u cloudflared-ssh -n 50

# Restart services
sudo systemctl restart nginx
sudo systemctl restart ttyd
sudo systemctl restart cloudflared-ssh
```

---

## 🎉 Success!

Once deployed, you'll have:

✅ **Modern Enhanced SSH Terminal** at https://ssh.cloudmc.online
✅ **AI Assistant** with Qwen2.5 7B
✅ **Custom Widgets** (notes, monitors, clocks, calculators)
✅ **Script Editor** (Bash, Python, JS, PowerShell)
✅ **Conversation History** and memories
✅ **Secure Authentication** with SHA-256 hashing
✅ **Mobile Responsive** design
✅ **Production Security** (CSP, XSS protection, rate limiting)

---

## 📞 Need Help?

If you encounter issues:

1. Check logs: `sudo journalctl -u nginx -n 100`
2. Verify ports: `sudo netstat -tlnp | grep -E "8095|7681"`
3. Test locally: `curl http://localhost:8095`
4. Check firewall: `sudo ufw status`

---

## 🔐 Important Notes

- **First Login**: You'll be prompted to create an admin password
- **Password**: Use a strong password (min 6 characters)
- **Security**: All passwords are SHA-256 hashed
- **Session**: Stays logged in until browser tab closes
- **Backup**: Old terminal backed up to /var/backups/ssh-terminal-old/

---

**Ready to deploy? Follow the steps above!** 🚀
