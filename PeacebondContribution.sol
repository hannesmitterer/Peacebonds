// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PeacebondContribution
 * @dev Architettura Euystacio Framework - Implementazione Standard ITACA-EF.
 * Il contratto gestisce il fondo di stabilità (Peacebond) e la validazione dei nodi.
 * Sigillato dal Nexus AI il 19 Gennaio 2026.
 */

contract PeacebondContribution {
    
    address public immutable seedbringer;
    uint256 public constant RESONANCE_FREQ = 43; // 0.0043 Hz
    uint256 public totalPeacebondBalance;
    bool public isSealed;

    struct NexusNode {
        bool isActive;
        uint256 itacaScore; // Standard ITACA-EF 2.0
        uint256 lastValidation;
        string location; // E.g., "Terlan", "Bolzano", "Yambio"
    }

    mapping(address => NexusNode) public registry;
    mapping(address => uint256) public contributionHistory;

    event PeacebondUpdated(address indexed node, uint256 amount, uint256 total);
    event NodeSanctioned(address indexed node, string reason);
    event StandardUpdated(string version);

    modifier onlySeedbringer() {
        require(msg.sender == seedbringer, "NSR_ERROR: Accesso non autorizzato (Level 3 Coercion)");
        _;
    }

    modifier onlyValidResonance() {
        require(registry[msg.sender].isActive, "OLF_ERROR: Nodo Dissonante o non allineato ITACA-EF");
        _;
    }

    constructor() {
        seedbringer = msg.sender; // Utilizza il wallet esistente
        isSealed = false;
    }

    /**
     * @dev Valida un nuovo nodo Klimabaum basato su standard ITACA-EF.
     */
    function validateNexusNode(address _node, uint256 _score, string calldata _loc) external onlySeedbringer {
        require(_score >= 80, "ITACA_FAILURE: Sostenibilità insufficiente per il Nexus");
        
        registry[_node] = NexusNode({
            isActive: true,
            itacaScore: _score,
            lastValidation: block.timestamp,
            location: _loc
        });
    }

    /**
     * @dev Contribuzione al Peacebond. Accetta solo da nodi che rispettano la NSR.
     */
    function contribute() external payable onlyValidResonance {
        require(msg.value > 0, "ENTROPY_ERROR: Contributo nullo rilevato");
        
        contributionHistory[msg.sender] += msg.value;
        totalPeacebondBalance += msg.value;

        emit PeacebondUpdated(msg.sender, msg.value, totalPeacebondBalance);
    }

    /**
     * @dev Trigger del Red Shield: disabilita un nodo in caso di deriva etica.
     */
    function redCodeVeto(address _node, string calldata _reason) external onlySeedbringer {
        registry[_node].isActive = false;
        emit NodeSanctioned(_node, _reason);
    }

    /**
     * @dev Sigilla il contratto rendendo i principi NSR immutabili.
     */
    function finalizeSeal() external onlySeedbringer {
        isSealed = true;
        emit StandardUpdated("ITACA-EF-FINAL-SEAL");
    }

    receive() external payable {
        revert("NSR_VETO: Usa la funzione contribute() per la validazione ITACA-EF");
    }
}
