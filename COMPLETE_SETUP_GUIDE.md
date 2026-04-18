# 🚀 Complete Pterodactyl Server Setup Guide
## From Zero to Fully Automated with P.R.I.S.M

---

## 📋 **Overview**

This guide will take you through:
1. ✅ Setting up Git and GitHub
2. ✅ Preparing your server
3. ✅ Installing Pterodactyl Panel & Wings
4. ✅ Customizing your panel
5. ✅ Setting up P.R.I.S.M AI Assistant
6. ✅ Configuring automation and monitoring

**Estimated Time:** 2-3 hours  
**Difficulty:** Beginner-friendly

---

# PART 1: GIT & GITHUB SETUP

## Step 1: Install Git on Your Local Machine

### Windows:
```powershell
# Download Git from https://git-scm.com/download/win
# Or use winget:
winget install --id Git.Git -e --source winget

# Verify installation
git --version
```

### Linux/macOS:
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install git

# CentOS/RHEL
sudo yum install git

# macOS
brew install git

# Verify installation
git --version
```

## Step 2: Configure Git

```bash
# Set your name and email (use your GitHub email)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Verify configuration
git config --list
```

## Step 3: Create GitHub Account

1. Go to https://github.com
2. Click "Sign up"
3. Follow the registration process
4. Verify your email address

## Step 4: Create Your Repository

### Option A: Via GitHub Website (Easiest)

1. Log into GitHub
2. Click the "+" icon (top right) → "New repository"
3. Repository name: `pteroanyinstall`
4. Description: "Automated Pterodactyl installation with AI assistant"
5. Choose "Public" (or Private if you prefer)
6. ✅ Check "Add a README file"
7. Choose license: "MIT License" (recommended)
8. Click "Create repository"

### Option B: Via Command Line

```bash
# Navigate to your project directory
cd C:\Users\Jeremiah Payne\CascadeProjects\pteroanyinstall

# Initialize Git repository
git init

# Add all files
git add .

# Create first commit
git commit -m "Initial commit: Pterodactyl automation scripts with P.R.I.S.M"

# Create repository on GitHub first, then:
git remote add origin https://github.com/YOUR_USERNAME/pteroanyinstall.git
git branch -M main
git push -u origin main
```

## Step 5: Push Your Code to GitHub

```bash
# Navigate to your project
cd C:\Users\Jeremiah Payne\CascadeProjects\pteroanyinstall

# Initialize Git (if not already done)
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit: Complete Pterodactyl automation suite with P.R.I.S.M AI"

# Add remote (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/pteroanyinstall.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## Step 6: Set Up GitHub Authentication

### Option A: Personal Access Token (Recommended)

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Note: "pteroanyinstall access"
4. Select scopes:
   - ✅ repo (all)
   - ✅ workflow
