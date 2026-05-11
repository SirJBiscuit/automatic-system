#!/usr/bin/env python3
"""
Pterodactyl Web Console
Web-based dashboard for managing Pterodactyl game servers
"""

from flask import Flask, render_template, request, jsonify, session, redirect, url_for
from flask_socketio import SocketIO, emit
from werkzeug.middleware.proxy_fix import ProxyFix
import requests
import os
from datetime import datetime
import secrets
import logging
import websocket
import threading
import json as json_lib

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', secrets.token_hex(32))

# Support for Cloudflare Tunnel and reverse proxies
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1, x_prefix=1)

socketio = SocketIO(app, cors_allowed_origins="*", async_mode='threading')

# Configuration
PTERODACTYL_URL = os.getenv('PTERODACTYL_URL', 'https://panel.yourdomain.com')
PTERODACTYL_API_KEY = os.getenv('PTERODACTYL_API_KEY', '')
WEB_USERNAME = os.getenv('WEB_USERNAME', 'admin')
WEB_PASSWORD = os.getenv('WEB_PASSWORD', 'changeme')

# Active WebSocket connections for console streaming
active_console_connections = {}

# API Headers
headers = {
    'Authorization': f'Bearer {PTERODACTYL_API_KEY}',
    'Accept': 'application/json',
    'Content-Type': 'application/json'
}

def check_auth():
    """Check if user is authenticated"""
    return session.get('authenticated', False)

@app.route('/health')
def health():
    """Health check endpoint for monitoring"""
    return jsonify({
        'status': 'healthy',
        'service': 'pterodactyl-web-console',
        'timestamp': datetime.now().isoformat()
    }), 200

@app.route('/api/status')
def api_status():
    """API status check"""
    try:
        # Test Pterodactyl API connection
        response = requests.get(f'{PTERODACTYL_URL}/api/client', headers=headers, timeout=5)
        api_working = response.status_code == 200
    except Exception as e:
        logger.error(f"API check failed: {e}")
        api_working = False
    
    return jsonify({
        'web_console': 'running',
        'pterodactyl_api': 'connected' if api_working else 'disconnected',
        'panel_url': PTERODACTYL_URL
    }), 200

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

