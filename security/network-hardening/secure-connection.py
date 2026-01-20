#!/usr/bin/env python3
"""
Network Communication Hardening Module
Implements QUIC protocol with TLS 1.3 and disables unencrypted communications
"""

import ssl
import socket
import logging
from typing import Optional, Dict, Any
import json

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class SecureConnectionConfig:
    """Configuration for secure connections"""
    
    def __init__(self, config_path: str = "/etc/peacebonds/network-security.json"):
        self.config_path = config_path
        self.config = self._load_config()
        
    def _load_config(self) -> Dict[str, Any]:
        """Load configuration"""
        default_config = {
            "tls_version": "TLSv1.3",
            "cipher_suites": [
                "TLS_AES_256_GCM_SHA384",
                "TLS_CHACHA20_POLY1305_SHA256",
                "TLS_AES_128_GCM_SHA256"
            ],
            "allow_unencrypted": False,
            "quic_enabled": True,
            "quic_port": 4433,
            "cert_file": "/etc/peacebonds/certs/server.crt",
            "key_file": "/etc/peacebonds/certs/server.key",
            "verify_client": True,
            "ca_file": "/etc/peacebonds/certs/ca.crt"
        }
        
        try:
            import os
            if os.path.exists(self.config_path):
                with open(self.config_path, 'r') as f:
                    loaded_config = json.load(f)
                    default_config.update(loaded_config)
        except Exception as e:
            logger.warning(f"Could not load config: {e}. Using defaults.")
            
        return default_config


class SecureTLSContext:
    """Creates secure TLS 1.3 context"""
    
    def __init__(self, config: SecureConnectionConfig):
        self.config = config
        
    def create_server_context(self) -> ssl.SSLContext:
        """Create server SSL context with TLS 1.3"""
        logger.info("Creating secure TLS 1.3 server context")
        
        # Create context with TLS 1.3 minimum
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        
        # Set minimum TLS version to 1.3
        context.minimum_version = ssl.TLSVersion.TLSv1_3
        context.maximum_version = ssl.TLSVersion.TLSv1_3
        
        # Configure cipher suites (TLS 1.3 uses different cipher suite configuration)
        # The cipher suites are set automatically for TLS 1.3
        
        # Load server certificate and key
        try:
            context.load_cert_chain(
                certfile=self.config.config['cert_file'],
                keyfile=self.config.config['key_file']
            )
            logger.info("Server certificate loaded successfully")
        except Exception as e:
            logger.error(f"Failed to load certificates: {e}")
            raise
        
        # Configure client verification if required
        if self.config.config['verify_client']:
            context.verify_mode = ssl.CERT_REQUIRED
            context.load_verify_locations(cafile=self.config.config['ca_file'])
            logger.info("Client certificate verification enabled")
        else:
            context.verify_mode = ssl.CERT_NONE
            
        # Security options
        context.options |= ssl.OP_NO_TLSv1
        context.options |= ssl.OP_NO_TLSv1_1
        context.options |= ssl.OP_NO_TLSv1_2
        context.options |= ssl.OP_NO_COMPRESSION
        context.options |= ssl.OP_SINGLE_DH_USE
        context.options |= ssl.OP_SINGLE_ECDH_USE
        
        logger.info("TLS 1.3 server context configured successfully")
        return context
    
    def create_client_context(self) -> ssl.SSLContext:
        """Create client SSL context with TLS 1.3"""
        logger.info("Creating secure TLS 1.3 client context")
        
        # Create context with TLS 1.3 minimum
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
        
        # Set minimum TLS version to 1.3
        context.minimum_version = ssl.TLSVersion.TLSv1_3
        context.maximum_version = ssl.TLSVersion.TLSv1_3
        
        # Load CA certificates for server verification
        context.load_verify_locations(cafile=self.config.config['ca_file'])
        context.verify_mode = ssl.CERT_REQUIRED
        context.check_hostname = True
        
        # Security options
        context.options |= ssl.OP_NO_TLSv1
        context.options |= ssl.OP_NO_TLSv1_1
        context.options |= ssl.OP_NO_TLSv1_2
        context.options |= ssl.OP_NO_COMPRESSION
        
        logger.info("TLS 1.3 client context configured successfully")
        return context


class QUICConnectionWrapper:
    """Wrapper for QUIC protocol connections"""
    
    def __init__(self, config: SecureConnectionConfig):
        self.config = config
        
    def is_quic_available(self) -> bool:
        """Check if QUIC support is available"""
        try:
            import aioquic
            return True
        except ImportError:
            logger.warning("aioquic library not available. QUIC support disabled.")
            return False
    
    def create_quic_configuration(self):
        """Create QUIC configuration with TLS 1.3"""
        if not self.is_quic_available():
            return None
            
        try:
            from aioquic.quic.configuration import QuicConfiguration
            
            logger.info("Creating QUIC configuration")
            
            configuration = QuicConfiguration(
                is_client=False,
                alpn_protocols=["peacebonds/1.0"],
            )
            
            # Load TLS certificates
            configuration.load_cert_chain(
                certfile=self.config.config['cert_file'],
                keyfile=self.config.config['key_file']
            )
            
            # Verify client certificates if required
            if self.config.config['verify_client']:
                configuration.verify_mode = ssl.CERT_REQUIRED
                configuration.load_verify_locations(
                    cafile=self.config.config['ca_file']
                )
            
            logger.info("QUIC configuration created successfully")
            return configuration
            
        except Exception as e:
            logger.error(f"Failed to create QUIC configuration: {e}")
            return None


