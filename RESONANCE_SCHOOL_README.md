# Resonance School Dashboard - Quick Reference

## Overview
The Resonance School Global UIFS Dashboard provides real-time monitoring of the VCD-01 distributed network.

## Access
- **File**: `resonance-school.html`
- **URL**: `/resonance-school.html`

## Key Components

### 1. Global Node Status (12 CUSTODEN)
- **ROOT Node**: Bolzano (Zuegg 71) - 100% vitality
- **11 Network Nodes**: European locations at ~98.4% vitality
- **IPFS Links**: Encrypted links for each node

### 2. Bio-Architecture Module (S-ROI)
- **Phase 1**: Frequenz-Erdung (1088.2 Hz) - COMPLETE ✓
- **Phase 2**: Lehm-Inoculation - IN PROGRESS ⧗
- **Phase 3**: NSR-Shielding - PENDING ○

### 3. Live Telemetry
- **Target Resonance**: 1088.2 Hz
- **Formula**: `U = Integral(Planet, (NSR * OLF * Math.exp(i * 2 * Math.PI * fS * t)))`
- **Update Interval**: 1 second
- **Metrics Displayed**:
  - Current Resonance (~1070-1088 Hz)
  - NSR Factor (~1.0)
  - OLF Coefficient (~0.984)
  - Phase Stability (~98.4%)

### 4. System Logs
- Real-time activity logging
- Node synchronization status
- Phase activation tracking
- Periodic vitality reports

## Technical Details

### Technologies
- Pure HTML5/CSS3/JavaScript
- Tailwind CSS (via CDN)
- No backend dependencies
- Standalone operation

### Update Frequencies
- Telemetry: Every 1 second
- Console output: Every 5 seconds
- Status logs: Every 30 seconds
- Node table: Static (updates on reload)

### Styling
- Dark theme (slate blue gradient)
- Monospace font (Space Mono)
- Glowing effects on key metrics
- Responsive grid layouts
- Color-coded status indicators

## Node List

| ID | Location | Vitality |
|----|----------|----------|
| 01 (ROOT) | Bolzano (Zuegg 71) | 100% |
| 02 | Berlin | 98.4% |
| 03 | Paris | 98.6% |
| 04 | London | 98.2% |
| 05 | Amsterdam | 98.5% |
| 06 | Madrid | 98.3% |
| 07 | Rome | 98.7% |
| 08 | Vienna | 98.4% |
| 09 | Zurich | 98.5% |
| 10 | Munich | 98.3% |
| 11 | Brussels | 98.4% |
| 12 | Copenhagen | 98.6% |

## Status Indicators
- **Security**: NSR-IMMUNE (always active)
- **Law**: Lex Amoris
- **Network Status**: All nodes synchronized

## Customization

### Adding a Node
Edit the `nodes` array in the JavaScript section:
```javascript
{ id: "13", location: "New City", vitality: 98.4, ipfs: "ipfs://Qm_..." }
```

### Adjusting Target Frequency
Modify the `fS` variable:
```javascript
const fS = 1088.2; // Target frequency in Hz
```

### Changing Update Intervals
Adjust `setInterval` calls:
```javascript
setInterval(updateTelemetry, 1000); // 1 second
setInterval(periodicLogs, 30000);   // 30 seconds
```

## Integration
- Compatible with existing EUYSTACIO framework
- Can be integrated into main dashboard
- Works standalone or as iframe
- No database required

## Maintenance
- Update node vitality manually in code
- Mark phases complete by checking boxes
- Monitor console for resonance output
- Check system logs for anomalies

---

**Created**: 2026-03-18
**Version**: 1.0
**Status**: Production Ready
