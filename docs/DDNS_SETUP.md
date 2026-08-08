# Cloudflare Dynamic DNS Setup Guide

This guide will help you set up automatic DNS updates when your public IP changes.

## Prerequisites

- Cloudflare account with `cloudmc.online` domain
- `jq` installed on your server

## Step 1: Install jq

```bash
sudo apt update
sudo apt install jq -y
```

## Step 2: Get Cloudflare API Token

1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Click **Create Token**
3. Use template: **Edit zone DNS**
4. Configure:
   - **Permissions:** Zone → DNS → Edit
   - **Zone Resources:** Include → Specific zone → `cloudmc.online`
5. Click **Continue to summary**
6. Click **Create Token**
7. **Copy the token** (you won't see it again!)

## Step 3: Get Zone ID

1. Go to https://dash.cloudflare.com
2. Click on `cloudmc.online` domain
3. Scroll down on the **Overview** page
4. Find **Zone ID** on the right side
5. Copy the Zone ID

## Step 4: Configure the Script

```bash
cd ~/CascadeProjects/pteroanyinstall
nano scripts/cloudflare-ddns.sh
```

Edit these lines:
```bash
CLOUDFLARE_API_TOKEN="paste_your_token_here"
ZONE_ID="paste_your_zone_id_here"
DOMAINS_TO_UPDATE=(
    "cloudmc.online"
    "mc.cloudmc.online"
)
```

Add any other domains you want to auto-update.

## Step 5: Install the Service

```bash
# Copy service files
sudo cp systemd/cloudflare-ddns.service /etc/systemd/system/
sudo cp systemd/cloudflare-ddns.timer /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable and start the timer
sudo systemctl enable cloudflare-ddns.timer
sudo systemctl start cloudflare-ddns.timer

# Test it manually first
sudo ./scripts/cloudflare-ddns.sh
```

## Step 6: Verify It's Working

```bash
# Check timer status
sudo systemctl status cloudflare-ddns.timer

# Check when it will run next
sudo systemctl list-timers | grep cloudflare

# View logs
sudo journalctl -u cloudflare-ddns.service -n 50

# Force a run to test
sudo systemctl start cloudflare-ddns.service
```

## How It Works

- **Checks every 5 minutes** if your public IP has changed
- **Runs on boot** after 2 minutes
- **Updates DNS records** automatically when IP changes
- **Logs to syslog** for monitoring

## Troubleshooting

### Check current IP
```bash
curl -4 ifconfig.me
```

### Check DNS resolution
```bash
dig cloudmc.online A +short
```

### Manual update
```bash
sudo ./scripts/cloudflare-ddns.sh
```

### View detailed logs
```bash
sudo journalctl -u cloudflare-ddns.service -f
```

## Domains Updated

By default, the script updates:
- `cloudmc.online` - Main domain
- `mc.cloudmc.online` - Minecraft subdomain

All other subdomains (panel, share, etc.) use Cloudflare Tunnel, so they don't need IP updates.

## Security

- API token is stored in the script file
- Make sure the script is only readable by root:
  ```bash
  sudo chmod 700 ~/CascadeProjects/pteroanyinstall/scripts/cloudflare-ddns.sh
  ```

## Adding More Domains

Edit the script and add to the array:
```bash
DOMAINS_TO_UPDATE=(
    "cloudmc.online"
    "mc.cloudmc.online"
    "another.cloudmc.online"
)
```

Then restart the timer:
```bash
sudo systemctl restart cloudflare-ddns.timer
```
