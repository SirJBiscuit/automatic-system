# 🌐 Network Setup Guide for Any Device

## Overview

This guide helps you set up Pterodactyl on **any device** - whether it's a dedicated server, VPS, home PC, mini PC, or Raspberry Pi.

## Supported Devices

✅ **Dedicated Servers** - Full public IP, no configuration needed  
✅ **VPS/Cloud Servers** - AWS, DigitalOcean, Linode, etc.  
✅ **Home Servers** - Desktop PCs, workstations  
✅ **Mini PCs** - Intel NUC, Beelink, MINISFORUM  
✅ **Raspberry Pi** - Pi 4, Pi 5 (4GB+ RAM recommended)  
✅ **Old Laptops** - Repurposed as servers  

## Network Types

### Type 1: Public IP (Easy!)
**What it is:** Server has a direct internet connection with public IP  
**Examples:** VPS, dedicated servers, some business connections  
**Setup:** ✅ No port forwarding needed!  
**Time:** 2 minutes

### Type 2: Behind Router/NAT (Common)
**What it is:** Server is on home network behind a router  
**Examples:** Home PCs, mini PCs, Raspberry Pi  
**Setup:** ⚠️ Requires port forwarding OR Cloudflare Tunnel  
**Time:** 10-30 minutes

## Quick Start

### Option A: Automatic Setup (Recommended)

```bash
# Run the network wizard
sudo bash network-setup-wizard.sh
```

The wizard will:
1. Detect your network type
2. Try automatic port forwarding (UPnP)
3. Guide you through manual setup if needed
4. Offer Cloudflare Tunnel alternative
5. Configure firewall
6. Test port accessibility

### Option B: Cloudflare Tunnel (No Port Forwarding!)

**Best for:**
- Home networks
- No router access
- ISP blocks ports
- Want maximum security

```bash
# Install cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# Follow setup in Cloudflare dashboard
# No port forwarding needed!
```

## Detailed Setup Guides

### For Home Servers / Mini PCs

#### Step 1: Find Your Network Info

```bash
# Get your local IP
hostname -I

# Get your public IP
curl https://api.ipify.org

# Get your router IP (gateway)
ip route | grep default
```

**Example output:**
```
Local IP: 192.168.1.100
Public IP: 203.0.113.45
Gateway: 192.168.1.1
```

#### Step 2: Choose Your Method

**Method A: Port Forwarding (Traditional)**
- Pros: Direct connection, lower latency
- Cons: Requires router access, exposes IP

**Method B: Cloudflare Tunnel (Modern)**
- Pros: No port forwarding, hides IP, free SSL
- Cons: Slight latency increase

#### Step 3A: Port Forwarding Setup

**Required Ports:**
```
80    - HTTP (Panel)
443   - HTTPS (Panel)
8080  - Wings API
2022  - Wings SFTP
```

**Router-Specific Guides:**

##### Netgear Routers
```
1. Go to http://192.168.1.1
2. Login (default: admin/password)
3. Advanced → Advanced Setup → Port Forwarding
4. Add Custom Service:
   - Service Name: Pterodactyl-HTTP
   - External Port: 80
   - Internal Port: 80
   - Internal IP: 192.168.1.100 (your server)
   - Protocol: TCP
5. Repeat for ports 443, 8080, 2022
```

##### TP-Link Routers
```
1. Go to http://192.168.0.1 or http://192.168.1.1
2. Login (default: admin/admin)
3. Forwarding → Virtual Servers
4. Add New:
   - Service Port: 80
   - IP Address: 192.168.1.100
   - Protocol: TCP
   - Status: Enabled
5. Repeat for ports 443, 8080, 2022
```

##### ASUS Routers
```
1. Go to http://router.asus.com or http://192.168.1.1
2. Login (default: admin/admin)
3. WAN → Virtual Server / Port Forwarding
4. Enable Port Forwarding
5. Add:
   - Service Name: Pterodactyl-HTTP
   - Port Range: 80
   - Local IP: 192.168.1.100
   - Protocol: TCP
6. Repeat for ports 443, 8080, 2022
```

##### Linksys Routers
```
1. Go to http://192.168.1.1
2. Login (default: admin/admin)
3. Security → Apps and Gaming → Single Port Forwarding
4. Add:
   - Application Name: Pterodactyl-HTTP
   - External Port: 80
   - Internal Port: 80
   - Device IP: 192.168.1.100
   - Protocol: TCP
   - Enabled: ✓
5. Repeat for ports 443, 8080, 2022
```

##### D-Link Routers
```
1. Go to http://192.168.0.1
2. Login (default: admin/blank)
3. Advanced → Port Forwarding
4. Add:
   - Name: Pterodactyl-HTTP
   - Public Port: 80
   - Private Port: 80
   - Traffic Type: TCP
   - Private IP: 192.168.1.100
5. Repeat for ports 443, 8080, 2022
```

