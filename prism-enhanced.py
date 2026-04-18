#!/usr/bin/env python3

"""
P.R.I.S.M Enhanced - Pterodactyl Resource Intelligence & System Monitor
Advanced AI-powered server management with comprehensive automation
"""

import json
import subprocess
import time
import requests
import os
import sys
import re
import sqlite3
from datetime import datetime, timedelta
from collections import defaultdict
import hashlib

CONFIG_FILE = "/opt/ptero-assistant/config.json"
LOG_FILE = "/var/log/ptero-assistant.log"
DB_FILE = "/opt/ptero-assistant/prism.db"
METRICS_DB = "/opt/ptero-assistant/metrics.db"

class PRISMEnhanced:
    def __init__(self):
        self.config = self.load_config()
        self.init_database()
        self.webhooks = self.load_webhooks()
        self.pterodactyl_api = self.load_pterodactyl_config()
        
    def log(self, message, level="INFO"):
        """Enhanced logging with database storage"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] [{level}] {message}"
        print(log_entry)
        
        with open(LOG_FILE, "a") as f:
            f.write(log_entry + "\n")
        
        # Store in database for analysis
        conn = sqlite3.connect(DB_FILE)
        c = conn.cursor()
        c.execute("INSERT INTO logs (timestamp, level, message) VALUES (?, ?, ?)",
                  (timestamp, level, message))
        conn.commit()
        conn.close()
    
    def init_database(self):
        """Initialize SQLite databases for metrics and analysis"""
        conn = sqlite3.connect(DB_FILE)
        c = conn.cursor()
        
        # Logs table
        c.execute('''CREATE TABLE IF NOT EXISTS logs
                     (id INTEGER PRIMARY KEY, timestamp TEXT, level TEXT, message TEXT)''')
        
        # Alerts table
        c.execute('''CREATE TABLE IF NOT EXISTS alerts
                     (id INTEGER PRIMARY KEY, timestamp TEXT, type TEXT, severity TEXT, 
                      message TEXT, resolved INTEGER DEFAULT 0)''')
        
        # Webhooks table
        c.execute('''CREATE TABLE IF NOT EXISTS webhooks
                     (id INTEGER PRIMARY KEY, name TEXT, url TEXT, enabled INTEGER DEFAULT 1)''')
        
        # Custom rules table
        c.execute('''CREATE TABLE IF NOT EXISTS custom_rules
                     (id INTEGER PRIMARY KEY, name TEXT, condition TEXT, action TEXT, 
                      enabled INTEGER DEFAULT 1)''')
        
        # Backup verification table
        c.execute('''CREATE TABLE IF NOT EXISTS backup_verifications
                     (id INTEGER PRIMARY KEY, timestamp TEXT, backup_file TEXT, 
                      status TEXT, details TEXT)''')
        
        # Game server health table
        c.execute('''CREATE TABLE IF NOT EXISTS game_servers
                     (id INTEGER PRIMARY KEY, server_id TEXT, name TEXT, 
                      last_check TEXT, status TEXT, uptime INTEGER)''')
        
        conn.commit()
        conn.close()
        
        # Metrics database
        conn = sqlite3.connect(METRICS_DB)
        c = conn.cursor()
        
        c.execute('''CREATE TABLE IF NOT EXISTS metrics
                     (id INTEGER PRIMARY KEY, timestamp TEXT, metric_type TEXT, 
                      value REAL, metadata TEXT)''')
        
        conn.commit()
        conn.close()
    
    def load_config(self):
        """Load configuration"""
        try:
            with open(CONFIG_FILE, "r") as f:
                return json.load(f)
        except:
            return {
                "enabled": True,
                "model": "gemma2:1b",
                "check_interval": 300,
                "auto_fix": True,
                "notify_admin": True,
                "assistant_name": "P.R.I.S.M"
            }
    
    def save_config(self):
        """Save configuration"""
        with open(CONFIG_FILE, "w") as f:
            json.dump(self.config, f, indent=2)
    
    def load_webhooks(self):
        """Load webhook configurations"""
        conn = sqlite3.connect(DB_FILE)
        c = conn.cursor()
        c.execute("SELECT name, url FROM webhooks WHERE enabled = 1")
        webhooks = {row[0]: row[1] for row in c.fetchall()}
        conn.close()
        return webhooks
    
    def load_pterodactyl_config(self):
        """Load Pterodactyl API configuration"""
        api_config_file = "/opt/ptero-assistant/pterodactyl-api.json"
        try:
            with open(api_config_file, "r") as f:
                return json.load(f)
        except:
            return None
    
    def send_webhook(self, message, severity="info"):
        """Send notifications to all configured webhooks"""
        if not self.config.get("notify_admin", True):
            return
        
        color_map = {
            "critical": 0xFF0000,  # Red
            "warning": 0xFFA500,   # Orange
            "info": 0x00FF00,      # Green
            "success": 0x00FFFF    # Cyan
        }
        
        for name, url in self.webhooks.items():
            try:
                if "discord" in url:
                    # Discord webhook format
                    payload = {
                        "embeds": [{
                            "title": f"🤖 P.R.I.S.M Alert",
                            "description": message,
                            "color": color_map.get(severity, 0x0000FF),
                            "timestamp": datetime.utcnow().isoformat(),
                            "footer": {
                                "text": "Pterodactyl Resource Intelligence & System Monitor"
                            }
                        }]
                    }
                elif "slack" in url:
                    # Slack webhook format
                    payload = {
                        "text": f"🤖 *P.R.I.S.M Alert*\n{message}"
                    }
                else:
                    # Generic webhook
                    payload = {
                        "message": message,
                        "severity": severity,
                        "timestamp": datetime.utcnow().isoformat()
                    }
                
                requests.post(url, json=payload, timeout=5)
                self.log(f"Webhook sent to {name}", "INFO")
            except Exception as e:
                self.log(f"Failed to send webhook to {name}: {e}", "ERROR")
    
    def query_ollama(self, prompt):
        """Query Ollama API"""
        try:
            response = requests.post(
                "http://localhost:11434/api/generate",
                json={
                    "model": self.config.get("model", "gemma2:1b"),
                    "prompt": prompt,
                    "stream": False
                },
                timeout=30
            )
            
            if response.status_code == 200:
                return response.json().get("response", "")
            else:
                self.log(f"Ollama API error: {response.status_code}", "ERROR")
                return None
        except Exception as e:
            self.log(f"Failed to query Ollama: {e}", "ERROR")
            return None
    
    def get_system_metrics(self):
        """Collect comprehensive system metrics"""
        metrics = {}
        
        # CPU usage
        try:
            cpu = subprocess.run(["top", "-bn1"], capture_output=True, text=True)
            for line in cpu.stdout.split("\n"):
                if "Cpu(s)" in line:
                    idle = float(line.split(",")[3].split()[0])
                    metrics["cpu_usage"] = round(100 - idle, 2)
                    break
        except:
            metrics["cpu_usage"] = 0
        
        # Memory usage
        try:
            mem = subprocess.run(["free", "-m"], capture_output=True, text=True)
            lines = mem.stdout.split("\n")
            if len(lines) > 1:
                parts = lines[1].split()
                total = int(parts[1])
                used = int(parts[2])
                metrics["memory_usage"] = round((used / total) * 100, 2)
                metrics["memory_total_mb"] = total
                metrics["memory_used_mb"] = used
        except:
            metrics["memory_usage"] = 0
        
        # Disk usage
        try:
            disk = subprocess.run(["df", "-h", "/"], capture_output=True, text=True)
            lines = disk.stdout.split("\n")
            if len(lines) > 1:
                parts = lines[1].split()
                metrics["disk_usage"] = int(parts[4].replace("%", ""))
                metrics["disk_available"] = parts[3]
                metrics["disk_total"] = parts[1]
        except:
            metrics["disk_usage"] = 0
        
        # Network stats
        try:
            net = subprocess.run(["cat", "/proc/net/dev"], capture_output=True, text=True)
            for line in net.stdout.split("\n"):
                if "eth0" in line or "ens" in line:
                    parts = line.split()
                    metrics["network_rx_bytes"] = int(parts[1])
                    metrics["network_tx_bytes"] = int(parts[9])
                    break
        except:
            pass
        
        # Service status
        services = ["nginx", "mysql", "mariadb", "redis-server", "redis", "wings", "docker"]
        metrics["services"] = {}
        for service in services:
            try:
                result = subprocess.run(
                    ["systemctl", "is-active", service],
                    capture_output=True,
                    text=True
                )
                metrics["services"][service] = result.stdout.strip() == "active"
            except:
                metrics["services"][service] = False
        
        # Store metrics in database
        self.store_metrics(metrics)
        
        return metrics
    
    def store_metrics(self, metrics):
        """Store metrics in database for trend analysis"""
        conn = sqlite3.connect(METRICS_DB)
        c = conn.cursor()
        timestamp = datetime.now().isoformat()
        
        for key, value in metrics.items():
            if isinstance(value, (int, float)):
                c.execute("INSERT INTO metrics (timestamp, metric_type, value, metadata) VALUES (?, ?, ?, ?)",
                          (timestamp, key, value, ""))
        
        conn.commit()
        conn.close()
    
    def predictive_maintenance(self):
        """Analyze trends and predict future issues"""
        conn = sqlite3.connect(METRICS_DB)
        c = conn.cursor()
        
        predictions = []
        
        # Predict disk fill time
        c.execute("""SELECT timestamp, value FROM metrics 
                     WHERE metric_type = 'disk_usage' 
                     ORDER BY timestamp DESC LIMIT 100""")
        disk_data = c.fetchall()
        
        if len(disk_data) >= 10:
            # Simple linear regression
            recent_growth = disk_data[0][1] - disk_data[-1][1]
            time_diff = (datetime.fromisoformat(disk_data[0][0]) - 
                        datetime.fromisoformat(disk_data[-1][0])).days
            
            if time_diff > 0 and recent_growth > 0:
                daily_growth = recent_growth / time_diff
                current_usage = disk_data[0][1]
                days_until_full = (100 - current_usage) / daily_growth if daily_growth > 0 else 999
                
                if days_until_full < 30:
                    predictions.append({
                        "type": "disk_space",
                        "severity": "warning" if days_until_full > 7 else "critical",
                        "message": f"Disk will be full in approximately {int(days_until_full)} days",
                        "days": int(days_until_full)
                    })
        
        # Predict memory issues
        c.execute("""SELECT timestamp, value FROM metrics 
                     WHERE metric_type = 'memory_usage' 
                     ORDER BY timestamp DESC LIMIT 50""")
        mem_data = c.fetchall()
        
        if len(mem_data) >= 10:
            avg_mem = sum(row[1] for row in mem_data[:10]) / 10
            if avg_mem > 85:
                predictions.append({
                    "type": "memory",
                    "severity": "warning",
                    "message": f"Memory usage trending high (avg {avg_mem:.1f}% over last 10 checks)",
                    "average": avg_mem
                })
        
        conn.close()
        return predictions
    
    def monitor_game_servers(self):
        """Monitor individual game servers via Pterodactyl API"""
        if not self.pterodactyl_api:
            return []
        
        issues = []
        
        try:
            headers = {
                "Authorization": f"Bearer {self.pterodactyl_api['api_key']}",
                "Accept": "application/json"
            }
            
            # Get all servers
            response = requests.get(
                f"{self.pterodactyl_api['panel_url']}/api/application/servers",
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                servers = response.json().get("data", [])
                
                for server in servers:
                    server_id = server["attributes"]["identifier"]
                    server_name = server["attributes"]["name"]
                    
                    # Check server status
                    status_response = requests.get(
                        f"{self.pterodactyl_api['panel_url']}/api/client/servers/{server_id}/resources",
                        headers=headers,
                        timeout=5
                    )
                    
                    if status_response.status_code == 200:
                        resources = status_response.json()["attributes"]
                        current_state = resources["current_state"]
                        
                        # Update database
                        conn = sqlite3.connect(DB_FILE)
                        c = conn.cursor()
                        c.execute("""INSERT OR REPLACE INTO game_servers 
                                     (server_id, name, last_check, status, uptime) 
                                     VALUES (?, ?, ?, ?, ?)""",
                                  (server_id, server_name, datetime.now().isoformat(),
                                   current_state, resources.get("uptime", 0)))
                        conn.commit()
                        conn.close()
                        
                        # Check for issues
                        if current_state == "offline" or current_state == "stopping":
                            issues.append({
                                "server": server_name,
                                "issue": f"Server is {current_state}",
                                "severity": "warning"
                            })
                        
                        # Check resource usage
                        if resources.get("memory_bytes", 0) > 0:
                            mem_limit = server["attributes"]["limits"]["memory"] * 1024 * 1024
                            mem_usage_pct = (resources["memory_bytes"] / mem_limit) * 100
                            
                            if mem_usage_pct > 95:
                                issues.append({
                                    "server": server_name,
                                    "issue": f"Memory usage at {mem_usage_pct:.1f}%",
                                    "severity": "critical"
                                })
        
        except Exception as e:
            self.log(f"Error monitoring game servers: {e}", "ERROR")
        
        return issues
    
    def verify_backups(self):
        """Verify backup integrity"""
        backup_dir = "/var/backups/pterodactyl"
        issues = []
        
        if not os.path.exists(backup_dir):
            return issues
        
        try:
            # Find recent backups
            backups = []
            for file in os.listdir(backup_dir):
                if file.endswith(".tar.gz") or file.endswith(".sql.gz"):
                    filepath = os.path.join(backup_dir, file)
                    backups.append((filepath, os.path.getmtime(filepath)))
            
            # Sort by modification time
            backups.sort(key=lambda x: x[1], reverse=True)
            
            # Verify most recent backup
            if backups:
                latest_backup = backups[0][0]
                
                # Check file size
                size = os.path.getsize(latest_backup)
                if size < 1024:  # Less than 1KB is suspicious
                    issues.append({
                        "type": "backup",
                        "severity": "critical",
                        "message": f"Backup file {os.path.basename(latest_backup)} is suspiciously small ({size} bytes)"
                    })
                
                # Test archive integrity
                if latest_backup.endswith(".tar.gz"):
                    result = subprocess.run(
                        ["tar", "-tzf", latest_backup],
                        capture_output=True,
                        timeout=30
                    )
                    
                    status = "valid" if result.returncode == 0 else "corrupted"
                    
                    # Store verification result
                    conn = sqlite3.connect(DB_FILE)
                    c = conn.cursor()
                    c.execute("""INSERT INTO backup_verifications 
                                 (timestamp, backup_file, status, details) 
                                 VALUES (?, ?, ?, ?)""",
                              (datetime.now().isoformat(), latest_backup, status,
                               f"Size: {size} bytes"))
                    conn.commit()
                    conn.close()
                    
                    if status == "corrupted":
                        issues.append({
                            "type": "backup",
                            "severity": "critical",
                            "message": f"Backup file {os.path.basename(latest_backup)} is corrupted"
                        })
        
        except Exception as e:
            self.log(f"Error verifying backups: {e}", "ERROR")
        
        return issues
    
    def security_scan(self):
        """Perform security scans"""
        issues = []
        
        # Check for failed login attempts
        try:
            result = subprocess.run(
                ["grep", "Failed password", "/var/log/auth.log"],
                capture_output=True,
                text=True
            )
            
            failed_logins = len(result.stdout.split("\n"))
            if failed_logins > 10:
                issues.append({
                    "type": "security",
                    "severity": "warning",
                    "message": f"{failed_logins} failed login attempts detected in auth.log"
                })
        except:
            pass
        
        # Check for outdated packages
        try:
            result = subprocess.run(
                ["apt", "list", "--upgradable"],
                capture_output=True,
                text=True
            )
            
            upgradable = len([l for l in result.stdout.split("\n") if "/" in l])
            if upgradable > 20:
                issues.append({
                    "type": "security",
                    "severity": "info",
                    "message": f"{upgradable} packages have updates available"
                })
        except:
            pass
        
        # Check open ports
        try:
            result = subprocess.run(
                ["ss", "-tuln"],
                capture_output=True,
                text=True
            )
            
            # Look for suspicious ports
            suspicious_ports = ["23", "21", "69"]  # Telnet, FTP, TFTP
            for port in suspicious_ports:
                if f":{port}" in result.stdout:
                    issues.append({
                        "type": "security",
                        "severity": "warning",
                        "message": f"Suspicious port {port} is open"
                    })
        except:
            pass
        
        return issues
    
    def analyze_logs(self):
        """Analyze logs for patterns and insights"""
        patterns = {
            "database_error": r"(database|mysql|mariadb).*(error|failed|timeout)",
            "memory_error": r"(out of memory|oom|killed process)",
            "disk_error": r"(no space left|disk full|i/o error)",
            "network_error": r"(connection refused|timeout|network unreachable)"
        }
        
        issues = []
        log_files = [
            "/var/log/syslog",
            "/var/log/nginx/error.log",
            "/var/www/pterodactyl/storage/logs/laravel.log"
        ]
        
        for log_file in log_files:
            if not os.path.exists(log_file):
                continue
            
            try:
                # Read last 1000 lines
                result = subprocess.run(
                    ["tail", "-1000", log_file],
                    capture_output=True,
                    text=True,
                    timeout=5
                )
                
                for pattern_name, pattern in patterns.items():
                    matches = re.findall(pattern, result.stdout, re.IGNORECASE)
                    if len(matches) > 5:
                        issues.append({
                            "type": "log_analysis",
                            "severity": "warning",
                            "message": f"Detected {len(matches)} {pattern_name} occurrences in {os.path.basename(log_file)}"
                        })
            except:
                pass
        
        return issues
    
    def network_monitoring(self):
        """Monitor network performance and bandwidth"""
        issues = []
        
        try:
            # Get current network stats
            metrics = self.get_system_metrics()
            
            # Check for high bandwidth usage (requires historical data)
            conn = sqlite3.connect(METRICS_DB)
            c = conn.cursor()
            
            c.execute("""SELECT value FROM metrics 
                         WHERE metric_type = 'network_tx_bytes' 
                         ORDER BY timestamp DESC LIMIT 2""")
            tx_data = c.fetchall()
            
            if len(tx_data) == 2:
                bandwidth_used = tx_data[0][0] - tx_data[1][0]
                # If more than 1GB in 5 minutes
                if bandwidth_used > 1073741824:
                    issues.append({
                        "type": "network",
                        "severity": "warning",
                        "message": f"High bandwidth usage detected: {bandwidth_used / 1073741824:.2f} GB in last interval"
                    })
            
            conn.close()
        except Exception as e:
            self.log(f"Error in network monitoring: {e}", "ERROR")
        
        return issues
    
    def auto_troubleshoot(self, issue_type):
        """Automated troubleshooting and fixes"""
        fixed = []
        
        if issue_type == "high_memory":
            # Clear cache
            try:
                subprocess.run(["sync"], check=True)
                subprocess.run(["sh", "-c", "echo 3 > /proc/sys/vm/drop_caches"], check=True)
                fixed.append("Cleared system cache")
            except:
                pass
        
        elif issue_type == "service_down":
            # Restart services
            services = ["nginx", "mysql", "redis-server", "wings"]
            for service in services:
                try:
                    result = subprocess.run(
                        ["systemctl", "is-active", service],
                        capture_output=True,
                        text=True
                    )
                    if result.stdout.strip() != "active":
                        subprocess.run(["systemctl", "restart", service], check=True)
                        fixed.append(f"Restarted {service}")
                except:
                    pass
        
        elif issue_type == "disk_full":
            # Clean old logs
            try:
                subprocess.run([
                    "find", "/var/log", "-type", "f", "-name", "*.log",
                    "-mtime", "+30", "-delete"
                ], check=True)
                fixed.append("Cleaned old log files")
            except:
                pass
        
        return fixed
    
    def evaluate_custom_rules(self, metrics):
        """Evaluate and execute custom user-defined rules"""
        conn = sqlite3.connect(DB_FILE)
        c = conn.cursor()
        c.execute("SELECT name, condition, action FROM custom_rules WHERE enabled = 1")
        rules = c.fetchall()
        conn.close()
        
        actions_taken = []
        
        for rule_name, condition, action in rules:
            try:
                # Evaluate condition (simple eval for now - could be enhanced)
                if eval(condition, {"metrics": metrics}):
                    self.log(f"Custom rule triggered: {rule_name}", "INFO")
                    # Execute action
                    subprocess.run(action, shell=True)
                    actions_taken.append(rule_name)
            except Exception as e:
                self.log(f"Error evaluating rule {rule_name}: {e}", "ERROR")
        
        return actions_taken
    
    def generate_daily_report(self):
        """Generate daily summary report"""
        conn = sqlite3.connect(METRICS_DB)
        c = conn.cursor()
        
        # Get metrics from last 24 hours
        yesterday = (datetime.now() - timedelta(days=1)).isoformat()
        
        c.execute("""SELECT AVG(value) FROM metrics 
                     WHERE metric_type = 'cpu_usage' AND timestamp > ?""", (yesterday,))
        avg_cpu = c.fetchone()[0] or 0
        
        c.execute("""SELECT AVG(value) FROM metrics 
                     WHERE metric_type = 'memory_usage' AND timestamp > ?""", (yesterday,))
        avg_memory = c.fetchone()[0] or 0
        
        c.execute("""SELECT AVG(value) FROM metrics 
                     WHERE metric_type = 'disk_usage' AND timestamp > ?""", (yesterday,))
        avg_disk = c.fetchone()[0] or 0
        
        conn.close()
        
        # Get alerts from last 24 hours
        conn = sqlite3.connect(DB_FILE)
        c = conn.cursor()
        c.execute("""SELECT COUNT(*) FROM alerts 
                     WHERE timestamp > ? AND severity = 'critical'""", (yesterday,))
        critical_alerts = c.fetchone()[0]
        
        c.execute("""SELECT COUNT(*) FROM alerts 
                     WHERE timestamp > ? AND severity = 'warning'""", (yesterday,))
        warning_alerts = c.fetchone()[0]
        
        conn.close()
        
        report = f"""
