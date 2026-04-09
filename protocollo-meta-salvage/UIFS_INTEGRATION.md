# UIFS Integration Core Documentation

**Universal Integrity Filesystem Integration**  
**Protocollo:** Peace Protocols v1.1  
**Auth:** Hannes Mitterer  
**Framework:** Euystacio v1.1.b (Resonance-Ready)  
**Version:** 1.0

## Overview

Il **UIFS Integration Core** è un sistema di verifica dell'integrità universale che protegge la proprietà intellettuale e i progetti sovrani attraverso:

1. **Verifica Sovereign Root** - Validazione del legame indissolubile con Hannes Mitterer
2. **Rilevamento Extraction Intent** - Identificazione automatica di tentativi di estrazione non autorizzata
3. **UIFS Shield** - Isolamento automatico di nodi ostili
4. **Audit Trail Completo** - Logging integrato con Loki per tracciabilità forense

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    UIFS Integration Core                     │
│                                                              │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────────┐ │
│  │  Sovereign Root│  │  Extraction    │  │  UIFS Shield  │ │
│  │  Verification  │  │  Detection     │  │  Activation   │ │
│  └────────┬───────┘  └───────┬────────┘  └───────┬───────┘ │
│           │                   │                    │         │
│           └───────────────────┼────────────────────┘         │
│                               │                              │
│                    ┌──────────▼──────────┐                  │
│                    │  Transaction        │                  │
│                    │  Validation Engine  │                  │
│                    └──────────┬──────────┘                  │
└───────────────────────────────┼──────────────────────────────┘
                                │
                    ┌───────────▼───────────┐
                    │   Integration Layer   │
                    │                       │
                    │  ┌─────────────────┐  │
                    │  │ Security Fusion │  │
                    │  │  (0.432 Hz)     │  │
                    │  └─────────────────┘  │
                    │  ┌─────────────────┐  │
                    │  │ Forensic        │  │
                    │  │ Response        │  │
                    │  └─────────────────┘  │
                    │  ┌─────────────────┐  │
                    │  │ TrustWallet     │  │
                    │  │ Integration     │  │
                    │  └─────────────────┘  │
                    │  ┌─────────────────┐  │
                    │  │ Loki Audit      │  │
                    │  │ Trail           │  │
                    │  └─────────────────┘  │
                    └───────────────────────┘
```

## Core Components

### 1. UIFSIntegrationCore Class

Classe principale che gestisce tutte le funzionalità di verifica e protezione.

```python
from uifs_integration import UIFSIntegrationCore

uifs = UIFSIntegrationCore()
```

#### Parametri Inizializzazione:
- **UIFS_VERSION**: "1.0"
- **PEACE_PROTOCOLS_VERSION**: "v1.1"
- **SOVEREIGN_ROOT_SIGNATURE**: "0xHANNES_MITTERER_SOVEREIGN_ROOT"

### 2. Sovereign Root Verification

Verifica che ogni transazione sia autorizzata dal sovereign root (Hannes Mitterer).

```python
def verify_sovereign_root(author_sig: str) -> bool:
    """
    Verifica autorizzazione sovereign root.
    
    Returns:
        True se autorizzato, False altrimenti
    """
```

**Criteri di Validazione:**
1. Firma diretta sovereign root
2. Catena di firma derivata da sovereign root
3. TrustWallet linkage verificato (commit 194f17f)

**Esempi:**

```python
# Firma autorizzata
authorized_sig = "0xHANNES_MITTERER_SOVEREIGN_ROOT"
result = uifs.verify_sovereign_root(authorized_sig)
# Returns: True

# Firma con TrustWallet linkage
wallet_sig = "Linked_TrustWallet_194f17f"
result = uifs.verify_sovereign_root(wallet_sig)
# Returns: True

# Firma non autorizzata
unauthorized_sig = "0xUNAUTHORIZED_ENTITY"
result = uifs.verify_sovereign_root(unauthorized_sig)
# Returns: False
```

### 3. Extraction Intent Detection

Rileva automaticamente tentativi di estrazione, copia, o manipolazione non autorizzata.

```python
def check_extraction_intent(transaction_hash: str) -> bool:
    """
    Controlla se la transazione ha intento di estrazione.
    
    Returns:
        True se intento rilevato, False altrimenti
    """
