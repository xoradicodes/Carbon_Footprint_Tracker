// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title CarbonFootprintTracker
 * @dev Smart contract for tracking carbon emissions and managing carbon offsets
 * @author Your Name
 */
contract CarbonFootprintTracker {
    
    // Struct to store user's carbon footprint data
    struct CarbonData {
        uint256 totalEmissions;      // Total CO2 emissions in kg
        uint256 totalOffsets;        // Total CO2 offsets purchased in kg
        uint256 lastUpdated;         // Timestamp of last update
        bool isRegistered;           // Check if user is registered
    }
    
    // Struct to store emission records
    struct EmissionRecord {
        string category;             // e.g., "transport", "energy", "food"
        uint256 amount;              // CO2 amount in kg
        uint256 timestamp;           // When emission was recorded
        string description;          // Optional description
    }
    
    // State variables
    mapping(address => CarbonData) public carbonFootprints;
    mapping(address => EmissionRecord[]) public emissionHistory;
    mapping(address => uint256) public offsetCredits; // Available offset credits
    
    uint256 public constant OFFSET_PRICE = 0.001 ether; // Price per kg CO2 offset
    uint256 public totalGlobalEmissions;
    uint256 public totalGlobalOffsets;
    address public owner;
    
    // Events
    event UserRegistered(address indexed user, uint256 timestamp);
    event EmissionRecorded(address indexed user, string category, uint256 amount, uint256 timestamp);
    event OffsetsUpgraded(address indexed user, uint256 amount, uint256 cost);
    event CarbonNeutral(address indexed user, uint256 timestamp);
    
    // Modifiers
    modifier onlyRegistered() {
        require(carbonFootprints[msg.sender].isRegistered, "User not registered");
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Register a new user in the carbon tracking system
     */
    function registerUser() external {
        require(!carbonFootprints[msg.sender].isRegistered, "User already registered");
        
        carbonFootprints[msg.sender] = CarbonData({
            totalEmissions: 0,
            totalOffsets: 0,
            lastUpdated: block.timestamp,
            isRegistered: true
        });
        
        emit UserRegistered(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Record carbon emission for the user
     * @param _category Category of emission (transport, energy, food, etc.)
     * @param _amount Amount of CO2 in kg
     * @param _description Optional description of the emission source
     */
    function recordEmission(
        string memory _category, 
        uint256 _amount, 
        string memory _description
    ) external onlyRegistered {
        require(_amount > 0, "Emission amount must be greater than 0");
        
        // Update user's total emissions
        carbonFootprints[msg.sender].totalEmissions += _amount;
        carbonFootprints[msg.sender].lastUpdated = block.timestamp;
        
        // Add to emission history
        emissionHistory[msg.sender].push(EmissionRecord({
            category: _category,
            amount: _amount,
            timestamp: block.timestamp,
            description: _description
        }));
        
        // Update global emissions
        totalGlobalEmissions += _amount;
        
        emit EmissionRecorded(msg.sender, _category, _amount, block.timestamp);
    }
    
    /**
     * @dev Purchase carbon offsets to compensate for emissions
     */
    function purchaseOffsets(uint256 _offsetAmount) external payable onlyRegistered {
        require(_offsetAmount > 0, "Offset amount must be greater than 0");
        
        uint256 totalCost = _offsetAmount * OFFSET_PRICE;
        require(msg.value >= totalCost, "Insufficient payment for offsets");
        
        // Update user's offset credits and total offsets
        offsetCredits[msg.sender] += _offsetAmount;
        carbonFootprints[msg.sender].totalOffsets += _offsetAmount;
        carbonFootprints[msg.sender].lastUpdated = block.timestamp;
        
        // Update global offsets
        totalGlobalOffsets += _offsetAmount;
        
        // Refund excess payment
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
        
        // Check if user achieved carbon neutrality
        if (carbonFootprints[msg.sender].totalOffsets >= carbonFootprints[msg.sender].totalEmissions) {
            emit CarbonNeutral(msg.sender, block.timestamp);
        }
        
        emit OffsetsUpgraded(msg.sender, _offsetAmount, totalCost);
    }
    
    /**
     * @dev Get user's carbon footprint summary
     * @param _user Address of the user
     * @return totalEmissions Total CO2 emissions in kg
     * @return totalOffsets Total CO2 offsets in kg
     * @return netEmissions Net emissions (emissions - offsets)
     * @return isCarbonNeutral Whether user has achieved carbon neutrality
     */
    function getCarbonSummary(address _user) external view returns (
        uint256 totalEmissions,
        uint256 totalOffsets,
        uint256 netEmissions,
        bool isCarbonNeutral
    ) {
        require(carbonFootprints[_user].isRegistered, "User not registered");
        
        CarbonData memory data = carbonFootprints[_user];
        totalEmissions = data.totalEmissions;
        totalOffsets = data.totalOffsets;
        
        if (totalOffsets >= totalEmissions) {
            netEmissions = 0;
            isCarbonNeutral = true;
        } else {
            netEmissions = totalEmissions - totalOffsets;
            isCarbonNeutral = false;
        }
    }
    
    /**
     * @dev Get user's emission history count
     * @param _user Address of the user
     * @return count Number of emission records
     */
    function getEmissionHistoryCount(address _user) external view returns (uint256 count) {
        return emissionHistory[_user].length;
    }
    
    /**
     * @dev Owner can withdraw accumulated funds (for offset project funding)
     */
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner).transfer(balance);
    }
    
    /**
     * @dev Get global carbon statistics
     * @return globalEmissions Total global emissions tracked
     * @return globalOffsets Total global offsets purchased
     * @return netGlobalEmissions Net global emissions
     */
    function getGlobalStats() external view returns (
        uint256 globalEmissions,
        uint256 globalOffsets,
        uint256 netGlobalEmissions
    ) {
        globalEmissions = totalGlobalEmissions;
        globalOffsets = totalGlobalOffsets;
        
        if (globalOffsets >= globalEmissions) {
            netGlobalEmissions = 0;
        } else {
            netGlobalEmissions = globalEmissions - globalOffsets;
        }
    }
}
