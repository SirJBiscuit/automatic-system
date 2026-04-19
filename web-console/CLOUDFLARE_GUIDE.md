# 🌐 Cloudflare Tunnel Guide for Web Console

## 📋 **Overview**

Access your Pterodactyl Web Console from anywhere using a custom domain like `web.cloudmc.online` through Cloudflare Tunnel.

---

## 🎯 **Two Access Methods**

### **Method 1: Local Network (Default)** 🏠
- **URL:** `http://YOUR_SERVER_IP:8080`
- **Access:** Local network only
- **Setup:** Automatic (no configuration needed)
- **Best for:** Home networks, VPN users, single location

### **Method 2: Cloudflare Tunnel (Optional)** 🌍
- **URL:** `https://web.cloudmc.online` (your custom domain)
- **Access:** From anywhere in the world
- **Setup:** 5-minute configuration
- **Best for:** Remote access, multiple admins, mobile access

### **Method 3: Both** 🔄
- Use local access when at home
- Use Cloudflare when away
- Maximum flexibility

---

## 🚀 **Quick Setup**

### **Option A: During Installation**

When installing the web console, you'll be asked:
```
Would you like to set up remote access via Cloudflare Tunnel? (y/n):
```

- Press **Y** to set up Cloudflare Tunnel
- Press **N** to use local access only (can add later)

### **Option B: After Installation**

```bash
cd /opt/pterodactyl-web-console
sudo bash setup-access.sh
```

Choose your preferred method:
1. Local Network Access
2. Cloudflare Tunnel
3. Both

---

## 📖 **Detailed Cloudflare Setup**

### **Prerequisites**

1. **Domain Name**
   - Own a domain (e.g., `cloudmc.online`)
   - Free options: Freenom (.tk, .ml, .ga, .cf, .gq)
   - Paid options: Namecheap, Google Domains, Cloudflare Registrar