##### Can't Find Your Router?
Search: "[Your Router Model] port forwarding guide"

Example: "Netgear R7000 port forwarding"

#### Step 3B: Cloudflare Tunnel Setup

**No router configuration needed!**

```bash
# 1. Install cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# 2. Login to Cloudflare
cloudflared tunnel login
```

**In Cloudflare Dashboard:**
```
1. Go to https://dash.cloudflare.com
2. Select your domain
3. Zero Trust → Access → Tunnels
4. Create a tunnel
5. Name: pterodactyl
6. Install connector (copy the command)
7. Run the command on your server
8. Add public hostnames:
   
   Panel:
   - Subdomain: panel
   - Domain: yourdomain.com
   - Service: HTTP
   - URL: localhost:80
   
   Wings:
   - Subdomain: node1
   - Domain: yourdomain.com
   - Service: HTTP
   - URL: localhost:8080
```

**Done!** No port forwarding needed!

#### Step 4: DHCP Reservation (Recommended)

**Why?** Ensures your server always gets the same local IP

**How:**

```bash
# Get your MAC address
ip link show | grep "link/ether"
```

**In Router:**
```
1. Find "DHCP Settings" or "LAN Settings"
2. Look for "Address Reservation" or "Static DHCP"
3. Add reservation:
   - MAC Address: [your MAC]
   - IP Address: 192.168.1.100
   - Name: Pterodactyl-Server
4. Save and reboot router
```

#### Step 5: Firewall Configuration

```bash
# Install UFW
sudo apt-get install ufw

# Configure rules
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw allow 8080/tcp comment 'Wings API'
sudo ufw allow 2022/tcp comment 'Wings SFTP'

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

#### Step 6: Test Port Accessibility

**Online Port Checker:**
- https://www.yougetsignal.com/tools/open-ports/
- https://portchecker.co/
- https://canyouseeme.org/

**Enter:**
- IP Address: [Your Public IP]
- Port: 80

**Repeat for:** 443, 8080, 2022

**All should show "Open"**

### For VPS / Cloud Servers

#### Step 1: Check Your IP

```bash
curl https://api.ipify.org
```

This is your public IP - use it for DNS records!

#### Step 2: Configure Firewall

**For UFW (Ubuntu/Debian):**
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 2022/tcp
sudo ufw enable
```

**For iptables:**
```bash
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 2022 -j ACCEPT
sudo iptables-save
```

**For cloud provider firewall:**
- AWS: Security Groups
- DigitalOcean: Cloud Firewalls
- Linode: Cloud Firewall
- Vultr: Firewall Rules

Add rules for ports: 80, 443, 8080, 2022

#### Step 3: Test Ports

```bash
# Test if ports are listening
sudo netstat -tlnp | grep -E '80|443|8080|2022'
```

### For Raspberry Pi

#### Requirements
- Raspberry Pi 4 or 5
- 4GB+ RAM (8GB recommended)
- 32GB+ SD card (64GB recommended)
- Ubuntu Server 22.04 LTS

#### Special Considerations

**1. Power Supply**
- Use official power supply
- Minimum 3A for Pi 4
- Minimum 5A for Pi 5

**2. Cooling**
- Active cooling recommended
- Case with fan
- Heatsinks

**3. Storage**
- Use SSD instead of SD card for better performance
- USB 3.0 SSD adapter

**4. Network**
- Ethernet preferred over WiFi
- Gigabit ethernet for best performance

#### Setup Steps

Same as "Home Servers" above, but:

**Install 64-bit OS:**
```bash
# Use Raspberry Pi Imager
# Choose: Ubuntu Server 22.04 LTS (64-bit)
```

**Optimize for Pi:**
```bash
# Increase swap
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# Set CONF_SWAPSIZE=2048
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

# Disable unnecessary services
sudo systemctl disable bluetooth
sudo systemctl disable hciuart
```

## Troubleshooting

### Ports Not Accessible

**Check 1: Port Forwarding**
```bash
# Verify rules in router
# Make sure:
# - Correct internal IP
# - Correct ports
# - TCP protocol
# - Rules are enabled
```

**Check 2: Firewall**
```bash
# Check UFW
sudo ufw status

# Check iptables
sudo iptables -L -n
```

**Check 3: Service Running**
```bash
# Check if service is listening
sudo netstat -tlnp | grep 80
```

**Check 4: ISP Blocking**
```
Some ISPs block ports 80 and 443 for residential connections.

Solutions:
1. Contact ISP to unblock
2. Use alternative ports (8080, 8443)
3. Use Cloudflare Tunnel (bypasses ISP)
4. Get business internet plan
```

### Dynamic IP Address

**Problem:** Your public IP changes periodically

**Solutions:**

**1. Dynamic DNS (DDNS)**
```bash
# Install ddclient
sudo apt-get install ddclient

# Configure for your DDNS provider
# (No-IP, DuckDNS, Dynu, etc.)
```

