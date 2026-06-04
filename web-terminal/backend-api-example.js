/**
 * Backend API Example for Enhanced SSH Terminal
 * 
 * This is a Node.js/Express example showing how to implement
 * server authentication validation with proper security.
 * 
 * Install dependencies:
 * npm install express bcrypt jsonwebtoken cors helmet
 */

const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const helmet = require('helmet');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-this';

// Middleware
app.use(helmet());
app.use(cors({
    origin: ['https://ssh.cloudmc.online', 'http://localhost:8095'],
    credentials: true
}));
app.use(express.json());

// In-memory storage (use database in production)
const servers = new Map();
const sessions = new Map();

// Rate limiting middleware
const rateLimitMap = new Map();
function rateLimit(req, res, next) {
    const ip = req.ip;
    const now = Date.now();
    const windowMs = 15 * 60 * 1000; // 15 minutes
    const maxRequests = 10;

    if (!rateLimitMap.has(ip)) {
        rateLimitMap.set(ip, []);
    }

    const requests = rateLimitMap.get(ip).filter(time => now - time < windowMs);
    requests.push(now);
    rateLimitMap.set(ip, requests);

    if (requests.length > maxRequests) {
        return res.status(429).json({ error: 'Too many requests' });
    }

    next();
}

/**
 * Register a server with encrypted credentials
 * POST /api/servers/register
 */
app.post('/api/servers/register', rateLimit, async (req, res) => {
    try {
        const { serverId, username, password, host, port } = req.body;

        if (!serverId || !username || !password) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        // Hash password with bcrypt
        const hashedPassword = await bcrypt.hash(password, 10);

        // Store server credentials
        servers.set(serverId, {
            serverId,
            username,
            password: hashedPassword,
            host,
            port,
            createdAt: new Date()
        });

        res.json({ 
            success: true, 
            message: 'Server registered successfully',
            serverId 
        });
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ error: 'Server registration failed' });
    }
});

/**
 * Authenticate and get token
 * POST /api/auth/login
 */
app.post('/api/auth/login', rateLimit, async (req, res) => {
    try {
        const { serverId, username, password } = req.body;

        if (!serverId || !username || !password) {
            return res.status(400).json({ error: 'Missing credentials' });
        }

        // Get server credentials
        const server = servers.get(serverId);
        if (!server) {
            return res.status(404).json({ error: 'Server not found' });
        }

        // Verify username
        if (username !== server.username) {
            return res.status(401).json({ error: 'Invalid username' });
        }

        // Verify password
        const passwordMatch = await bcrypt.compare(password, server.password);
        if (!passwordMatch) {
            return res.status(401).json({ error: 'Invalid password' });
        }

        // Generate JWT token
        const token = jwt.sign(
            { 
                serverId, 
                username,
                host: server.host,
                port: server.port
            },
            JWT_SECRET,
            { expiresIn: '1h' }
        );

        // Store session
        sessions.set(token, {
            serverId,
            username,
            createdAt: Date.now(),
            expiresAt: Date.now() + 3600000 // 1 hour
        });

        res.json({
            success: true,
            token,
            expiresIn: 3600,
            server: {
                serverId,
                host: server.host,
                port: server.port
            }
        });
    } catch (error) {
        console.error('Authentication error:', error);
        res.status(500).json({ error: 'Authentication failed' });
    }
});

/**
 * Validate token
 * POST /api/auth/validate
 */
app.post('/api/auth/validate', (req, res) => {
    try {
        const { token } = req.body;

        if (!token) {
            return res.status(400).json({ error: 'Token required' });
        }

        // Verify JWT
        const decoded = jwt.verify(token, JWT_SECRET);

        // Check session
        const session = sessions.get(token);
        if (!session) {
            return res.status(401).json({ error: 'Invalid session' });
        }

        // Check expiration
        if (Date.now() > session.expiresAt) {
            sessions.delete(token);
            return res.status(401).json({ error: 'Session expired' });
        }

        res.json({
            valid: true,
            serverId: decoded.serverId,
            username: decoded.username,
            expiresIn: Math.floor((session.expiresAt - Date.now()) / 1000)
        });
    } catch (error) {
        res.status(401).json({ error: 'Invalid token' });
    }
});

/**
 * Logout / Invalidate token
 * POST /api/auth/logout
 */
app.post('/api/auth/logout', (req, res) => {
    const { token } = req.body;
    
    if (token && sessions.has(token)) {
        sessions.delete(token);
    }

    res.json({ success: true, message: 'Logged out successfully' });
});

/**
 * Refresh token
 * POST /api/auth/refresh
 */
app.post('/api/auth/refresh', (req, res) => {
    try {
        const { token } = req.body;

        if (!token) {
            return res.status(400).json({ error: 'Token required' });
        }

        // Verify old token
        const decoded = jwt.verify(token, JWT_SECRET);
        const session = sessions.get(token);

        if (!session) {
            return res.status(401).json({ error: 'Invalid session' });
        }

        // Generate new token
        const newToken = jwt.sign(
            { 
                serverId: decoded.serverId, 
                username: decoded.username,
                host: decoded.host,
                port: decoded.port
            },
            JWT_SECRET,
            { expiresIn: '1h' }
        );

        // Delete old session
        sessions.delete(token);

        // Create new session
        sessions.set(newToken, {
            serverId: decoded.serverId,
            username: decoded.username,
            createdAt: Date.now(),
            expiresAt: Date.now() + 3600000
        });

        res.json({
            success: true,
            token: newToken,
            expiresIn: 3600
        });
    } catch (error) {
        res.status(401).json({ error: 'Token refresh failed' });
    }
});

// Cleanup expired sessions every 5 minutes
setInterval(() => {
    const now = Date.now();
    for (const [token, session] of sessions.entries()) {
        if (now > session.expiresAt) {
            sessions.delete(token);
        }
    }
}, 5 * 60 * 1000);

// Start server
app.listen(PORT, () => {
    console.log(`SSH Terminal Auth API running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    process.exit(0);
});
