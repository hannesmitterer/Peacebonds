#!/usr/bin/env python3
"""
Automated Forensic Response System
Monitors logs for suspicious activity and activates Tor/VPN routing
"""

import re
import time
import subprocess
import logging
import os
import json
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Any

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/peacebonds/forensic-watcher.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class ForensicResponseConfig:
    """Configuration for forensic response system"""
    
    def __init__(self, config_path: str = "/etc/peacebonds/forensic-config.json"):
        self.config_path = config_path
        self.config = self._load_config()
        
    def _load_config(self) -> Dict[str, Any]:
        """Load configuration from file"""
        default_config = {
            "log_files": [
                "/var/log/peacebonds/app.log",
                "/var/log/peacebonds/access.log",
                "/var/log/auth.log",
                "/var/log/syslog"
            ],
            "suspicious_patterns": [
                {
                    "name": "failed_login_attempts",
                    "pattern": r"Failed password for .* from (\d+\.\d+\.\d+\.\d+)",
                    "threshold": 5,
                    "window_seconds": 300,
                    "severity": "high"
                },
                {
                    "name": "unauthorized_access",
                    "pattern": r"(403|401|Unauthorized|Forbidden)",
                    "threshold": 10,
                    "window_seconds": 60,
                    "severity": "medium"
                },
                {
                    "name": "port_scan_detected",
                    "pattern": r"(port scan|SYN flood|DDoS)",
                    "threshold": 1,
                    "window_seconds": 10,
                    "severity": "critical"
                },
                {
                    "name": "suspicious_ipfs_activity",
                    "pattern": r"(IPFS.*error|CID.*not found|gateway.*timeout)",
                    "threshold": 20,
                    "window_seconds": 300,
                    "severity": "medium"
                },
                {
                    "name": "blockchain_anomaly",
                    "pattern": r"(transaction failed|nonce|gas limit|revert)",
                    "threshold": 15,
                    "window_seconds": 600,
                    "severity": "low"
                }
            ],
            "response_actions": {
                "tor_enabled": True,
                "vpn_enabled": True,
                "tor_priority": True,
                "rate_limiting": True,
                "notification_enabled": True
            },
            "tor_config": {
                "socks_port": 9050,
                "control_port": 9051,
                "service_name": "tor"
            },
            "vpn_config": {
                "provider": "openvpn",
                "config_file": "/etc/openvpn/client.conf",
                "service_name": "openvpn"
            }
        }
        
        try:
            if os.path.exists(self.config_path):
                with open(self.config_path, 'r') as f:
                    loaded_config = json.load(f)
                    default_config.update(loaded_config)
        except Exception as e:
            logger.warning(f"Could not load config from {self.config_path}: {e}. Using defaults.")
            
        return default_config


class SuspiciousActivityTracker:
    """Tracks suspicious activity patterns"""
    
    def __init__(self):
        self.events = {}
        
    def add_event(self, pattern_name: str, timestamp: float):
        """Add a suspicious event"""
        if pattern_name not in self.events:
            self.events[pattern_name] = []
        self.events[pattern_name].append(timestamp)
        
    def check_threshold(self, pattern_name: str, threshold: int, window_seconds: int) -> bool:
        """Check if pattern exceeds threshold within time window"""
        if pattern_name not in self.events:
            return False
            
        current_time = time.time()
        cutoff_time = current_time - window_seconds
        
        # Remove old events
        self.events[pattern_name] = [
            t for t in self.events[pattern_name] if t > cutoff_time
        ]
        
        count = len(self.events[pattern_name])
        logger.debug(f"Pattern {pattern_name}: {count} events in last {window_seconds}s (threshold: {threshold})")
        
        return count >= threshold
        
    def clear_events(self, pattern_name: str):
        """Clear events for a pattern"""
        if pattern_name in self.events:
            self.events[pattern_name] = []


