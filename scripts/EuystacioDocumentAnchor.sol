// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EuystacioDocumentAnchor
 * @notice Anchors Euystacio Framework documentation hashes on Ethereum blockchain
 * @dev Provides immutable proof of existence and integrity for documentation
 * 
 * This contract allows the Euystacio Framework team to anchor content hashes
 * on the blockchain, creating a permanent, verifiable record of documentation
 * existence and integrity.
 * 
 * Anyone can verify that a document existed at a specific time and has not
 * been tampered with by comparing the on-chain hash with the document hash.
 */
contract EuystacioDocumentAnchor {
    
    // ============ Structs ============
    
    /**
     * @notice Record of an anchored document
     * @param contentHash SHA-256 hash of the document content
     * @param ipfsCid IPFS Content Identifier for decentralized storage
     * @param version Document version (e.g., "1.0.0")
     * @param timestamp Block timestamp when anchored
     * @param publisher Address that anchored the document
     * @param metadata Additional metadata as JSON string
     */
    struct DocumentRecord {
        bytes32 contentHash;
        string ipfsCid;
        string version;
        uint256 timestamp;
        address publisher;
        string metadata;
    }
    
    // ============ State Variables ============
    
    /// @notice Mapping from content hash to document record
    mapping(bytes32 => DocumentRecord) public documents;
    
    /// @notice Array of all document hashes (for enumeration)
    bytes32[] public documentHashes;
    
    /// @notice Authorized publishers (can anchor documents)
    mapping(address => bool) public authorizedPublishers;
    
    /// @notice Contract owner (can manage authorized publishers)
    address public owner;
    
    // ============ Events ============
    
    /**
     * @notice Emitted when a document is anchored
     * @param contentHash Hash of the anchored content
     * @param ipfsCid IPFS CID for the content
     * @param version Document version
     * @param timestamp When the document was anchored
     * @param publisher Who anchored the document
     */
    event DocumentAnchored(
        bytes32 indexed contentHash,
        string ipfsCid,
        string version,
        uint256 timestamp,
        address indexed publisher
    );
    
    /**
     * @notice Emitted when a publisher is authorized or deauthorized
     * @param publisher Address of the publisher
     * @param authorized Whether they are now authorized
     */
    event PublisherUpdated(
        address indexed publisher,
        bool authorized
    );
    
    /**
     * @notice Emitted when ownership is transferred
     * @param previousOwner Previous owner address
     * @param newOwner New owner address
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    // ============ Modifiers ============
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized: only owner");
        _;
    }
    
    modifier onlyAuthorized() {
        require(
            authorizedPublishers[msg.sender] || msg.sender == owner,
            "Not authorized: must be authorized publisher or owner"
        );
        _;
    }
    
    // ============ Constructor ============
    
    constructor() {
        owner = msg.sender;
        authorizedPublishers[msg.sender] = true;
        emit PublisherUpdated(msg.sender, true);
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Anchor a document hash on the blockchain
     * @param _contentHash SHA-256 hash of document content (must be unique)
     * @param _ipfsCid IPFS Content Identifier where document is stored
     * @param _version Document version identifier
     * @param _metadata Additional metadata as JSON string
     * 
     * @dev Only authorized publishers can call this function
     * @dev Each content hash can only be anchored once
     */
    function anchorDocument(
        bytes32 _contentHash,
        string memory _ipfsCid,
        string memory _version,
        string memory _metadata
    ) public onlyAuthorized {
        require(
            documents[_contentHash].timestamp == 0,
            "Document already anchored"
        );
        require(_contentHash != bytes32(0), "Invalid content hash");
        require(bytes(_ipfsCid).length > 0, "IPFS CID required");
        require(bytes(_version).length > 0, "Version required");
        
        DocumentRecord memory record = DocumentRecord({
            contentHash: _contentHash,
            ipfsCid: _ipfsCid,
            version: _version,
            timestamp: block.timestamp,
            publisher: msg.sender,
            metadata: _metadata
        });
        
        documents[_contentHash] = record;
        documentHashes.push(_contentHash);
        
        emit DocumentAnchored(
            _contentHash,
            _ipfsCid,
            _version,
            block.timestamp,
            msg.sender
        );
    }
    
    /**
     * @notice Verify a document exists and retrieve its record
     * @param _contentHash SHA-256 hash to verify
     * @return Record of the anchored document
     * 
     * @dev Reverts if document is not found
     */
    function verifyDocument(bytes32 _contentHash)
        public
        view
        returns (DocumentRecord memory)
    {
        require(
            documents[_contentHash].timestamp != 0,
            "Document not found"
        );
        return documents[_contentHash];
    }
    
    /**
     * @notice Check if a document hash has been anchored
     * @param _contentHash Hash to check
     * @return True if document exists, false otherwise
     */
    function documentExists(bytes32 _contentHash)
        public
        view
        returns (bool)
    {
        return documents[_contentHash].timestamp != 0;
    }
    
    /**
     * @notice Get total number of anchored documents
     * @return Count of all anchored documents
     */
    function getDocumentCount() public view returns (uint256) {
        return documentHashes.length;
    }
    
    /**
     * @notice Get document hash at a specific index
     * @param _index Index in the documentHashes array
     * @return Document hash at that index
     */
    function getDocumentHashAt(uint256 _index)
        public
        view
        returns (bytes32)
    {
        require(_index < documentHashes.length, "Index out of bounds");
        return documentHashes[_index];
    }
    
    /**
     * @notice Get all document hashes
     * @return Array of all document hashes
     * 
     * @dev Warning: This can be expensive for large numbers of documents
     */
    function getAllDocumentHashes()
        public
        view
        returns (bytes32[] memory)
    {
        return documentHashes;
    }
    
    // ============ Admin Functions ============
    
    /**
     * @notice Authorize or deauthorize a publisher
     * @param _publisher Address to update
     * @param _authorized True to authorize, false to deauthorize
     * 
     * @dev Only owner can call this function
     */
    function setAuthorizedPublisher(address _publisher, bool _authorized)
        public
        onlyOwner
    {
        require(_publisher != address(0), "Invalid publisher address");
        authorizedPublishers[_publisher] = _authorized;
        emit PublisherUpdated(_publisher, _authorized);
    }
    
    /**
     * @notice Transfer ownership of the contract
     * @param _newOwner Address of the new owner
     * 
     * @dev Only current owner can call this function
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        address oldOwner = owner;
        owner = _newOwner;
        authorizedPublishers[_newOwner] = true;
        emit OwnershipTransferred(oldOwner, _newOwner);
        emit PublisherUpdated(_newOwner, true);
    }
}
