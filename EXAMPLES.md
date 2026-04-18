# Pterodactyl Installation Examples

## Example 1: Simple Panel Installation

**Scenario:** Installing Pterodactyl Panel on a fresh Ubuntu 22.04 server

**Prerequisites:**
- Domain: `panel.gamehost.com` pointing to `203.0.113.10`
- Fresh Ubuntu 22.04 server
- Root access

**Steps:**

```bash
# Download script
wget https://raw.githubusercontent.com/yourusername/pteroanyinstall/main/pteroanyinstall.sh
chmod +x pteroanyinstall.sh

# Run installation
sudo ./pteroanyinstall.sh install-panel
```

**Prompts and Responses:**
```
Enter Panel FQDN: panel.gamehost.com
Enter Public IP address: 203.0.113.10
Enter your email address: admin@gamehost.com
Enter admin password: [leave empty for auto-generate]
Do you want to setup SSL with Let's Encrypt? (y/n): y
Do you want to setup Cloudflare integration? (y/n): n
```

**Result:** Panel accessible at `https://panel.gamehost.com`

---

## Example 2: Wings Installation with GPU Support

**Scenario:** Installing Wings on a dedicated server with NVIDIA GPU

**Prerequisites:**
- Domain: `node1.gamehost.com` pointing to `203.0.113.20`
- Server with NVIDIA GPU
- NVIDIA drivers already installed
- Panel already set up

**Steps:**

```bash
# Download script
wget https://raw.githubusercontent.com/yourusername/pteroanyinstall/main/pteroanyinstall.sh
chmod +x pteroanyinstall.sh

# Run installation
sudo ./pteroanyinstall.sh install-wings
```

**Prompts and Responses:**
```
Enter Wings FQDN: node1.gamehost.com
Enter Public IP address: 203.0.113.20
Do you want to enable GPU support? (y/n): y
Enter your email address: admin@gamehost.com
Have you created the node in the panel and ready to paste the config? (y/n): y
[Paste configuration from Panel]
Do you want to setup SSL for Wings? (y/n): y
```

**Panel Configuration:**
1. Login to Panel at `https://panel.gamehost.com`
2. Go to Admin → Locations → Create New
   - Short Code: `us-east`
   - Description: `US East Coast`
3. Go to Admin → Nodes → Create New
   - Name: `Node 1`
   - FQDN: `node1.gamehost.com`
   - Communicate Over SSL: Yes
   - Memory: `32768` (32GB)
   - Disk: `500000` (500GB)
4. Copy configuration from Configuration tab

**Result:** Wings running with GPU support, ready to host game servers

---

## Example 3: Full Installation (Panel + Wings on Same Server)

**Scenario:** Small setup with Panel and Wings on the same server

**Prerequisites:**
- Domains: 
  - `panel.minecraft.net` → `198.51.100.50`
  - `node.minecraft.net` → `198.51.100.50`
- Ubuntu 22.04 server with 8GB RAM
- Root access

**Steps:**

```bash
# Download script
wget https://raw.githubusercontent.com/yourusername/pteroanyinstall/main/pteroanyinstall.sh
chmod +x pteroanyinstall.sh

# Run installation
sudo ./pteroanyinstall.sh install-full
```

**Prompts and Responses:**
```
Do you want to enable GPU support? (y/n): n
Enter your email address: admin@minecraft.net
Enter admin password: MySecurePassword123!

[Panel Installation]
Enter Panel FQDN: panel.minecraft.net
Enter Public IP address: 198.51.100.50
Do you want to setup SSL with Let's Encrypt? (y/n): y

Do you want to install Wings on this server too? (y/n): y

[Wings Installation]
Enter Wings FQDN: node.minecraft.net
Enter Public IP address: 198.51.100.50
Have you created the node in the panel and ready to paste the config? (y/n): y
[Paste configuration]
Do you want to setup SSL for Wings? (y/n): y

Do you want to setup Cloudflare integration? (y/n): n
```

**Result:** Complete Pterodactyl setup ready to create servers

---

## Example 4: Multi-Node Setup with Cloudflare

**Scenario:** Production setup with Panel and multiple Wings nodes behind Cloudflare

**Infrastructure:**
- Panel: `panel.hosting.io` (Cloudflare proxied)
- Node 1: `node1.hosting.io` (NOT proxied)
- Node 2: `node2.hosting.io` (NOT proxied)

### Step 1: Install Panel

