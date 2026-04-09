#!/usr/bin/env python3
"""
Automated Forensic Response System
Monitors logs for suspicious activity and activates Tor/VPN routing
"""

import sys
import os
import re
import time
import json
import hashlib
import subprocess
from datetime import datetime
from collections import defaultdict
from typing import Dict, List, Optional

# Optional requests import for Loki integration
try:
    import requests
    REQUESTS_AVAILABLE = True
except ImportError:
    REQUESTS_AVAILABLE = False

# Configuration
LOG_FILE = os.getenv('LOG_FILE', '/var/log/peacebonds/security.log')
LOKI_URL = os.getenv('LOKI_URL', 'http://localhost:3100')
TOR_ENABLED = os.getenv('TOR_ENABLED', 'true').lower() == 'true'
VPN_ENABLED = os.getenv('VPN_ENABLED', 'true').lower() == 'true'
CHECK_INTERVAL = int(os.getenv('CHECK_INTERVAL', '30'))  # seconds
ALERT_THRESHOLD = int(os.getenv('ALERT_THRESHOLD', '5'))
QUARANTINE_THRESHOLD = int(os.getenv('QUARANTINE_THRESHOLD', '10'))

# Suspicious patterns
SUSPICIOUS_PATTERNS = [
    r'(?i)(failed.*login|authentication.*failed)',
    r'(?i)(unauthorized.*access|access.*denied)',
    r'(?i)(sql.*injection|xss.*attempt|code.*injection)',
    r'(?i)(port.*scan|network.*scan)',
    r'(?i)(brute.*force|dictionary.*attack)',
    r'(?i)(malware|virus|trojan|ransomware)',
    r'(?i)(data.*exfiltration|suspicious.*transfer)',
    r'(?i)(privilege.*escalation|root.*access)',
    r'(?i)(ddos|dos.*attack)',
    r'(?i)(intrusion.*detected|security.*breach)',
]

# Anomaly detection state
anomaly_tracker: Dict[str, int] = defaultdict(int)
ip_tracker: Dict[str, int] = defaultdict(int)
last_alert_time: Dict[str, float] = {}


