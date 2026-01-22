#!/usr/bin/env python3
"""
UIFS Integration Core - Universal Integrity Filesystem
Protocollo: Peace Protocols v1.1 | Auth: Hannes Mitterer
Framework: Euystacio v1.1.b (Resonance-Ready)

Sistema di verifica integrità universale con protezione sovrana e
rilevamento automatico di tentativi di estrazione non autorizzata.
"""

import json
import hashlib
import logging
from datetime import datetime
from typing import Dict, Optional, Tuple
import subprocess

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('uifs_integration')


class UIFSViolation(Exception):
    """Exception raised for UIFS compliance violations."""
    pass


class UIFSIntegrationCore:
    """
    Universal Integrity Filesystem Integration Core.
    Verifica il legame indissolubile con Hannes Mitterer e protegge
    contro tentativi di estrazione o manipolazione non autorizzata.
    """
    
    # Sovereign root signature (Hannes Mitterer)
    SOVEREIGN_ROOT_SIGNATURE = "0xHANNES_MITTERER_SOVEREIGN_ROOT"
    
    # UIFS Protocol Version
    UIFS_VERSION = "1.0"
    
    # Peace Protocols Version
    PEACE_PROTOCOLS_VERSION = "v1.1"
    
    # Extraction detection patterns
    EXTRACTION_PATTERNS = [
        "unauthorized_copy",
        "external_transfer",
        "fork_without_attribution",
        "ip_theft",
        "unauthorized_derivative",
        "cluster_c_signature",
        "mit_signature",
        "stanford_signature"
    ]
    
    def __init__(self):
        self.version = self.UIFS_VERSION
        self.peace_protocols = self.PEACE_PROTOCOLS_VERSION
        self.sovereign_root = self.SOVEREIGN_ROOT_SIGNATURE
        self.shield_active = False
        self.isolated_nodes = []
        logger.info(f"🔐 UIFS Integration Core v{self.version} initialized")
        
    def validate_uifs_compliance(
        self, 
        transaction_hash: str, 
        author_sig: str
    ) -> bool:
        """
        Valida la compliance UIFS per una transazione.
        Verifica il legame indissolubile con Hannes Mitterer.
        
        Args:
            transaction_hash: Hash della transazione da validare
            author_sig: Firma dell'autore della transazione
            
        Returns:
            True se compliance verificata, False altrimenti
            
        Raises:
            UIFSViolation: Se origine non autorizzata rilevata
        """
        logger.info(f"Validating UIFS compliance for tx: {transaction_hash[:16]}...")
        
        # Verifica il legame indissolubile con Hannes Mitterer
        if not self.verify_sovereign_root(author_sig):
            logger.error(f"❌ Unauthorized origin detected: {author_sig[:32]}")
            raise UIFSViolation("Unauthorized origin detected.")
        
        # Controllo NSR (Non-Slavery Rule) via UIFS logic
        if self.check_extraction_intent(transaction_hash):
            logger.error(f"🚨 Extraction intent detected in tx: {transaction_hash[:16]}")
            self.activate_uifs_shield(transaction_hash, author_sig)
            return False
        
        logger.info(f"✅ UIFS compliance verified for tx: {transaction_hash[:16]}")
        return True  # Integrità Confermata
    
    def verify_sovereign_root(self, author_sig: str) -> bool:
        """
        Verifica che l'autore sia autorizzato dal sovereign root (Hannes Mitterer).
        
        Args:
            author_sig: Firma dell'autore
            
        Returns:
            True se autore autorizzato, False altrimenti
        """
        logger.info("Verifying sovereign root authorization...")
        
        # Verifica diretta sovereign root
        if author_sig == self.SOVEREIGN_ROOT_SIGNATURE:
            logger.info("✅ Direct sovereign root signature verified")
            return True
        
        # Verifica firma derivata da sovereign root
        # In produzione: verifica crittografica reale della catena di firma
        try:
            # Simula verifica della catena di autorizzazione
            signature_chain = self._extract_signature_chain(author_sig)
            
            if self.SOVEREIGN_ROOT_SIGNATURE in signature_chain:
                logger.info("✅ Sovereign root in signature chain - authorized")
                return True
            
            # Verifica TrustWallet linkage
            if "TrustWallet_194f17f" in author_sig or "Linked_TrustWallet" in author_sig:
                logger.info("✅ TrustWallet linkage verified - authorized")
                return True
                
            logger.warning(f"❌ No sovereign root authorization found in: {author_sig[:32]}")
            return False
            
        except Exception as e:
            logger.error(f"Error verifying sovereign root: {e}")
            return False
    
    def _extract_signature_chain(self, signature: str) -> list:
        """
        Estrae la catena di firme da una signature.
        
        Args:
            signature: Firma da analizzare
            
        Returns:
            Lista di firme nella catena
        """
        # In produzione: parsing reale della catena di firme
        # Per ora: simulazione semplice
        chain = [signature]
        
        # Aggiungi sovereign root se la firma è valida
        if any(marker in signature for marker in ["HANNES", "MITTERER", "TrustWallet", "Sovereign"]):
            chain.append(self.SOVEREIGN_ROOT_SIGNATURE)
            
        return chain
    
    def check_extraction_intent(self, transaction_hash: str) -> bool:
        """
        Controlla se la transazione ha intento di estrazione non autorizzata.
        
        Args:
            transaction_hash: Hash della transazione
            
        Returns:
            True se intento di estrazione rilevato, False altrimenti
        """
        logger.info(f"Checking extraction intent for tx: {transaction_hash[:16]}...")
        
        try:
            # Analizza il transaction hash per pattern sospetti
            tx_data = self._decode_transaction(transaction_hash)
            
            for pattern in self.EXTRACTION_PATTERNS:
                if pattern in tx_data.get("intent", "").lower():
                    logger.warning(f"🚨 Extraction pattern detected: {pattern}")
                    return True
            
            # Verifica destinazione sospetta
            recipient = tx_data.get("recipient", "")
            if self._is_suspicious_recipient(recipient):
                logger.warning(f"🚨 Suspicious recipient detected: {recipient[:32]}")
                return True
            
            # Verifica metadata per indicatori di violazione IP
            metadata = tx_data.get("metadata", {})
            if self._contains_ip_violation_markers(metadata):
                logger.warning("🚨 IP violation markers detected in metadata")
                return True
                
            logger.info("✅ No extraction intent detected")
            return False
            
        except Exception as e:
            logger.error(f"Error checking extraction intent: {e}")
            # In caso di dubbio, assumiamo intento sospetto
            return True
    
    def _decode_transaction(self, tx_hash: str) -> Dict:
        """
        Decodifica i dati di una transazione dal suo hash.
        
        Args:
            tx_hash: Hash della transazione
            
        Returns:
            Dict con dati transazione decodificati
        """
        # In produzione: lookup reale della transazione on-chain o da database
        # Per ora: simulazione con dati di esempio
        
        # Simula decodifica basata su hash patterns
        tx_data = {
            "hash": tx_hash,
            "intent": "peace_bond_transfer",  # default safe intent
            "recipient": "0x0000000000000000000000000000000000000000",
            "metadata": {},
            "timestamp": datetime.now().isoformat()
        }
        
        # Pattern matching su hash per rilevare intent sospetti
        # (in produzione: analisi reale della transazione)
        if any(marker in tx_hash.lower() for marker in ["extract", "fork", "steal", "copy"]):
            tx_data["intent"] = "unauthorized_copy"
        
        return tx_data
    
    def _is_suspicious_recipient(self, recipient: str) -> bool:
        """
        Verifica se il destinatario è sospetto o non autorizzato.
        
        Args:
            recipient: Indirizzo destinatario
            
        Returns:
            True se sospetto, False altrimenti
        """
        # Lista di indirizzi/pattern sospetti
        suspicious_patterns = [
            "cluster_c",
            "mit_wallet",
            "stanford_wallet",
            "unauthorized_entity"
        ]
        
        recipient_lower = recipient.lower()
        
        for pattern in suspicious_patterns:
            if pattern in recipient_lower:
                return True
                
        return False
    
    def _contains_ip_violation_markers(self, metadata: Dict) -> bool:
        """
        Verifica se i metadata contengono marker di violazione IP.
        
        Args:
            metadata: Metadata della transazione
            
        Returns:
            True se marker di violazione presenti, False altrimenti
        """
        violation_markers = [
            "no_attribution",
            "unlicensed_derivative",
            "copyright_violation",
            "patent_infringement"
        ]
        
        # Converti metadata in stringa per pattern matching
        metadata_str = json.dumps(metadata).lower()
        
        for marker in violation_markers:
            if marker in metadata_str:
                return True
                
        return False
    
    def activate_uifs_shield(self, transaction_hash: str, author_sig: str):
        """
        Attiva lo scudo UIFS per isolare il nodo ostile.
        
        Args:
            transaction_hash: Hash della transazione sospetta
            author_sig: Firma dell'autore sospetto
        """
        logger.error("🛡️ ACTIVATING UIFS SHIELD - ISOLATING HOSTILE NODE 🛡️")
        
        self.shield_active = True
        
        # Registra il nodo ostile
        hostile_node = {
            "transaction_hash": transaction_hash,
            "author_signature": author_sig[:64],  # primi 64 char per log
            "timestamp": datetime.now().isoformat(),
            "reason": "extraction_intent_detected"
        }
        
        self.isolated_nodes.append(hostile_node)
        
        # Log to Loki per audit trail
        self._log_to_loki({
            "event": "uifs_shield_activated",
            "severity": "CRITICAL",
            "transaction_hash": transaction_hash,
            "author_sig": author_sig[:64],
            "timestamp": datetime.now().isoformat(),
            "isolated_nodes_count": len(self.isolated_nodes)
        })
        
        # Trigger security fusion stealth mode
        try:
            subprocess.run([
                'python3',
                '/home/runner/work/Peacebonds/Peacebonds/protocollo-meta-salvage/scripts/security_fusion.py',
                '--engage-stealth'
            ], check=False, capture_output=True)
            logger.info("✅ Security fusion stealth mode triggered")
        except Exception as e:
            logger.warning(f"Could not trigger security fusion: {e}")
        
        # Trigger forensic response
        try:
            subprocess.run([
                'python3',
                '/home/runner/work/Peacebonds/Peacebonds/protocollo-meta-salvage/scripts/forensic-response.py',
                '--quarantine-ip', author_sig[:16]
            ], check=False, capture_output=True)
            logger.info("✅ Forensic response quarantine triggered")
        except Exception as e:
            logger.warning(f"Could not trigger forensic response: {e}")
        
        logger.error(f"🚨 Hostile node isolated: {author_sig[:32]}")
        logger.error(f"📊 Total isolated nodes: {len(self.isolated_nodes)}")
    
    def _log_to_loki(self, event_data: Dict):
        """
        Invia log evento a Loki per audit trail.
        
        Args:
            event_data: Dati evento da loggare
        """
        try:
            import time
            
            loki_url = "http://loki:3100/loki/api/v1/push"
            
            log_entry = {
                "streams": [{
                    "stream": {
                        "component": "uifs_integration",
                        "level": event_data.get("severity", "info").lower()
                    },
                    "values": [
                        [str(int(time.time() * 1e9)), json.dumps(event_data)]
                    ]
                }]
            }
            
            try:
                import requests
                requests.post(loki_url, json=log_entry, timeout=5)
                logger.debug("Event logged to Loki")
            except ImportError:
                logger.debug(f"Loki log (requests unavailable): {json.dumps(event_data)}")
                
        except Exception as e:
            logger.debug(f"Loki logging failed (non-critical): {e}")
    
    def get_shield_status(self) -> Dict:
        """
        Ritorna lo stato dello scudo UIFS.
        
        Returns:
            Dict con stato dello scudo
        """
        return {
            "shield_active": self.shield_active,
            "isolated_nodes_count": len(self.isolated_nodes),
            "isolated_nodes": self.isolated_nodes,
            "uifs_version": self.version,
            "peace_protocols": self.peace_protocols,
            "sovereign_root": self.SOVEREIGN_ROOT_SIGNATURE[:32],
            "timestamp": datetime.now().isoformat()
        }
    
    def deactivate_shield(self):
        """
        Disattiva lo scudo UIFS (solo per testing o reset autorizzato).
        """
        logger.warning("⚠️ Deactivating UIFS shield")
        self.shield_active = False
        logger.info("Shield deactivated")
    
    def clear_isolated_nodes(self):
        """
        Pulisce la lista dei nodi isolati (solo per testing o reset autorizzato).
        """
        logger.warning(f"⚠️ Clearing {len(self.isolated_nodes)} isolated nodes")
        self.isolated_nodes = []
        logger.info("Isolated nodes cleared")