📊 **P.R.I.S.M Daily Report** - {datetime.now().strftime('%Y-%m-%d')}

**System Performance (24h Average):**
• CPU Usage: {avg_cpu:.1f}%
• Memory Usage: {avg_memory:.1f}%
• Disk Usage: {avg_disk:.1f}%

**Alerts:**
• Critical: {critical_alerts}
• Warnings: {warning_alerts}

**Status:** {"✅ All systems operational" if critical_alerts == 0 else "⚠️ Issues detected"}
"""
        
        return report
    
    def main_loop(self):
        """Main monitoring loop with all features"""
        self.log("P.R.I.S.M Enhanced started", "INFO")
        self.send_webhook("🤖 P.R.I.S.M Enhanced is now online and monitoring", "success")
        
        last_daily_report = datetime.now().date()
        
        while True:
            try:
                if not self.config.get("enabled", True):
                    self.log("P.R.I.S.M is disabled, sleeping...", "INFO")
                    time.sleep(60)
                    continue
                
                # Collect metrics
                metrics = self.get_system_metrics()
                
                all_issues = []
                
                # Run all monitoring modules
                all_issues.extend(self.predictive_maintenance())
                all_issues.extend(self.monitor_game_servers())
                all_issues.extend(self.verify_backups())
                all_issues.extend(self.security_scan())
                all_issues.extend(self.analyze_logs())
                all_issues.extend(self.network_monitoring())
                
                # Evaluate custom rules
                triggered_rules = self.evaluate_custom_rules(metrics)
                
                # Process issues
                for issue in all_issues:
                    severity = issue.get("severity", "info")
                    message = issue.get("message", str(issue))
                    
                    self.log(f"Issue detected: {message}", severity.upper())
                    
                    # Store alert
                    conn = sqlite3.connect(DB_FILE)
                    c = conn.cursor()
                    c.execute("""INSERT INTO alerts (timestamp, type, severity, message) 
                                 VALUES (?, ?, ?, ?)""",
                              (datetime.now().isoformat(), issue.get("type", "unknown"),
                               severity, message))
                    conn.commit()
                    conn.close()
                    
                    # Send webhook for critical/warning issues
                    if severity in ["critical", "warning"]:
                        self.send_webhook(message, severity)
                    
                    # Auto-fix if enabled
                    if self.config.get("auto_fix", True) and severity == "critical":
                        issue_type = issue.get("type", "")
                        fixes = self.auto_troubleshoot(issue_type)
                        if fixes:
                            fix_msg = f"Auto-fixed: {', '.join(fixes)}"
                            self.log(fix_msg, "SUCCESS")
                            self.send_webhook(fix_msg, "success")
                
                # Generate daily report
                if datetime.now().date() > last_daily_report:
                    report = self.generate_daily_report()
                    self.send_webhook(report, "info")
                    last_daily_report = datetime.now().date()
                
                # Sleep until next check
                time.sleep(self.config.get("check_interval", 300))
                
            except KeyboardInterrupt:
                self.log("P.R.I.S.M Enhanced stopped by user", "INFO")
                self.send_webhook("🤖 P.R.I.S.M Enhanced shutting down", "info")
                break
            except Exception as e:
                self.log(f"Error in main loop: {e}", "ERROR")
                time.sleep(60)

if __name__ == "__main__":
    prism = PRISMEnhanced()
    prism.main_loop()