2. **Cloudflare Account**
   - Sign up at [cloudflare.com](https://cloudflare.com) (free)
   - Add your domain to Cloudflare
   - Update nameservers at your registrar

### **Step-by-Step Guide**

#### **Step 1: Get a Domain**

**Free Option (Freenom):**
1. Go to [freenom.com](https://freenom.com)
2. Search for available domain
3. Select `.tk`, `.ml`, `.ga`, `.cf`, or `.gq`
4. Register for free (12 months)

**Paid Option:**
1. Buy from Namecheap, Google Domains, etc.
2. Any TLD works (.com, .net, .online, etc.)

#### **Step 2: Add Domain to Cloudflare**

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Click **"Add a Site"**
3. Enter your domain (e.g., `cloudmc.online`)
4. Select **Free plan**
5. Click **"Add site"**
6. Cloudflare will scan your DNS records
7. Click **"Continue"**
8. Note the nameservers provided (e.g., `ns1.cloudflare.com`)

#### **Step 3: Update Nameservers**

At your domain registrar:
1. Find DNS/Nameserver settings
2. Replace existing nameservers with Cloudflare's
3. Save changes
4. Wait 5-60 minutes for propagation

Cloudflare will email you when it's active.

#### **Step 4: Run Cloudflare Setup**

```bash
cd /opt/pterodactyl-web-console
sudo bash cloudflare-tunnel.sh
```

**You'll be prompted for:**

1. **Subdomain** (e.g., `web`)
   - This creates `web.cloudmc.online`
   - Can be anything: `console`, `panel`, `admin`, etc.

2. **Domain** (e.g., `cloudmc.online`)
   - Your domain from Step 1

3. **Cloudflare Login**
   - A browser will open
   - Log in to your Cloudflare account
   - Authorize the tunnel

**The script will:**
- ✅ Install cloudflared
- ✅ Create a tunnel
- ✅ Configure DNS automatically
- ✅ Set up HTTPS
- ✅ Start the service

#### **Step 5: Access Your Console**

After 2-5 minutes:
```
https://web.cloudmc.online
```

---

## 🎨 **Example Domains**

You can use any subdomain you want:

- `https://web.cloudmc.online`
- `https://console.cloudmc.online`
- `https://panel.cloudmc.online`
- `https://admin.cloudmc.online`
- `https://servers.cloudmc.online`
- `https://dashboard.cloudmc.online`

---

## 🔧 **Service Management**

### **Check Status**
```bash
sudo systemctl status cloudflared-webconsole
```

### **View Logs**
```bash
sudo journalctl -u cloudflared-webconsole -f
```

### **Restart**
```bash
sudo systemctl restart cloudflared-webconsole
```

### **Stop**
```bash
sudo systemctl stop cloudflared-webconsole
```

### **Start**
```bash
sudo systemctl start cloudflared-webconsole
```

---

## 🔄 **Switching Access Methods**

### **Add Cloudflare to Existing Local Setup**
```bash
cd /opt/pterodactyl-web-console
sudo bash cloudflare-tunnel.sh
```

### **Remove Cloudflare Tunnel**
```bash
sudo systemctl stop cloudflared-webconsole
sudo systemctl disable cloudflared-webconsole
sudo rm /etc/systemd/system/cloudflared-webconsole.service
sudo systemctl daemon-reload
```

Local access will still work at `http://YOUR_IP:8080`

---

## 🛡️ **Security Features**

### **Cloudflare Tunnel Provides:**
- ✅ **Automatic HTTPS** - SSL/TLS encryption
- ✅ **DDoS Protection** - Cloudflare's network
- ✅ **No Open Ports** - No port forwarding needed
- ✅ **IP Hiding** - Server IP not exposed
- ✅ **WAF** - Web Application Firewall (optional)
- ✅ **Rate Limiting** - Prevent brute force

### **Additional Security (Optional)**

#### **1. Cloudflare Access (Zero Trust)**
Add authentication before accessing:
1. Go to Cloudflare Dashboard
2. Navigate to **Zero Trust** → **Access**
3. Create an application for your domain
4. Add authentication (Google, GitHub, email OTP)

#### **2. IP Restrictions**
Limit access to specific countries:
1. Go to **Security** → **WAF**
2. Create a firewall rule
3. Block/allow specific countries

---

## 💰 **Cost Breakdown**

### **Free Option**
- Domain: **Free** (Freenom)
- Cloudflare: **Free** (Free plan)
- Tunnel: **Free** (Included)
- **Total: $0/year**

### **Paid Option**
- Domain: **$10-15/year** (Namecheap, Google)
- Cloudflare: **Free** (Free plan)
- Tunnel: **Free** (Included)
- **Total: $10-15/year**

---

## 🐛 **Troubleshooting**

### **Tunnel Not Working**

1. **Check service status:**
   ```bash
   sudo systemctl status cloudflared-webconsole
   ```

2. **View logs:**
   ```bash
   sudo journalctl -u cloudflared-webconsole -n 50
   ```

3. **Verify DNS:**
   ```bash
   nslookup web.cloudmc.online
   ```

4. **Restart tunnel:**
   ```bash
   sudo systemctl restart cloudflared-webconsole
   ```

### **Domain Not Resolving**

- Wait 5-10 minutes for DNS propagation
- Check nameservers are updated at registrar
- Verify domain is active in Cloudflare

### **502 Bad Gateway**

- Web console service might be down:
  ```bash
  sudo systemctl status pterodactyl-web-console
  sudo systemctl restart pterodactyl-web-console
  ```

### **Authentication Failed**

- Re-run cloudflare login:
  ```bash
  cloudflared tunnel login
  ```

---

## 📊 **Comparison**

| Feature | Local Access | Cloudflare Tunnel |
|---------|-------------|-------------------|
| **Access** | Local network only | Anywhere |
| **URL** | `http://IP:8080` | `https://custom.domain` |
| **HTTPS** | ❌ No | ✅ Yes (automatic) |
| **Setup** | ✅ Automatic | 5 minutes |
| **Cost** | Free | Free |
| **Port Forwarding** | Required for remote | ❌ Not needed |
| **DDoS Protection** | ❌ No | ✅ Yes |
| **Custom Domain** | ❌ No | ✅ Yes |
| **Mobile Access** | VPN needed | ✅ Direct |

---

## 🎯 **Use Cases**

### **Scenario 1: Home User**
- **Use:** Local access
- **Why:** Only access from home network
- **Setup:** Default (no configuration)

### **Scenario 2: Multiple Locations**
- **Use:** Cloudflare Tunnel
- **Why:** Access from work, home, mobile
- **Setup:** 5-minute Cloudflare setup

### **Scenario 3: Team Management**
- **Use:** Cloudflare Tunnel + Access
- **Why:** Multiple admins, secure access
- **Setup:** Cloudflare + Zero Trust

### **Scenario 4: Hybrid**
- **Use:** Both methods
- **Why:** Local when home, remote when away
- **Setup:** Keep both running

---

## 📝 **Quick Reference**

### **Setup Commands**
```bash
# Choose access method
sudo bash /opt/pterodactyl-web-console/setup-access.sh

# Set up Cloudflare only
sudo bash /opt/pterodactyl-web-console/cloudflare-tunnel.sh

# Check tunnel status
sudo systemctl status cloudflared-webconsole

# View tunnel logs
sudo journalctl -u cloudflared-webconsole -f
```

### **Access URLs**
```
Local:      http://YOUR_SERVER_IP:8080
Cloudflare: https://web.cloudmc.online (your domain)
```

---

## 🎉 **Summary**

**Cloudflare Tunnel gives you:**
- ✅ Access from anywhere
- ✅ Custom domain (looks professional)
- ✅ Automatic HTTPS
- ✅ DDoS protection
- ✅ No port forwarding
- ✅ Free forever

**Perfect for:**
- Remote server management
- Multiple administrators
- Mobile access
- Professional setup

**The choice is yours!** 🚀✨