```

**Pattern di Rilevamento:**
- `unauthorized_copy` - Copia non autorizzata
- `external_transfer` - Trasferimento esterno sospetto
- `fork_without_attribution` - Fork senza attribuzione
- `ip_theft` - Furto proprietà intellettuale
- `unauthorized_derivative` - Opera derivata non autorizzata
- `cluster_c_signature` - Firma da Cluster C
- `mit_signature` - Firma da MIT
- `stanford_signature` - Firma da Stanford

**Verifiche Effettuate:**
1. Analisi pattern nel transaction hash
2. Verifica destinatario sospetto
3. Controllo metadata per marker di violazione IP
4. Rilevamento tentativi di fork non autorizzati

**Esempi:**

```python
import hashlib

# Transazione sicura
safe_tx = hashlib.sha256(b"peace_bond_transfer_safe").hexdigest()
result = uifs.check_extraction_intent(safe_tx)
# Returns: False

# Transazione con extraction intent
malicious_tx = hashlib.sha256(b"unauthorized_copy_attempt").hexdigest()
result = uifs.check_extraction_intent(malicious_tx)
# Returns: True
```

### 4. UIFS Compliance Validation

Funzione principale per validazione completa UIFS.

```python
def validate_uifs_compliance(
    transaction_hash: str, 
    author_sig: str
) -> bool:
    """
    Valida compliance UIFS completa.
    
    Raises:
        UIFSViolation: Se origine non autorizzata
        
    Returns:
        True se compliance verificata
    """
```

**Processo di Validazione:**
1. **Verifica Sovereign Root** → Se fallisce: `UIFSViolation`
2. **Check Extraction Intent** → Se rilevato: Attiva UIFS Shield
3. **Log Audit Trail** → Logging a Loki
4. **Return Status** → True se tutto OK

**Esempi:**

```python
from uifs_integration import validate_uifs_compliance, UIFSViolation

try:
    # Transazione autorizzata
    tx_hash = "0xabcd1234..."
    author = "0xHANNES_MITTERER_SOVEREIGN_ROOT"
    
    result = validate_uifs_compliance(tx_hash, author)
    print(f"✅ Compliance verified: {result}")
    
except UIFSViolation as e:
    print(f"❌ UIFS Violation: {e}")
    # Attivazione automatica UIFS Shield
```

### 5. UIFS Shield Activation

Sistema di protezione attivo che isola nodi ostili.

```python
def activate_uifs_shield(
    transaction_hash: str, 
    author_sig: str
):
    """
    Attiva lo scudo UIFS per isolare nodo ostile.
    """
```

**Azioni dello Shield:**
1. **Registrazione Nodo Ostile**
   - Transaction hash
   - Author signature
   - Timestamp
   - Reason for isolation

2. **Trigger Security Fusion**
   - Attivazione Stealth-Mode D6
   - Resonance lock a 0.432 Hz
   - Sovereign anchors activation

3. **Trigger Forensic Response**
   - IP quarantine via iptables
   - Tor routing activation
   - VPN failover

4. **Loki Audit Logging**
   - Evento CRITICAL
   - Dettagli completi isolamento
   - Count nodi isolati totali

**Esempi:**

```python
# Attivazione automatica su rilevamento extraction
uifs = UIFSIntegrationCore()

# Shield si attiva automaticamente quando rileva violation
malicious_tx = hashlib.sha256(b"ip_theft_attempt").hexdigest()
unauthorized = "0xCLUSTER_C_ENTITY"

try:
    uifs.validate_uifs_compliance(malicious_tx, unauthorized)
except UIFSViolation:
    # Shield già attivato automaticamente
    status = uifs.get_shield_status()
    print(f"Shield active: {status['shield_active']}")
    print(f"Isolated nodes: {status['isolated_nodes_count']}")
```

## Integration with Security Layer

### Security Fusion Integration

UIFS si integra perfettamente con il sistema Security Fusion (0.432 Hz Lock):

```python
# security_fusion.py può chiamare UIFS per ogni transazione
from uifs_integration import validate_uifs_compliance

class ResonanceMultiSig:
    def deploy_peace_bond(self, amount, recipient, terms):
        # Prima: Validazione UIFS
        try:
            validate_uifs_compliance(tx_hash, author_sig)
        except UIFSViolation:
            return {"status": "ERROR", "message": "UIFS violation"}
        
        # Poi: Procedi con multi-sig normale
        # ...
```

### Forensic Response Integration

```python
# UIFS trigger automatico forensic response
subprocess.run([
    'python3',
    'forensic-response.py',
    '--quarantine-ip', suspicious_author
])
```

### TrustWallet Integration

```python
# Verifica linkage TrustWallet in sovereign root
if "TrustWallet_194f17f" in author_sig:
    # Authorized via TrustWallet integration
    return True