class SecureConnectionManager:
    """Manages secure connections with TLS 1.3 and QUIC"""
    
    def __init__(self, config: SecureConnectionConfig):
        self.config = config
        self.tls_context = SecureTLSContext(config)
        self.quic_wrapper = QUICConnectionWrapper(config)
        
    def wrap_socket_server(self, sock: socket.socket) -> ssl.SSLSocket:
        """Wrap server socket with TLS 1.3"""
        if not self.config.config['allow_unencrypted']:
            logger.info("Wrapping server socket with TLS 1.3")
            context = self.tls_context.create_server_context()
            return context.wrap_socket(sock, server_side=True)
        else:
            logger.warning("Unencrypted connections allowed - this is insecure!")
            return sock
    
    def wrap_socket_client(self, sock: socket.socket, server_hostname: str) -> ssl.SSLSocket:
        """Wrap client socket with TLS 1.3"""
        if not self.config.config['allow_unencrypted']:
            logger.info(f"Wrapping client socket with TLS 1.3 for {server_hostname}")
            context = self.tls_context.create_client_context()
            return context.wrap_socket(sock, server_hostname=server_hostname)
        else:
            logger.warning("Unencrypted connections allowed - this is insecure!")
            return sock
    
    def verify_connection_security(self, conn: ssl.SSLSocket) -> bool:
        """Verify that connection meets security requirements"""
        try:
            # Get connection info
            version = conn.version()
            cipher = conn.cipher()
            
            logger.info(f"Connection TLS version: {version}")
            logger.info(f"Connection cipher: {cipher}")
            
            # Verify TLS 1.3
            if version != 'TLSv1.3':
                logger.error(f"Connection does not use TLS 1.3: {version}")
                return False
            
            # For TLS 1.3, cipher verification is less critical since 
            # only secure ciphers are supported, but we still log the cipher used
            if cipher:
                logger.info(f"Using cipher: {cipher[0]}")
                return True
            else:
                logger.warning("Could not determine cipher suite")
                # Still return True since we verified TLS 1.3
                return True
                
        except Exception as e:
            logger.error(f"Error verifying connection security: {e}")
            return False


def example_server():
    """Example TLS 1.3 server"""
    config = SecureConnectionConfig()
    manager = SecureConnectionManager(config)
    
    # Create server socket
    # Note: Using '0.0.0.0' for demonstration purposes only
    # In production, bind to specific interface (e.g., '127.0.0.1' for localhost only)
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    # For production, use specific interface:
    # server_socket.bind(('127.0.0.1', 8443))  # localhost only
    # server_socket.bind(('192.168.1.100', 8443))  # specific IP
    server_socket.bind(('127.0.0.1', 8443))  # Bind to localhost for security
    server_socket.listen(5)
    
    logger.info("Server listening on 127.0.0.1:8443 with TLS 1.3")
    
    # Wrap with TLS
    secure_socket = manager.wrap_socket_server(server_socket)
    
    while True:
        try:
            client_socket, address = secure_socket.accept()
            logger.info(f"Connection from {address}")
            
            # Verify security
            if manager.verify_connection_security(client_socket):
                # Handle client
                data = client_socket.recv(1024)
                logger.info(f"Received: {data}")
                client_socket.sendall(b"Secure response via TLS 1.3")
            
            client_socket.close()
            
        except KeyboardInterrupt:
            break
        except Exception as e:
            logger.error(f"Error handling client: {e}")
    
    secure_socket.close()


def example_client():
    """Example TLS 1.3 client"""
    config = SecureConnectionConfig()
    manager = SecureConnectionManager(config)
    
    # Create client socket
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    
    # Connect and wrap with TLS
    client_socket.connect(('localhost', 8443))
    secure_socket = manager.wrap_socket_client(client_socket, 'localhost')
    
    # Verify security
    if manager.verify_connection_security(secure_socket):
        # Send data
        secure_socket.sendall(b"Secure request via TLS 1.3")
        response = secure_socket.recv(1024)
        logger.info(f"Received: {response}")
    
    secure_socket.close()


if __name__ == '__main__':
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == 'server':
        example_server()
    elif len(sys.argv) > 1 and sys.argv[1] == 'client':
        example_client()
    else:
        print("Usage:")
        print(f"  {sys.argv[0]} server    - Start TLS 1.3 server")
        print(f"  {sys.argv[0]} client    - Connect as TLS 1.3 client")
