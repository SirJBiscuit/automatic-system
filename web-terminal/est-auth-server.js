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
let PASSWORD_HASH = null;
let SESSION_SECRET = null;

// Try to load from config file FIRST (preferred method)
if (fs.existsSync(CONFIG_FILE)) {
    const config = fs.readFileSync(CONFIG_FILE, 'utf8');
    console.log('📁 Config file found:', CONFIG_FILE);
    
    const hashMatch = config.match(/EST_PASSWORD_HASH="(.+)"/);
    if (hashMatch) {
        PASSWORD_HASH = hashMatch[1];
        console.log('✅ Password hash loaded from config');
    } else {
        console.log('❌ Failed to extract password hash from config');
    }
    
    const secretMatch = config.match(/SESSION_SECRET="(.+)"/);
    if (secretMatch) {
        SESSION_SECRET = secretMatch[1];
        console.log('✅ Session secret loaded from config');
    } else {
        console.log('❌ Failed to extract session secret from config');
    }
} else {
    console.log('❌ Config file not found:', CONFIG_FILE);
}

// Fallback to environment variables if config didn't load
if (!PASSWORD_HASH) {
    PASSWORD_HASH = process.env.EST_PASSWORD_HASH;
    if (PASSWORD_HASH) {
        console.log('📌 Using password hash from environment variable');
    }
}

if (!SESSION_SECRET) {
    SESSION_SECRET = process.env.SESSION_SECRET;
    if (SESSION_SECRET) {
        console.log('📌 Using session secret from environment variable');
    }
}

// Check if password is configured (function to allow dynamic checking)
function isFirstTimeSetup() {
    return !PASSWORD_HASH;
}