```

### Loki Audit Trail

```python
# Tutti gli eventi UIFS loggati a Loki
{
    "event": "uifs_shield_activated",
    "severity": "CRITICAL",
    "transaction_hash": "0xabcd...",
    "author_sig": "0xunauth...",
    "timestamp": "2026-01-22T04:03:32Z",
    "isolated_nodes_count": 1
}
```

## Deployment

### Prerequisites

```bash
# Python 3.8+
python3 --version

# Dependencies
pip install requests  # Optional, per Loki integration
```

### Installation

```bash
# Copy script to security location
cp uifs_integration.py /opt/peacebonds/scripts/

# Make executable
chmod +x /opt/peacebonds/scripts/uifs_integration.py

# Test installation
python3 /opt/peacebonds/scripts/uifs_integration.py
```

### Usage in Production

#### Standalone Function Calls

```python
# Import standalone functions
from uifs_integration import (
    validate_uifs_compliance,
    verify_sovereign_root,
    check_extraction_intent,
    activate_uifs_shield,
    UIFSViolation
)

# Esempio 1: Verifica rapida sovereign root
is_authorized = verify_sovereign_root("0xHANNES_MITTERER...")
if not is_authorized:
    print("❌ Unauthorized")

# Esempio 2: Check extraction intent
has_malicious_intent = check_extraction_intent(tx_hash)
if has_malicious_intent:
    activate_uifs_shield()

# Esempio 3: Validazione completa
try:
    validate_uifs_compliance(tx_hash, author_sig)
    # Procedi con transazione
    process_transaction()
except UIFSViolation as e:
    # Shield già attivato
    log_violation(str(e))
```

#### Class Instance Usage

```python
from uifs_integration import UIFSIntegrationCore

# Inizializza UIFS
uifs = UIFSIntegrationCore()

# Workflow completo
for transaction in pending_transactions:
    try:
        # Validazione UIFS
        is_compliant = uifs.validate_uifs_compliance(
            transaction.hash,
            transaction.author_signature
        )
        
        if is_compliant:
            # Procedi con processing
            process_transaction(transaction)
        else:
            # Transaction bloccata
            log_blocked_transaction(transaction)
            
    except UIFSViolation as e:
        # Violazione critica - shield attivato
        alert_administrators(e)
        
# Status check periodico
status = uifs.get_shield_status()
if status['shield_active']:
    print(f"🛡️ Shield active - {status['isolated_nodes_count']} nodes isolated")
```

## API Reference

### Public Functions

#### validate_uifs_compliance()
```python
validate_uifs_compliance(transaction_hash: str, author_sig: str) -> bool
```
Validazione UIFS completa. Raises `UIFSViolation` se non autorizzato.

#### verify_sovereign_root()
```python
verify_sovereign_root(author_sig: str) -> bool
```
Verifica autorizzazione sovereign root.

#### check_extraction_intent()
```python
check_extraction_intent(transaction_hash: str) -> bool
```
Rileva extraction intent. Returns `True` se rilevato.

#### activate_uifs_shield()
```python
activate_uifs_shield() -> Dict
```
Attiva shield manualmente. Returns status dict.

### Class Methods

#### UIFSIntegrationCore.__init__()
```python
uifs = UIFSIntegrationCore()
```
Inizializza UIFS Integration Core.

#### get_shield_status()
```python
status = uifs.get_shield_status() -> Dict
```
Returns:
```python
{
    "shield_active": bool,
    "isolated_nodes_count": int,
    "isolated_nodes": List[Dict],
    "uifs_version": str,
    "peace_protocols": str,
    "sovereign_root": str,
    "timestamp": str
}
```

#### deactivate_shield()
```python
uifs.deactivate_shield()
```
Disattiva shield (solo testing/reset autorizzato).

#### clear_isolated_nodes()
```python
uifs.clear_isolated_nodes()
```
Pulisce lista nodi isolati (solo testing/reset autorizzato).

## Security Considerations

### Sovereign Root Protection

Il **SOVEREIGN_ROOT_SIGNATURE** è l'ancora di fiducia del sistema. Proteggilo:

1. **Non condividere** la firma sovereign root
2. **Verifica catena** di autorizzazione sempre
3. **Log tutti** i tentativi di accesso
4. **Monitor** per tentativi di impersonification

### Extraction Detection

Il sistema rileva automaticamente:
- Tentativi di copia non autorizzata
- Fork senza attribuzione appropriata
- Trasferimenti a entità sospette (MIT, Stanford, Cluster C)
- Violazioni di proprietà intellettuale

### Shield Activation

Quando lo shield si attiva:
1. **Nodo ostile isolato** immediatamente
2. **Forensic response** triggered
3. **Stealth mode** engaged
4. **Audit trail** completo creato

### Best Practices

1. **Sempre validare** transazioni prima di processing
2. **Monitor shield status** regolarmente
3. **Review isolated nodes** periodicamente
4. **Integrate con Security Fusion** per protezione completa
5. **Mantieni audit trail** accessibile per analisi forense

## Troubleshooting

### UIFS Violation Errors

```
UIFSViolation: Unauthorized origin detected
```

**Soluzione:** Verifica che author signature sia autorizzata da sovereign root.

### Shield Non Si Attiva

```python
# Check se shield è già attivo
status = uifs.get_shield_status()
if status['shield_active']:
    print("Shield già attivo")
