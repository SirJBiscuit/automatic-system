#!/usr/bin/env python3
"""
Filebrowser Admin Interface
Web-based management for filebrowser configuration, users, and social plugin
"""

from flask import Flask, render_template, request, jsonify, redirect, url_for
import subprocess
import sqlite3
import os
import json

app = Flask(__name__)

DB_PATH = '/etc/filebrowser/filebrowser.db'
BRANDING_DIR = '/etc/filebrowser/branding'

@app.route('/')
def index():
    return render_template('admin.html')

# User Management
@app.route('/api/users', methods=['GET'])
def get_users():
    try:
        result = subprocess.run(
            ['filebrowser', 'users', 'ls', '--database', DB_PATH],
            capture_output=True, text=True
        )
        users = []
        for line in result.stdout.split('\n')[1:]:  # Skip header
            if line.strip():
                parts = line.split()
                if len(parts) >= 2:
                    users.append({
                        'id': parts[0],
                        'username': parts[1],
                        'admin': 'Admin' in line
                    })
        return jsonify(users)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/users/add', methods=['POST'])
def add_user():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    is_admin = data.get('admin', False)
    
    try:
        cmd = ['filebrowser', 'users', 'add', username, password, '--database', DB_PATH]
        if is_admin:
            cmd.append('--perm.admin')
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            return jsonify({'success': True})
        else:
            return jsonify({'error': result.stderr}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/users/delete/<username>', methods=['DELETE'])
def delete_user(username):
    try:
        result = subprocess.run(
            ['filebrowser', 'users', 'rm', username, '--database', DB_PATH],
            capture_output=True, text=True
        )
        
        if result.returncode == 0:
            return jsonify({'success': True})
        else:
            return jsonify({'error': result.stderr}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/users/password', methods=['POST'])
def change_password():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    
    try:
        result = subprocess.run(
            ['filebrowser', 'users', 'update', username, '--password', password, '--database', DB_PATH],
            capture_output=True, text=True
        )
        
        if result.returncode == 0:
            return jsonify({'success': True})
        else:
            return jsonify({'error': result.stderr}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Database Management
@app.route('/api/database/status', methods=['GET'])
def database_status():
    try:
        # Check if database exists and is valid
        if not os.path.exists(DB_PATH):
            return jsonify({'status': 'missing', 'valid': False})
        
        # Try to query it
        result = subprocess.run(
            ['sqlite3', DB_PATH, 'SELECT COUNT(*) FROM users;'],
            capture_output=True, text=True
        )
        
        if result.returncode == 0:
            user_count = int(result.stdout.strip())
            return jsonify({
                'status': 'ok',
                'valid': True,
                'users': user_count,
                'path': DB_PATH
            })
        else:
            return jsonify({'status': 'corrupted', 'valid': False})
    except Exception as e:
        return jsonify({'status': 'error', 'valid': False, 'error': str(e)})

@app.route('/api/database/reset', methods=['POST'])
def reset_database():
    try:
        # Stop filebrowser
        subprocess.run(['systemctl', 'stop', 'filebrowser'])
        
        # Backup old database
        if os.path.exists(DB_PATH):
            backup_path = DB_PATH + '.backup.' + str(int(os.time.time()))
            os.rename(DB_PATH, backup_path)
        
        # Initialize new database
        subprocess.run(['filebrowser', 'config', 'init', '--database', DB_PATH])
        subprocess.run(['filebrowser', 'config', 'set', '--address', '127.0.0.1', '--database', DB_PATH])
        subprocess.run(['filebrowser', 'config', 'set', '--port', '8090', '--database', DB_PATH])
        subprocess.run(['filebrowser', 'config', 'set', '--root', '/var/filebrowser', '--database', DB_PATH])
        subprocess.run(['filebrowser', 'config', 'set', '--branding.name', 'File Share Portal', '--database', DB_PATH])
        subprocess.run(['filebrowser', 'config', 'set', '--branding.files', BRANDING_DIR, '--database', DB_PATH])
        
        # Start filebrowser
        subprocess.run(['systemctl', 'start', 'filebrowser'])
        
        return jsonify({'success': True, 'message': 'Database reset successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Service Management
@app.route('/api/service/status', methods=['GET'])
def service_status():
    try:
        result = subprocess.run(
            ['systemctl', 'is-active', 'filebrowser'],
            capture_output=True, text=True
        )
        
        active = result.stdout.strip() == 'active'
        
        return jsonify({
            'active': active,
            'status': result.stdout.strip()
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/service/restart', methods=['POST'])
def restart_service():
    try:
        subprocess.run(['systemctl', 'restart', 'filebrowser'])
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Social Plugin Management
@app.route('/api/social/status', methods=['GET'])
def social_status():
    try:
        js_exists = os.path.exists(os.path.join(BRANDING_DIR, 'custom.js'))
        css_exists = os.path.exists(os.path.join(BRANDING_DIR, 'custom.css'))
        
        return jsonify({
            'installed': js_exists and css_exists,
            'js': js_exists,
            'css': css_exists,
            'path': BRANDING_DIR
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/social/install', methods=['POST'])
def install_social():
    try:
        # Create branding directory
        os.makedirs(BRANDING_DIR, exist_ok=True)
        
        # Download and install social plugin
        subprocess.run(['git', 'clone', 'https://github.com/SirJBiscuit/automatic-system.git', '/tmp/fb-social-install'])
        subprocess.run(['cp', '/tmp/fb-social-install/filebrowser-social/custom.js', BRANDING_DIR])
        subprocess.run(['cp', '/tmp/fb-social-install/filebrowser-social/custom.css', BRANDING_DIR])
        subprocess.run(['rm', '-rf', '/tmp/fb-social-install'])
        
        # Configure filebrowser
        subprocess.run(['filebrowser', 'config', 'set', '--branding.files', BRANDING_DIR, '--database', DB_PATH])
        
        # Restart service
        subprocess.run(['systemctl', 'restart', 'filebrowser'])
        
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5002, debug=False)