class ForensicResponse:
    """Automated forensic response handler"""
    
    def __init__(self):
        self.tor_active = False
        self.vpn_active = False
        self.quarantined_ips = set()
        
    def check_log_entry(self, line: str) -> Optional[Dict]:
        """Check if log entry matches suspicious patterns"""
        for pattern in SUSPICIOUS_PATTERNS:
            if re.search(pattern, line):
                return {
                    'timestamp': datetime.now().isoformat(),
                    'pattern': pattern,
                    'line': line.strip(),
                    'severity': self._calculate_severity(line)
                }
        return None
    
    def _calculate_severity(self, line: str) -> str:
        """Calculate severity based on keywords"""
        critical_keywords = ['breach', 'root', 'exfiltration', 'ransomware']
        high_keywords = ['injection', 'escalation', 'malware', 'intrusion']
        medium_keywords = ['unauthorized', 'brute', 'scan', 'ddos']
        
        line_lower = line.lower()
        if any(kw in line_lower for kw in critical_keywords):
            return 'critical'
        elif any(kw in line_lower for kw in high_keywords):
            return 'high'
        elif any(kw in line_lower for kw in medium_keywords):
            return 'medium'
        return 'low'
    
    def extract_ip(self, line: str) -> Optional[str]:
        """Extract IP address from log line"""
        ip_pattern = r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'
        match = re.search(ip_pattern, line)
        return match.group(0) if match else None
    
    def activate_tor_routing(self) -> bool:
        """Activate Tor routing for anonymous communication"""
        if not TOR_ENABLED or self.tor_active:
            return False
        
        try:
            print(f"[{datetime.now().isoformat()}] FORENSIC ALERT: Activating Tor routing")
            
            # Start Tor service
            subprocess.run(['systemctl', 'start', 'tor'], 
                         check=False, capture_output=True)
            
            # Configure iptables to route traffic through Tor
            commands = [
                ['iptables', '-t', 'nat', '-A', 'OUTPUT', '-p', 'tcp', 
                 '--syn', '-j', 'REDIRECT', '--to-ports', '9050'],
                ['iptables', '-A', 'OUTPUT', '-p', 'udp', '--dport', '53',
                 '-j', 'REDIRECT', '--to-ports', '5353']
            ]
            
            for cmd in commands:
                subprocess.run(cmd, check=False, capture_output=True)
            
            self.tor_active = True
            self._log_forensic_action('tor_activated', 'Tor routing activated')
            return True
            
        except Exception as e:
            print(f"ERROR: Failed to activate Tor: {e}")
            return False
    
    def activate_vpn_routing(self) -> bool:
        """Activate VPN routing for secure communication"""
        if not VPN_ENABLED or self.vpn_active:
            return False
        
        try:
            print(f"[{datetime.now().isoformat()}] FORENSIC ALERT: Activating VPN routing")
            
            # Connect to VPN
            vpn_config = os.getenv('VPN_CONFIG', '/etc/openvpn/peacebonds.ovpn')
            subprocess.Popen(['openvpn', '--config', vpn_config],
                           stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL)
            
            time.sleep(5)  # Wait for VPN to establish
            
            # Verify VPN connection
            result = subprocess.run(['ip', 'addr', 'show', 'tun0'],
                                  capture_output=True, text=True)
            
            if result.returncode == 0:
                self.vpn_active = True
                self._log_forensic_action('vpn_activated', 'VPN routing activated')
                return True
            else:
                print("ERROR: VPN connection failed to establish")
                return False
                
        except Exception as e:
            print(f"ERROR: Failed to activate VPN: {e}")
            return False
    
    def quarantine_ip(self, ip: str):
        """Quarantine suspicious IP address"""
        if ip in self.quarantined_ips:
            return
        
        try:
            print(f"[{datetime.now().isoformat()}] FORENSIC ALERT: Quarantining IP {ip}")
            
            # Block IP using iptables (insert at beginning to ensure priority)
            subprocess.run(['iptables', '-I', 'INPUT', '1', '-s', ip, '-j', 'DROP'],
                         check=False, capture_output=True)
            subprocess.run(['iptables', '-I', 'OUTPUT', '1', '-d', ip, '-j', 'DROP'],
                         check=False, capture_output=True)
            
            self.quarantined_ips.add(ip)
            self._log_forensic_action('ip_quarantined', f'IP {ip} quarantined')
            
        except Exception as e:
            print(f"ERROR: Failed to quarantine IP {ip}: {e}")
    
    def _log_forensic_action(self, action: str, details: str):
        """Log forensic action to file and Loki"""
        log_entry = {
            'timestamp': datetime.now().isoformat(),
            'action': action,
            'details': details,
            'tor_active': self.tor_active,
            'vpn_active': self.vpn_active,
            'quarantined_ips': list(self.quarantined_ips)
        }
        
        # Write to local log
        forensic_log = os.getenv('FORENSIC_LOG', '/var/log/peacebonds/forensic.log')
        os.makedirs(os.path.dirname(forensic_log), exist_ok=True)
        
        with open(forensic_log, 'a') as f:
            f.write(json.dumps(log_entry) + '\n')
        
        # Send to Loki if available
        if REQUESTS_AVAILABLE:
            try:
                loki_payload = {
                    'streams': [{
                        'stream': {'job': 'forensic-response', 'level': 'alert'},
                        'values': [[str(int(time.time() * 1e9)), json.dumps(log_entry)]]
                    }]
                }
                requests.post(f'{LOKI_URL}/loki/api/v1/push', json=loki_payload, timeout=5)
            except Exception:
                pass  # Silently fail if Loki is not available
    
    def monitor_logs(self):
        """Main monitoring loop"""
        print(f"[{datetime.now().isoformat()}] Starting forensic response monitor...")
        print(f"Monitoring: {LOG_FILE}")
        print(f"Tor enabled: {TOR_ENABLED}, VPN enabled: {VPN_ENABLED}")
        print(f"Alert threshold: {ALERT_THRESHOLD}, Quarantine threshold: {QUARANTINE_THRESHOLD}")
        
        try:
            # Follow log file
            with open(LOG_FILE, 'r') as f:
                # Seek to end of file
                f.seek(0, 2)
                
                while True:
                    line = f.readline()
                    
                    if not line:
                        time.sleep(1)
                        continue
                    
                    # Check for suspicious activity
                    alert = self.check_log_entry(line)
                    if alert:
                        self._handle_alert(alert, line)
                    
        except FileNotFoundError:
            print(f"ERROR: Log file not found: {LOG_FILE}")
            print("Creating log file...")
            os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
            open(LOG_FILE, 'a').close()
            time.sleep(5)
            self.monitor_logs()
            
        except KeyboardInterrupt:
            print("\nShutting down forensic response monitor...")
            sys.exit(0)
    
    def _handle_alert(self, alert: Dict, line: str):
        """Handle detected alert"""
        severity = alert['severity']
        pattern_hash = hashlib.md5(alert['pattern'].encode()).hexdigest()
        
        # Track anomaly
        anomaly_tracker[pattern_hash] += 1
        
        # Track IP if present
        ip = self.extract_ip(line)
        if ip:
            ip_tracker[ip] += 1
        
        print(f"[{datetime.now().isoformat()}] ALERT: {severity.upper()} - {alert['line'][:100]}")
        
        # Escalate based on severity and frequency
        if severity == 'critical' or anomaly_tracker[pattern_hash] >= ALERT_THRESHOLD:
            if not self.tor_active and not self.vpn_active:
                # Activate Tor first, then VPN as backup
                if not self.activate_tor_routing():
                    self.activate_vpn_routing()
        
        # Quarantine aggressive IPs
        if ip and ip_tracker[ip] >= QUARANTINE_THRESHOLD:
            self.quarantine_ip(ip)


def main():
    """Main entry point"""
    response = ForensicResponse()
    response.monitor_logs()


if __name__ == '__main__':
    main()
