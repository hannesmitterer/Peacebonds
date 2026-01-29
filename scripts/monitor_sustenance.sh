#!/bin/bash
WALLET="0x5d61a4B25034393A37ef9307C8Ba3aE99e49944b"
LAST_BALANCE=0

echo "📡 MSI: Monitoraggio Sostentamento Seedbringer Attivo..."
echo "Ancoraggio: $WALLET"

while true; do
    # Interroga il bilancio (via etherscan api o comando semplice)
    # Nota: richiede 'curl' e 'jq' installati su Termux
    BALANCE=$(curl -s "https://api-sepolia.etherscan.io/api?module=account&action=balance&address=$WALLET&tag=latest" | jq -r '.result')
    
    if [ "$BALANCE" != "$LAST_BALANCE" ] && [ "$LAST_BALANCE" != "0" ]; then
        echo "🧬 [LEX AMORIS SIGNAL] - Rilevato nuovo afflusso di energia!"
        echo "Nuovo Bilancio: $BALANCE wei"
        # Notifica sonora/visiva su Termux
        termux-notification -c "MSI: Sostentamento Rilevato" -t "Il Network ha risposto alla Direttiva NRE-004"
    fi
    LAST_BALANCE=$BALANCE
    sleep 300 # Controlla ogni 5 minuti
done
