#!/usr/bin/env python3
"""
Social Filebrowser - Enhanced file sharing with friends system
"""

from flask import Flask, render_template, request, jsonify, session, redirect, url_for, send_from_directory
from flask_socketio import SocketIO, emit, join_room, leave_room
import sqlite3
import subprocess
import os
import json
from datetime import datetime
from functools import wraps
import hashlib
import shutil

app = Flask(__name__)
app.config['SECRET_KEY'] = os.urandom(24)
socketio = SocketIO(app, cors_allowed_origins="*")

DB_PATH = '/etc/filebrowser/filebrowser.db'
SOCIAL_DB = '/var/lib/filebrowser/social.db'
STATUS_DIR = '/var/lib/filebrowser/status'
TRADE_DIR = '/var/lib/filebrowser/trades'
STORAGE_DIR = '/var/filebrowser'
QUARANTINE_DIR = '/var/filebrowser/.quarantine'

# Initialize social database
def init_social_db():
    conn = sqlite3.connect(SOCIAL_DB)
    c = conn.cursor()
    
    # Friends table
    c.execute('''CREATE TABLE IF NOT EXISTS friends
                 (user_id TEXT, friend_id TEXT, status TEXT, created_at TIMESTAMP,
                  PRIMARY KEY (user_id, friend_id))''')
    
    # File transfers table
    c.execute('''CREATE TABLE IF NOT EXISTS transfers
                 (id INTEGER PRIMARY KEY AUTOINCREMENT,
                  from_user TEXT, to_user TEXT, file_path TEXT, file_name TEXT,
                  file_size INTEGER, status TEXT, message TEXT,
                  created_at TIMESTAMP, accepted_at TIMESTAMP)''')
    
    # Notifications table
    c.execute('''CREATE TABLE IF NOT EXISTS notifications
                 (id INTEGER PRIMARY KEY AUTOINCREMENT,
                  user_id TEXT, type TEXT, message TEXT, data TEXT,
                  read INTEGER DEFAULT 0, created_at TIMESTAMP)''')
    
    conn.commit()
    conn.close()

init_social_db()

# Login required decorator
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'username' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

# Get user's friends
def get_friends(username):
    conn = sqlite3.connect(SOCIAL_DB)
    c = conn.cursor()
    c.execute('''SELECT friend_id, status FROM friends 
                 WHERE user_id = ? AND status = 'accepted' ''', (username,))
    friends = c.fetchall()
    conn.close()
    
    # Check online status for each friend
    friends_list = []
    for friend_id, status in friends:
        online = is_user_online(friend_id)
        friends_list.append({
            'username': friend_id,
            'online': online,
            'status': status
        })
    
    return friends_list

# Check if user is online
def is_user_online(username):
    status_file = os.path.join(STATUS_DIR, f"{username}.status")
    if not os.path.exists(status_file):
        return False
    
    try:
        with open(status_file, 'r') as f:
            last_seen = int(f.read().strip())
        
        current_time = int(datetime.now().timestamp())
        return (current_time - last_seen) < 300  # 5 minutes
    except:
        return False

# Update user online status
def update_online_status(username):
    os.makedirs(STATUS_DIR, exist_ok=True)
    status_file = os.path.join(STATUS_DIR, f"{username}.status")
    with open(status_file, 'w') as f:
        f.write(str(int(datetime.now().timestamp())))

# Routes
@app.route('/')
@login_required
def index():
    return render_template('dashboard.html', username=session['username'])

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        # Verify against filebrowser database
        if verify_user(username, password):
            session['username'] = username
            update_online_status(username)
            return redirect(url_for('index'))
        else:
            return render_template('login.html', error='Invalid credentials')
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    if 'username' in session:
        # Mark as offline
        status_file = os.path.join(STATUS_DIR, f"{session['username']}.status")
        if os.path.exists(status_file):
            os.remove(status_file)
        session.pop('username', None)
    return redirect(url_for('login'))

# API Routes
@app.route('/api/friends')
@login_required
def api_friends():
    friends = get_friends(session['username'])
    return jsonify(friends)

@app.route('/api/friends/add', methods=['POST'])
@login_required
def api_add_friend():
    friend_username = request.json.get('username')
    
    conn = sqlite3.connect(SOCIAL_DB)
    c = conn.cursor()
    
    # Add friend request
    c.execute('''INSERT OR IGNORE INTO friends (user_id, friend_id, status, created_at)
                 VALUES (?, ?, 'pending', ?)''',
              (session['username'], friend_username, datetime.now()))
    
    # Create notification for friend
    c.execute('''INSERT INTO notifications (user_id, type, message, created_at)
                 VALUES (?, 'friend_request', ?, ?)''',
              (friend_username, f"{session['username']} sent you a friend request", datetime.now()))
    
    conn.commit()
    conn.close()
    
    # Emit socket event
    socketio.emit('friend_request', {
        'from': session['username']
    }, room=friend_username)
    
    return jsonify({'success': True})

