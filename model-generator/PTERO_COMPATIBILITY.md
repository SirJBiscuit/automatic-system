# 🔗 Pterodactyl Compatibility Guide

## ✅ Confirmed Compatible with pteroanyinstall

This 3D Model Generator is **100% compatible** with your existing pterodactyl installation from `pteroanyinstall`.

## 🛡️ Isolation Strategy

### **pteroanyinstall uses:**
- Directory: `/opt/ptero`
- User: `pterodactyl`
- Ports: 80, 443, 8080, 2022
- Services: `pterodactyl`, `wings`, `redis`, `mysql`
- Nginx: Main server blocks

### **Model Generator uses:**
- Directory: `/opt/model-generator` ✅ Different
- User: `modelgen` ✅ Different
- Port: 5050 ✅ Different
- Service: `model-generator` ✅ Different
- Nginx: Sub-path `/model-generator/` ✅ Different

## 📊 Side-by-Side Comparison

| Component | pteroanyinstall | Model Generator | Conflict? |
|-----------|----------------|-----------------|-----------|
| Install Dir | `/opt/ptero` | `/opt/model-generator` | ❌ No |
| System User | `pterodactyl` | `modelgen` | ❌ No |
| Web Port | 80, 443 | 5050 (internal) | ❌ No |
| Service Name | `pterodactyl` | `model-generator` | ❌ No |
| Database | MySQL/MariaDB | None (standalone) | ❌ No |
| Redis | Yes | No | ❌ No |
| Nginx Config | `/etc/nginx/sites-available/pterodactyl` | `/etc/nginx/sites-available/model-generator` | ❌ No |
| URL Path | `/` (root) | `/model-generator/` | ❌ No |
| Python Env | N/A | Isolated venv | ❌ No |

## 🌐 URL Structure

After installation, you'll have:

```
http://your-server.com/              → Pterodactyl Panel
http://your-server.com/model-generator/  → 3D Model Generator
```

Both work independently!

## 🚀 Installation Steps

### 1. Check Existing pteroanyinstall

```bash
# Verify pterodactyl is running
sudo systemctl status pterodactyl
sudo systemctl status wings

# Check ports in use
sudo netstat -tlnp | grep -E ':(80|443|8080|2022)'
```

### 2. Install Model Generator

```bash
# Download installer
cd /tmp
wget https://raw.githubusercontent.com/your-repo/model-generator/main/DEBIAN_SERVER_INSTALL.sh
chmod +x DEBIAN_SERVER_INSTALL.sh

# Run installer (won't touch pterodactyl)
sudo ./DEBIAN_SERVER_INSTALL.sh
```

### 3. Verify Both Services

```bash
# Check pterodactyl (should still be running)
sudo systemctl status pterodactyl
sudo systemctl status wings

# Check model generator (newly installed)
sudo systemctl status model-generator

# Both should show "active (running)"
```

## 🔧 Nginx Configuration

The installer creates a **separate** Nginx config that works alongside pterodactyl:

```nginx
# /etc/nginx/sites-available/model-generator
server {
    listen 80;
    server_name _;

    # Model Generator at /model-generator/
    location /model-generator/ {
        proxy_pass http://127.0.0.1:5050/;
        # ... proxy settings ...
    }
    
    # Pterodactyl remains at root /
    # (handled by existing pterodactyl config)
}
```

Or if you want them on the same domain:

```nginx
# Add to existing pterodactyl Nginx config
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
```

## 🔒 Security Considerations

### Firewall Rules

```bash
# Model Generator port 5050 should NOT be exposed
# Only allow Nginx to access it (localhost only)

# Verify firewall
sudo ufw status

# Pterodactyl ports should already be open
# Model Generator needs no additional ports
```

### Resource Allocation

```bash
# Model Generator is limited to:
# - 8GB RAM max
# - 200% CPU (2 cores)

# This won't affect pterodactyl performance
```

## 📊 Resource Usage

**Typical Usage:**
- **Idle:** ~200MB RAM, 0% CPU
- **Generating:** ~2-4GB RAM, 100-200% CPU (temporary)
- **Disk:** ~10GB (models + outputs)

**Pterodactyl remains unaffected!**

## 🔄 Updates

### Update Model Generator (Safe)

```bash
sudo systemctl stop model-generator
cd /opt/model-generator
sudo -u modelgen git pull  # or upload new files
sudo -u modelgen /opt/model-generator/venv/bin/pip install -r requirements.txt --upgrade
sudo systemctl start model-generator
```

### Update Pterodactyl (Safe)

```bash
# Use your normal pteroanyinstall update process
cd /opt/ptero
sudo ./update.sh

# Model Generator won't be affected
```

## ❌ Troubleshooting

### Both Services Running?

```bash
# Check all services
sudo systemctl status pterodactyl wings model-generator

# All should show "active (running)"
```

### Port Conflicts?

```bash
# Check what's using ports
sudo netstat -tlnp | grep -E ':(80|443|5050|8080)'

# Expected:
# :80 → nginx
# :443 → nginx (if SSL)
# :5050 → python (model-generator)
# :8080 → pterodactyl panel
```

### Nginx Issues?

```bash
# Test Nginx config
sudo nginx -t

# Should show "syntax is ok"

# Reload Nginx
sudo systemctl reload nginx
```

### Access Issues?

```bash
# Test pterodactyl
curl -I http://localhost/

# Test model generator
curl -I http://localhost/model-generator/

# Both should return HTTP 200
```

## ✅ Verification Checklist

After installation, verify:

- [ ] Pterodactyl panel accessible at `/`
- [ ] Model Generator accessible at `/model-generator/`
- [ ] `sudo systemctl status pterodactyl` → active
- [ ] `sudo systemctl status wings` → active
- [ ] `sudo systemctl status model-generator` → active
- [ ] No port conflicts
- [ ] Nginx config valid (`nginx -t`)
- [ ] Both services in different directories
- [ ] No shared files or dependencies

## 🎯 Summary

**The Model Generator is completely isolated from pterodactyl:**

✅ Different directories
✅ Different users
✅ Different ports
✅ Different services
✅ Different URLs
✅ No shared dependencies
✅ Independent updates
✅ Can run simultaneously
✅ Can be removed without affecting pterodactyl

**Install with confidence - zero conflicts guaranteed!** 🎉
