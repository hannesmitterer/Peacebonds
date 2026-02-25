#!/usr/bin/env python3
"""
VCD-01 Threat Intelligence Integration
Syncs suspicious IPs with OTX (AlienVault) and AbuseIPDB
"""

import os
import sys
import json
import requests
import time
from datetime import datetime
from typing import List, Dict

# Configuration
SUSPICIOUS_IPS = [
    "185.191.171.3",
    "192.0.78.24",
    "192.0.78.25",
    "52.230.152.148",
    "34.223.12.181",
    "66.249.66.75"
]

# API Configuration (set via environment variables)
OTX_API_KEY = os.getenv('OTX_API_KEY', '')
ABUSEIPDB_API_KEY = os.getenv('ABUSEIPDB_API_KEY', '')

# Endpoints
OTX_BASE_URL = "https://otx.alienvault.com/api/v1"
ABUSEIPDB_BASE_URL = "https://api.abuseipdb.com/api/v2"

class ThreatIntelSync:
    def __init__(self):
        self.otx_key = OTX_API_KEY
        self.abuseipdb_key = ABUSEIPDB_API_KEY
        self.results = []
    
    def check_otx(self, ip: str) -> Dict:
        """Check IP against OTX AlienVault"""
        if not self.otx_key:
            print(f"  ⚠ OTX API key not set, skipping {ip}")
            return {}
        
        try:
            headers = {'X-OTX-API-KEY': self.otx_key}
            url = f"{OTX_BASE_URL}/indicators/IPv4/{ip}/general"
            
            response = requests.get(url, headers=headers, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            return {
                'ip': ip,
                'source': 'OTX',
                'reputation': data.get('reputation', 0),
                'pulse_count': data.get('pulse_info', {}).get('count', 0),
                'asn': data.get('asn', 'Unknown'),
                'country': data.get('country_name', 'Unknown'),
                'timestamp': datetime.now().isoformat()
            }
        except requests.exceptions.RequestException as e:
            print(f"  ✗ OTX check failed for {ip}: {e}")
            return {}
    
    def check_abuseipdb(self, ip: str) -> Dict:
        """Check IP against AbuseIPDB"""
        if not self.abuseipdb_key:
            print(f"  ⚠ AbuseIPDB API key not set, skipping {ip}")
            return {}
        
        try:
            headers = {
                'Key': self.abuseipdb_key,
                'Accept': 'application/json'
            }
            params = {
                'ipAddress': ip,
                'maxAgeInDays': '90',
                'verbose': ''
            }
            
            response = requests.get(
                f"{ABUSEIPDB_BASE_URL}/check",
                headers=headers,
                params=params,
                timeout=10
            )
            response.raise_for_status()
            
            data = response.json()['data']
            return {
                'ip': ip,
                'source': 'AbuseIPDB',
                'abuse_confidence_score': data.get('abuseConfidenceScore', 0),
                'total_reports': data.get('totalReports', 0),
                'last_reported': data.get('lastReportedAt', 'Never'),
                'isp': data.get('isp', 'Unknown'),
                'domain': data.get('domain', 'Unknown'),
                'timestamp': datetime.now().isoformat()
            }
        except requests.exceptions.RequestException as e:
            print(f"  ✗ AbuseIPDB check failed for {ip}: {e}")
            return {}
    
    def report_to_abuseipdb(self, ip: str, categories: List[int], comment: str) -> bool:
        """Report IP to AbuseIPDB"""
        if not self.abuseipdb_key:
            print(f"  ⚠ AbuseIPDB API key not set, cannot report {ip}")
            return False
        
        try:
            headers = {
                'Key': self.abuseipdb_key,
                'Accept': 'application/json'
            }
            data = {
                'ip': ip,
                'categories': ','.join(map(str, categories)),
                'comment': comment
            }
            
            response = requests.post(
                f"{ABUSEIPDB_BASE_URL}/report",
                headers=headers,
                data=data,
                timeout=10
            )
            response.raise_for_status()
            
            print(f"  ✓ Reported {ip} to AbuseIPDB")
            return True
        except requests.exceptions.RequestException as e:
            print(f"  ✗ Failed to report {ip}: {e}")
            return False
    
    def sync_all(self):
        """Sync all suspicious IPs with threat intel feeds"""
        print("=" * 50)
        print("VCD-01 Threat Intelligence Sync")
        print("=" * 50)
        print(f"Checking {len(SUSPICIOUS_IPS)} suspicious IPs...\n")
        
        for ip in SUSPICIOUS_IPS:
            print(f"Checking {ip}...")
            
            # Check OTX
            otx_data = self.check_otx(ip)
            if otx_data:
                self.results.append(otx_data)
                print(f"  ✓ OTX: Reputation={otx_data.get('reputation', 0)}, "
                      f"Pulses={otx_data.get('pulse_count', 0)}")
            
            # Check AbuseIPDB
            abuse_data = self.check_abuseipdb(ip)
            if abuse_data:
                self.results.append(abuse_data)
                print(f"  ✓ AbuseIPDB: Score={abuse_data.get('abuse_confidence_score', 0)}%, "
                      f"Reports={abuse_data.get('total_reports', 0)}")
            
            print()
            time.sleep(1)  # Rate limiting
        
        # Save results
        self.save_results()
        print("\n✓ Threat intelligence sync complete")
    
    def save_results(self):
        """Save results to JSON file"""
        output_file = '/var/log/vcd01-security/threat-intel.json'
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        
        try:
            with open(output_file, 'w') as f:
                json.dump({
                    'timestamp': datetime.now().isoformat(),
                    'results': self.results
                }, f, indent=2)
            print(f"\n✓ Results saved to {output_file}")
        except Exception as e:
            print(f"\n✗ Failed to save results: {e}")

def main():
    """Main entry point"""
    print("\nVCD-01 Threat Intelligence Integration")
    print("=" * 50)
    
    if not OTX_API_KEY and not ABUSEIPDB_API_KEY:
        print("\n⚠ Warning: No API keys configured!")
        print("Set OTX_API_KEY and/or ABUSEIPDB_API_KEY environment variables")
        print("\nExample:")
        print("  export OTX_API_KEY='your-otx-key'")
        print("  export ABUSEIPDB_API_KEY='your-abuseipdb-key'")
        print()
    
    sync = ThreatIntelSync()
    sync.sync_all()

if __name__ == '__main__':
    main()