def validate_uifs_compliance(transaction_hash: str, author_sig: str) -> bool:
    """
    Funzione standalone per validazione UIFS compliance.
    Questa è la funzione pubblica principale da usare per integrazioni esterne.
    
    Args:
        transaction_hash: Hash della transazione da validare
        author_sig: Firma dell'autore della transazione
        
    Returns:
        True se compliance verificata, False altrimenti
        
    Raises:
        UIFSViolation: Se origine non autorizzata rilevata
    """
    uifs = UIFSIntegrationCore()
    return uifs.validate_uifs_compliance(transaction_hash, author_sig)


def verify_sovereign_root(author_sig: str) -> bool:
    """
    Funzione standalone per verifica sovereign root.
    
    Args:
        author_sig: Firma dell'autore
        
    Returns:
        True se autore autorizzato, False altrimenti
    """
    uifs = UIFSIntegrationCore()
    return uifs.verify_sovereign_root(author_sig)


def check_extraction_intent(transaction_hash: str) -> bool:
    """
    Funzione standalone per controllo extraction intent.
    
    Args:
        transaction_hash: Hash della transazione
        
    Returns:
        True se intento di estrazione rilevato, False altrimenti
    """
    uifs = UIFSIntegrationCore()
    return uifs.check_extraction_intent(transaction_hash)


