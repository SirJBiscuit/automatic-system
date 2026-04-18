#!/usr/bin/env python3
"""
Pterodactyl Web Console
Web-based dashboard for managing Pterodactyl game servers
"""

from flask import Flask, render_template, request, jsonify, session, redirect, url_for
from flask_socketio import SocketIO, emit
import requests
import os
from datetime import datetime
import secrets

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', secrets.token_hex(32))
socketio = SocketIO(app, cors_allowed_origins="*")

# Configuration
PTERODACTYL_URL = os.getenv('PTERODACTYL_URL', 'https://panel.yourdomain.com')
PTERODACTYL_API_KEY = os.getenv('PTERODACTYL_API_KEY', '')
WEB_USERNAME = os.getenv('WEB_USERNAME', 'admin')
WEB_PASSWORD = os.getenv('WEB_PASSWORD', 'changeme')

# API Headers
headers = {
    'Authorization': f'Bearer {PTERODACTYL_API_KEY}',
    'Accept': 'application/json',
    'Content-Type': 'application/json'
}

def check_auth():
    """Check if user is authenticated"""
    return session.get('authenticated', False)

@app.route('/')
def index():
    """Main dashboard"""
    if not check_auth():
        return redirect(url_for('login'))
    return render_template('dashboard.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    """Login page"""
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        if username == WEB_USERNAME and password == WEB_PASSWORD:
            session['authenticated'] = True
            return redirect(url_for('index'))
        else:
            return render_template('login.html', error='Invalid credentials')
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    """Logout"""
    session.clear()
    return redirect(url_for('login'))

@app.route('/api/servers')
def get_servers():
    """Get all servers"""
    if not check_auth():
        return jsonify({'error': 'Unauthorized'}), 401
    
    try:
        response = requests.get(
            f'{PTERODACTYL_URL}/api/client',
            headers=headers
        )
        
        if response.status_code == 200:
            return jsonify(response.json())
        else:
            return jsonify({'error': 'Failed to fetch servers'}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/servers/<server_id>/status')
def get_server_status(server_id):
    """Get server status"""
    if not check_auth():
        return jsonify({'error': 'Unauthorized'}), 401
    
    try:
        response = requests.get(
            f'{PTERODACTYL_URL}/api/client/servers/{server_id}/resources',
            headers=headers
        )
        
        if response.status_code == 200:
            return jsonify(response.json())
        else:
            return jsonify({'error': 'Failed to fetch status'}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/servers/<server_id>/power', methods=['POST'])
def server_power(server_id):
    """Send power action to server"""
    if not check_auth():
        return jsonify({'error': 'Unauthorized'}), 401
    
    action = request.json.get('action')
    
    try:
        response = requests.post(
            f'{PTERODACTYL_URL}/api/client/servers/{server_id}/power',
            headers=headers,
            json={'signal': action}
        )
        
        if response.status_code == 204:
            return jsonify({'success': True})
        else:
            return jsonify({'error': 'Failed to send power action'}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/servers/<server_id>/command', methods=['POST'])
def send_command(server_id):
    """Send console command"""
    if not check_auth():
        return jsonify({'error': 'Unauthorized'}), 401
    
    command = request.json.get('command')
    
    try:
        response = requests.post(
            f'{PTERODACTYL_URL}/api/client/servers/{server_id}/command',
            headers=headers,
            json={'command': command}
        )
        
        if response.status_code == 204:
            return jsonify({'success': True})
        else:
            return jsonify({'error': 'Failed to send command'}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@socketio.on('connect')
def handle_connect():
    """Handle WebSocket connection"""
    if not check_auth():
        return False
    emit('connected', {'message': 'Connected to server'})

@socketio.on('subscribe_server')
def handle_subscribe(data):
    """Subscribe to server updates"""
    server_id = data.get('server_id')
    # In production, you'd set up actual console streaming here
    emit('subscribed', {'server_id': server_id})

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=False)
