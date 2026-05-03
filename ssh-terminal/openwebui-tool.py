"""
title: SSH Terminal Tool
author: CloudMC
version: 1.0
description: Execute commands on your server via SSH terminal
"""

import requests
from typing import Optional

class Tools:
    def __init__(self):
        # Use localhost since Open WebUI and SSH Terminal are on same server
        # This is faster and avoids SSL/auth issues
        self.ssh_terminal_url = "http://localhost:5003"
        # Alternative: Use public URL if needed
        # self.ssh_terminal_url = "https://ssh.cloudmc.online"
        self.session = requests.Session()
    
    def execute_command(self, command: str) -> str:
        """
        Execute a shell command on the server
        :param command: The shell command to execute (e.g., "ls -la", "df -h", "docker ps")
        :return: Command output
        """
        try:
            response = self.session.post(
                f"{self.ssh_terminal_url}/api/execute",
                json={"command": command},
                timeout=30
            )
            
            if response.status_code == 200:
                data = response.json()
                output = data.get('output', 'No output')
                returncode = data.get('returncode', 0)
                
                if returncode == 0:
                    return f"✅ Command executed successfully:\n\n{output}"
                else:
                    return f"⚠️ Command exited with code {returncode}:\n\n{output}"
            else:
                return f"❌ Error: {response.status_code} - {response.text}"
                
        except requests.exceptions.Timeout:
            return "❌ Command timed out (30s limit)"
        except Exception as e:
            return f"❌ Error executing command: {str(e)}"
    
    def get_system_status(self) -> str:
        """
        Get current system status (CPU, memory, disk)
        :return: System status information
        """
        commands = [
            ("Uptime", "uptime -p"),
            ("CPU Load", "cat /proc/loadavg | awk '{print $1, $2, $3}'"),
            ("Memory", "free -h | grep Mem | awk '{print \"Used: \" $3 \" / \" $2}'"),
            ("Disk", "df -h / | tail -1 | awk '{print \"Used: \" $3 \" / \" $2 \" (\" $5 \")\"}'"),
        ]
        
        results = []
        for label, cmd in commands:
            try:
                response = self.session.post(
                    f"{self.ssh_terminal_url}/api/execute",
                    json={"command": cmd},
                    timeout=10
                )
                if response.status_code == 200:
                    output = response.json().get('output', '').strip()
                    results.append(f"**{label}:** {output}")
            except:
                results.append(f"**{label}:** Error")
        
        return "📊 **System Status**\n\n" + "\n".join(results)
    
    def list_docker_containers(self) -> str:
        """
        List all Docker containers
        :return: Docker container list
        """
        return self.execute_command("docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'")
    
    def check_service(self, service_name: str) -> str:
        """
        Check the status of a systemd service
        :param service_name: Name of the service (e.g., "nginx", "ssh-terminal")
        :return: Service status
        """
        return self.execute_command(f"systemctl status {service_name} --no-pager")