```bash
# On panel server (203.0.113.100)
wget https://raw.githubusercontent.com/yourusername/pteroanyinstall/main/pteroanyinstall.sh
chmod +x pteroanyinstall.sh
sudo ./pteroanyinstall.sh install-panel
```

**Responses:**
```
Enter Panel FQDN: panel.hosting.io
Enter Public IP address: 203.0.113.100
Enter your email address: ops@hosting.io
Enter admin password: [auto-generate]
Do you want to setup SSL with Let's Encrypt? (y/n): y
Do you want to setup Cloudflare integration? (y/n): y
Enter Cloudflare API Token: [your-api-token]
Enter Cloudflare Zone ID: [your-zone-id]
```

**Cloudflare Settings:**
- SSL/TLS Mode: Full (strict)
- Proxy Status: Proxied (orange cloud)

### Step 2: Install Wings Node 1

```bash
# On node1 server (203.0.113.101)
wget https://raw.githubusercontent.com/yourusername/pteroanyinstall/main/pteroanyinstall.sh
chmod +x pteroanyinstall.sh
sudo ./pteroanyinstall.sh install-wings
```

**Responses:**
```
Enter Wings FQDN: node1.hosting.io
Enter Public IP address: 203.0.113.101
Do you want to enable GPU support? (y/n): n
Enter your email address: ops@hosting.io
```

**Cloudflare Settings for node1.hosting.io:**
- Proxy Status: DNS only (gray cloud) - IMPORTANT!

### Step 3: Install Wings Node 2

```bash
# On node2 server (203.0.113.102)
wget https://raw.githubusercontent.com/yourusername/pteroanyinstall/main/pteroanyinstall.sh
chmod +x pteroanyinstall.sh
sudo ./pteroanyinstall.sh install-wings
```

**Responses:**
```
Enter Wings FQDN: node2.hosting.io
Enter Public IP address: 203.0.113.102
Do you want to enable GPU support? (y/n): y
Enter your email address: ops@hosting.io
```

**Cloudflare Settings for node2.hosting.io:**
- Proxy Status: DNS only (gray cloud) - IMPORTANT!

**Result:** Scalable multi-node setup with Cloudflare protection on Panel

---

## Example 5: Update Existing Installation

**Scenario:** Updating all Pterodactyl components on existing server

```bash
# Navigate to script location
cd /root
./pteroanyinstall.sh update
```

**What Happens:**
1. System packages updated
2. Panel updated to latest version
3. Wings updated to latest version
4. Health check performed
5. All services verified

**Output:**
```
[INFO] Starting full system update...
[INFO] Updating system packages...
[SUCCESS] System updated
[INFO] Updating Pterodactyl Panel...
[SUCCESS] Panel updated
[INFO] Updating Pterodactyl Wings...
[SUCCESS] Wings updated
[INFO] Performing health check...
[SUCCESS] docker is running
[SUCCESS] mariadb is running
[SUCCESS] nginx is running
[SUCCESS] redis-server is running
[SUCCESS] wings is running
[SUCCESS] All services are healthy
[SUCCESS] All updates completed
```

---

## Example 6: Scan and Fix Broken Installation

**Scenario:** Panel showing errors after server restart

```bash
./pteroanyinstall.sh scan
```

**What Happens:**
1. Detects Panel installation
2. Fixes file permissions
3. Clears all caches
4. Tests database connection
5. Restarts queue workers
6. Checks Wings configuration
7. Restarts Wings service
8. Runs health check

**Output:**
```
[INFO] Scanning and fixing Pterodactyl installation...
[INFO] Found Panel installation, checking...
[INFO] Fixing permissions...
[INFO] Clearing caches...
[INFO] Checking database connection...
[SUCCESS] Database connection OK
[INFO] Restarting queue workers...
[INFO] Found Wings installation, checking...
[SUCCESS] Wings configuration found
[INFO] Performing health check...
[SUCCESS] All services are healthy
[SUCCESS] Scan and fix completed
```

---

## Example 7: Health Check Only

**Scenario:** Verify all services are running correctly

```bash
./pteroanyinstall.sh health-check
```

**Output:**
```
[INFO] Performing health check...
[SUCCESS] docker is running
[SUCCESS] mariadb is running
[SUCCESS] nginx is running
[SUCCESS] redis-server is running
[SUCCESS] wings is running
[INFO] Checking Panel status...
Pterodactyl Panel v1.11.5
[SUCCESS] All services are healthy
```

---

## Example 8: Interactive Mode for First-Time Users

**Scenario:** New user unsure what to install

