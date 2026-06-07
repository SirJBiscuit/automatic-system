/**
 * Enhanced SSH Terminal - Authentication Server
 * 
 * Provides secure server-side authentication for the EST web interface
 * Run on port 8085, serves the EST with login protection
 */

const express = require('express');
const session = require('express-session');
const bcrypt = require('bcrypt');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 8085;

// Load password from environment or config file
const CONFIG_FILE = '/etc/automatic-system/est-auth.conf';
let PASSWORD_HASH = process.env.EST_PASSWORD_HASH;

// Try to load from config file if not in environment
if (!PASSWORD_HASH && fs.existsSync(CONFIG_FILE)) {
    const config = fs.readFileSync(CONFIG_FILE, 'utf8');
    const match = config.match(/PASSWORD_HASH="(.+)"/);
    if (match) {
        PASSWORD_HASH = match[1];
    }
}

// Default hash for 'admin' - CHANGE THIS!
if (!PASSWORD_HASH) {
    PASSWORD_HASH = '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy';
    console.warn('⚠️  Using default password hash! Run setup script to change password.');
}

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(session({
    secret: process.env.SESSION_SECRET || require('crypto').randomBytes(32).toString('hex'),
    resave: false,
    saveUninitialized: false,
    cookie: { 
        secure: process.env.NODE_ENV === 'production',
        maxAge: 24 * 60 * 60 * 1000, // 24 hours
        sameSite: 'lax',
        httpOnly: true
    }
}));

// Security headers
app.use((req, res, next) => {
    res.setHeader('X-Frame-Options', 'SAMEORIGIN');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-XSS-Protection', '1; mode=block');
    next();
});

// Authentication middleware
function requireAuth(req, res, next) {
    if (req.session && req.session.authenticated) {
        return next();
    }
    
    // For API calls, return JSON error
    if (req.path.startsWith('/api/')) {
        return res.status(401).json({ success: false, error: 'Not authenticated' });
    }
    
    // For page requests, redirect to login
    res.redirect('/login');
}

// Serve static files (index.html) - requires authentication
app.use('/static', requireAuth, express.static(path.join(__dirname)));

// Login API
app.post('/api/login', async (req, res) => {
    const { password } = req.body;
    
    if (!password) {
        return res.json({ success: false, error: 'Password required' });
    }
    
    try {
        const isValid = await bcrypt.compare(password, PASSWORD_HASH);
        
        if (isValid) {
            req.session.authenticated = true;
            req.session.loginTime = Date.now();
            res.json({ success: true });
        } else {
            res.json({ success: false, error: 'Invalid password' });
        }
    } catch (error) {
        console.error('Login error:', error);
        res.json({ success: false, error: 'Authentication error' });
    }
});

// Check auth status API
app.get('/api/auth/status', (req, res) => {
    if (req.session && req.session.authenticated) {
        res.json({ 
            authenticated: true,
            loginTime: req.session.loginTime
        });
    } else {
        res.json({ authenticated: false });
    }
});

// Logout API
app.post('/api/logout', (req, res) => {
    req.session.destroy((err) => {
        if (err) {
            return res.json({ success: false, error: 'Logout failed' });
        }
        res.json({ success: true });
    });
});

