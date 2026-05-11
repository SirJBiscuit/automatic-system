# Enhanced SSH Terminal - Authentication Setup

## 🔐 Security Features

- **JWT-based authentication** with 24-hour token expiration
- **SHA-256 password hashing**
- **Brute-force protection** with login delays
- **HTTPS recommended** for production use
- **Environment variable configuration** for secrets

## 📋 Installation

### 1. Install Dependencies

```bash
cd /var/www/enhanced-terminal
pip3 install flask flask-cors pyjwt
```

### 2. Set Admin Password

**Generate password hash:**
```bash
python3 -c "import hashlib; print(hashlib.sha256(b'YOUR_SECURE_PASSWORD').hexdigest())"
```

**Set environment variable:**
```bash
export TERMINAL_ADMIN_PASS_HASH='<your_hash_here>'
```

### 3. Generate Secret Key

```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
export TERMINAL_SECRET_KEY='<your_key_here>'
```

### 4. Create Systemd Service

Create `/etc/systemd/system/terminal-auth.service`:

```ini
[Unit]
Description=Enhanced SSH Terminal Authentication
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/enhanced-terminal
Environment="TERMINAL_ADMIN_USER=admin"
Environment="TERMINAL_ADMIN_PASS_HASH=<your_hash>"
Environment="TERMINAL_SECRET_KEY=<your_key>"
ExecStart=/usr/bin/python3 /var/www/enhanced-terminal/auth.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

### 5. Start Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable terminal-auth
sudo systemctl start terminal-auth
sudo systemctl status terminal-auth
```

## 🌐 Nginx Configuration

### Update Nginx to Proxy Auth Server

Edit your nginx config (e.g., `/etc/nginx/sites-available/enhanced-terminal`):

```nginx
server {
    listen 80;
    server_name termux.cloudmc.online;

    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name termux.cloudmc.online;

    # SSL Configuration (Cloudflare or Let's Encrypt)
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Auth endpoints
    location /api/ {
        proxy_pass http://127.0.0.1:8095;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # Static files (login page, terminal)
    location / {
        proxy_pass http://127.0.0.1:8095;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }

    # Terminal WebSocket (ttyd)
    location /terminal/ {
        proxy_pass http://127.0.0.1:7681/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
    }
}
```

### Reload Nginx

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## 🔒 HTTPS Setup

### Option 1: Cloudflare Tunnel (Recommended)

If using Cloudflare Tunnel, HTTPS is automatic! No certificate needed.

### Option 2: Let's Encrypt

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d termux.cloudmc.online
```

### Option 3: Self-Signed (Development Only)

```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/terminal.key \
  -out /etc/ssl/certs/terminal.crt
```

## 🎯 Usage

1. **Access terminal:** https://termux.cloudmc.online
2. **Login with admin credentials**
3. **Token stored in localStorage** (24-hour expiration)
4. **Auto-logout on token expiration**

## 🛡️ Security Best Practices

1. **Always use HTTPS in production**
2. **Change default password immediately**
3. **Use strong, unique passwords**
4. **Rotate secret keys periodically**
5. **Monitor login attempts**
6. **Keep dependencies updated**
7. **Use firewall rules to restrict access**

## 🔧 Troubleshooting

### Check Auth Service Status
```bash
sudo systemctl status terminal-auth
sudo journalctl -u terminal-auth -f
```

### Test Login API
```bash
curl -X POST http://localhost:8095/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'
```

### Reset Password
```bash
# Generate new hash
python3 -c "import hashlib; print(hashlib.sha256(b'new_password').hexdigest())"

# Update service
sudo systemctl edit terminal-auth
# Add: Environment="TERMINAL_ADMIN_PASS_HASH=<new_hash>"

sudo systemctl restart terminal-auth
```

## 📝 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `TERMINAL_ADMIN_USER` | Admin username | `admin` |
| `TERMINAL_ADMIN_PASS_HASH` | SHA-256 password hash | Hash of `admin` |
| `TERMINAL_SECRET_KEY` | JWT signing key | Random 32-byte hex |

## ⚠️ Important Notes

- **Default password is `admin`** - Change immediately!
- **HTTP is insecure** - Use HTTPS in production
- **Tokens expire after 24 hours**
- **Failed logins have 1-second delay** to prevent brute force
- **Store secrets in environment variables**, not in code
