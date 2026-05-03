#!/usr/bin/env python3
"""
SSH Web Terminal
Beautiful web-based SSH terminal with AI assistant integration
"""

from flask import Flask, render_template, request, jsonify, session, redirect
from flask_socketio import SocketIO, emit
from functools import wraps
import subprocess
import json
import os
import hashlib
import pty
import select
import termios
import struct
import fcntl
import threading
import requests

app = Flask(__name__)
app.secret_key = os.urandom(24)
app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'
app.config['SESSION_COOKIE_SECURE'] = False
socketio = SocketIO(app, cors_allowed_origins="*", manage_session=False)

# Configuration
CREDENTIALS_FILE = '/opt/ssh-terminal/credentials.json'
CUSTOMIZATION_FILE = '/opt/ssh-terminal/customization.json'

# Terminal sessions storage
terminal_sessions = {}

def hash_password(password):
    """Hash password using SHA-256"""
    return hashlib.sha256(password.encode()).hexdigest()

def init_credentials():
    """Initialize default credentials if not exists"""
    if not os.path.exists(CREDENTIALS_FILE):
        os.makedirs(os.path.dirname(CREDENTIALS_FILE), exist_ok=True)
        default_creds = {
            'username': 'admin',
            'password': hash_password('admin123')
        }
        with open(CREDENTIALS_FILE, 'w') as f:
            json.dump(default_creds, f)

def verify_credentials(username, password):
    """Verify login credentials"""
    try:
        with open(CREDENTIALS_FILE, 'r') as f:
            creds = json.load(f)
        return creds['username'] == username and creds['password'] == hash_password(password)
    except:
        return False