**2. Cloudflare Tunnel**
```
No public IP needed!
Works with any IP, even if it changes
```

**3. Static IP from ISP**
```
Contact ISP for static IP
Usually $5-10/month extra
```

### UPnP Not Working

**Enable UPnP in Router:**
```
1. Log in to router
2. Find "UPnP" settings
3. Enable UPnP
4. Save and reboot router
```

**Test UPnP:**
```bash
# Install miniupnpc
sudo apt-get install miniupnpc

# List UPnP devices
upnpc -l

# Try forwarding a port
upnpc -a 192.168.1.100 80 80 TCP
```

### Can't Access Router

**Find Router IP:**
```bash
ip route | grep default
# Usually: 192.168.1.1 or 192.168.0.1
```

**Common Router IPs:**
- 192.168.1.1 (most common)
- 192.168.0.1
- 192.168.2.1
- 10.0.0.1
- 192.168.100.1

**Reset Router:**
```
1. Find reset button (usually on back)
2. Hold for 10-30 seconds
3. Router resets to factory defaults
4. Use default login (check router label)
```

### Firewall Blocking

**Temporarily disable to test:**
```bash
# Disable UFW
sudo ufw disable

# Test if ports work now
# If yes, firewall was blocking

# Re-enable and add rules
sudo ufw enable
sudo ufw allow 80/tcp
```

## Network Diagrams

### Home Network Setup
```
Internet
   ↓
ISP Modem
   ↓
Router (192.168.1.1)
   ↓
[Port Forwarding: 80→192.168.1.100]
   ↓
Your Server (192.168.1.100)
   ↓
Pterodactyl Panel (localhost:80)
```

### Cloudflare Tunnel Setup
```
Internet
   ↓
Cloudflare Edge
   ↓
Encrypted Tunnel
   ↓
Your Server (any IP, behind firewall)
   ↓
Pterodactyl Panel (localhost:80)

No port forwarding needed!
```

## Best Practices

### Security
- ✅ Use firewall (UFW)
- ✅ Change default router password
- ✅ Disable WPS on router
- ✅ Use strong WiFi password
- ✅ Keep router firmware updated
- ✅ Use Cloudflare for DDoS protection

### Performance
- ✅ Use ethernet over WiFi
- ✅ Place server close to router
- ✅ Use quality ethernet cables (Cat6+)
- ✅ Enable QoS on router for gaming
- ✅ Reserve DHCP for server

### Reliability
- ✅ Use UPS for power backup
- ✅ Set up DHCP reservation
- ✅ Monitor server uptime
- ✅ Configure automatic restarts
- ✅ Set up monitoring alerts

## Device-Specific Tips

### Intel NUC
- Excellent for Pterodactyl
- Low power consumption
- Quiet operation
- Easy to upgrade RAM/storage

### Raspberry Pi
- Budget-friendly
- Low power
- Requires active cooling
- Use SSD for better performance

### Old Laptop
- Free if you have one
- Built-in UPS (battery)
- Disable screen to save power
- Remove battery if always plugged in

### Desktop PC
- Most powerful option
- Higher power consumption
- Good for multiple game servers
- Ensure good cooling

## Cost Comparison

| Device Type | Initial Cost | Monthly Power | Total Year 1 |
|-------------|--------------|---------------|--------------|
| Raspberry Pi 4 | $75 | $1 | $87 |
| Intel NUC | $300 | $2 | $324 |
| Old Laptop | $0 | $3 | $36 |
| Desktop PC | $500 | $10 | $620 |
| VPS (4GB) | $0 | $20 | $240 |

**Cheapest:** Repurpose old laptop  
**Best Value:** Raspberry Pi 4  
**Most Powerful:** Desktop PC  
**Easiest:** VPS (no hardware needed)

## FAQ

**Q: Can I use WiFi instead of ethernet?**  
A: Yes, but ethernet is strongly recommended for stability and performance.

**Q: My ISP blocks port 80, what do I do?**  
A: Use Cloudflare Tunnel or alternative ports (8080, 8443).

**Q: Do I need a static IP?**  
A: No, but it helps. Use DDNS or Cloudflare Tunnel for dynamic IPs.

**Q: Can I run this on Windows?**  
A: Pterodactyl requires Linux. Use WSL2 or install Ubuntu.

**Q: How much bandwidth do I need?**  
A: Minimum 10 Mbps upload. 50+ Mbps recommended for multiple servers.

**Q: Will this work with Starlink?**  
A: Yes! Use Cloudflare Tunnel (Starlink uses CGNAT).

**Q: Can I use a VPN?**  
A: Not recommended. VPN will interfere with port forwarding.

---

**Need Help?**

Run the automated network wizard:
```bash
sudo bash network-setup-wizard.sh
```

Or install AI assistant first for guided help:
```bash
sudo bash install-interactive.sh
# Choose option 0: AI Assistant First
```
