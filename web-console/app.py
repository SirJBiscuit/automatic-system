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

@app.route('/api/servers/<server_id>/players')
def get_players(server_id):
    """Get player list for server"""
    if not check_auth():
        return jsonify({'error': 'Unauthorized'}), 401
    
    try:
        # Send 'list' command to get players (works for most game servers)
        response = requests.post(
            f'{PTERODACTYL_URL}/api/client/servers/{server_id}/command',
            headers=headers,
            json={'command': 'list'}
        )
        
        # Note: Actual player data would need WebSocket console streaming
        # This is a placeholder for the feature
        return jsonify({
            'players': [],
            'max_players': 0,
            'online': 0,
            'note': 'Player tracking requires WebSocket console streaming'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/system/stats')
def get_system_stats():
    """Get system-wide statistics including GPU"""
    if not check_auth():
        return jsonify({'error': 'Unauthorized'}), 401
    
    try:
        import psutil
        
        # CPU Stats
        cpu_percent = psutil.cpu_percent(interval=1, percpu=True)
        cpu_freq = psutil.cpu_freq()
        
        # Memory Stats
        memory = psutil.virtual_memory()
        
        # Disk Stats
        disk = psutil.disk_usage('/')
        
        # Network Stats
        net_io = psutil.net_io_counters()
        
        stats = {
            'cpu': {
                'percent': round(sum(cpu_percent) / len(cpu_percent), 1),
                'cores': cpu_percent,
                'frequency': round(cpu_freq.current, 0) if cpu_freq else 0,
                'count': psutil.cpu_count()
            },
            'memory': {
                'total': memory.total,
                'used': memory.used,
                'percent': memory.percent,
                'available': memory.available
            },
            'disk': {
                'total': disk.total,
                'used': disk.used,
                'free': disk.free,
                'percent': disk.percent
            },
            'network': {
                'bytes_sent': net_io.bytes_sent,
                'bytes_recv': net_io.bytes_recv,
                'packets_sent': net_io.packets_sent,
                'packets_recv': net_io.packets_recv
            }
        }
        
        # Try to get GPU stats (NVIDIA)
        try:
            import subprocess
            nvidia_smi = subprocess.check_output(
                ['nvidia-smi', '--query-gpu=index,name,temperature.gpu,utilization.gpu,memory.used,memory.total', '--format=csv,noheader,nounits'],
                encoding='utf-8'
            )
            
            gpus = []
            for line in nvidia_smi.strip().split('\n'):
                parts = [p.strip() for p in line.split(',')]
                if len(parts) >= 6:
                    gpus.append({
                        'index': int(parts[0]),
                        'name': parts[1],
                        'temperature': int(parts[2]),
                        'utilization': int(parts[3]),
                        'memory_used': int(parts[4]),
                        'memory_total': int(parts[5])
                    })
            
            stats['gpu'] = {
                'available': True,
                'count': len(gpus),
                'devices': gpus
            }
        except:
            stats['gpu'] = {
                'available': False,
                'count': 0,
                'devices': []
            }
        
        return jsonify(stats)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/servers/<server_id>/metrics')
def get_server_metrics(server_id):
    """Get detailed server metrics"""
    if not check_auth():
        return jsonify({'error': 'Unauthorized'}), 401
    
    try:
        response = requests.get(
            f'{PTERODACTYL_URL}/api/client/servers/{server_id}/resources',
            headers=headers
        )
        
        if response.status_code == 200:
            data = response.json()
            resources = data.get('attributes', {}).get('resources', {})
            
            metrics = {
                'cpu': {
                    'current': resources.get('cpu_absolute', 0),
                    'limit': 100  # Would need to get from server limits
                },
                'memory': {
                    'current': resources.get('memory_bytes', 0),
                    'limit': resources.get('memory_limit_bytes', 0)
                },
                'disk': {
                    'current': resources.get('disk_bytes', 0),
                    'limit': resources.get('disk_limit_bytes', 0)
                },
                'network': {
                    'rx': resources.get('network_rx_bytes', 0),
                    'tx': resources.get('network_tx_bytes', 0)
                },
                'uptime': resources.get('uptime', 0),
                'state': data.get('attributes', {}).get('current_state', 'unknown')
            }
            
            return jsonify(metrics)
        else:
            return jsonify({'error': 'Failed to fetch metrics'}), 500
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
