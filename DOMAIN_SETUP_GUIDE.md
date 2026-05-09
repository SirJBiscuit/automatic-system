# 🌐 Domain & DNS Setup Guide

## Table of Contents
- [Understanding Domains](#understanding-domains)
- [DNS Record Types](#dns-record-types)
- [Cloudflare Setup](#cloudflare-setup)
- [Cloudflare Tunnels](#cloudflare-tunnels)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Understanding Domains

### What is a Domain?
A domain is your website's address on the internet (e.g., `example.com`, `google.com`)

### What is a Subdomain?
A subdomain is a prefix added to your main domain:
- `panel.example.com` - For Pterodactyl Panel
- `node1.example.com` - For Wings node
- `admin.example.com` - For Admin Panel
- `ssh.example.com` - For SSH Terminal

### Domain Structure
```
subdomain.domain.tld
    ↓       ↓     ↓
  panel  example com
```

### Where to Buy Domains
- **Namecheap** - https://namecheap.com (Recommended)
- **GoDaddy** - https://godaddy.com
- **Google Domains** - https://domains.google
- **Cloudflare** - https://cloudflare.com

**Cost:** Usually $10-15/year

---

## 📋 DNS Record Types

### A Record (Address Record)
**What it does:** Points a domain/subdomain to an IPv4 address

**Example:**
```
Type: A
Name: panel
Content: 192.168.1.100
TTL: Auto
```
Result: `panel.example.com` → `192.168.1.100`

**When to use:**
- ✅ Pointing to your server's IP
- ✅ Most common for Pterodactyl setup

### AAAA Record
**What it does:** Points a domain/subdomain to an IPv6 address

**Example:**
```
Type: AAAA
Name: panel
Content: 2001:0db8:85a3:0000:0000:8a2e:0370:7334
TTL: Auto
```

**When to use:**
- ✅ If you have IPv6 enabled
- ✅ Optional, but recommended for modern setups

### CNAME Record (Canonical Name)
**What it does:** Points a domain to another domain (alias)

**Example:**
```
Type: CNAME
Name: www
Content: example.com
TTL: Auto
```
Result: `www.example.com` → `example.com`

**When to use:**
- ✅ Creating aliases
- ❌ NOT for root domain (@)
- ❌ NOT recommended for Pterodactyl

### TXT Record
**What it does:** Stores text information for verification

**When to use:**
- ✅ Domain verification
- ✅ SPF records for email
- ✅ SSL certificate validation

---

## ☁️ Cloudflare Setup

### Why Use Cloudflare?
- ✅ **Free SSL certificates** - Automatic HTTPS
- ✅ **DDoS protection** - Protects against attacks
- ✅ **CDN** - Faster loading times
- ✅ **Analytics** - Traffic insights
- ✅ **Firewall** - Block malicious traffic
- ✅ **Tunnels** - Expose services without port forwarding

### Step-by-Step Cloudflare Setup

#### 1. Create Cloudflare Account
```
1. Go to https://cloudflare.com
2. Click "Sign Up"
3. Enter your email and create password
4. Verify your email
```

#### 2. Add Your Domain
```
1. Click "Add a Site"
2. Enter your domain (e.g., example.com)
3. Click "Add site"
4. Choose the FREE plan
5. Click "Continue"
```

#### 3. Review DNS Records
```
Cloudflare will scan your existing DNS records.

✓ Review the records
✓ Make sure important ones are listed
✓ Click "Continue"
```

#### 4. Change Nameservers
```
Cloudflare will provide 2 nameservers:
• ns1.cloudflare.com
• ns2.cloudflare.com

You need to update these at your domain registrar.
```

#### 5. Update Nameservers at Registrar

**For Namecheap:**
```
1. Log in to Namecheap
2. Go to "Domain List"
3. Click "Manage" next to your domain
4. Find "Nameservers" section
5. Select "Custom DNS"
6. Enter Cloudflare's nameservers:
   - ns1.cloudflare.com
   - ns2.cloudflare.com
7. Click "Save"
```

**For GoDaddy:**
```
1. Log in to GoDaddy
2. Go to "My Products"
3. Click "DNS" next to your domain
4. Scroll to "Nameservers"
5. Click "Change"
6. Select "Custom"
7. Enter Cloudflare's nameservers
8. Click "Save"
```

#### 6. Wait for Activation
```
⏳ Propagation time: 5 minutes to 48 hours
📧 You'll receive an email when active
✅ Status will show "Active" in Cloudflare
```

#### 7. Configure SSL/TLS
```
1. In Cloudflare, go to "SSL/TLS"
2. Set encryption mode to "Full (strict)"
3. Enable "Always Use HTTPS"
4. Enable "Automatic HTTPS Rewrites"
```

### Adding DNS Records in Cloudflare

#### For Pterodactyl Panel
```
Type: A
Name: panel
IPv4 address: [Your Server IP]
Proxy status: Proxied (Orange cloud)
TTL: Auto
```

#### For Wings Node
```
Type: A
Name: node1
IPv4 address: [Your Server IP]
Proxy status: DNS only (Gray cloud) ⚠️
TTL: Auto
```
**Important:** Wings MUST be "DNS only" (gray cloud), not proxied!

#### For Admin Panel
```
Type: A
Name: admin
IPv4 address: [Your Server IP]
Proxy status: Proxied (Orange cloud)
TTL: Auto
```

#### For SSH Terminal
```
Type: A
Name: ssh
IPv4 address: [Your Server IP]
Proxy status: Proxied (Orange cloud)
TTL: Auto
```

### Cloudflare Proxy Status

**🟠 Proxied (Orange Cloud):**
- ✅ Traffic goes through Cloudflare
- ✅ DDoS protection active
- ✅ SSL handled by Cloudflare
- ✅ Hides your server IP
- ❌ May break some game server protocols

**⚪ DNS Only (Gray Cloud):**
- ✅ Direct connection to server
- ✅ Required for Wings
- ✅ Required for game servers
- ❌ No DDoS protection
- ❌ Server IP is visible

---

## 🔒 Cloudflare Tunnels

### What is a Cloudflare Tunnel?
A secure way to expose your web services **without opening ports** on your firewall!

### How It Works
```
User Request
    ↓
Cloudflare Edge
    ↓
Encrypted Tunnel
    ↓
Your Server (localhost)
```

### Benefits
- ✅ **No port forwarding** - Works behind NAT/firewall
- ✅ **Free SSL** - Automatic HTTPS
- ✅ **DDoS protection** - Cloudflare handles attacks
- ✅ **Hide server IP** - IP stays private
- ✅ **Zero Trust** - Built-in access control

### When to Use Tunnels
- ✅ Admin Panel
- ✅ SSH Terminal
- ✅ FileBrowser
- ✅ Open WebUI
- ❌ Pterodactyl Panel (use regular DNS)
- ❌ Wings (requires direct connection)

### Setting Up a Tunnel

#### 1. Install Cloudflared
```bash
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
```

#### 2. Authenticate
```bash
cloudflared tunnel login
```
This opens a browser to authenticate with Cloudflare.

#### 3. Create a Tunnel
```bash
cloudflared tunnel create my-tunnel
```
This creates a tunnel and gives you a tunnel ID.

#### 4. Configure the Tunnel
Create `/etc/cloudflared/config.yml`:
```yaml
tunnel: YOUR_TUNNEL_ID
credentials-file: /root/.cloudflared/YOUR_TUNNEL_ID.json

ingress:
  # Admin Panel
  - hostname: admin.example.com
    service: http://localhost:5002
  
  # SSH Terminal
  - hostname: ssh.example.com
    service: http://localhost:5000
  
  # Catch-all rule
  - service: http_status:404
```

#### 5. Create DNS Records
```bash
cloudflared tunnel route dns my-tunnel admin.example.com
cloudflared tunnel route dns my-tunnel ssh.example.com
```

#### 6. Run the Tunnel
```bash
cloudflared tunnel run my-tunnel
```

#### 7. Install as Service
```bash
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
```

### Tunnel Dashboard Setup (Easier Method)

#### 1. Go to Zero Trust Dashboard
```
1. Log in to Cloudflare
2. Go to "Zero Trust" in the sidebar
3. Click "Access" → "Tunnels"
4. Click "Create a tunnel"
```

#### 2. Name Your Tunnel
```
Name: pterodactyl-services
Click "Save tunnel"
```

#### 3. Install Connector
```
Copy the command shown and run on your server:

sudo cloudflared service install eyJhIjoiYWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXoxMjM0NTY3ODkwIn0=
```

#### 4. Add Public Hostnames
```
For Admin Panel:
  Subdomain: admin
  Domain: example.com
  Service: HTTP
  URL: localhost:5002

For SSH Terminal:
  Subdomain: ssh
  Domain: example.com
  Service: HTTP
  URL: localhost:5000
```

#### 5. Save and Test
```
✓ Click "Save tunnel"
✓ Visit https://admin.example.com
✓ Visit https://ssh.example.com
```

---

## 🔧 Troubleshooting

### DNS Not Propagating

**Problem:** Domain doesn't resolve after adding DNS record

**Solutions:**
```bash
# Check DNS propagation
dig panel.example.com

# Check from different DNS servers
dig @8.8.8.8 panel.example.com  # Google DNS
dig @1.1.1.1 panel.example.com  # Cloudflare DNS

# Force DNS cache clear (Linux)
sudo systemd-resolve --flush-caches

# Force DNS cache clear (Windows)
ipconfig /flushdns
```

**Wait Time:**
- Cloudflare: 5-10 minutes
- Other providers: Up to 48 hours

### SSL Certificate Errors

**Problem:** "Your connection is not private" or SSL errors

**Solutions:**

1. **Check Cloudflare SSL Mode:**
   ```
   Cloudflare Dashboard → SSL/TLS → Overview
   Set to: Full (strict)
   ```

2. **Install Origin Certificate:**
   ```
   Cloudflare Dashboard → SSL/TLS → Origin Server
   Create Certificate → Install on server
   ```

3. **Wait for Certificate Generation:**
   ```
   New domains may take 15-30 minutes for SSL
   ```

### Wings Connection Issues

**Problem:** Wings can't connect to Panel

**Solutions:**

1. **Check Wings DNS is NOT Proxied:**
   ```
   Wings domain MUST have gray cloud (DNS only)
   Orange cloud will break the connection
   ```

2. **Verify Firewall Rules:**
   ```bash
   sudo ufw allow 8080/tcp
   sudo ufw allow 2022/tcp
   ```

3. **Check Wings Configuration:**
   ```bash
   cat /etc/pterodactyl/config.yml
   # Verify remote URL matches Panel URL
   ```

### Cloudflare Tunnel Not Working

**Problem:** Tunnel shows offline or can't connect

**Solutions:**

1. **Check Tunnel Status:**
   ```bash
   sudo systemctl status cloudflared
   ```

2. **View Tunnel Logs:**
   ```bash
   sudo journalctl -u cloudflared -f
   ```

3. **Restart Tunnel:**
   ```bash
   sudo systemctl restart cloudflared
   ```

4. **Verify Configuration:**
   ```bash
   cat /etc/cloudflared/config.yml
   ```

### Domain Shows Wrong IP

**Problem:** DNS resolves to old/wrong IP address

**Solutions:**

1. **Update DNS Record:**
   ```
   Cloudflare Dashboard → DNS → Edit record
   Update IP address
   ```

2. **Clear Cloudflare Cache:**
   ```
   Cloudflare Dashboard → Caching → Configuration
   Click "Purge Everything"
   ```

3. **Wait for TTL:**
   ```
   DNS changes respect TTL (Time To Live)
   Lower TTL = faster updates
   ```

### Can't Access Service After Setup

**Problem:** Domain configured but service unreachable

**Checklist:**
```
✓ Is the service running?
  sudo systemctl status [service-name]

✓ Is the port open?
  sudo netstat -tlnp | grep [port]

✓ Is firewall allowing traffic?
  sudo ufw status

✓ Is DNS resolving correctly?
  dig [your-domain]

✓ Is SSL certificate valid?
  curl -I https://[your-domain]

✓ Is Cloudflare proxy correct?
  Check orange/gray cloud status
```

---

## 📊 Quick Reference

### Common Pterodactyl Ports
```
Panel:         80, 443 (HTTP/HTTPS)
Wings:         8080 (Daemon API)
Wings SFTP:    2022
MySQL:         3306 (localhost only)
Redis:         6379 (localhost only)
```

### Recommended DNS Setup
```
panel.example.com    → A record → Server IP (Proxied ✓)
node1.example.com    → A record → Server IP (DNS only ✓)
admin.example.com    → A record → Server IP (Proxied ✓)
ssh.example.com      → A record → Server IP (Proxied ✓)
ai.example.com       → A record → Server IP (Proxied ✓)
files.example.com    → A record → Server IP (Proxied ✓)
```

### DNS Propagation Check Tools
- https://dnschecker.org
- https://www.whatsmydns.net
- https://mxtoolbox.com/SuperTool.aspx

### Cloudflare Resources
- Dashboard: https://dash.cloudflare.com
- Zero Trust: https://one.dash.cloudflare.com
- Community: https://community.cloudflare.com
- Docs: https://developers.cloudflare.com

---

## 🎓 Learning Resources

### Video Tutorials
- **Cloudflare Setup:** https://www.youtube.com/watch?v=XQKkb84EjNQ
- **DNS Explained:** https://www.youtube.com/watch?v=Rck3BALhI5c
- **Cloudflare Tunnels:** https://www.youtube.com/watch?v=ZvIdFs3M5ic

### Written Guides
- **Cloudflare Docs:** https://developers.cloudflare.com/dns/
- **DNS Basics:** https://www.cloudflare.com/learning/dns/what-is-dns/
- **Tunnel Guide:** https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/

---

## ✅ Setup Checklist

### Before Installation
- [ ] Domain purchased and accessible
- [ ] Cloudflare account created
- [ ] Domain added to Cloudflare
- [ ] Nameservers updated at registrar
- [ ] Cloudflare shows "Active" status
- [ ] Server IP address known

### During Installation
- [ ] DNS records created for each service
- [ ] Proxy status set correctly (orange/gray cloud)
- [ ] DNS propagation verified
- [ ] SSL/TLS mode set to "Full (strict)"
- [ ] Firewall rules configured

### After Installation
- [ ] All services accessible via HTTPS
- [ ] SSL certificates valid
- [ ] No browser warnings
- [ ] Wings connected to Panel
- [ ] Cloudflare Tunnels running (if used)

---

**Need Help?** The interactive installer includes a built-in wizard that will guide you through each step!

Run: `bash install-interactive.sh`
