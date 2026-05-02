#!/usr/bin/env python3
"""
Unified Server Admin Panel
Complete control center for all server services and settings
"""

from flask import Flask, render_template, request, jsonify, session, redirect, url_for
from functools import wraps
import subprocess
import sqlite3
import os
import json
import time
import shutil
import hashlib

app = Flask(__name__)
app.secret_key = os.urandom(24)  # Change this to a fixed secret in production

# Configuration
DB_PATH = '/etc/filebrowser/filebrowser.db'
BRANDING_DIR = '/etc/filebrowser/branding'
PINGVIN_DIR = '/opt/pingvin-share'
NEXTCLOUD_DIR = '/opt/nextcloud'
ADMIN_CREDENTIALS_FILE = '/etc/admin-panel/credentials.json'

# Create credentials directory
os.makedirs('/etc/admin-panel', exist_ok=True)

def hash_password(password):
    """Hash password with SHA256"""
    return hashlib.sha256(password.encode()).hexdigest()

def init_admin_credentials():
    """Initialize admin credentials if not exists"""
    if not os.path.exists(ADMIN_CREDENTIALS_FILE):
        # Default credentials - CHANGE ON FIRST LOGIN
        default_creds = {
            'username': 'admin',
            'password': hash_password('ChangeMe123!')  # Default password
        }
        with open(ADMIN_CREDENTIALS_FILE, 'w') as f:
            json.dump(default_creds, f)
        os.chmod(ADMIN_CREDENTIALS_FILE, 0o600)  # Secure permissions

def verify_credentials(username, password):
    """Verify admin credentials"""
    try:
        with open(ADMIN_CREDENTIALS_FILE, 'r') as f:
            creds = json.load(f)
        return creds['username'] == username and creds['password'] == hash_password(password)
    except:
        return False