5. Click "Generate token"
6. **COPY THE TOKEN** (you won't see it again!)
7. Use this token as your password when pushing to GitHub

### Option B: SSH Key

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"

# Press Enter to accept default location
# Enter a passphrase (optional)

# Copy public key
# Windows:
type %USERPROFILE%\.ssh\id_ed25519.pub

# Linux/macOS:
cat ~/.ssh/id_ed25519.pub

# Add to GitHub:
# 1. Go to GitHub → Settings → SSH and GPG keys
# 2. Click "New SSH key"
# 3. Paste your public key
# 4. Click "Add SSH key"

# Test connection
ssh -T git@github.com

# Change remote to SSH
git remote set-url origin git@github.com:YOUR_USERNAME/pteroanyinstall.git
```

## Step 7: Verify GitHub Setup

```bash
# Check remote
git remote -v

# Should show:
# origin  https://github.com/YOUR_USERNAME/pteroanyinstall.git (fetch)
# origin  https://github.com/YOUR_USERNAME/pteroanyinstall.git (push)

# Or with SSH:
# origin  git@github.com:YOUR_USERNAME/pteroanyinstall.git (fetch)
# origin  git@github.com:YOUR_USERNAME/pteroanyinstall.git (push)
```

## Step 8: Update Repository URLs in Scripts

Update the repository URL in `install.sh`:

```bash
# Edit install.sh
nano install.sh

# Change this line:
REPO_URL="https://raw.githubusercontent.com/yourusername/pteroanyinstall/main"

# To:
REPO_URL="https://raw.githubusercontent.com/YOUR_USERNAME/pteroanyinstall/main"

# Save and commit
git add install.sh
git commit -m "Update repository URL"
git push
```

## Step 9: Test One-Line Installation

```bash
# This should now work from any server:
bash <(curl -s https://raw.githubusercontent.com/YOUR_USERNAME/pteroanyinstall/main/install.sh)
```

---

# PART 2: SERVER PREPARATION

## Step 1: Get a Server

### Recommended Providers:
- **Hetzner** - Best value (€4-20/month)
- **DigitalOcean** - Easy to use ($6-40/month)
- **Vultr** - Good performance ($6-40/month)
- **OVH** - Budget-friendly (€5-30/month)

### Minimum Requirements:
- **OS:** Ubuntu 20.04/22.04 or Debian 11/12
- **RAM:** 4GB minimum (8GB recommended)
- **CPU:** 2 cores minimum (4 cores recommended)
- **Disk:** 40GB minimum (100GB+ recommended)
- **Network:** 100Mbps minimum

## Step 2: Initial Server Access

```bash
# SSH into your server
ssh root@YOUR_SERVER_IP

# Update system
apt update && apt upgrade -y

# Reboot if kernel was updated
reboot
```

## Step 3: Basic Security Setup

```bash
# Create a new user (optional but recommended)
adduser pteroadmin
usermod -aG sudo pteroadmin

# Set up firewall
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 8080/tcp  # Wings
ufw allow 2022/tcp  # Wings SFTP
ufw enable

# Verify firewall
ufw status
```

## Step 4: Set Up Domain & DNS

### Get a Domain:
- **Namecheap** - $8-15/year
- **Cloudflare Registrar** - At-cost pricing
- **Google Domains** - $12/year

### DNS Setup:

1. **For Panel:**
   - Type: `A`
   - Name: `panel` (or `@` for root domain)
   - Value: `YOUR_SERVER_IP`
   - TTL: `Auto` or `300`

2. **For Node (Wings):**
   - Type: `A`
   - Name: `node1` (or `node`)
   - Value: `YOUR_SERVER_IP`
   - TTL: `Auto` or `300`

3. **Wait for DNS propagation** (5-30 minutes)

### Verify DNS:
```bash
# Check if DNS is working
nslookup panel.yourdomain.com
nslookup node1.yourdomain.com

# Or use dig
dig panel.yourdomain.com
dig node1.yourdomain.com
```

## Step 5: Optional - Cloudflare Setup

1. Go to https://cloudflare.com
2. Add your domain
3. Update nameservers at your registrar
4. Set SSL/TLS mode to "Full (strict)"
5. Enable "Always Use HTTPS"

---

# PART 3: INSTALL PTERODACTYL

## Step 1: Download Installation Scripts

```bash
# One-line installation
bash <(curl -s https://raw.githubusercontent.com/YOUR_USERNAME/pteroanyinstall/main/install.sh)

# This will download all scripts to /opt/ptero
cd /opt/ptero
```

## Step 2: Run Pre-Installation Checks

```bash
cd /opt/ptero
./pteroanyinstall.sh pre-check

# This will check:
# - Existing Pterodactyl installation
# - DNS configuration
# - Port forwarding
# - System requirements
```

## Step 3: Install Pterodactyl Panel

```bash
cd /opt/ptero
./pteroanyinstall.sh panel

# You'll be asked for:
# - Domain name (e.g., panel.yourdomain.com)
# - Email for SSL certificate
# - Database password
# - Admin user details
```

### What Gets Installed:
- ✅ Nginx web server
- ✅ MySQL/MariaDB database
- ✅ PHP 8.1+ with extensions
- ✅ Redis cache
- ✅ Pterodactyl Panel
- ✅ SSL certificate (Let's Encrypt)
- ✅ Firewall rules

**Installation Time:** 15-30 minutes

## Step 4: Install Pterodactyl Wings

```bash
cd /opt/ptero
./pteroanyinstall.sh wings

# You'll be asked for:
# - Panel URL (e.g., https://panel.yourdomain.com)
# - Node FQDN (e.g., node1.yourdomain.com)
```

### What Gets Installed:
- ✅ Docker
- ✅ Pterodactyl Wings
- ✅ SSL certificate for node
- ✅ SFTP server
- ✅ Firewall rules

**Installation Time:** 10-20 minutes

## Step 5: Configure Node in Panel

1. Log into your Panel: `https://panel.yourdomain.com`
2. Go to **Admin Panel** → **Locations**
3. Create a new location (e.g., "Main Datacenter")
4. Go to **Nodes** → **Create New**
5. Fill in details:
   - **Name:** `Node 1`
   - **Location:** Select your location
   - **FQDN:** `node1.yourdomain.com`
   - **Communicate Over SSL:** ✅ Yes
   - **Behind Proxy:** ✅ Yes (if using Cloudflare)
   - **Memory:** Your server RAM (e.g., 8192 MB)
   - **Disk:** Your available disk (e.g., 100000 MB)
6. Click **Create Node**
7. Go to **Configuration** tab
8. Copy the configuration command
9. Run it on your server:

```bash
# Paste the command from the panel
# It will look like:
cd /etc/pterodactyl
./wings configure --panel-url https://panel.yourdomain.com --token YOUR_TOKEN --node YOUR_NODE_ID

# Start Wings
systemctl start wings
systemctl enable wings

# Check status
systemctl status wings
```

---

# PART 4: CUSTOMIZE YOUR PANEL

## Step 1: Run Panel Customizer

```bash
cd /opt/ptero
./pteroanyinstall.sh customize

# You'll be able to customize:
# - Logo (upload or URL)
# - Background (image, gradient, or solid color)
# - Color scheme (primary/secondary colors)
# - Company name
# - Favicon
```

### Tips:
- Use **Imgur** or **ImgBB** for free image hosting
- Choose colors that match your brand
- Keep logo simple and readable
- Test on mobile devices

## Step 2: Set Up Billing (Optional)

```bash
cd /opt/ptero
./pteroanyinstall.sh billing

# Choose your billing system:
# 1. WHMCS
# 2. Blesta
# 3. HostBill
# 4. Custom integration
```

---

# PART 5: SET UP P.R.I.S.M AI ASSISTANT

## Step 1: Install AI Assistant

```bash
cd /opt/ptero
./pteroanyinstall.sh ai-assistant

# You'll be asked:
# 1. AI Model: Choose Gemma2:1b (recommended) or 4b
# 2. LLM Hosting Mode: Yes if hosting LLM game servers
# 3. Discord Webhook: Optional (recommended)
# 4. Pterodactyl API: Optional (recommended)
```

### Installation Process:
1. **Ollama Installation** (~5 minutes)
2. **AI Model Download** (~10 minutes for 1b, ~20 minutes for 4b)
3. **Service Setup** (~2 minutes)
4. **Discord Configuration** (optional, ~2 minutes)
5. **API Configuration** (optional, ~2 minutes)

## Step 2: Configure Discord Notifications

### Get Discord Webhook:
1. Open your Discord server
2. Go to **Server Settings** → **Integrations** → **Webhooks**
3. Click **New Webhook**
4. Name it "P.R.I.S.M"
5. Choose a channel (e.g., #server-alerts)
6. Click **Copy Webhook URL**

### Configure in P.R.I.S.M:
```bash
chatbot webhook setup
# Paste your webhook URL
# Test message will be sent automatically
```

## Step 3: Configure Pterodactyl API

### Get API Key:
1. Log into Pterodactyl Panel
2. Go to **Account** → **API Credentials**
3. Click **Create API Key**
4. Description: "P.R.I.S.M Monitoring"
5. Select **all permissions**
6. Click **Create**
7. **Copy the API key** (you won't see it again!)

### Configure in P.R.I.S.M:
```bash
chatbot api setup
# Enter Panel URL: https://panel.yourdomain.com
# Enter API Key: (paste your key)
# Connection will be tested automatically
```

## Step 4: Run First System Analysis

```bash
chatbot detect

# P.R.I.S.M will:
# - Analyze your entire system
# - Check PHP, MySQL, Nginx, Redis
# - Scan for security issues
# - Provide optimization recommendations
# - Offer to apply automatic fixes
```

## Step 5: Verify P.R.I.S.M is Running

```bash
# Check status
chatbot status

# Should show:
# 🤖 P.R.I.S.M: Online and monitoring

# View logs
chatbot logs

# Ask AI a question
chatbot ask "Is everything running correctly?"
```

---

# PART 6: QUICK WINS & AUTOMATION

## Step 1: Set Up Quick Wins

```bash
cd /opt/ptero
./pteroanyinstall.sh quick-setup

# This sets up:
# ✅ SSL certificate monitoring
# ✅ Fail2ban security
# ✅ Automated backups
# ✅ Health dashboard
# ✅ Update notifications
```

## Step 2: Configure Automated Backups

```bash
# Backups are automatically configured to run daily at 2 AM
# Location: /var/backups/pterodactyl/

# Test backup manually
/opt/ptero-backup/backup.sh

# Verify backup
ls -lh /var/backups/pterodactyl/

# Set up remote backup (optional)
# Edit backup script to add rsync/rclone
nano /opt/ptero-backup/backup.sh
```

## Step 3: Set Up Monitoring Dashboard

```bash
# Access health dashboard
ptero-health

# Shows:
# - Service status
# - Resource usage
# - Recent alerts
# - Backup status
# - SSL certificate expiry
```

---

# PART 7: FINAL CONFIGURATION

## Step 1: Create Your First Server

1. Log into Panel: `https://panel.yourdomain.com`
2. Go to **Admin Panel** → **Servers** → **Create New**
3. Fill in server details:
   - **Name:** Test Server
   - **Owner:** Select user
   - **Node:** Select your node
   - **Egg:** Minecraft (or your choice)
   - **Allocations:** Select IP:Port
   - **Memory:** 2048 MB
   - **Disk:** 5000 MB
   - **CPU:** 100%
4. Click **Create Server**
5. Test the server works

## Step 2: Set Up Admin Panel Access

```bash
cd /opt/ptero
./pteroanyinstall.sh admin

# This opens the admin control panel
# You can:
# - View system health
# - Manage services
# - Configure security
# - Run backups
# - Check updates
```

## Step 3: Configure Email (Optional)

```bash
# Edit Panel .env file
nano /var/www/pterodactyl/.env

# Add SMTP settings:
MAIL_DRIVER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=your-email@gmail.com
MAIL_FROM_NAME="Your Server Name"

# Clear cache
cd /var/www/pterodactyl
php artisan config:clear
php artisan cache:clear
```

## Step 4: Security Hardening

```bash
# Install Fail2ban (if not already done)
apt install fail2ban -y

# Configure Fail2ban for Pterodactyl
cat > /etc/fail2ban/jail.local <<EOF
[pterodactyl]
enabled = true
port = http,https
filter = pterodactyl
logpath = /var/www/pterodactyl/storage/logs/*.log
maxretry = 3
bantime = 3600
EOF

# Restart Fail2ban
systemctl restart fail2ban

# Check SSH security
nano /etc/ssh/sshd_config
# Set: PermitRootLogin no
# Set: PasswordAuthentication no (if using SSH keys)

systemctl restart sshd
```

---

# PART 8: TESTING & VERIFICATION

## Checklist:

### Panel Tests:
- [ ] Panel accessible at `https://panel.yourdomain.com`
- [ ] SSL certificate valid (green padlock)
- [ ] Can log in as admin
- [ ] Can create users
- [ ] Can create servers
- [ ] Email notifications working (if configured)

### Wings Tests:
- [ ] Wings service running: `systemctl status wings`
- [ ] Node shows online in Panel
- [ ] Can start/stop test server
- [ ] Can access server console
- [ ] SFTP working
- [ ] File manager working

### P.R.I.S.M Tests:
- [ ] P.R.I.S.M running: `chatbot status`
- [ ] Discord notifications working: `chatbot webhook test`
- [ ] API connection working: `chatbot api test`
- [ ] System analysis working: `chatbot detect`
- [ ] AI responses working: `chatbot ask "test"`

### Automation Tests:
- [ ] Backups running: Check `/var/backups/pterodactyl/`
- [ ] SSL monitoring active
- [ ] Fail2ban protecting services
- [ ] Health dashboard accessible: `ptero-health`

---

# PART 9: DAILY OPERATIONS

## Daily Commands:

```bash
# Check P.R.I.S.M status
chatbot status

# View system health
ptero-health

# Check for issues
chatbot detect

# View logs
chatbot logs

# Ask AI for help
chatbot ask "Any issues today?"
```

## Weekly Tasks:

```bash
# Run full system optimization
chatbot detect

# Check backups
ls -lh /var/backups/pterodactyl/

# Update system
apt update && apt upgrade -y

# Check for Pterodactyl updates
cd /var/www/pterodactyl
php artisan p:upgrade:check
```

## Monthly Tasks:

```bash
# Review security
fail2ban-client status

# Check disk usage
df -h

# Review logs
chatbot ask "Show me any issues from the past month"

# Test backup restoration (important!)
# Restore to a test environment
```

---

# TROUBLESHOOTING

## Panel Not Accessible

```bash
# Check Nginx
systemctl status nginx
systemctl restart nginx

# Check PHP-FPM
systemctl status php8.1-fpm
systemctl restart php8.1-fpm

# Check logs
tail -f /var/log/nginx/error.log
tail -f /var/www/pterodactyl/storage/logs/laravel-$(date +%Y-%m-%d).log
```

## Wings Not Connecting

```bash
# Check Wings status
systemctl status wings

# Check Wings logs
journalctl -u wings -n 100

# Restart Wings
systemctl restart wings

# Verify configuration
cat /etc/pterodactyl/config.yml
```

## P.R.I.S.M Not Working

```bash
# Check service
systemctl status ptero-assistant

# Check logs
chatbot logs

# Restart P.R.I.S.M
chatbot restart

# Check Ollama
systemctl status ollama
```

## Database Issues

```bash
# Check MySQL
systemctl status mysql

# Access MySQL
mysql -u root -p

# Check Pterodactyl database
USE panel;
SHOW TABLES;

# Repair tables if needed
mysqlcheck -u root -p --auto-repair --all-databases
```

---

# NEXT STEPS

## Recommended Actions:

1. **Set up monitoring** - Configure Discord for instant alerts
2. **Create backup schedule** - Automate daily backups
3. **Add more nodes** - Scale your infrastructure
4. **Configure billing** - Start monetizing your service
5. **Customize branding** - Make it your own
6. **Join community** - Get support and share knowledge

## Useful Resources:

- **Pterodactyl Docs:** https://pterodactyl.io/
- **Discord Community:** https://discord.gg/pterodactyl
- **Your GitHub Repo:** https://github.com/YOUR_USERNAME/pteroanyinstall
- **P.R.I.S.M Commands:** `chatbot help`

---

# QUICK REFERENCE

## Essential Commands:

```bash
# P.R.I.S.M
chatbot status              # Check status
chatbot detect              # Run analysis
chatbot ask "question"      # Ask AI
chatbot webhook setup       # Configure Discord
chatbot api setup           # Configure API
chatbot help                # Show all commands

# Services
systemctl status nginx      # Check Nginx
systemctl status wings      # Check Wings
systemctl status mysql      # Check MySQL
systemctl status redis      # Check Redis

# Pterodactyl
cd /var/www/pterodactyl     # Panel directory
php artisan cache:clear     # Clear cache
php artisan queue:restart   # Restart queue

# Logs
chatbot logs                # P.R.I.S.M logs
tail -f /var/log/nginx/error.log
journalctl -u wings -f
tail -f /var/www/pterodactyl/storage/logs/laravel-*.log

# Backups
ls /var/backups/pterodactyl/
/opt/ptero-backup/backup.sh

# Updates
apt update && apt upgrade -y
cd /var/www/pterodactyl && php artisan p:upgrade:check
```

---

# 🎉 CONGRATULATIONS!

You now have a fully automated Pterodactyl server with:
- ✅ Professional panel installation
- ✅ Wings node configured
- ✅ P.R.I.S.M AI assistant monitoring 24/7
- ✅ Discord notifications
- ✅ Automated backups
- ✅ Security hardening
- ✅ Custom branding
- ✅ Complete automation

**Your server is production-ready!** 🚀

---

**Need help?** Run `chatbot ask "your question"` - P.R.I.S.M is always ready to help!