// Login page
app.get('/login', (req, res) => {
    res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Enhanced SSH Terminal - Login</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .login-container {
            background: rgba(255, 255, 255, 0.95);
            border-radius: 20px;
            padding: 50px 40px;
            width: 100%;
            max-width: 420px;
            box-shadow: 0 30px 80px rgba(0, 0, 0, 0.3);
            backdrop-filter: blur(10px);
        }
        
        .login-header {
            text-align: center;
            margin-bottom: 40px;
        }
        
        .login-header i {
            font-size: 64px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 20px;
        }
        
        .login-header h1 {
            color: #333;
            margin: 0 0 10px 0;
            font-size: 28px;
            font-weight: 700;
        }
        
        .login-header p {
            color: #666;
            margin: 0;
            font-size: 15px;
        }
        
        .form-group {
            margin-bottom: 25px;
        }
        
        .form-label {
            display: block;
            color: #555;
            margin-bottom: 10px;
            font-weight: 600;
            font-size: 14px;
        }
        
        .form-input {
            width: 100%;
            padding: 15px 20px;
            background: #f5f5f5;
            border: 2px solid transparent;
            border-radius: 12px;
            color: #333;
            font-size: 15px;
            transition: all 0.3s;
        }
        
        .form-input:focus {
            outline: none;
            border-color: #667eea;
            background: #fff;
        }
        
        .btn {
            width: 100%;
            padding: 15px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 12px;
            font-size: 16px;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .btn:hover {
            transform: translateY(-3px);
            box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4);
        }
        
        .btn:active {
            transform: translateY(-1px);
        }
        
        .login-error {
            background: #fee;
            border: 2px solid #f88;
            color: #c33;
            padding: 15px;
            border-radius: 12px;
            margin-top: 20px;
            text-align: center;
            animation: shake 0.5s;
            display: none;
        }
        
        .login-error.show {
            display: block;
        }
        
        @keyframes shake {
            0%, 100% { transform: translateX(0); }
            25% { transform: translateX(-10px); }
            75% { transform: translateX(10px); }
        }
        
        .login-footer {
            text-align: center;
            margin-top: 30px;
        }
        
        .login-footer p {
            color: #888;
            font-size: 13px;
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="login-header">
            <i class="fas fa-terminal"></i>
            <h1>Enhanced SSH Terminal</h1>
            <p>Secure Access Required</p>
        </div>
        <form id="loginForm">
            <div class="form-group">
                <label class="form-label">
                    <i class="fas fa-lock"></i> Password
                </label>
                <input 
                    type="password" 
                    id="password" 
                    name="password" 
                    class="form-input"
                    placeholder="Enter your password"
                    autocomplete="current-password"
                    required 
                    autofocus
                >
            </div>
            <button type="submit" class="btn">
                <i class="fas fa-sign-in-alt"></i> Login
            </button>
        </form>
        <div id="error" class="login-error">
            <i class="fas fa-exclamation-circle"></i> <span id="errorText">Incorrect password</span>
        </div>
        <div class="login-footer">
            <p>
                <i class="fas fa-shield-alt"></i> Protected by server-side authentication
            </p>
        </div>
    </div>
    
    <script>
        document.getElementById('loginForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const password = document.getElementById('password').value;
            const errorDiv = document.getElementById('error');
            const errorText = document.getElementById('errorText');
            
            try {
                const response = await fetch('/api/login', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ password })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    window.location.href = '/';
                } else {
                    errorText.textContent = data.error || 'Invalid password';
                    errorDiv.classList.add('show');
                    setTimeout(() => errorDiv.classList.remove('show'), 3000);
                    document.getElementById('password').value = '';
                    document.getElementById('password').focus();
                }
            } catch (error) {
                errorText.textContent = 'Login failed. Please try again.';
                errorDiv.classList.add('show');
                setTimeout(() => errorDiv.classList.remove('show'), 3000);
            }
        });
    </script>
</body>
</html>
    `);
});

// Serve main app (index.html) - requires authentication
app.get('/', requireAuth, (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// Serve any other static files - requires authentication
app.get('*', requireAuth, (req, res) => {
    const filePath = path.join(__dirname, req.path);
    if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
        res.sendFile(filePath);
    } else {
        res.status(404).send('Not found');
    }
});

// Start server
app.listen(PORT, () => {
    console.log(`Enhanced SSH Terminal Auth Server running on port ${PORT}`);
    console.log(`Access: http://localhost:${PORT}`);
    if (!process.env.EST_PASSWORD_HASH) {
        console.log('⚠️  Run setup script to set a secure password!');
    }
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    process.exit(0);
});
