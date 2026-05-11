#!/usr/bin/env python3
"""
Simple authentication server for Enhanced SSH Terminal
Provides JWT-based authentication for admin access
"""

from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import jwt
import datetime
import hashlib
import os
import secrets

app = Flask(__name__)
CORS(app)

# Configuration - CHANGE THESE IN PRODUCTION
SECRET_KEY = os.getenv('TERMINAL_SECRET_KEY', secrets.token_hex(32))
ADMIN_USERNAME = os.getenv('TERMINAL_ADMIN_USER', 'admin')
# Default password is 'admin' - CHANGE THIS!
ADMIN_PASSWORD_HASH = os.getenv('TERMINAL_ADMIN_PASS_HASH', 
    hashlib.sha256('admin'.encode()).hexdigest())

def hash_password(password):
    """Hash a password using SHA-256"""
    return hashlib.sha256(password.encode()).hexdigest()

def generate_token(username):
    """Generate JWT token"""
    payload = {
        'username': username,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24),
        'iat': datetime.datetime.utcnow()
    }
    return jwt.encode(payload, SECRET_KEY, algorithm='HS256')

def verify_token(token):
    """Verify JWT token"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None

@app.route('/api/login', methods=['POST'])
def login():
    """Handle login requests"""
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    
    if not username or not password:
        return jsonify({'success': False, 'error': 'Missing credentials'}), 400
    
    # Verify credentials
    password_hash = hash_password(password)
    if username == ADMIN_USERNAME and password_hash == ADMIN_PASSWORD_HASH:
        token = generate_token(username)
        return jsonify({
            'success': True,
            'token': token,
            'username': username
        })
    else:
        # Add small delay to prevent brute force
        import time
        time.sleep(1)
        return jsonify({'success': False, 'error': 'Invalid credentials'}), 401

@app.route('/api/verify', methods=['GET'])
def verify():
    """Verify token validity"""
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({'valid': False}), 401
    
    token = auth_header.split(' ')[1]
    payload = verify_token(token)
    
    if payload:
        return jsonify({'valid': True, 'username': payload['username']})
    else:
        return jsonify({'valid': False}), 401

@app.route('/api/logout', methods=['POST'])
def logout():
    """Handle logout (client-side token removal)"""
    return jsonify({'success': True})

@app.route('/')
def index():
    """Serve login page"""
    return send_from_directory('.', 'login.html')

@app.route('/index.html')
def terminal():
    """Serve terminal page (requires auth)"""
    # In production, verify token here
    return send_from_directory('.', 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    """Serve static files"""
    return send_from_directory('.', path)

if __name__ == '__main__':
    print("=" * 60)
    print("Enhanced SSH Terminal Authentication Server")
    print("=" * 60)
    print(f"Admin Username: {ADMIN_USERNAME}")
    print("Admin Password: [Set via TERMINAL_ADMIN_PASS_HASH env var]")
    print("\nTo set a custom password:")
    print("  python3 -c \"import hashlib; print(hashlib.sha256(b'YOUR_PASSWORD').hexdigest())\"")
    print("  export TERMINAL_ADMIN_PASS_HASH='<hash>'")
    print("\nTo generate a secure secret key:")
    print("  python3 -c \"import secrets; print(secrets.token_hex(32))\"")
    print("  export TERMINAL_SECRET_KEY='<key>'")
    print("=" * 60)
    print("\n⚠️  WARNING: Default password is 'admin' - CHANGE THIS!")
    print("=" * 60)
    
    # Run server
    app.run(host='0.0.0.0', port=8095, debug=False)