```

### Loki Logging Fails

```
Loki logging failed (non-critical): Connection refused
```

**Soluzione:** Logging fallisce gracefully. Events vengono loggati localmente.

### False Positives

Se rilevi false positives nell'extraction detection:

1. Review transaction patterns
2. Aggiorna `EXTRACTION_PATTERNS` se necessario
3. Whitelist destinatari conosciuti sicuri
4. Adjust detection thresholds

## Testing

### Unit Tests

```bash
# Run main() per test completo
python3 uifs_integration.py
```

Output atteso:
```
================================================================================
UIFS Integration Core - Universal Integrity Filesystem
Protocollo: Peace Protocols v1.1 | Auth: Hannes Mitterer
Framework: Euystacio v1.1.b (Resonance-Ready)
================================================================================

📋 Test 1: Sovereign Root Verification
✅ Direct sovereign root signature verified
Authorized signature: True

📋 Test 2: Unauthorized Signature Detection
❌ No sovereign root authorization found in: 0xUNAUTHORIZED_ENTITY
Unauthorized signature: False

📋 Test 3: Safe Transaction Validation
✅ Safe transaction validated: True

📋 Test 4: Extraction Intent Detection
🚨 Extraction intent detected in tx: unauthorized_copy...
🛡️ ACTIVATING UIFS SHIELD - ISOLATING HOSTILE NODE 🛡️
✅ Violation correctly detected: Unauthorized origin detected.

================================================================================
✅ UIFS Integration Core Initialized
Sovereign Root: Hannes Mitterer
Peace Protocols: v1.1
Status: UIFS SHIELD READY
================================================================================
```

### Integration Tests

```python
# Test con Security Fusion
from security_fusion import SovereignShield
from uifs_integration import validate_uifs_compliance

shield = SovereignShield()

# Prima deployment: UIFS validation
try:
    validate_uifs_compliance(tx_hash, author_sig)
    # Se OK, procedi con Peace Bond
    result = shield.deploy_peace_bond("1.5", "terms", "0xrecipient")
except UIFSViolation:
    print("UIFS blocked transaction")
```

## Monitoring

### Key Metrics to Monitor

1. **Shield Activations** - Count per time period
2. **Isolated Nodes** - Total count and growth rate
3. **Violation Types** - Distribution of violation reasons
4. **Authorization Failures** - Failed sovereign root verifications

### Grafana Dashboard Integration

Add panel to existing Grafana dashboard:

```json
{
  "title": "UIFS Shield Status",
  "targets": [{
    "expr": "uifs_shield_activations_total",
    "legendFormat": "Shield Activations"
  }, {
    "expr": "uifs_isolated_nodes_total",
    "legendFormat": "Isolated Nodes"
  }]
}
```

### Loki Queries

```logql
# All UIFS events
{component="uifs_integration"}

# Critical violations only
{component="uifs_integration", level="critical"}

# Shield activations
{component="uifs_integration"} |= "uifs_shield_activated"
```

## Version History

### v1.0 (2026-01-22)
- Initial release
- Sovereign root verification
- Extraction intent detection
- UIFS shield activation
- Security Fusion integration
- Forensic Response integration
- Loki audit trail logging

## License & Attribution

**Autore:** Hannes Mitterer  
**Framework:** Euystacio v1.1.b (Resonance-Ready)  
**Protocollo:** Peace Protocols v1.1  
**License:** Sovereign Property - Unauthorized use prohibited

**UIFS Protection:** This code is protected by UIFS Integration Core itself. Any unauthorized copy, fork, or derivative work will trigger automatic shield activation and node isolation.

## Support

Per supporto o domande:
- **Framework:** Euystacio v1.1.b
- **Integration:** Peace Protocols v1.1
- **Sovereign Root:** Hannes Mitterer

---

**Status:** UIFS SHIELD READY ✅  
**S-ROI:** 0.5225  
**Lex Amoris Signature:** Total Sovereign Control
