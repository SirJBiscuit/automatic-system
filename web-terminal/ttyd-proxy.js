/**
 * TTYD Authentication Proxy
 * 
 * Provides login screen before allowing access to ttyd terminal
 * Run on port 8095, proxies to ttyd on port 7681
 */

const express = require('express');
const session = require('express-session');
const bcrypt = require('bcrypt');
const { createProxyMiddleware } = require('http-proxy-middleware');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 8095;
const TTYD_PORT = process.env.TTYD_PORT || 7681;

// Load password from environment or use default (CHANGE THIS!)
const PASSWORD_HASH = process.env.PASSWORD_HASH || '$2b$10$rBV2pXq9QJZYfJlJKx.xHOqGxE8L0qYvJZQXqYxKQxQxQxQxQxQxQ'; // 'admin123'

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(session({
    secret: process.env.SESSION_SECRET || 'change-this-secret-key',
    resave: false,
    saveUninitialized: false,
    cookie: { 
        secure: false, // Set to true if using HTTPS
        maxAge: 3600000 // 1 hour
    }
}));

// Serve static files for login page
app.use('/static', express.static(path.join(__dirname, 'public')));

// Authentication middleware
function requireAuth(req, res, next) {
    if (req.session && req.session.authenticated) {
        return next();
    }
    res.redirect('/login');
}

// Login page
app.get('/login', (req, res) => {
    res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Direct Terminal - Login</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #1a1a1a 0%, #2d1b4e 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .login-screen {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: linear-gradient(135deg, #1a1a1a 0%, #2d1b4e 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 10000;
        }
        
        .login-container {
            background: #1e1e1e;
            border: 1px solid #333;
            border-radius: 16px;
            padding: 40px;
            width: 100%;
            max-width: 400px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
        }
        
        .login-header {
            text-align: center;
            margin-bottom: 32px;
        }
        
        .login-header i {
            font-size: 48px;
            color: #667eea;
            margin-bottom: 16px;
        }
        
        .login-header h1 {
            color: #fff;
            margin: 0 0 8px 0;
            font-size: 24px;
        }
        
        .login-header p {
            color: #888;
            margin: 0;
            font-size: 14px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-label {
            display: block;
            color: #ccc;
            margin-bottom: 8px;
            font-weight: 500;
            font-size: 14px;
        }
        
        .form-label i {
            margin-right: 6px;
        }
        
        .form-input {
            width: 100%;
            padding: 12px;
            background: #2a2a2a;
            border: 1px solid #444;
            border-radius: 8px;
            color: #fff;
            font-size: 14px;
            transition: all 0.3s;
        }
        
        .form-input:focus {
            outline: none;
            border-color: #667eea;
            background: #333;
        }
        
        .btn {
            width: 100%;
            padding: 12px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 20px rgba(102, 126, 234, 0.4);
        }
        
        .login-error {
            background: rgba(239, 68, 68, 0.1);
            border: 1px solid #ef4444;
            color: #ef4444;
            padding: 12px;
            border-radius: 8px;
            margin-top: 16px;
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
            margin-top: 24px;
        }
        
        .login-footer p {
            color: #666;
            font-size: 12px;
            margin: 16px 0 0 0;
        }
        
        .login-footer i {
            margin-right: 4px;
        }
    </style>
</head>
<body>
    <div class="login-screen">
        <div class="login-container">
            <div class="login-header">
                <i class="fas fa-terminal"></i>
                <h1>Direct Terminal</h1>
                <p>Admin Access Required</p>
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
                        placeholder="Enter admin password"
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
                    <i class="fas fa-info-circle"></i> Direct access to system terminal
                </p>
            </div>
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

// Login API
app.post('/api/login', async (req, res) => {
    const { password } = req.body;
    
    if (!password) {
        return res.json({ success: false, error: 'Password required' });
    }
    
    try {
        // For demo, use simple comparison (use bcrypt in production)
        // To generate hash: bcrypt.hash('yourpassword', 10)
        const isValid = await bcrypt.compare(password, PASSWORD_HASH);
        
        if (isValid) {
            req.session.authenticated = true;
            res.json({ success: true });
        } else {
            res.json({ success: false, error: 'Invalid password' });
        }
    } catch (error) {
        res.json({ success: false, error: 'Authentication error' });
    }
});

// Logout
app.get('/logout', (req, res) => {
    req.session.destroy();
    res.redirect('/login');
});

// Proxy to ttyd (requires authentication)
app.use('/', requireAuth, createProxyMiddleware({
    target: `http://localhost:${TTYD_PORT}`,
    changeOrigin: true,
    ws: true, // Enable WebSocket proxying
    onError: (err, req, res) => {
        console.error('Proxy error:', err);
        res.status(500).send('Terminal connection error');
    }
}));

// Start server
app.listen(PORT, () => {
    console.log(`TTYD Proxy running on port ${PORT}`);
    console.log(`Proxying to ttyd on port ${TTYD_PORT}`);
    console.log(`Access: http://localhost:${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    process.exit(0);
});