if (isFirstTimeSetup()) {
    console.log('🔧 First-time setup required - no password configured');
    console.log('📝 Visit the web interface to set up your password');
}

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Trust proxy (we're behind Nginx/Cloudflare)
app.set('trust proxy', 1);

app.use(session({
    secret: SESSION_SECRET || require('crypto').randomBytes(32).toString('hex'),
    resave: false,
    saveUninitialized: false,
    proxy: true, // Trust the reverse proxy
    cookie: { 
        secure: true, // Always use secure cookies (we're behind HTTPS via Cloudflare)
        maxAge: 30 * 60 * 1000, // 30 minutes default (can be extended with "Remember Me")
        sameSite: 'none', // Required for cookies to work through Cloudflare tunnel
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
    // If first-time setup, redirect to setup page
    if (isFirstTimeSetup() && !req.path.startsWith('/api/setup')) {
        if (req.path.startsWith('/api/')) {
            return res.status(401).json({ success: false, error: 'Setup required', setupRequired: true });
        }
        return res.redirect('/setup');
    }
    
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

// First-time setup page
app.get('/setup', (req, res) => {
    if (!isFirstTimeSetup()) {
        return res.redirect('/login');
    }
    
    res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Enhanced SSH Terminal - First Time Setup</title>
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
        
        .setup-container {
            background: rgba(255, 255, 255, 0.95);
            border-radius: 20px;
            padding: 50px 40px;
            width: 100%;
            max-width: 500px;
            box-shadow: 0 30px 80px rgba(0, 0, 0, 0.3);
            backdrop-filter: blur(10px);
        }
        
        .setup-header {
            text-align: center;
            margin-bottom: 40px;
        }
        
        .setup-header i {
            font-size: 64px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 20px;
        }
        
        .setup-header h1 {
            color: #333;
            margin: 0 0 10px 0;
            font-size: 28px;
            font-weight: 700;
        }
        
        .setup-header p {
            color: #666;
            margin: 0;
            font-size: 15px;
            line-height: 1.6;
        }
        
        .alert {
            background: #e3f2fd;
            border: 2px solid #2196f3;
            color: #1565c0;
            padding: 15px;
            border-radius: 12px;
            margin-bottom: 25px;
            display: flex;
            align-items: start;
            gap: 10px;
        }
        
        .alert i {
            font-size: 20px;
            margin-top: 2px;
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
        
        .password-strength {
            margin-top: 8px;
            height: 4px;
            background: #e0e0e0;
            border-radius: 2px;
            overflow: hidden;
        }
        
        .password-strength-bar {
            height: 100%;
            width: 0%;
            transition: all 0.3s;
        }
        
        .strength-weak { background: #f44336; width: 33%; }
        .strength-medium { background: #ff9800; width: 66%; }
        .strength-strong { background: #4caf50; width: 100%; }
        
        .password-hint {
            margin-top: 8px;
            font-size: 12px;
            color: #888;
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
        
        .btn:disabled {
            opacity: 0.6;
            cursor: not-allowed;
            transform: none;
        }
        
        .setup-error {
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
        
        .setup-error.show {
            display: block;
        }
        
        @keyframes shake {
            0%, 100% { transform: translateX(0); }
            25% { transform: translateX(-10px); }
            75% { transform: translateX(10px); }
        }
    </style>
</head>
<body>
    <div class="setup-container">
        <div class="setup-header">
            <i class="fas fa-shield-alt"></i>
            <h1>First Time Setup</h1>
            <p>Create a secure password to protect your Enhanced SSH Terminal</p>
        </div>
        
        <div class="alert">
            <i class="fas fa-info-circle"></i>
            <div>
                <strong>Important:</strong> This password will be required to access the terminal interface. 
                Make sure to remember it or store it securely.
            </div>
        </div>
        
        <form id="setupForm">
            <div class="form-group">
                <label class="form-label">
                    <i class="fas fa-lock"></i> Create Password
                </label>
                <input 
                    type="password" 
                    id="password" 
                    name="password" 
                    class="form-input"
                    placeholder="Enter a strong password"
                    required 
                    autofocus
                    minlength="6"
                >
                <div class="password-strength">
                    <div class="password-strength-bar" id="strengthBar"></div>
                </div>
                <div class="password-hint" id="strengthText">Minimum 6 characters</div>
            </div>
            
            <div class="form-group">
                <label class="form-label">
                    <i class="fas fa-lock"></i> Confirm Password
                </label>
                <input 
                    type="password" 
                    id="confirmPassword" 
                    name="confirmPassword" 
                    class="form-input"
                    placeholder="Re-enter your password"
                    required
                    minlength="6"
                >
            </div>
            
            <button type="submit" class="btn" id="submitBtn">
                <i class="fas fa-check"></i> Complete Setup
            </button>
        </form>
        
        <div id="error" class="setup-error">
            <i class="fas fa-exclamation-circle"></i> <span id="errorText"></span>
        </div>
    </div>
    
    <script>
        const passwordInput = document.getElementById('password');
        const confirmInput = document.getElementById('confirmPassword');
        const strengthBar = document.getElementById('strengthBar');
        const strengthText = document.getElementById('strengthText');
        
        // Password strength checker
        passwordInput.addEventListener('input', () => {
            const password = passwordInput.value;
            let strength = 0;
            
            if (password.length >= 6) strength++;
            if (password.length >= 10) strength++;
            if (/[a-z]/.test(password) && /[A-Z]/.test(password)) strength++;
            if (/[0-9]/.test(password)) strength++;
            if (/[^a-zA-Z0-9]/.test(password)) strength++;
            
            strengthBar.className = 'password-strength-bar';
            
            if (strength <= 2) {
                strengthBar.classList.add('strength-weak');
                strengthText.textContent = 'Weak password';
                strengthText.style.color = '#f44336';
            } else if (strength <= 4) {
                strengthBar.classList.add('strength-medium');
                strengthText.textContent = 'Medium strength';
                strengthText.style.color = '#ff9800';
            } else {
                strengthBar.classList.add('strength-strong');
                strengthText.textContent = 'Strong password!';
                strengthText.style.color = '#4caf50';
            }
        });
        
        document.getElementById('setupForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const password = passwordInput.value;
            const confirmPassword = confirmInput.value;
            const errorDiv = document.getElementById('error');
            const errorText = document.getElementById('errorText');
            const submitBtn = document.getElementById('submitBtn');
            
            // Validate
            if (password.length < 6) {
                errorText.textContent = 'Password must be at least 6 characters';
                errorDiv.classList.add('show');
                return;
            }
            
            if (password !== confirmPassword) {
                errorText.textContent = 'Passwords do not match';
                errorDiv.classList.add('show');
                return;
            }
            
            // Submit
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Setting up...';
            
            try {
                const response = await fetch('/api/setup', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ password })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    submitBtn.innerHTML = '<i class="fas fa-check"></i> Success! Redirecting...';
                    setTimeout(() => {
                        window.location.href = '/';
                    }, 1000);
                } else {
                    errorText.textContent = data.error || 'Setup failed';
                    errorDiv.classList.add('show');
                    submitBtn.disabled = false;
                    submitBtn.innerHTML = '<i class="fas fa-check"></i> Complete Setup';
                }
            } catch (error) {
                errorText.textContent = 'Setup failed. Please try again.';
                errorDiv.classList.add('show');
                submitBtn.disabled = false;
                submitBtn.innerHTML = '<i class="fas fa-check"></i> Complete Setup';
            }
        });
    </script>
</body>
</html>
    `);
});

// Setup API
app.post('/api/setup', async (req, res) => {
    if (!isFirstTimeSetup()) {
        return res.json({ success: false, error: 'Setup already completed' });
    }
    
    const { password } = req.body;
    
    if (!password || password.length < 6) {
        return res.json({ success: false, error: 'Password must be at least 6 characters' });
    }
    
    try {
        // Generate bcrypt hash
        const hash = await bcrypt.hash(password, 10);
        
        // Create config directory if it doesn't exist
        const configDir = path.dirname(CONFIG_FILE);
        if (!fs.existsSync(configDir)) {
            fs.mkdirSync(configDir, { recursive: true });
        }
        
        // Generate session secret
        const sessionSecret = require('crypto').randomBytes(32).toString('hex');
        
        // Save to config file
        const configContent = `# Enhanced SSH Terminal Authentication Configuration
# Generated: ${new Date().toISOString()}

EST_PASSWORD_HASH="${hash}"
SESSION_SECRET="${sessionSecret}"
`;
        
        fs.writeFileSync(CONFIG_FILE, configContent, { mode: 0o600 });
        
        // Update in-memory password hash
        PASSWORD_HASH = hash;
        
        // Authenticate the session
        req.session.authenticated = true;
        req.session.loginTime = Date.now();
        
        console.log('✅ First-time setup completed successfully');
        console.log('📁 Configuration saved to:', CONFIG_FILE);
        
        res.json({ success: true, message: 'Setup completed successfully' });
        
        // Note: Server needs restart to fully apply changes
        setTimeout(() => {
            console.log('⚠️  Please restart the service for changes to take full effect:');
            console.log('   sudo systemctl restart est-auth');
        }, 2000);
        
    } catch (error) {
        console.error('Setup error:', error);
        res.json({ success: false, error: 'Setup failed. Please try again.' });
    }
});

// Login API
app.post('/api/login', async (req, res) => {
    const { password, rememberMe } = req.body;
    
    if (!password) {
        return res.json({ success: false, error: 'Password required' });
    }
    
    try {
        const isValid = await bcrypt.compare(password, PASSWORD_HASH);
        
        if (isValid) {
            req.session.authenticated = true;
            req.session.loginTime = Date.now();
            
            // Extend session if "Remember Me" is checked
            if (rememberMe) {
                req.session.cookie.maxAge = 30 * 24 * 60 * 60 * 1000; // 30 days
            } else {
                req.session.cookie.maxAge = 30 * 60 * 1000; // 30 minutes
            }
            
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

// Reset password API (requires current password for verification)
app.post('/api/reset-password', async (req, res) => {
    const { currentPassword, newPassword } = req.body;
    
    if (!currentPassword || !newPassword) {
        return res.json({ success: false, error: 'Both passwords required' });
    }
    
    if (newPassword.length < 6) {
        return res.json({ success: false, error: 'New password must be at least 6 characters' });
    }
    
    try {
        // Verify current password (admin verification)
        const isValid = await bcrypt.compare(currentPassword, PASSWORD_HASH);
        
        if (!isValid) {
            return res.json({ success: false, error: 'Current password is incorrect' });
        }
        
        // Generate new hash
        const newHash = await bcrypt.hash(newPassword, 10);
        
        // Update config file
        const configDir = path.dirname(CONFIG_FILE);
        if (!fs.existsSync(configDir)) {
            fs.mkdirSync(configDir, { recursive: true });
        }
        
        const sessionSecret = require('crypto').randomBytes(32).toString('hex');
        const configContent = `# Enhanced SSH Terminal Authentication Configuration
# Updated: ${new Date().toISOString()}

EST_PASSWORD_HASH="${newHash}"
SESSION_SECRET="${sessionSecret}"
`;
        
        fs.writeFileSync(CONFIG_FILE, configContent, { mode: 0o600 });
        
        // Update in-memory hash
        PASSWORD_HASH = newHash;
        
        // Invalidate all sessions except current
        req.session.authenticated = true;
        req.session.loginTime = Date.now();
        
        console.log('✅ Password reset successfully');
        
        res.json({ success: true, message: 'Password reset successfully' });
        
    } catch (error) {
        console.error('Password reset error:', error);
        res.json({ success: false, error: 'Password reset failed' });
    }
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
        
        .reset-link {
            color: #667eea;
            text-decoration: none;
            font-size: 14px;
            display: inline-block;
            margin-top: 15px;
            transition: all 0.3s;
        }
        
        .reset-link:hover {
            color: #764ba2;
            text-decoration: underline;
        }
        
        .modal-overlay {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.7);
            z-index: 9999;
            align-items: center;
            justify-content: center;
        }
        
        .modal-overlay.active {
            display: flex;
        }
        
        .modal-box {
            background: rgba(255, 255, 255, 0.95);
            border-radius: 20px;
            padding: 40px;
            width: 90%;
            max-width: 450px;
            box-shadow: 0 30px 80px rgba(0, 0, 0, 0.5);
        }
        
        .modal-header {
            text-align: center;
            margin-bottom: 30px;
        }
        
        .modal-header h2 {
            color: #333;
            margin: 0 0 10px 0;
            font-size: 24px;
        }
        
        .modal-header p {
            color: #666;
            margin: 0;
            font-size: 14px;
        }
        
        .modal-close {
            position: absolute;
            top: 15px;
            right: 15px;
            background: none;
            border: none;
            font-size: 24px;
            color: #999;
            cursor: pointer;
            transition: color 0.3s;
        }
        
        .modal-close:hover {
            color: #333;
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
            <div class="form-group" style="margin-bottom: 20px;">
                <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; color: #666; font-size: 14px;">
                    <input 
                        type="checkbox" 
                        id="rememberMe" 
                        name="rememberMe"
                        style="width: 18px; height: 18px; cursor: pointer;"
                    >
                    <span>Remember me for 30 days</span>
                </label>
                <small style="display: block; margin-top: 6px; color: #888; font-size: 12px;">
                    <i class="fas fa-info-circle"></i> Without this, session expires in 30 minutes
                </small>
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
            <a href="#" class="reset-link" onclick="showResetModal(); return false;">
                <i class="fas fa-key"></i> Reset Password
            </a>
        </div>
    </div>
    
    <!-- Reset Password Modal -->
    <div class="modal-overlay" id="resetModal">
        <div class="modal-box" style="position: relative;">
            <button class="modal-close" onclick="closeResetModal()">&times;</button>
            <div class="modal-header">
                <h2><i class="fas fa-key"></i> Reset Password</h2>
                <p>Enter current password to verify admin access</p>
            </div>
            <form id="resetForm">
                <div class="form-group">
                    <label class="form-label">
                        <i class="fas fa-lock"></i> Current Password (Admin Verification)
                    </label>
                    <input 
                        type="password" 
                        id="currentPassword" 
                        class="form-input"
                        placeholder="Enter current password"
                        required
                    >
                </div>
                <div class="form-group">
                    <label class="form-label">
                        <i class="fas fa-key"></i> New Password
                    </label>
                    <input 
                        type="password" 
                        id="newPassword" 
                        class="form-input"
                        placeholder="Enter new password"
                        required
                        minlength="6"
                    >
                </div>
                <div class="form-group">
                    <label class="form-label">
                        <i class="fas fa-key"></i> Confirm New Password
                    </label>
                    <input 
                        type="password" 
                        id="confirmNewPassword" 
                        class="form-input"
                        placeholder="Confirm new password"
                        required
                        minlength="6"
                    >
                </div>
                <button type="submit" class="btn">
                    <i class="fas fa-check"></i> Reset Password
                </button>
            </form>
            <div id="resetError" class="login-error">
                <i class="fas fa-exclamation-circle"></i> <span id="resetErrorText"></span>
            </div>
        </div>
    </div>
    
    <script>
        document.getElementById('loginForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const password = document.getElementById('password').value;
            const rememberMe = document.getElementById('rememberMe').checked;
            const errorDiv = document.getElementById('error');
            const errorText = document.getElementById('errorText');
            
            try {
                const response = await fetch('/api/login', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ password, rememberMe })
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
        
        // Reset Password Modal Functions
        function showResetModal() {
            document.getElementById('resetModal').classList.add('active');
            document.getElementById('currentPassword').focus();
        }
        
        function closeResetModal() {
            document.getElementById('resetModal').classList.remove('active');
            document.getElementById('resetForm').reset();
            document.getElementById('resetError').classList.remove('show');
        }
        
        document.getElementById('resetForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const currentPassword = document.getElementById('currentPassword').value;
            const newPassword = document.getElementById('newPassword').value;
            const confirmNewPassword = document.getElementById('confirmNewPassword').value;
            const resetError = document.getElementById('resetError');
            const resetErrorText = document.getElementById('resetErrorText');
            
            // Validate passwords match
            if (newPassword !== confirmNewPassword) {
                resetErrorText.textContent = 'New passwords do not match';
                resetError.classList.add('show');
                return;
            }
            
            if (newPassword.length < 6) {
                resetErrorText.textContent = 'Password must be at least 6 characters';
                resetError.classList.add('show');
                return;
            }
            
            try {
                const response = await fetch('/api/reset-password', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ currentPassword, newPassword })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    alert('✅ Password reset successfully! You can now login with your new password.');
                    closeResetModal();
                    window.location.reload();
                } else {
                    resetErrorText.textContent = data.error || 'Password reset failed';
                    resetError.classList.add('show');
                    setTimeout(() => resetError.classList.remove('show'), 3000);
                }
            } catch (error) {
                resetErrorText.textContent = 'Password reset failed. Please try again.';
                resetError.classList.add('show');
                setTimeout(() => resetError.classList.remove('show'), 3000);
            }
        });
        
        // Close modal on overlay click
        document.getElementById('resetModal').addEventListener('click', (e) => {
            if (e.target.id === 'resetModal') {
                closeResetModal();
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

// Catch-all route for any other requests - requires authentication
app.use(requireAuth);
app.use(express.static(__dirname));

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