class ForensicResponseSystem:
    """Main forensic response system"""
    
    def __init__(self, config: ForensicResponseConfig):
        self.config = config
        self.tracker = SuspiciousActivityTracker()
        self.tor_active = False
        self.vpn_active = False
        self.log_positions = {}
        
    def _read_log_lines(self, log_file: str) -> List[str]:
        """Read new lines from log file"""
        try:
            if not os.path.exists(log_file):
                logger.warning(f"Log file {log_file} does not exist")
                return []
                
            # Get current position or start from end
            if log_file not in self.log_positions:
                # Start from current end of file
                with open(log_file, 'r') as f:
                    f.seek(0, os.SEEK_END)
                    self.log_positions[log_file] = f.tell()
                return []
            
            # Read from last position
            with open(log_file, 'r') as f:
                f.seek(self.log_positions[log_file])
                lines = f.readlines()
                self.log_positions[log_file] = f.tell()
                
            return lines
            
        except Exception as e:
            logger.error(f"Error reading log file {log_file}: {e}")
            return []
    
    def _check_pattern(self, line: str, pattern_config: Dict[str, Any]) -> bool:
        """Check if line matches suspicious pattern"""
        try:
            pattern = re.compile(pattern_config['pattern'], re.IGNORECASE)
            match = pattern.search(line)
            
            if match:
                logger.info(f"SUSPICIOUS: Pattern '{pattern_config['name']}' matched: {line.strip()}")
                return True
                
        except Exception as e:
            logger.error(f"Error checking pattern {pattern_config['name']}: {e}")
            
        return False
    
    def _activate_tor_routing(self) -> bool:
        """Activate Tor routing"""
        if self.tor_active:
            logger.info("Tor routing already active")
            return True
            
        try:
            logger.warning("FORENSIC ACTION: Activating Tor routing")
            
            # Validate service name to prevent command injection
            service_name = self.config.config['tor_config']['service_name']
            if not service_name.isalnum() and service_name not in ['tor', 'tor.service']:
                logger.error(f"Invalid service name: {service_name}")
                return False
            
            # Start Tor service
            result = subprocess.run(
                ['systemctl', 'start', service_name],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                self.tor_active = True
                logger.info("Tor routing activated successfully")
                
                # Configure application to use Tor SOCKS proxy
                self._configure_tor_proxy()
                return True
            else:
                logger.error(f"Failed to activate Tor: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"Error activating Tor routing: {e}")
            return False
    
    def _activate_vpn_routing(self) -> bool:
        """Activate VPN routing as fallback"""
        if self.vpn_active:
            logger.info("VPN routing already active")
            return True
            
        try:
            logger.warning("FORENSIC ACTION: Activating VPN routing")
            
            # Validate service name to prevent command injection
            service_name = self.config.config['vpn_config']['service_name']
            if not service_name.isalnum() and service_name not in ['openvpn', 'openvpn.service']:
                logger.error(f"Invalid service name: {service_name}")
                return False
            
            # Start VPN service
            result = subprocess.run(
                ['systemctl', 'start', service_name],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                self.vpn_active = True
                logger.info("VPN routing activated successfully")
                return True
            else:
                logger.error(f"Failed to activate VPN: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"Error activating VPN routing: {e}")
            return False
    
    def _configure_tor_proxy(self):
        """Configure application to route through Tor"""
        try:
            tor_port = self.config.config['tor_config']['socks_port']
            
            # Set environment variables for Tor proxy
            os.environ['HTTP_PROXY'] = f'socks5://127.0.0.1:{tor_port}'
            os.environ['HTTPS_PROXY'] = f'socks5://127.0.0.1:{tor_port}'
            
            logger.info(f"Configured application to use Tor SOCKS proxy on port {tor_port}")
            
        except Exception as e:
            logger.error(f"Error configuring Tor proxy: {e}")
    
    def _send_alert(self, pattern_name: str, severity: str):
        """Send alert notification"""
        try:
            alert_message = {
                "timestamp": datetime.now().isoformat(),
                "pattern": pattern_name,
                "severity": severity,
                "action": "tor_activated" if self.tor_active else "vpn_activated" if self.vpn_active else "monitoring",
                "message": f"Suspicious activity detected: {pattern_name}"
            }
            
            logger.warning(f"ALERT: {json.dumps(alert_message, indent=2)}")
            
            # Write to alert log
            alert_file = "/var/log/peacebonds/security-alerts.log"
            os.makedirs(os.path.dirname(alert_file), exist_ok=True)
            with open(alert_file, 'a') as f:
                f.write(json.dumps(alert_message) + '\n')
                
        except Exception as e:
            logger.error(f"Error sending alert: {e}")
    
    def _handle_suspicious_activity(self, pattern_config: Dict[str, Any]):
        """Handle detected suspicious activity"""
        pattern_name = pattern_config['name']
        severity = pattern_config['severity']
        
        logger.warning(f"THRESHOLD EXCEEDED: {pattern_name} (severity: {severity})")
        
        # Send alert
        self._send_alert(pattern_name, severity)
        
        # Take action based on severity and configuration
        if severity in ['critical', 'high']:
            if self.config.config['response_actions']['tor_enabled']:
                if self.config.config['response_actions']['tor_priority']:
                    success = self._activate_tor_routing()
                    if not success and self.config.config['response_actions']['vpn_enabled']:
                        self._activate_vpn_routing()
                else:
                    success = self._activate_vpn_routing()
                    if not success:
                        self._activate_tor_routing()
            elif self.config.config['response_actions']['vpn_enabled']:
                self._activate_vpn_routing()
        
        # Clear events after handling
        self.tracker.clear_events(pattern_name)
    
    def monitor_logs(self):
        """Main monitoring loop"""
        logger.info("Starting forensic log monitoring...")
        logger.info(f"Monitoring {len(self.config.config['log_files'])} log files")
        logger.info(f"Tracking {len(self.config.config['suspicious_patterns'])} suspicious patterns")
        
        while True:
            try:
                # Check each log file
                for log_file in self.config.config['log_files']:
                    lines = self._read_log_lines(log_file)
                    
                    # Check each line against patterns
                    for line in lines:
                        for pattern_config in self.config.config['suspicious_patterns']:
                            if self._check_pattern(line, pattern_config):
                                # Add event
                                self.tracker.add_event(pattern_config['name'], time.time())
                                
                                # Check if threshold exceeded
                                if self.tracker.check_threshold(
                                    pattern_config['name'],
                                    pattern_config['threshold'],
                                    pattern_config['window_seconds']
                                ):
                                    self._handle_suspicious_activity(pattern_config)
                
                # Sleep before next check
                time.sleep(5)
                
            except KeyboardInterrupt:
                logger.info("Shutting down forensic monitoring...")
                break
            except Exception as e:
                logger.error(f"Error in monitoring loop: {e}")
                time.sleep(10)


def main():
    """Main entry point"""
    # Create log directory
    os.makedirs('/var/log/peacebonds', exist_ok=True)
    
    # Load configuration
    config = ForensicResponseConfig()
    
    # Create and start forensic system
    forensic_system = ForensicResponseSystem(config)
    forensic_system.monitor_logs()


if __name__ == '__main__':
    main()