```bash
./pteroanyinstall.sh
```

**Interaction:**
```
[INFO] Welcome to pteroanyinstall v1.0.0

Do you want to scan existing Pterodactyl installation? (y/n): n

[INFO] What would you like to install?
1) Panel only
2) Wings only
3) Full installation (Panel + Wings)
4) Update existing installation
5) Exit

Enter choice [1-5]: 3

[INFO] Starting full Pterodactyl installation...
[continues with prompts...]
```

---

## Common Installation Patterns

### Pattern 1: Development/Testing Setup
- Single server
- Panel + Wings on same machine
- No GPU support
- Self-signed SSL or Let's Encrypt
- No Cloudflare

**Command:** `./pteroanyinstall.sh install-full`

### Pattern 2: Small Production Setup
- Single server
- Panel + Wings on same machine
- Let's Encrypt SSL
- Cloudflare for DDoS protection
- Regular backups

**Command:** `./pteroanyinstall.sh install-full`

### Pattern 3: Medium Production Setup
- Separate Panel server
- 2-3 Wings nodes
- Let's Encrypt SSL
- Cloudflare on Panel only
- Load balancing across nodes

**Commands:**
```bash
# Panel server
./pteroanyinstall.sh install-panel

# Each Wings server
./pteroanyinstall.sh install-wings
```

### Pattern 4: Large Production Setup
- Dedicated Panel server
- 5+ Wings nodes
- Some nodes with GPU support
- Cloudflare with API integration
- Automated backups and monitoring
- Geographic distribution

**Commands:**
```bash
# Panel server
./pteroanyinstall.sh install-panel

# GPU nodes
./pteroanyinstall.sh install-wings
# Answer yes to GPU support

# Regular nodes
./pteroanyinstall.sh install-wings
# Answer no to GPU support
```

---

## Troubleshooting Examples

### Example: DNS Not Propagated

**Problem:**
```
[WARNING] DNS points to 1.2.3.4 but expected 203.0.113.10
Continue anyway? (y/n):
```

**Solution:**
- Type `n` to abort
- Wait for DNS to propagate (check with `dig +short yourdomain.com`)
- Run script again when DNS is correct

### Example: SSL Certificate Failed

**Problem:**
```
[ERROR] Certbot failed to issue certificate
```

**Solution:**
```bash
# Verify DNS
dig +short panel.example.com

# Check firewall
sudo ufw status

# Try manual certificate
sudo certbot certonly --nginx -d panel.example.com --dry-run

# If dry-run works, run without --dry-run
sudo certbot certonly --nginx -d panel.example.com
```

### Example: Wings Won't Start

**Problem:**
```
[ERROR] wings is not running
```

**Solution:**
```bash
# Check logs
journalctl -u wings -n 50

# Common issues:
# 1. Config file missing
ls -la /etc/pterodactyl/config.yml

# 2. SSL certificate issues
ls -la /etc/letsencrypt/live/node.example.com/

# 3. Port conflicts
netstat -tulpn | grep 8080

# Restart Wings
systemctl restart wings
systemctl status wings
```

---

## Automation Examples

### Automated Installation Script

Create `auto-install.sh`:

```bash
#!/bin/bash

export PANEL_FQDN="panel.example.com"
export PUBLIC_IP="203.0.113.10"
export USER_EMAIL="admin@example.com"
export ADMIN_PASS="SecurePassword123!"

wget https://raw.githubusercontent.com/yourusername/pteroanyinstall/main/pteroanyinstall.sh
chmod +x pteroanyinstall.sh

# Note: Still requires user interaction for some prompts
sudo ./pteroanyinstall.sh install-panel
```

### Scheduled Updates

Add to crontab:

```bash
crontab -e

# Update every Sunday at 3 AM
0 3 * * 0 /root/pteroanyinstall.sh update >> /var/log/ptero-update.log 2>&1

# Health check daily at 6 AM
0 6 * * * /root/pteroanyinstall.sh health-check >> /var/log/ptero-health.log 2>&1
```

### Monitoring Script

Create `monitor.sh`:

```bash
#!/bin/bash

if ! /root/pteroanyinstall.sh health-check | grep -q "All services are healthy"; then
    echo "Pterodactyl services unhealthy!" | mail -s "Alert: Pterodactyl Down" admin@example.com
    /root/pteroanyinstall.sh scan
fi
```

---

These examples cover the most common installation scenarios and troubleshooting situations you'll encounter with the pteroanyinstall script.
