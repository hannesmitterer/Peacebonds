// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title PeaceContributionEngine
 * @notice Smart contract for VCD-01 Ethical Dividend (δ_E) tracking and distribution
 * @dev Implements 2.7% universal contribution tax and NFT-based Proof of Impact
 */
contract PeaceContributionEngine is ERC721Enumerable, AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;

    // Roles
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

    // Constants
    uint256 public constant CONTRIBUTION_RATE = 27; // 2.7% represented as 27/1000
    uint256 public constant RATE_DENOMINATOR = 1000;
    uint256 public constant INTEGRITY_THRESHOLD = 984; // 98.4% as 984/1000

    // Token ID counter for Proof of Impact NFTs
    Counters.Counter private _tokenIdCounter;

    // Contribution tracking
    struct Contribution {
        address contributor;
        uint256 amount;
        uint256 timestamp;
        uint256 impactScore;
        string category; // "IDRO", "HELIOS", "R&D", "Operations"
        bool distributed;
    }

    // Proof of Impact NFT metadata
    struct ProofOfImpact {
        uint256 contributionId;
        uint256 impactScore;
        uint256 beneficiariesReached;
        uint256 resourcesDeployed;
        string category;
        string ipfsCID; // Link to detailed impact report
        uint256 timestamp;
    }

    // Allocation categories
    struct AllocationCategory {
        string name;
        uint256 percentage; // Out of 1000 (e.g., 400 = 40%)
        uint256 totalAllocated;
        uint256 totalDistributed;
        bool active;
    }

    // Storage
    mapping(uint256 => Contribution) public contributions;
    mapping(uint256 => ProofOfImpact) public proofOfImpacts;
    mapping(address => uint256[]) public contributorHistory;
    mapping(string => AllocationCategory) public allocationCategories;
    
    uint256 public totalContributions;
    uint256 public totalDistributed;
    uint256 private _contributionIdCounter;

    // Events
    event ContributionReceived(
        uint256 indexed contributionId,
        address indexed contributor,
        uint256 amount,
        uint256 contributionTax,
        string category
    );

    event ImpactNFTMinted(
        uint256 indexed tokenId,
        uint256 indexed contributionId,
        address indexed recipient,
        uint256 impactScore,
        string ipfsCID
    );

    event FundsDistributed(
        uint256 indexed contributionId,
        string category,
        uint256 amount,
        address recipient
    );

    event CategoryUpdated(
        string category,
        uint256 percentage,
        bool active
    );

    /**
     * @notice Constructor initializes the Peace Contribution Engine
     */
    constructor() ERC721("PeaceImpactProof", "PIP") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        
        // Initialize allocation categories
        _initializeCategories();
    }

    /**
     * @dev Initialize default allocation categories
     */
    function _initializeCategories() private {
        allocationCategories["IDRO"] = AllocationCategory({
            name: "IDRO Infrastructure",
            percentage: 400, // 40%
            totalAllocated: 0,
            totalDistributed: 0,
            active: true
        });

        allocationCategories["HELIOS"] = AllocationCategory({
            name: "HELIOS Network",
            percentage: 350, // 35%
            totalAllocated: 0,
            totalDistributed: 0,
            active: true
        });

        allocationCategories["R&D"] = AllocationCategory({
            name: "Research & Development",
            percentage: 150, // 15%
            totalAllocated: 0,
            totalDistributed: 0,
            active: true
        });

        allocationCategories["OPERATIONS"] = AllocationCategory({
            name: "Network Operations",
            percentage: 100, // 10%
            totalAllocated: 0,
            totalDistributed: 0,
            active: true
        });
    }

    /**
     * @notice Make a contribution to the Peace Contribution Engine
     * @dev Automatically deducts 2.7% contribution tax and allocates to categories
     */
    function contribute() external payable nonReentrant returns (uint256) {
        return _processContribution(msg.sender, msg.value);
    }

    /**
     * @dev Internal function to process contributions
     */
    function _processContribution(address contributor, uint256 amount) private returns (uint256) {
        require(amount > 0, "Contribution must be greater than 0");

        // Calculate contribution tax (2.7%)
        uint256 contributionTax = (amount * CONTRIBUTION_RATE) / RATE_DENOMINATOR;
        uint256 netContribution = amount - contributionTax;

        // Create contribution record
        uint256 contributionId = _contributionIdCounter++;
        contributions[contributionId] = Contribution({
            contributor: contributor,
            amount: amount,
            timestamp: block.timestamp,
            impactScore: 0, // To be calculated later
            category: "PENDING",
            distributed: false
        });

        contributorHistory[contributor].push(contributionId);
        totalContributions += amount;

        emit ContributionReceived(
            contributionId,
            contributor,
            amount,
            contributionTax,
            "PENDING"
        );

        // Allocate to categories
        _allocateToCategories(contributionId, contributionTax);

        return contributionId;
    }

    /**
     * @dev Allocate contribution to predefined categories
     */
    function _allocateToCategories(uint256 contributionId, uint256 amount) private {
        uint256 remaining = amount;

        // Allocate to IDRO
        uint256 idroAmount = (amount * allocationCategories["IDRO"].percentage) / RATE_DENOMINATOR;
        allocationCategories["IDRO"].totalAllocated += idroAmount;
        remaining -= idroAmount;

        // Allocate to HELIOS
        uint256 heliosAmount = (amount * allocationCategories["HELIOS"].percentage) / RATE_DENOMINATOR;
        allocationCategories["HELIOS"].totalAllocated += heliosAmount;
        remaining -= heliosAmount;

        // Allocate to R&D
        uint256 rndAmount = (amount * allocationCategories["R&D"].percentage) / RATE_DENOMINATOR;
        allocationCategories["R&D"].totalAllocated += rndAmount;
        remaining -= rndAmount;

        // Allocate remaining to Operations
        allocationCategories["OPERATIONS"].totalAllocated += remaining;
    }

    /**
     * @notice Mint Proof of Impact NFT for a contribution
     * @param contributionId The contribution to create NFT for
     * @param impactScore Calculated impact score
     * @param beneficiariesReached Number of beneficiaries
     * @param resourcesDeployed Amount of resources deployed
     * @param category Impact category
     * @param ipfsCID IPFS CID of detailed impact report
     */
    function mintProofOfImpact(
        uint256 contributionId,
        uint256 impactScore,
        uint256 beneficiariesReached,
        uint256 resourcesDeployed,
        string memory category,
        string memory ipfsCID
    ) external onlyRole(OPERATOR_ROLE) returns (uint256) {
        require(contributionId < _contributionIdCounter, "Invalid contribution ID");
        require(contributions[contributionId].impactScore == 0, "Impact already recorded");
        require(bytes(ipfsCID).length > 0, "IPFS CID required");

        // Update contribution with impact score
        contributions[contributionId].impactScore = impactScore;
        contributions[contributionId].category = category;

        // Mint NFT
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        proofOfImpacts[tokenId] = ProofOfImpact({
            contributionId: contributionId,
            impactScore: impactScore,
            beneficiariesReached: beneficiariesReached,
            resourcesDeployed: resourcesDeployed,
            category: category,
            ipfsCID: ipfsCID,
            timestamp: block.timestamp
        });

        _safeMint(contributions[contributionId].contributor, tokenId);

        emit ImpactNFTMinted(
            tokenId,
            contributionId,
            contributions[contributionId].contributor,
            impactScore,
            ipfsCID
        );

        return tokenId;
    }

    /**
     * @notice Distribute funds from a category to recipient
     * @param category The category to distribute from
     * @param amount Amount to distribute
     * @param recipient Recipient address
     */
    function distributeFunds(
        string memory category,
        uint256 amount,
        address payable recipient
    ) external onlyRole(OPERATOR_ROLE) nonReentrant {
        require(allocationCategories[category].active, "Category not active");
        require(
            allocationCategories[category].totalAllocated - allocationCategories[category].totalDistributed >= amount,
            "Insufficient allocated funds"
        );
        require(address(this).balance >= amount, "Insufficient contract balance");

        allocationCategories[category].totalDistributed += amount;
        totalDistributed += amount;

        // Use call instead of transfer for better gas flexibility
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");

        emit FundsDistributed(0, category, amount, recipient);
    }

    /**
     * @notice Update allocation category parameters
     * @param category Category name
     * @param percentage New percentage (out of 1000)
     * @param active Whether category is active
     */
    function updateCategory(
        string memory category,
        uint256 percentage,
        bool active
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        allocationCategories[category].percentage = percentage;
        allocationCategories[category].active = active;

        emit CategoryUpdated(category, percentage, active);
    }

    /**
     * @notice Get contribution history for an address
     * @param contributor The address to query
     * @return Array of contribution IDs
     */
    function getContributorHistory(address contributor) external view returns (uint256[] memory) {
        return contributorHistory[contributor];
    }

    /**
     * @notice Get total impact score for an address
     * @param contributor The address to query
     * @return Total impact score
     */
    function getTotalImpactScore(address contributor) external view returns (uint256) {
        uint256 totalImpact = 0;
        uint256[] memory history = contributorHistory[contributor];

        for (uint256 i = 0; i < history.length; i++) {
            totalImpact += contributions[history[i]].impactScore;
        }

        return totalImpact;
    }

    /**
     * @notice Get category allocation status
     * @param category Category name
     * @return name Category name
     * @return percentage Allocation percentage
     * @return totalAllocated Total allocated amount
     * @return totalDistributed Total distributed amount
     * @return available Available for distribution
     * @return active Whether category is active
     */
    function getCategoryStatus(string memory category) external view returns (
        string memory name,
        uint256 percentage,
        uint256 totalAllocated,
        uint256 totalDistributed,
        uint256 available,
        bool active
    ) {
        AllocationCategory memory cat = allocationCategories[category];
        return (
            cat.name,
            cat.percentage,
            cat.totalAllocated,
            cat.totalDistributed,
            cat.totalAllocated - cat.totalDistributed,
            cat.active
        );
    }

    /**
     * @notice Get NFT metadata URI
     * @param tokenId Token ID
     * @return Token URI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        ProofOfImpact memory poi = proofOfImpacts[tokenId];
        Contribution memory contribution = contributions[poi.contributionId];

        // In production, construct full JSON metadata with IPFS links
        return string(
            abi.encodePacked(
                "ipfs://",
                poi.ipfsCID
            )
        );
    }

    /**
     * @notice Check if contract has reached integrity threshold
     * @return True if operational integrity is maintained
     */
    function checkIntegrity() external view returns (bool) {
        // Calculate integrity based on successful distributions vs allocations
        if (totalContributions == 0) return true;

        uint256 successRate = (totalDistributed * RATE_DENOMINATOR) / totalContributions;
        return successRate >= INTEGRITY_THRESHOLD;
    }

    /**
     * @notice Get contract statistics
     * @return _totalContributions Total contributions received
     * @return _totalDistributed Total funds distributed
     * @return _contributionCount Number of contributions
     * @return _nftsMinted Number of Impact NFTs minted
     */
    function getStatistics() external view returns (
        uint256 _totalContributions,
        uint256 _totalDistributed,
        uint256 _contributionCount,
        uint256 _nftsMinted
    ) {
        return (
            totalContributions,
            totalDistributed,
            _contributionIdCounter,
            _tokenIdCounter.current()
        );
    }

    /**
     * @dev See {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Withdraw function (emergency only, requires admin)
     */
    function emergencyWithdraw(address payable recipient) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        require(recipient != address(0), "Invalid recipient");
        uint256 balance = address(this).balance;
        
        // Use call instead of transfer for better gas flexibility
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Transfer failed");
    }

    /**
     * @notice Receive function to accept ETH - contributes automatically
     * @dev Processes contribution using internal function
     */
    receive() external payable {
        _processContribution(msg.sender, msg.value);
    }
}
