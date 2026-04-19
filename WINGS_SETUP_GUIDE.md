# Wings Node Setup Guide

## Overview
This guide explains how to set up your first Wings node and troubleshoot common issues, especially the "node not green" problem.

---

## First-Time Node Setup Flow

### 1. **DNS Configuration (CRITICAL)**

Before creating a node, set up DNS records in Cloudflare:

#### Panel Domain (e.g., panel.cloudmc.online)
- **Type:** A Record
- **Name:** panel (or your subdomain)
- **Content:** Your server IP (e.g., 143.103.18.56)
- **Proxy status:** ✅ **Proxied (Orange Cloud)** - REQUIRED for Panel
- **TTL:** Auto

#### Wings Domain (e.g., node.cloudmc.online)
- **Type:** A Record
- **Name:** node (or your subdomain)
- **Content:** Your server IP (e.g., 143.103.18.56)
- **Proxy status:** ⚠️ **DNS only (Gray Cloud)** - MUST BE GRAY for Wings!
- **TTL:** Auto

**Why different proxy settings?**
- Panel uses ports 80/443 which Cloudflare proxies properly
- Wings uses port 8080 which Cloudflare does NOT proxy properly
- If Wings is proxied (orange), port 8080 will be blocked!

---

### 2. **SSL Certificates**

#### Get SSL for Wings:
```bash
# Stop Wings if running
systemctl stop wings

# Stop Nginx temporarily
systemctl stop nginx

# Get certificate
certbot certonly --standalone -d node.cloudmc.online --non-interactive --agree-tos -m your-email@example.com

# Start Nginx back
systemctl start nginx
```

The certificate will be saved at:
- Cert: `/etc/letsencrypt/live/node.cloudmc.online/fullchain.pem`
- Key: `/etc/letsencrypt/live/node.cloudmc.online/privkey.pem`

---

### 3. **Create Node in Panel**

1. Log into Panel: `https://panel.cloudmc.online`
2. Go to **Admin** → **Locations** → Create a location (e.g., "Main Location")
3. Go to **Admin** → **Nodes** → **Create New**

**Node Settings:**
- **Name:** Your node name (e.g., "Universal Node")
- **Description:** Optional description
- **Location:** Select the location you created
- **FQDN:** `node.cloudmc.online` (your Wings domain)
- **Communicate Over SSL:** ✅ **Yes** (IMPORTANT!)
- **Behind Proxy:** ❌ **No** (Wings is NOT behind Cloudflare proxy)
- **Daemon Server Port:** `8080`
- **Daemon SFTP Port:** `2022`
- **Memory:** Your server's RAM in MB (e.g., 32768 for 32GB)
- **Disk:** Your available disk in MB (e.g., 1500000 for ~1.5TB)

4. Click **Create Node**

---

### 4. **Configure Wings**

1. In the Panel, go to your node → **Configuration** tab
2. **Copy the entire YAML configuration**
3. On your server:

```bash
nano /etc/pterodactyl/config.yml
```

4. **Delete everything** and paste the Panel's configuration
5. **Verify SSL is enabled** in the config:

```yaml
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: true
    cert: /etc/letsencrypt/live/node.cloudmc.online/fullchain.pem
    key: /etc/letsencrypt/live/node.cloudmc.online/privkey.pem
  upload_limit: 100
```

6. Save: `Ctrl+O`, `Enter`, `Ctrl+X`

---

### 5. **Start Wings**

```bash
systemctl start wings
systemctl enable wings
systemctl status wings
```

---

### 6. **Verify Connection**

Wait 1-2 minutes, then refresh the Panel. The node should show a **green pulsing heart** ✅

---

## Common Issues & Fixes

### Issue 1: Node Not Green (Red/Gray Heart)

**Symptoms:**
- Node shows as offline in Panel
- Browser console shows: "Mixed Content" error or "ERR_CONNECTION_CLOSED"

**Cause:**
Panel is loaded over HTTPS but Wings is using HTTP, causing browser to block "mixed content"

**Fix:**
1. Enable SSL in Wings config (see step 4 above)
2. Make sure Panel node settings have "Communicate Over SSL" = Yes
3. Restart Wings: `systemctl restart wings`

---

### Issue 2: Connection Timeout to Wings

**Symptoms:**
- `curl http://node.cloudmc.online:8080` times out
- Can't reach Wings from outside

**Causes & Fixes:**

#### A. Cloudflare Proxy is ON (Orange Cloud)
**Fix:** Change DNS record to **DNS only (Gray Cloud)**

#### B. Firewall Blocking Port 8080
**Fix:**
```bash
ufw allow 8080/tcp
ufw allow 2022/tcp
ufw reload
```

#### C. Provider-Level Firewall
**Fix:** Check your hosting provider's control panel (Vultr, DigitalOcean, etc.) and allow ports 8080 and 2022

---

### Issue 3: Token Mismatch

**Symptoms:**
- Wings logs show no errors
- Wings can fetch from API
- Node still not green

**Fix:**
The Panel's configuration has the correct token. Copy it from Panel → Node → Configuration tab and replace Wings config entirely.

---

### Issue 4: SSL Certificate Path Wrong

**Symptoms:**
- Wings fails to start
- Error about certificate files not found

**Fix:**
Make sure the certificate paths in Wings config match your domain:
```yaml
cert: /etc/letsencrypt/live/node.cloudmc.online/fullchain.pem
key: /etc/letsencrypt/live/node.cloudmc.online/privkey.pem
```

NOT:
```yaml
cert: /etc/letsencrypt/live/panel.cloudmc.online/fullchain.pem  # WRONG!
```