def login_required(f):
    """Decorator to require login"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'logged_in' not in session:
            if request.path.startswith('/api/'):
                return jsonify({'error': 'Authentication required'}), 401
            return redirect('/login.html')
        return f(*args, **kwargs)
    return decorated_function

@app.route('/login.html')
def login_page():
    """Serve login page"""
    return render_template('login.html')

@app.route('/')
@login_required
def index():
    return render_template('terminal.html')

@app.route('/editor')
@login_required
def editor():
    return render_template('editor.html')

@app.route('/login', methods=['POST'])
def login():
    """Handle login"""
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
    """Handle logout"""
    session.clear()
    return jsonify({'success': True})

@app.route('/api/customization/load', methods=['GET'])
@login_required
def load_customization():
    """Load customization settings"""
    try:
        if os.path.exists(CUSTOMIZATION_FILE):
            with open(CUSTOMIZATION_FILE, 'r') as f:
                return jsonify(json.load(f))
        return jsonify({})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/customization/save', methods=['POST'])
@login_required
def save_customization():
    """Save customization settings"""
    try:
        data = request.json
        os.makedirs(os.path.dirname(CUSTOMIZATION_FILE), exist_ok=True)
        with open(CUSTOMIZATION_FILE, 'w') as f:
            json.dump(data, f)
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/execute', methods=['POST'])
@login_required
def execute_command():
    """Execute a command and return output (for Open WebUI integration)"""
    try:
        data = request.json
        command = data.get('command', '')
        
        if not command:
            return jsonify({'error': 'No command provided'}), 400
        
        # Execute command
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=30
        )
        
        return jsonify({
            'output': result.stdout + result.stderr,
            'returncode': result.returncode
        })
    except subprocess.TimeoutExpired:
        return jsonify({'error': 'Command timed out'}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/ai/chat', methods=['POST'])
@login_required
def ai_chat():
    """Chat with AI assistant (Open WebUI + Ollama Qwen2.5:7b)"""
    try:
        data = request.json
        message = data.get('message', '')
        context = data.get('context', '')  # Code context if provided
        
        # Prepare prompt with context
        full_prompt = message
        if context:
            full_prompt = f"Context:\n```\n{context}\n```\n\nQuestion: {message}"
        
        # Connect to Ollama running on localhost
        ollama_url = "http://localhost:11434/api/generate"
        
        # Build the system prompt
        system_prompt = "You are a helpful coding assistant. You help with Linux commands, code explanations, debugging, and code generation. Be concise and practical."
        
        # Combine system prompt with user message
        if context:
            combined_prompt = f"{system_prompt}\n\nContext:\n```\n{context}\n```\n\nUser: {message}\n\nAssistant:"
        else:
            combined_prompt = f"{system_prompt}\n\nUser: {message}\n\nAssistant:"
        
        payload = {
            "model": "qwen2.5:7b",
            "prompt": combined_prompt,
            "stream": False
        }
        
        try:
            ai_response = requests.post(ollama_url, json=payload, timeout=60)
            
            if ai_response.status_code == 200:
                ai_data = ai_response.json()
                response_text = ai_data.get('response', 'No response from AI')
                
                return jsonify({
                    'response': response_text,
                    'model': 'qwen2.5:7b'
                })
            else:
                return jsonify({
                    'response': f"Ollama returned error {ai_response.status_code}. Make sure qwen2.5:7b is installed.\n\nRun: `ollama pull qwen2.5:7b`",
                    'suggestions': ['ls -la', 'df -h', 'top']
                })
        except requests.exceptions.ConnectionError:
            return jsonify({
                'response': "Cannot connect to Ollama. Make sure it's running:\n\n`systemctl status ollama`\n\nOr start it:\n\n`systemctl start ollama`",
                'suggestions': ['systemctl status ollama', 'ollama list']
            })
        except requests.exceptions.Timeout:
            return jsonify({
                'response': "Ollama request timed out. The model might be loading...",
                'suggestions': ['Try again in a moment']
            })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

class Terminal:
    """PTY-based terminal session"""
    
    def __init__(self, session_id):
        self.session_id = session_id
        self.fd = None
        self.child_pid = None
        
    def spawn(self):
        """Spawn a new terminal session"""
        self.child_pid, self.fd = pty.fork()
        
        if self.child_pid == 0:
            # Child process - run bash with explicit environment
            env = {
                'TERM': 'xterm-256color',
                'PATH': '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
                'HOME': '/root',
                'SHELL': '/bin/bash'
            }
            subprocess.run(['/bin/bash', '-l'], env=env)
        else:
            # Parent process
            self.set_size(24, 80)
            
    def set_size(self, rows, cols):
        """Set terminal size"""
        if self.fd:
            winsize = struct.pack('HHHH', rows, cols, 0, 0)
            fcntl.ioctl(self.fd, termios.TIOCSWINSZ, winsize)
    
    def write(self, data):
        """Write data to terminal"""
        if self.fd:
            os.write(self.fd, data.encode())
    
    def read(self):
        """Read data from terminal"""
        if self.fd:
            try:
                return os.read(self.fd, 1024).decode('utf-8', errors='ignore')
            except:
                return ''
        return ''
    
    def close(self):
        """Close terminal session"""
        if self.fd:
            os.close(self.fd)

@socketio.on('connect')
def handle_connect():
    """Handle WebSocket connection"""
    print(f"WebSocket connect attempt")
    # Don't check session for WebSocket - it doesn't work through Cloudflare Tunnel
    # The page itself is already protected by @login_required
    
    session_id = request.sid
    print(f"Creating terminal for session: {session_id}")
    terminal = Terminal(session_id)
    terminal.spawn()
    terminal_sessions[session_id] = terminal
    print(f"Terminal spawned successfully")
    
    # Start reading thread with optimized buffering
    def read_output():
        import time
        while session_id in terminal_sessions:
            terminal = terminal_sessions[session_id]
            if terminal.fd:
                try:
                    # Non-blocking read with larger buffer
                    r, _, _ = select.select([terminal.fd], [], [], 0.01)
                    if r:
                        output = os.read(terminal.fd, 4096).decode('utf-8', errors='ignore')
                        if output:
                            socketio.emit('output', {'data': output}, room=session_id)
                    else:
                        time.sleep(0.01)
                except:
                    time.sleep(0.01)
    
    thread = threading.Thread(target=read_output, daemon=True)
    thread.start()
    
    emit('connected', {'session_id': session_id})

@socketio.on('disconnect')
def handle_disconnect():
    """Handle WebSocket disconnection"""
    session_id = request.sid
    if session_id in terminal_sessions:
        terminal_sessions[session_id].close()
        del terminal_sessions[session_id]

@socketio.on('input')
def handle_input(data):
    """Handle terminal input"""
    session_id = request.sid
    print(f"Received input for session {session_id}: {repr(data['data'])}")
    if session_id in terminal_sessions:
        terminal_sessions[session_id].write(data['data'])
        print(f"Wrote to terminal")
    else:
        print(f"Session {session_id} not found in terminal_sessions!")

@socketio.on('resize')
def handle_resize(data):
    """Handle terminal resize"""
    session_id = request.sid
    if session_id in terminal_sessions:
        terminal_sessions[session_id].set_size(data['rows'], data['cols'])

if __name__ == '__main__':
    init_credentials()
    socketio.run(app, host='0.0.0.0', port=5003, debug=False)
