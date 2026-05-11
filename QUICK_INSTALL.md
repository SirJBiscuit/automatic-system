# Quick Install Commands

Ultra-short installation commands for easy copy-paste!

## 🚀 Main Installer

```bash
curl -sL bit.ly/ptero-auto | bash
```

Or using the GitHub short URL:

```bash
curl -sL git.io/pterodactyl-auto | bash
```

Or direct:

```bash
bash <(curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/installer.sh)
```

---

## 📱 Termux SSH Setup

**Shortest:**
```bash
curl -sL bit.ly/termux-ssh | bash
```

**Alternative:**
```bash
bash <(curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/termux-ssh-setup.sh)
```

**Or download first:**
```bash
curl -O https://git.io/termux-ssh.sh && bash termux-ssh.sh
```

---

## 🔐 Cloudflare SSH Tunnel Only

```bash
bash <(curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/cloudflare-ssh-tunnel.sh)
```

---

## 📦 Individual Components

### Panel Only
```bash
curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/installer.sh | bash -s -- --panel-only
```

### Wings Only
```bash
curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/installer.sh | bash -s -- --wings-only
```

### AI Assistant Only
```bash
curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/ai-assisted-install.sh | bash
```

---

## 🎯 Feature-Specific Installs

### Network Setup Wizard
```bash
bash <(curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/network-setup-wizard.sh)
```

### Firewall Manager
```bash
bash <(curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/firewall-manager.sh) auto
```

### IP Monitor
```bash
bash <(curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/ip-monitor.sh) install
```

---

## 📋 How to Create Your Own Short URLs

### Using bit.ly (Recommended)
1. Go to https://bitly.com
2. Paste your GitHub raw URL
3. Create custom short link
4. Example: `bit.ly/termux-ssh`

### Using git.io (GitHub's URL Shortener)
```bash
curl -i https://git.io -F "url=https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/termux-ssh-setup.sh" -F "code=termux-ssh"
```

### Using TinyURL
```bash
curl "http://tinyurl.com/api-create.php?url=https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/termux-ssh-setup.sh"
```

---

## 🔗 QR Codes for Mobile

Generate QR codes for easy mobile access:

### Termux SSH QR Code
```
https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=bash%20%3C(curl%20-sL%20https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/termux-ssh-setup.sh)
```

### Main Installer QR Code
```
https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=bash%20%3C(curl%20-sL%20https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/installer.sh)
```

---

## 💡 Tips

### Save as Alias
Add to your `~/.bashrc` or `~/.zshrc`:

```bash
alias install-termux-ssh='bash <(curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/termux-ssh-setup.sh)'
alias install-pterodactyl='bash <(curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/installer.sh)'
```

### One-Liner with Auto-Yes
```bash
yes | bash <(curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/termux-ssh-setup.sh)
```

### Silent Install (No Output)
```bash
bash <(curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/termux-ssh-setup.sh) &>/dev/null
```

---

## 🌐 CDN Mirrors (Faster Downloads)

### jsDelivr CDN
```bash
bash <(curl -sL https://cdn.jsdelivr.net/gh/SirJBiscuit/automatic-system@main/termux-ssh-setup.sh)
```

### Statically CDN
```bash
bash <(curl -sL https://cdn.statically.io/gh/SirJBiscuit/automatic-system/main/termux-ssh-setup.sh)
```

---

## 📱 For Termux Users

### Install in Termux
```bash
pkg install curl -y && bash <(curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/termux-ssh-setup.sh)
```

### Super Short Termux Command
```bash
pkg install curl -y && curl -sL bit.ly/termux-ssh | bash
```

---

## 🔒 Verify Before Running

Always verify scripts before running:

```bash
# View the script first
curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/termux-ssh-setup.sh | less

# Then run it
bash <(curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/termux-ssh-setup.sh)
```

---

## 📊 Comparison

| Method | Length | Speed | Notes |
|--------|--------|-------|-------|
| `bit.ly/termux-ssh` | 30 chars | Fast | Requires bit.ly setup |
| `bash <(curl -sL ...)` | 90 chars | Fast | Standard method |
| `curl -O && bash` | 60 chars | Medium | Downloads first |
| CDN mirrors | 95 chars | Fastest | Best for large files |

---

## 🎯 Recommended Short Commands

**For Documentation:**
```bash
bash <(curl -sL https://git.io/termux-ssh)
```

**For Quick Copy-Paste:**
```bash
curl -sL bit.ly/termux-ssh | bash
```

**For Reliability:**
```bash
bash <(curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/termux-ssh-setup.sh)
```