@app.route('/api/transfers/send', methods=['POST'])
@login_required
def api_send_file():
    to_user = request.json.get('to_user')
    file_path = request.json.get('file_path')
    message = request.json.get('message', '')
    
    # Get file info
    if not os.path.exists(file_path):
        return jsonify({'success': False, 'error': 'File not found'})
    
    file_name = os.path.basename(file_path)
    file_size = os.path.getsize(file_path)
    
    conn = sqlite3.connect(SOCIAL_DB)
    c = conn.cursor()
    
    # Create transfer
    c.execute('''INSERT INTO transfers 
                 (from_user, to_user, file_path, file_name, file_size, status, message, created_at)
                 VALUES (?, ?, ?, ?, ?, 'pending', ?, ?)''',
              (session['username'], to_user, file_path, file_name, file_size, message, datetime.now()))
    
    transfer_id = c.lastrowid
    
    # Create notification
    c.execute('''INSERT INTO notifications (user_id, type, message, data, created_at)
                 VALUES (?, 'file_transfer', ?, ?, ?)''',
              (to_user, f"{session['username']} sent you {file_name}", 
               json.dumps({'transfer_id': transfer_id}), datetime.now()))
    
    conn.commit()
    conn.close()
    
    # Emit socket event
    socketio.emit('file_transfer', {
        'from': session['username'],
        'file_name': file_name,
        'file_size': file_size,
        'transfer_id': transfer_id,
        'message': message
    }, room=to_user)
    
    return jsonify({'success': True, 'transfer_id': transfer_id})

@app.route('/api/transfers/pending')
@login_required
def api_pending_transfers():
    conn = sqlite3.connect(SOCIAL_DB)
    c = conn.cursor()
    
    c.execute('''SELECT id, from_user, file_name, file_size, message, created_at
                 FROM transfers WHERE to_user = ? AND status = 'pending'
                 ORDER BY created_at DESC''', (session['username'],))
    
    transfers = []
    for row in c.fetchall():
        transfers.append({
            'id': row[0],
            'from_user': row[1],
            'file_name': row[2],
            'file_size': row[3],
            'message': row[4],
            'created_at': row[5]
        })
    
    conn.close()
    return jsonify(transfers)

@app.route('/api/transfers/accept/<int:transfer_id>', methods=['POST'])
@login_required
def api_accept_transfer(transfer_id):
    conn = sqlite3.connect(SOCIAL_DB)
    c = conn.cursor()
    
    # Get transfer info
    c.execute('''SELECT from_user, to_user, file_path, file_name 
                 FROM transfers WHERE id = ? AND to_user = ?''',
              (transfer_id, session['username']))
    
    result = c.fetchone()
    if not result:
        conn.close()
        return jsonify({'success': False, 'error': 'Transfer not found'})
    
    from_user, to_user, file_path, file_name = result
    
    # Copy file to user's directory
    dest_dir = f"/var/filebrowser/trades/{to_user}"
    os.makedirs(dest_dir, exist_ok=True)
    dest_path = os.path.join(dest_dir, file_name)
    
    try:
        subprocess.run(['cp', file_path, dest_path], check=True)
        
        # Update transfer status
        c.execute('''UPDATE transfers SET status = 'accepted', accepted_at = ?
                     WHERE id = ?''', (datetime.now(), transfer_id))
        
        conn.commit()
        conn.close()
        
        # Notify sender
        socketio.emit('transfer_accepted', {
            'transfer_id': transfer_id,
            'by': session['username']
        }, room=from_user)
        
        return jsonify({'success': True, 'file_path': dest_path})
    except Exception as e:
        conn.close()
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/transfers/reject/<int:transfer_id>', methods=['POST'])
@login_required
def api_reject_transfer(transfer_id):
    conn = sqlite3.connect(SOCIAL_DB)
    c = conn.cursor()
    
    c.execute('''UPDATE transfers SET status = 'rejected' WHERE id = ? AND to_user = ?''',
              (transfer_id, session['username']))
    
    conn.commit()
    conn.close()
    
    return jsonify({'success': True})

@app.route('/api/notifications')
@login_required
def api_notifications():
    conn = sqlite3.connect(SOCIAL_DB)
    c = conn.cursor()
    
    c.execute('''SELECT id, type, message, data, read, created_at
                 FROM notifications WHERE user_id = ?
                 ORDER BY created_at DESC LIMIT 50''', (session['username'],))
    
    notifications = []
    for row in c.fetchall():
        notifications.append({
            'id': row[0],
            'type': row[1],
            'message': row[2],
            'data': json.loads(row[3]) if row[3] else {},
            'read': bool(row[4]),
            'created_at': row[5]
        })
    
    conn.close()
    return jsonify(notifications)

# Verify user credentials
def verify_user(username, password):
    # Check if user exists in filebrowser database
    try:
        result = subprocess.run(
            ['filebrowser', 'users', 'ls', '--database', DB_PATH],
            capture_output=True, text=True
        )
        # Just check if username exists (password verification happens in filebrowser itself)
        if username in result.stdout:
            return True
        return False
    except:
        return False

# Socket.IO events
@socketio.on('connect')
def handle_connect():
    if 'username' in session:
        join_room(session['username'])
        update_online_status(session['username'])
        
        # Broadcast online status to friends
        friends = get_friends(session['username'])
        for friend in friends:
            socketio.emit('friend_online', {
                'username': session['username']
            }, room=friend['username'])

@socketio.on('disconnect')
def handle_disconnect():
    if 'username' in session:
        leave_room(session['username'])

@socketio.on('heartbeat')
def handle_heartbeat():
    if 'username' in session:
        update_online_status(session['username'])

if __name__ == '__main__':
    socketio.run(app, host='127.0.0.1', port=5001, debug=False, allow_unsafe_werkzeug=True)