def login_required(f):
    """Decorator to require login"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'logged_in' not in session:
            return jsonify({'error': 'Authentication required'}), 401
        return f(*args, **kwargs)
    return decorated_function

@app.route('/')
def index():
    if 'logged_in' in session:
        return render_template('admin.html')
    return render_template('login.html')

@app.route('/login', methods=['POST'])
def login():
    """Admin login"""
    data = request.json
    username = data.get('username')
    password = data.get('password')
    
    if verify_credentials(username, password):
        session['logged_in'] = True
        session['username'] = username
        return jsonify({'success': True})
    else:
        return jsonify({'error': 'Invalid credentials'}), 401

@app.route('/logout', methods=['POST'])
def logout():
    """Admin logout"""
    session.clear()
    return jsonify({'success': True})

@app.route('/api/admin/change-password', methods=['POST'])
@login_required
def change_admin_password():
    """Change admin password"""
    data = request.json
    current_password = data.get('current_password')
    new_password = data.get('new_password')
    
    try:
        with open(ADMIN_CREDENTIALS_FILE, 'r') as f:
            creds = json.load(f)
        
        if creds['password'] != hash_password(current_password):
            return jsonify({'error': 'Current password incorrect'}), 400
        
        creds['password'] = hash_password(new_password)
        
        with open(ADMIN_CREDENTIALS_FILE, 'w') as f:
            json.dump(creds, f)
        
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/admin/change-username', methods=['POST'])
@login_required
def change_admin_username():
    """Change admin username"""
    data = request.json
    new_username = data.get('username')
    password = data.get('password')
    
    try:
        with open(ADMIN_CREDENTIALS_FILE, 'r') as f:
            creds = json.load(f)
        
        if creds['password'] != hash_password(password):
            return jsonify({'error': 'Password incorrect'}), 400
        
        creds['username'] = new_username
        
        with open(ADMIN_CREDENTIALS_FILE, 'w') as f:
            json.dump(creds, f)
        
        session['username'] = new_username
        
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ============================================================================
# SYSTEM MANAGEMENT
# ============================================================================

@app.route('/api/system/status', methods=['GET'])
@login_required
def system_status():
    """Get overall system status"""
    try:
        # Get uptime
        uptime = subprocess.run(['uptime', '-p'], capture_output=True, text=True).stdout.strip()
        
        # Get load average
        load = subprocess.run(['cat', '/proc/loadavg'], capture_output=True, text=True).stdout.split()[:3]
        
        # Get memory
        mem = subprocess.run(['free', '-h'], capture_output=True, text=True).stdout.split('\n')[1].split()
        
        # Get disk usage
        disk = subprocess.run(['df', '-h', '/'], capture_output=True, text=True).stdout.split('\n')[1].split()
        
        return jsonify({
            'uptime': uptime,
            'load': load,
            'memory': {'total': mem[1], 'used': mem[2], 'free': mem[3]},
            'disk': {'size': disk[1], 'used': disk[2], 'available': disk[3], 'percent': disk[4]}
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/system/reboot', methods=['POST'])
def system_reboot():
    """Safe system reboot"""
    try:
        # Stop services gracefully
        stop_all_services()
        
        # Schedule reboot
        subprocess.Popen(['shutdown', '-r', '+1', 'Rebooting from admin panel'])
        
        return jsonify({'success': True, 'message': 'Server will reboot in 1 minute'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/system/shutdown', methods=['POST'])
def system_shutdown():
    """Safe system shutdown"""
    try:
        # Stop services gracefully
        stop_all_services()
        
        # Schedule shutdown
        subprocess.Popen(['shutdown', '-h', '+1', 'Shutting down from admin panel'])
        
        return jsonify({'success': True, 'message': 'Server will shutdown in 1 minute'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def stop_all_services():
    """Stop all services gracefully"""
    services = ['filebrowser', 'filebrowser-admin', 'cloudflared', 'wings']
    for service in services:
        try:
            subprocess.run(['systemctl', 'stop', service], check=False)
        except:
            pass
    
    # Stop Docker containers
    try:
        subprocess.run(['docker', 'stop', '$(docker ps -q)'], shell=True, check=False)
    except:
        pass

# ============================================================================
# SERVICE MANAGEMENT
# ============================================================================

@app.route('/api/services/status', methods=['GET'])
def services_status():
    """Get status of all services"""
    try:
        services = {
            'filebrowser': check_service('filebrowser'),
            'cloudflared': check_service('cloudflared'),
            'wings': check_service('wings'),
            'docker': check_service('docker'),
            'pingvin': check_docker_container('pingvin-share'),
            'nextcloud': check_docker_container('nextcloud'),
            'nextcloud_db': check_docker_container('nextcloud-db')
        }
        return jsonify(services)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/services/restart/<service>', methods=['POST'])
def restart_service(service):
    """Restart a specific service"""
    try:
        if service in ['pingvin', 'nextcloud']:
            # Docker service
            dir_map = {'pingvin': PINGVIN_DIR, 'nextcloud': NEXTCLOUD_DIR}
            if os.path.exists(dir_map[service]):
                subprocess.run(['docker-compose', 'restart'], cwd=dir_map[service])
                return jsonify({'success': True})
        else:
            # Systemd service
            subprocess.run(['systemctl', 'restart', service])
            return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def check_service(service):
    """Check if systemd service is running"""
    result = subprocess.run(['systemctl', 'is-active', service], capture_output=True, text=True)
    return result.stdout.strip() == 'active'

def check_docker_container(container):
    """Check if Docker container is running"""
    result = subprocess.run(['docker', 'ps', '--format', '{{.Names}}'], capture_output=True, text=True)
    return container in result.stdout

# ============================================================================
# FILEBROWSER MANAGEMENT
# ============================================================================

@app.route('/api/filebrowser/users', methods=['GET'])
def get_filebrowser_users():
    """Get all filebrowser users"""
    try:
        result = subprocess.run(['filebrowser', 'users', 'ls', '--database', DB_PATH], capture_output=True, text=True)
        users = []
        for line in result.stdout.split('\n')[1:]:
            if line.strip():
                parts = line.split()
                if len(parts) >= 2:
                    users.append({'id': parts[0], 'username': parts[1], 'admin': 'Admin' in line})
        return jsonify(users)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/filebrowser/users/add', methods=['POST'])
def add_filebrowser_user():
    """Add filebrowser user"""
    data = request.json
    try:
        cmd = ['filebrowser', 'users', 'add', data['username'], data['password'], '--database', DB_PATH]
        if data.get('admin'):
            cmd.append('--perm.admin')
        subprocess.run(cmd, check=True)
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/filebrowser/users/delete/<username>', methods=['DELETE'])
def delete_filebrowser_user(username):
    """Delete filebrowser user"""
    try:
        subprocess.run(['filebrowser', 'users', 'rm', username, '--database', DB_PATH], check=True)
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ============================================================================
# STORAGE MANAGEMENT
# ============================================================================

@app.route('/api/storage/disks', methods=['GET'])
def get_disks():
    """Get all disk information"""
    try:
        result = subprocess.run(['lsblk', '-J'], capture_output=True, text=True)
        disks = json.loads(result.stdout)
        
        # Get mount points
        df_result = subprocess.run(['df', '-h'], capture_output=True, text=True)
        
        return jsonify({'disks': disks, 'mounts': df_result.stdout})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/storage/configure', methods=['POST'])
def configure_storage():
    """Configure storage paths for services"""
    data = request.json
    storage_path = data.get('path')
    
    try:
        # Update Pingvin Share
        if os.path.exists(PINGVIN_DIR):
            update_pingvin_storage(storage_path)
        
        # Update Nextcloud
        if os.path.exists(NEXTCLOUD_DIR):
            update_nextcloud_storage(storage_path)
        
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def update_pingvin_storage(path):
    """Update Pingvin Share storage location"""
    compose_file = os.path.join(PINGVIN_DIR, 'docker-compose.yml')
    # Read, modify, and write docker-compose.yml
    # Implementation depends on specific requirements
    pass

def update_nextcloud_storage(path):
    """Update Nextcloud storage location"""
    compose_file = os.path.join(NEXTCLOUD_DIR, 'docker-compose.yml')
    # Read, modify, and write docker-compose.yml
    pass

# ============================================================================
# QUICK ACTIONS
# ============================================================================

@app.route('/api/quick/fix-database', methods=['POST'])
def quick_fix_database():
    """Quick fix for corrupted filebrowser database"""
    try:
        subprocess.run(['systemctl', 'stop', 'filebrowser'])
        
        if os.path.exists(DB_PATH):
            backup = f"{DB_PATH}.backup.{int(time.time())}"
            shutil.move(DB_PATH, backup)
        
        subprocess.run(['filebrowser', 'config', 'init', '--database', DB_PATH])
        subprocess.run(['filebrowser', 'config', 'set', '--address', '127.0.0.1', '--database', DB_PATH])
        subprocess.run(['filebrowser', 'config', 'set', '--port', '8090', '--database', DB_PATH])
        subprocess.run(['filebrowser', 'config', 'set', '--root', '/var/filebrowser', '--database', DB_PATH])
        
        subprocess.run(['systemctl', 'start', 'filebrowser'])
        
        return jsonify({'success': True, 'message': 'Database reset successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/quick/restart-all', methods=['POST'])
def quick_restart_all():
    """Restart all services"""
    try:
        services = ['filebrowser', 'cloudflared']
        for service in services:
            subprocess.run(['systemctl', 'restart', service], check=False)
        
        # Restart Docker services
        for dir_path in [PINGVIN_DIR, NEXTCLOUD_DIR]:
            if os.path.exists(dir_path):
                subprocess.run(['docker-compose', 'restart'], cwd=dir_path, check=False)
        
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/quick/check-health', methods=['GET'])
def quick_check_health():
    """Quick health check of all services"""
    try:
        health = {
            'services': {
                'filebrowser': check_service('filebrowser'),
                'cloudflared': check_service('cloudflared'),
                'pingvin': check_docker_container('pingvin-share'),
                'nextcloud': check_docker_container('nextcloud')
            },
            'disk_space': get_disk_space(),
            'memory': get_memory_usage()
        }
        return jsonify(health)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def get_disk_space():
    """Get disk space usage"""
    result = subprocess.run(['df', '-h', '/'], capture_output=True, text=True)
    parts = result.stdout.split('\n')[1].split()
    return {'used': parts[2], 'available': parts[3], 'percent': parts[4]}

def get_memory_usage():
    """Get memory usage"""
    result = subprocess.run(['free', '-h'], capture_output=True, text=True)
    parts = result.stdout.split('\n')[1].split()
    return {'total': parts[1], 'used': parts[2], 'free': parts[3]}

# ============================================================================
# LOGS
# ============================================================================

@app.route('/api/logs/<service>', methods=['GET'])
@login_required
def get_logs(service):
    """Get logs for a service"""
    lines = request.args.get('lines', 50, type=int)
    try:
        if service in ['pingvin', 'nextcloud']:
            dir_map = {'pingvin': PINGVIN_DIR, 'nextcloud': NEXTCLOUD_DIR}
            result = subprocess.run(['docker-compose', 'logs', '--tail', str(lines)], 
                                  cwd=dir_map[service], capture_output=True, text=True)
        else:
            result = subprocess.run(['journalctl', '-u', service, '-n', str(lines), '--no-pager'], 
                                  capture_output=True, text=True)
        return jsonify({'logs': result.stdout})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ============================================================================
# SELF-UPDATE
# ============================================================================

@app.route('/api/update/self', methods=['POST'])
@login_required
def self_update():
    """Update admin panel from GitHub"""
    try:
        # Clone latest version
        subprocess.run(['rm', '-rf', '/tmp/automatic-system'], check=False)
        subprocess.run(['git', 'clone', 'https://github.com/SirJBiscuit/automatic-system.git', '/tmp/automatic-system'], check=True)
        
        # Copy updated files
        subprocess.run(['cp', '-r', '/tmp/automatic-system/unified-admin/templates/', '/opt/unified-admin/'], check=True)
        subprocess.run(['cp', '/tmp/automatic-system/unified-admin/admin.py', '/opt/unified-admin/'], check=True)
        
        # Restart service
        subprocess.Popen(['systemctl', 'restart', 'unified-admin'])
        
        return jsonify({'success': True, 'message': 'Admin panel updated! Refreshing in 3 seconds...'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/update/service/<service>', methods=['POST'])
@login_required
def update_service(service):
    """Update a specific service from GitHub"""
    try:
        service_map = {
            'pingvin': {'dir': PINGVIN_DIR, 'source': 'pingvin-share-setup'},
            'nextcloud': {'dir': NEXTCLOUD_DIR, 'source': 'nextcloud-setup'}
        }
        
        if service not in service_map:
            return jsonify({'error': 'Unknown service'}), 400
        
        # Clone latest version
        subprocess.run(['rm', '-rf', '/tmp/automatic-system'], check=False)
        subprocess.run(['git', 'clone', 'https://github.com/SirJBiscuit/automatic-system.git', '/tmp/automatic-system'], check=True)
        
        # Stop service
        subprocess.run(['docker-compose', 'down'], cwd=service_map[service]['dir'], check=False)
        
        # Update docker-compose.yml
        subprocess.run(['cp', f'/tmp/automatic-system/{service_map[service]["source"]}/docker-compose.yml', 
                       f'{service_map[service]["dir"]}/'], check=True)
        
        # Start service
        subprocess.run(['docker-compose', 'up', '-d'], cwd=service_map[service]['dir'], check=True)
        
        return jsonify({'success': True, 'message': f'{service} updated successfully!'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # Initialize admin credentials on first run
    init_admin_credentials()
    app.run(host='127.0.0.1', port=5002, debug=False)