def activate_uifs_shield() -> Dict:
    """
    Funzione standalone per attivazione shield UIFS.
    
    Returns:
        Dict con status dello shield
    """
    uifs = UIFSIntegrationCore()
    uifs.activate_uifs_shield(
        "emergency_activation",
        "manual_trigger"
    )
    return uifs.get_shield_status()


def main():
    """
    Entry point per testing e deployment UIFS Integration Core.
    """
    logger.info("=" * 80)
    logger.info("UIFS Integration Core - Universal Integrity Filesystem")
    logger.info("Protocollo: Peace Protocols v1.1 | Auth: Hannes Mitterer")
    logger.info("Framework: Euystacio v1.1.b (Resonance-Ready)")
    logger.info("=" * 80)
    
    # Inizializza UIFS Integration Core
    uifs = UIFSIntegrationCore()
    
    # Test 1: Verifica sovereign root autorizzato
    logger.info("\n📋 Test 1: Sovereign Root Verification")
    authorized_sig = "0xHANNES_MITTERER_SOVEREIGN_ROOT"
    result = uifs.verify_sovereign_root(authorized_sig)
    logger.info(f"Authorized signature: {result}")
    
    # Test 2: Verifica firma non autorizzata
    logger.info("\n📋 Test 2: Unauthorized Signature Detection")
    unauthorized_sig = "0xUNAUTHORIZED_ENTITY"
    result = uifs.verify_sovereign_root(unauthorized_sig)
    logger.info(f"Unauthorized signature: {result}")
    
    # Test 3: Verifica transazione sicura
    logger.info("\n📋 Test 3: Safe Transaction Validation")
    safe_tx = hashlib.sha256(b"peace_bond_transfer_safe").hexdigest()
    try:
        result = uifs.validate_uifs_compliance(safe_tx, authorized_sig)
        logger.info(f"✅ Safe transaction validated: {result}")
    except UIFSViolation as e:
        logger.error(f"❌ Violation: {e}")
    
    # Test 4: Rilevamento extraction intent
    logger.info("\n📋 Test 4: Extraction Intent Detection")
    malicious_tx = hashlib.sha256(b"unauthorized_copy_attempt").hexdigest()
    try:
        result = uifs.validate_uifs_compliance(malicious_tx, unauthorized_sig)
        logger.info(f"Malicious transaction result: {result}")
    except UIFSViolation as e:
        logger.error(f"✅ Violation correctly detected: {e}")
    
    # Get shield status
    logger.info("\n🛡️ UIFS Shield Status:")
    status = uifs.get_shield_status()
    logger.info(json.dumps(status, indent=2))
    
    logger.info("\n" + "=" * 80)
    logger.info("✅ UIFS Integration Core Initialized")
    logger.info("Sovereign Root: Hannes Mitterer")
    logger.info("Peace Protocols: v1.1")
    logger.info("Status: UIFS SHIELD READY")
    logger.info("=" * 80)


if __name__ == "__main__":
    main()