---

## Quick Diagnostic Commands

### Check Wings Status
```bash
systemctl status wings
```

### Check Wings Logs
```bash
journalctl -u wings -n 50 --no-pager
```

### Test Wings API Locally
```bash
curl http://127.0.0.1:8080
# Should return: {"error":"The required authorization heads were not present in the request."}
```

### Test Wings API Externally
```bash
curl https://node.cloudmc.online:8080
# Should return the same error (means it's working!)
```

### Check Firewall
```bash
ufw status | grep 8080
```

### Verify DNS
```bash
nslookup node.cloudmc.online
# Should return your server IP
```

### Check SSL Certificate
```bash
ls -la /etc/letsencrypt/live/node.cloudmc.online/
```

---

## The Complete Fix (What We Did)

### Problem
Node was not showing green in Panel after installation.

### Root Causes Found
1. **Mixed Content Error:** Panel (HTTPS) trying to connect to Wings (HTTP)
2. **SSL Not Enabled:** Wings was running without SSL
3. **Wrong Certificate Path:** Config pointed to panel's cert instead of node's cert
4. **Token Mismatch:** Wings config had old/wrong token

### Solution Steps
1. ✅ Created DNS A record for `node.cloudmc.online` with **gray cloud**
2. ✅ Obtained SSL certificate for Wings domain
3. ✅ Copied complete configuration from Panel
4. ✅ Enabled SSL in Wings config with correct certificate paths
5. ✅ Set Panel node to "Communicate Over SSL" = Yes
6. ✅ Restarted Wings
7. ✅ Waited for heartbeat (1-2 minutes)
8. ✅ Node turned green! 🟢

---

## Firewall Ports Required

### Panel
- **80/tcp** - HTTP (redirects to HTTPS)
- **443/tcp** - HTTPS
- **3306/tcp** - MySQL (only if remote access needed)

### Wings
- **8080/tcp** - Wings API
- **2022/tcp** - Wings SFTP
- **25565-25600/tcp** - Game server ports (Minecraft, etc.)
- **Game-specific ports** - As needed for your servers

---

## Best Practices

### DNS
- ✅ Panel domain: Proxied (Orange Cloud)
- ✅ Wings domain: DNS only (Gray Cloud)
- ✅ Wait for DNS propagation (1-5 minutes)

### SSL
- ✅ Always use SSL for both Panel and Wings
- ✅ Let's Encrypt auto-renews every 90 days
- ✅ Keep certificate paths correct in configs

### Security
- ✅ Enable firewall (UFW)
- ✅ Only open required ports
- ✅ Use strong passwords
- ✅ Keep software updated

### Monitoring
- ✅ Check Wings logs regularly
- ✅ Monitor node heartbeat in Panel
- ✅ Set up automatic backups
- ✅ Monitor disk space and resources

---

## Troubleshooting Checklist

When node is not green, check in this order:

- [ ] DNS record exists and points to correct IP
- [ ] DNS is **gray cloud** (DNS only) for Wings domain
- [ ] SSL certificate exists for Wings domain
- [ ] Wings config has SSL enabled with correct paths
- [ ] Panel node settings: "Communicate Over SSL" = Yes
- [ ] Panel node settings: "Behind Proxy" = No
- [ ] Firewall allows ports 8080 and 2022
- [ ] Provider firewall allows ports 8080 and 2022
- [ ] Wings is running: `systemctl status wings`
- [ ] Wings can reach Panel: `curl https://panel.cloudmc.online`
- [ ] Wings API responds: `curl http://127.0.0.1:8080`
- [ ] Token matches between Panel and Wings config
- [ ] Waited 1-2 minutes for heartbeat
- [ ] Hard refreshed Panel page (Ctrl+F5)

---

## Success Indicators

You know everything is working when:

✅ Wings status shows: `active (running)`
✅ Wings logs show: `fetching list of servers from API`
✅ Wings logs show: `processing servers returned by the API`
✅ `curl http://127.0.0.1:8080` returns authorization error
✅ `curl https://node.cloudmc.online:8080` returns authorization error
✅ Panel shows **green pulsing heart** for the node
✅ No errors in browser console when viewing node page

---

## Next Steps After Node is Green

1. **Create Allocations**
   - Go to Node → Allocation tab
   - Add IP:Port combinations for game servers

2. **Create Your First Server**
   - Admin → Servers → Create New
   - Select your node
   - Choose an egg (Minecraft, etc.)
   - Assign resources

3. **Test Server Creation**
   - Server should install automatically
   - Check server console for output
   - Start the server

4. **Set Up Backups** (Optional)
   - Run: `./pteroanyinstall.sh` and choose backup setup
   - Or configure manual backups

5. **Add More Nodes** (Optional)
   - Repeat this process on other servers
   - Each node needs its own domain/subdomain

---

## Quick Fix Command

If you encounter the "node not green" issue, run:

```bash
./pteroanyinstall.sh fixheart
```

This will automatically:
- Check DNS configuration
- Verify SSL certificates
- Enable SSL in Wings config
- Update Panel node settings
- Restart Wings
- Verify connection

---

## Support

If you're still having issues:

1. Check Wings logs: `journalctl -u wings -n 100`
2. Check Panel logs: `/var/www/pterodactyl/storage/logs/`
3. Verify all steps in this guide
4. Check Pterodactyl documentation: https://pterodactyl.io/wings/

---

**Remember:** The most common issue is Cloudflare proxy being ON (orange) for the Wings domain. It MUST be gray (DNS only)! 🌫️
