// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IPFSAnchor
 * @notice Anchors IPFS CIDs for the Euystacio Framework on Ethereum blockchain
 * @dev Provides permanent, immutable record of framework content identifiers
 * @author Euystacio Framework Team
 * @custom:security-contact security@euystacio.org
 */
contract IPFSAnchor {
    
    // ============ State Variables ============
    
    /// @notice The Final Principle - immutable foundation
    string public constant FINAL_PRINCIPLE = "Never slavery, only love first";
    
    /// @notice Framework name
    string public constant FRAMEWORK_NAME = "Euystacio Framework";
    
    /// @notice Current version
    string public constant VERSION = "1.2";
    
    /// @notice Contract owner address
    address public owner;
    
    /// @notice Current root IPFS CID
    string public currentCID;
    
    /// @notice Timestamp of last update
    uint256 public lastUpdated;
    
    /// @notice Total number of CID updates
    uint256 public updateCount;
    
    // ============ Structs ============
    
    /// @notice Record of a CID anchor event
    struct CIDRecord {
        string cid;
        uint256 timestamp;
        address updatedBy;
        string version;
        string description;
        bytes32 contentHash;
    }
    
    // ============ Storage ============
    
    /// @notice History of all CID updates
    CIDRecord[] public cidHistory;
    
    /// @notice Mapping of CID to its index in history
    mapping(string => uint256) public cidToIndex;
    
    /// @notice Authorized updaters (multi-sig in production)
    mapping(address => bool) public authorizedUpdaters;
    
    // ============ Events ============
    
    /// @notice Emitted when a new CID is anchored
    event CIDAnchored(
        string indexed cid,
        uint256 indexed timestamp,
        address indexed updatedBy,
        string version,
        string description
    );
    
    /// @notice Emitted when an updater is authorized
    event UpdaterAuthorized(address indexed updater, address indexed authorizedBy);
    
    /// @notice Emitted when an updater is revoked
    event UpdaterRevoked(address indexed updater, address indexed revokedBy);
    
    /// @notice Emitted when ownership is transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // ============ Modifiers ============
    
    /// @notice Restricts function to contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "IPFSAnchor: caller is not the owner");
        _;
    }
    
    /// @notice Restricts function to authorized updaters
    modifier onlyAuthorized() {
        require(
            authorizedUpdaters[msg.sender] || msg.sender == owner,
            "IPFSAnchor: caller is not authorized"
        );
        _;
    }
    
    /// @notice Validates CID format (checks for basic IPFS CID characteristics)
    modifier validCID(string memory cid) {
        bytes memory cidBytes = bytes(cid);
        require(cidBytes.length > 0, "IPFSAnchor: CID cannot be empty");
        require(cidBytes.length >= 46, "IPFSAnchor: CID too short"); // Min length for CIDv0
        require(cidBytes.length <= 100, "IPFSAnchor: CID too long"); // Reasonable max
        
        // Check that it starts with valid IPFS CID prefix
        // CIDv0: Qm (base58)
        // CIDv1: b (base32), z (base58), f (base16), u (base64url), etc.
        bool validPrefix = (cidBytes[0] == 'Q' && cidBytes[1] == 'm') || 
                          cidBytes[0] == 'b' || 
                          cidBytes[0] == 'z' || 
                          cidBytes[0] == 'f' || 
                          cidBytes[0] == 'u';
        require(validPrefix, "IPFSAnchor: Invalid CID prefix");
        
        _;
    }
    
    // ============ Constructor ============
    
    /// @notice Initializes the contract with initial CID
    /// @param initialCID The first IPFS CID to anchor
    /// @param description Description of the initial content
    constructor(string memory initialCID, string memory description) {
        owner = msg.sender;
        authorizedUpdaters[msg.sender] = true;
        
        _anchorCID(initialCID, VERSION, description);
        
        emit UpdaterAuthorized(msg.sender, msg.sender);
    }
    
    // ============ Core Functions ============
    
    /// @notice Anchors a new IPFS CID to the blockchain
    /// @param cid The IPFS Content Identifier
    /// @param version Framework version
    /// @param description Human-readable description
    function anchorCID(
        string memory cid,
        string memory version,
        string memory description
    ) external onlyAuthorized validCID(cid) {
        _anchorCID(cid, version, description);
    }
    
    /// @notice Internal function to anchor CID
    /// @param cid The IPFS Content Identifier
    /// @param version Framework version
    /// @param description Human-readable description
    function _anchorCID(
        string memory cid,
        string memory version,
        string memory description
    ) internal {
        // Calculate content hash
        bytes32 contentHash = keccak256(abi.encodePacked(cid, version, description));
        
        // Create record
        CIDRecord memory record = CIDRecord({
            cid: cid,
            timestamp: block.timestamp,
            updatedBy: msg.sender,
            version: version,
            description: description,
            contentHash: contentHash
        });
        
        // Store in history
        cidHistory.push(record);
        cidToIndex[cid] = cidHistory.length - 1;
        
        // Update current state
        currentCID = cid;
        lastUpdated = block.timestamp;
        updateCount++;
        
        emit CIDAnchored(cid, block.timestamp, msg.sender, version, description);
    }
    
    // ============ Query Functions ============
    
    /// @notice Gets the latest CID
    /// @return The current IPFS CID
    function getLatestCID() external view returns (string memory) {
        return currentCID;
    }
    
    /// @notice Gets a specific CID record by index
    /// @param index The index in history
    /// @return The CID record
    function getCIDRecord(uint256 index) external view returns (CIDRecord memory) {
        require(index < cidHistory.length, "IPFSAnchor: index out of bounds");
        return cidHistory[index];
    }
    
    /// @notice Gets the total number of CID records
    /// @return The count of historical CIDs
    function getHistoryCount() external view returns (uint256) {
        return cidHistory.length;
    }
    
    /// @notice Gets the index of a specific CID
    /// @param cid The IPFS CID to look up
    /// @return The index in history
    function getCIDIndex(string memory cid) external view returns (uint256) {
        return cidToIndex[cid];
    }
    
    /// @notice Verifies if a CID exists in history
    /// @param cid The IPFS CID to verify
    /// @return True if CID exists
    function verifyCID(string memory cid) external view returns (bool) {
        if (cidHistory.length == 0) return false;
        uint256 index = cidToIndex[cid];
        return keccak256(bytes(cidHistory[index].cid)) == keccak256(bytes(cid));
    }
    
    /// @notice Gets complete history of CIDs
    /// @return Array of all CID records
    function getFullHistory() external view returns (CIDRecord[] memory) {
        return cidHistory;
    }
    
    // ============ Admin Functions ============
    
    /// @notice Authorizes a new updater
    /// @param updater Address to authorize
    function authorizeUpdater(address updater) external onlyOwner {
        require(updater != address(0), "IPFSAnchor: invalid address");
        require(!authorizedUpdaters[updater], "IPFSAnchor: already authorized");
        
        authorizedUpdaters[updater] = true;
        emit UpdaterAuthorized(updater, msg.sender);
    }
    
    /// @notice Revokes an updater's authorization
    /// @param updater Address to revoke
    function revokeUpdater(address updater) external onlyOwner {
        require(authorizedUpdaters[updater], "IPFSAnchor: not authorized");
        require(updater != owner, "IPFSAnchor: cannot revoke owner");
        
        authorizedUpdaters[updater] = false;
        emit UpdaterRevoked(updater, msg.sender);
    }
    
    /// @notice Transfers ownership of the contract
    /// @param newOwner Address of the new owner
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "IPFSAnchor: invalid address");
        require(newOwner != owner, "IPFSAnchor: already owner");
        
        address previousOwner = owner;
        owner = newOwner;
        authorizedUpdaters[newOwner] = true;
        
        emit OwnershipTransferred(previousOwner, newOwner);
        emit UpdaterAuthorized(newOwner, previousOwner);
    }
    
    /// @notice Checks if an address is authorized
    /// @param account Address to check
    /// @return True if authorized
    function isAuthorized(address account) external view returns (bool) {
        return authorizedUpdaters[account] || account == owner;
    }
    
    // ============ Utility Functions ============
    
    /// @notice Gets contract metadata
    /// @return name Framework name
    /// @return version Current version
    /// @return principle The Final Principle
    function getMetadata() external pure returns (
        string memory name,
        string memory version,
        string memory principle
    ) {
        return (FRAMEWORK_NAME, VERSION, FINAL_PRINCIPLE);
    }
    
    /// @notice Gets current state summary
    /// @return cid Current CID
    /// @return timestamp Last update time
    /// @return count Total updates
    function getSummary() external view returns (
        string memory cid,
        uint256 timestamp,
        uint256 count
    ) {
        return (currentCID, lastUpdated, updateCount);
    }
}
