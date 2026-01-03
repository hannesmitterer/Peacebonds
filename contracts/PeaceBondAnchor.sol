// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title PeaceBondAnchor
 * @notice ERC-721 smart contract for anchoring PeaceBonds (Euystacio Protocol) v1.1
 * @dev Stores manifestCID and signatureCID with their keccak256 hashes for immutable verification
 * 
 * This contract implements the PeaceBonds protocol for public notarization and verification 
 * of manifest-like documents using IPFS for content-addressed storage and blockchain for 
 * immutable anchoring.
 */
contract PeaceBondAnchor is ERC721 {
    
    /// @dev Counter for token IDs
    uint256 private _tokenIdCounter;
    
    /// @notice Structure to store anchor data for each PeaceBond
    struct AnchorData {
        string manifestCID;      // IPFS CID of the manifest
        string signatureCID;     // IPFS CID of the signature file
        bytes32 manifestHash;    // keccak256 hash of manifestCID
        bytes32 signatureHash;   // keccak256 hash of signatureCID
        uint256 timestamp;       // Block timestamp when anchored
        address creator;         // Address that created the anchor
    }
    
    /// @notice Mapping from token ID to anchor data
    mapping(uint256 => AnchorData) private _anchors;
    
    /**
     * @notice Emitted when a new PeaceBond is anchored
     * @param tokenId The ID of the minted NFT
     * @param manifestCID IPFS CID of the manifest
     * @param signatureCID IPFS CID of the signature file
     * @param manifestHash keccak256 hash of manifestCID
     * @param signatureHash keccak256 hash of signatureCID
     * @param creator Address that created the anchor
     * @param timestamp Block timestamp
     */
    event PeaceBondAnchored(
        uint256 indexed tokenId,
        string manifestCID,
        string signatureCID,
        bytes32 manifestHash,
        bytes32 signatureHash,
        address indexed creator,
        uint256 timestamp
    );
    
    /**
     * @notice Emitted when a PeaceBond is verified
     * @param tokenId The ID of the verified NFT
     * @param verifier Address that performed the verification
     * @param isValid Whether the verification succeeded
     */
    event PeaceBondVerified(
        uint256 indexed tokenId,
        address indexed verifier,
        bool isValid
    );
    
    constructor() ERC721("PeaceBond", "PEACE") {
        _tokenIdCounter = 0;
    }
    
    /**
     * @notice Creates a new PeaceBond NFT with manifest and signature CIDs
     * @dev Mints an ERC-721 token and stores the anchor data
     * @param manifestCID IPFS CID of the manifest document
     * @param signatureCID IPFS CID of the signature file (containing secp256k1 signatures)
     * @return tokenId The ID of the newly minted PeaceBond NFT
     */
    function anchor(
        string memory manifestCID,
        string memory signatureCID
    ) external returns (uint256) {
        require(bytes(manifestCID).length > 0, "PeaceBondAnchor: manifestCID cannot be empty");
        require(bytes(signatureCID).length > 0, "PeaceBondAnchor: signatureCID cannot be empty");
        
        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;
        
        // Calculate hashes
        bytes32 manifestHash = keccak256(bytes(manifestCID));
        bytes32 signatureHash = keccak256(bytes(signatureCID));
        
        // Store anchor data
        _anchors[newTokenId] = AnchorData({
            manifestCID: manifestCID,
            signatureCID: signatureCID,
            manifestHash: manifestHash,
            signatureHash: signatureHash,
            timestamp: block.timestamp,
            creator: msg.sender
        });
        
        // Mint the NFT
        _safeMint(msg.sender, newTokenId);
        
        emit PeaceBondAnchored(
            newTokenId,
            manifestCID,
            signatureCID,
            manifestHash,
            signatureHash,
            msg.sender,
            block.timestamp
        );
        
        return newTokenId;
    }
    
    /**
     * @notice Verifies that the provided CIDs match the on-chain anchor data
     * @dev Compares keccak256 hashes of provided CIDs with stored hashes
     * @param tokenId The ID of the PeaceBond NFT to verify
     * @param manifestCID The manifest CID to verify
     * @param signatureCID The signature CID to verify
     * @return isValid True if both CIDs match the on-chain data
     */
    function verify(
        uint256 tokenId,
        string memory manifestCID,
        string memory signatureCID
    ) external returns (bool) {
        require(_exists(tokenId), "PeaceBondAnchor: token does not exist");
        
        AnchorData memory anchorData = _anchors[tokenId];
        
        bytes32 providedManifestHash = keccak256(bytes(manifestCID));
        bytes32 providedSignatureHash = keccak256(bytes(signatureCID));
        
        bool isValid = (
            providedManifestHash == anchorData.manifestHash &&
            providedSignatureHash == anchorData.signatureHash
        );
        
        emit PeaceBondVerified(tokenId, msg.sender, isValid);
        
        return isValid;
    }
    
    /**
     * @notice Retrieves the complete anchor data for a PeaceBond
     * @param tokenId The ID of the PeaceBond NFT
     * @return manifestCID IPFS CID of the manifest
     * @return signatureCID IPFS CID of the signature file
     * @return manifestHash keccak256 hash of manifestCID
     * @return signatureHash keccak256 hash of signatureCID
     * @return timestamp Block timestamp when anchored
     * @return creator Address that created the anchor
     */
    function getAnchor(uint256 tokenId) external view returns (
        string memory manifestCID,
        string memory signatureCID,
        bytes32 manifestHash,
        bytes32 signatureHash,
        uint256 timestamp,
        address creator
    ) {
        require(_exists(tokenId), "PeaceBondAnchor: token does not exist");
        
        AnchorData memory anchorData = _anchors[tokenId];
        
        return (
            anchorData.manifestCID,
            anchorData.signatureCID,
            anchorData.manifestHash,
            anchorData.signatureHash,
            anchorData.timestamp,
            anchorData.creator
        );
    }
    
    /**
     * @notice Returns the tokenURI with anchor metadata encoded as base64 JSON
     * @param tokenId The ID of the PeaceBond NFT
     * @return The base64-encoded JSON metadata URI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "PeaceBondAnchor: URI query for nonexistent token");
        
        AnchorData memory anchorData = _anchors[tokenId];
        
        bytes memory json = abi.encodePacked(
            '{"name":"PeaceBond #', _toString(tokenId), '",',
            '"description":"PeaceBond (Euystacio Protocol) - Publicly anchored manifest with cryptographic signatures",',
            '"manifestCID":"', anchorData.manifestCID, '",',
            '"signatureCID":"', anchorData.signatureCID, '",',
            '"manifestHash":"0x', _toHex(anchorData.manifestHash), '",',
            '"signatureHash":"0x', _toHex(anchorData.signatureHash), '",',
            '"timestamp":', _toString(anchorData.timestamp), ',',
            '"creator":"', _toHexAddress(anchorData.creator), '"}'
        );
        
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(json)
            )
        );
    }
    
    /**
     * @notice Returns the total number of PeaceBonds created
     * @return The current token ID counter
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }
    
    /**
     * @dev Internal helper to check if a token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
    
    /**
     * @dev Internal helper to convert bytes32 to hex string
     */
    function _toHex(bytes32 data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            str[i*2] = alphabet[uint8(data[i] >> 4)];
            str[i*2+1] = alphabet[uint8(data[i] & 0x0f)];
        }
        return string(str);
    }
    
    /**
     * @dev Internal helper to convert address to hex string
     */
    function _toHexAddress(address addr) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(uint160(addr) >> (4 * (39 - i))) & 0xf];
            str[3+i*2] = alphabet[uint8(uint160(addr) >> (4 * (38 - i))) & 0xf];
        }
        return string(str);
    }
    
    /**
     * @dev Internal helper to convert uint256 to string
     */
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
