#!/usr/bin/env python3
"""
Simple HTTP server for testing the Enhanced SSH Terminal locally
Run this before deploying to production
"""

import http.server
import socketserver
import os
import sys

PORT = 8095
DIRECTORY = os.path.dirname(os.path.abspath(__file__))

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)
    
    def end_headers(self):
        # Add CORS headers for local testing
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        super().end_headers()

def main():
    print("=" * 60)
    print("🚀 Enhanced SSH Terminal - Local Test Server")
    print("=" * 60)
    print(f"📁 Serving directory: {DIRECTORY}")
    print(f"🌐 Server running at: http://localhost:{PORT}")
    print(f"🔗 Direct link: http://localhost:{PORT}/index.html")
    print("=" * 60)
    print("\n✅ Features to test:")
    print("   1. Add a server (click 'Add' button)")
    print("   2. Right-click on tabs")
    print("   3. Drag files onto terminal")
    print("   4. Click robot icon for AI chat")
    print("   5. Open command history panel")
    print("\n💡 Demo functions (open browser console):")
    print("   - demoGhostTyping()")
    print("   - demoHistory()")
    print("   - toggleAIChat()")
    print("\n⚠️  Note: SSH connections won't work locally")
    print("   (Terminal iframes need real SSH server)")
    print("\n🛑 Press Ctrl+C to stop the server")
    print("=" * 60)
    print()

    try:
        with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n\n🛑 Server stopped by user")
        sys.exit(0)
    except OSError as e:
        if e.errno == 10048:  # Port already in use
            print(f"\n❌ ERROR: Port {PORT} is already in use!")
            print(f"   Try closing other applications or use a different port")
        else:
            print(f"\n❌ ERROR: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