@app.route('/api/servers/<server_id>/files')
def list_files(server_id):
    """List files in server directory"""
    if not check_auth():
        return jsonify({'error': 'Unauthorized'}), 401
    
    path = request.args.get('path', '/')
    
    try:
        response = requests.get(
            f'{PTERODACTYL_URL}/api/client/servers/{server_id}/files/list',
            headers=headers,
            params={'directory': path}
        )
        
        if response.status_code == 200:
            return jsonify(response.json())
        else:
            return jsonify({'error': 'Failed to list files'}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/servers/<server_id>/files/content')
def get_file_content(server_id):
    """Get file content"""
    if not check_auth():
        return jsonify({'error': 'Unauthorized'}), 401
    
    file_path = request.args.get('file')
    
    try:
        response = requests.get(
            f'{PTERODACTYL_URL}/api/client/servers/{server_id}/files/contents',
            headers=headers,
            params={'file': file_path}
        )
        
        if response.status_code == 200:
            return response.text
        else:
            return jsonify({'error': 'Failed to read file'}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/servers/<server_id>/files/save', methods=['POST'])
def save_file(server_id):
    """Save file content"""
    if not check_auth():
        return jsonify({'error': 'Unauthorized'}), 401
    
    file_path = request.json.get('file')
    content = request.json.get('content')
    
    try:
        response = requests.post(
            f'{PTERODACTYL_URL}/api/client/servers/{server_id}/files/write',
            headers=headers,
            params={'file': file_path},
            data=content
        )
        
        if response.status_code == 204:
            return jsonify({'success': True})
        else:
            return jsonify({'error': 'Failed to save file'}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/schedules', methods=['GET'])
def get_schedules():
    """Get all scheduled tasks"""
    if not check_auth():
        return jsonify({'error': 'Unauthorized'}), 401
    
    # For now, return from a simple JSON file or database
    # This would need to be implemented with actual storage
    try:
        import json
        import os
        schedule_file = 'schedules.json'
        if os.path.exists(schedule_file):
            with open(schedule_file, 'r') as f:
                schedules = json.load(f)
            return jsonify(schedules)
        else:
            return jsonify([])
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/schedules', methods=['POST'])
def create_schedule():
    """Create a new scheduled task"""
    if not check_auth():
        return jsonify({'error': 'Unauthorized'}), 401
    
    schedule_data = request.json
    
    try:
        import json
        import os
        schedule_file = 'schedules.json'
        
        schedules = []
        if os.path.exists(schedule_file):
            with open(schedule_file, 'r') as f:
                schedules = json.load(f)
        
        schedule_data['id'] = len(schedules) + 1
        schedules.append(schedule_data)
        
        with open(schedule_file, 'w') as f:
            json.dump(schedules, f, indent=2)
        
        return jsonify({'success': True, 'schedule': schedule_data})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/schedules/<int:schedule_id>', methods=['DELETE'])
def delete_schedule(schedule_id):
    """Delete a scheduled task"""
    if not check_auth():
        return jsonify({'error': 'Unauthorized'}), 401
    
    try:
        import json
        import os
        schedule_file = 'schedules.json'
        
        if os.path.exists(schedule_file):
            with open(schedule_file, 'r') as f:
                schedules = json.load(f)
            
            schedules = [s for s in schedules if s.get('id') != schedule_id]
            
            with open(schedule_file, 'w') as f:
                json.dump(schedules, f, indent=2)
        
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@socketio.on('connect')
def handle_connect():
    """Handle WebSocket connection"""
    if not check_auth():
        return False
    emit('connected', {'message': 'Connected to server'})
    logger.info(f"Client connected: {request.sid}")

@socketio.on('disconnect')
def handle_disconnect():
    """Handle WebSocket disconnection"""
    # Clean up any active console connections for this client
    if request.sid in active_console_connections:
        ws = active_console_connections[request.sid]
        try:
            ws.close()
        except:
            pass
        del active_console_connections[request.sid]
    logger.info(f"Client disconnected: {request.sid}")

@socketio.on('subscribe_console')
def handle_subscribe_console(data):
    """Subscribe to server console output"""
    if not check_auth():
        return False
    
    server_id = data.get('server_id')
    if not server_id:
        emit('console_error', {'error': 'No server_id provided'})
        return
    
    logger.info(f"Client {request.sid} subscribing to console for server {server_id}")
    
    try:
        # Get WebSocket credentials from Pterodactyl API
        response = requests.get(
            f'{PTERODACTYL_URL}/api/client/servers/{server_id}/websocket',
            headers=headers
        )
        
        if response.status_code != 200:
            emit('console_error', {'error': 'Failed to get WebSocket credentials'})
            return
        
        ws_data = response.json().get('data', {})
        ws_url = ws_data.get('socket')
        ws_token = ws_data.get('token')
        
        if not ws_url or not ws_token:
            emit('console_error', {'error': 'Invalid WebSocket credentials'})
            return
        
        # Start WebSocket connection in a separate thread
        thread = threading.Thread(
            target=connect_to_pterodactyl_console,
            args=(server_id, ws_url, ws_token, request.sid)
        )
        thread.daemon = True
        thread.start()
        
        emit('console_subscribed', {'server_id': server_id})
        
    except Exception as e:
        logger.error(f"Error subscribing to console: {e}")
        emit('console_error', {'error': str(e)})

@socketio.on('send_console_command')
def handle_console_command(data):
    """Send command to server console via WebSocket"""
    if not check_auth():
        return False
    
    server_id = data.get('server_id')
    command = data.get('command')
    
    if not server_id or not command:
        emit('console_error', {'error': 'Missing server_id or command'})
        return
    
    # Get the active WebSocket connection for this client
    if request.sid in active_console_connections:
        ws = active_console_connections[request.sid]
        try:
            # Send command through WebSocket
            ws.send(json_lib.dumps({
                'event': 'send command',
                'args': [command]
            }))
            logger.info(f"Sent command to {server_id}: {command}")
        except Exception as e:
            logger.error(f"Error sending command: {e}")
            emit('console_error', {'error': str(e)})
    else:
        # Fallback to REST API if WebSocket not available
        try:
            response = requests.post(
                f'{PTERODACTYL_URL}/api/client/servers/{server_id}/command',
                headers=headers,
                json={'command': command}
            )
            if response.status_code == 204:
                emit('console_output', {'output': f'> {command}\n'})
            else:
                emit('console_error', {'error': 'Failed to send command'})
        except Exception as e:
            logger.error(f"Error sending command via API: {e}")
            emit('console_error', {'error': str(e)})

def connect_to_pterodactyl_console(server_id, ws_url, ws_token, client_sid):
    """Connect to Pterodactyl's WebSocket for real-time console output"""
    
    def on_message(ws, message):
        try:
            data = json_lib.loads(message)
            event = data.get('event')
            
            if event == 'console output':
                # Forward console output to the client
                args = data.get('args', [])
                if args:
                    output = args[0]
                    socketio.emit('console_output', {
                        'server_id': server_id,
                        'output': output
                    }, room=client_sid)
            
            elif event == 'status':
                # Forward status updates
                status = data.get('args', [None])[0]
                socketio.emit('server_status', {
                    'server_id': server_id,
                    'status': status
                }, room=client_sid)
            
            elif event == 'stats':
                # Forward resource stats
                stats = data.get('args', [{}])[0]
                socketio.emit('server_stats', {
                    'server_id': server_id,
                    'stats': stats
                }, room=client_sid)
                
        except Exception as e:
            logger.error(f"Error processing WebSocket message: {e}")
    
    def on_error(ws, error):
        logger.error(f"WebSocket error for {server_id}: {error}")
        socketio.emit('console_error', {
            'server_id': server_id,
            'error': str(error)
        }, room=client_sid)
    
    def on_close(ws, close_status_code, close_msg):
        logger.info(f"WebSocket closed for {server_id}")
        if client_sid in active_console_connections:
            del active_console_connections[client_sid]
        socketio.emit('console_disconnected', {
            'server_id': server_id
        }, room=client_sid)
    
    def on_open(ws):
        logger.info(f"WebSocket opened for {server_id}")
        # Authenticate with the token
        ws.send(json_lib.dumps({
            'event': 'auth',
            'args': [ws_token]
        }))
        # Request console logs
        ws.send(json_lib.dumps({
            'event': 'send logs',
            'args': [None]
        }))
    
    try:
        # Create WebSocket connection with Origin header
        # websocket-client expects headers as a list of 'Key: Value' strings
        ws = websocket.WebSocketApp(
            ws_url,
            on_open=on_open,
            on_message=on_message,
            on_error=on_error,
            on_close=on_close,
            header=['Origin: https://console.cloudmc.online']
        )
        
        # Store the connection
        active_console_connections[client_sid] = ws
        
        # Run WebSocket connection (blocking)
        ws.run_forever()
        
    except Exception as e:
        logger.error(f"Error connecting to Pterodactyl WebSocket: {e}")
        socketio.emit('console_error', {
            'server_id': server_id,
            'error': str(e)
        }, room=client_sid)

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    logger.info(f"🚀 Starting Pterodactyl Web Console on port {port}")
    logger.info(f"🔗 Panel URL: {PTERODACTYL_URL}")
    logger.info(f"🌐 Access at: http://0.0.0.0:{port}")
    
    try:
        socketio.run(app, host='0.0.0.0', port=port, debug=False, allow_unsafe_werkzeug=True)
    except Exception as e:
        logger.error(f"❌ Failed to start server: {e}")
        raise
