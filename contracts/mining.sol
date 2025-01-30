// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Neuron.sol";

contract Mining is AccessControl, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    bytes32 public constant MINER_ROLE = keccak256("MINER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    Neuron public neuronToken;

    uint256 public difficulty;
    uint256 public blockReward;
    uint256 public lastDifficultyAdjustment;
    uint256 public targetBlockTime;
    uint256 public blocksMined;

    mapping(address => uint256) public minerHashrate;
    mapping(address => uint256) public lastMineTime;
    mapping(bytes32 => bool) public usedNonces;

    uint256 public totalHashrate;
    uint256 public constant RATE_LIMIT = 1 minutes;

    struct MinerTier {
        uint256 minHashrate;
        uint256 rewardMultiplier;
    }

    MinerTier[] public minerTiers;

    event BlockMined(address indexed miner, uint256 reward, uint256 difficulty);
    event DifficultyAdjusted(uint256 newDifficulty);
    event MinerTierAdded(uint256 minHashrate, uint256 rewardMultiplier);

    constructor(address _neuronToken, uint256 _initialDifficulty, uint256 _initialBlockReward, uint256 _targetBlockTime) {
        neuronToken = Neuron(_neuronToken);
        difficulty = _initialDifficulty;
        blockReward = _initialBlockReward;
        targetBlockTime = _targetBlockTime;
        lastDifficultyAdjustment = block.timestamp;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MINER_ROLE, msg.sender);

        // Initialize miner tiers
        addMinerTier(0, 100); // Base tier
        addMinerTier(1000, 110); // Medium tier: 10% bonus
        addMinerTier(10000, 125); // High tier: 25% bonus
    }

    function mine(uint256 nonce) external nonReentrant whenNotPaused {
        require(hasRole(MINER_ROLE, msg.sender), "Must have miner role to mine");
        require(block.timestamp >= lastMineTime[msg.sender].add(RATE_LIMIT), "Rate limit exceeded");

        bytes32 nonceHash = keccak256(abi.encodePacked(msg.sender, nonce, block.number));
        require(!usedNonces[nonceHash], "Nonce already used");

        require(verifyProofOfWork(nonce), "Invalid proof of work");

        usedNonces[nonceHash] = true;
        lastMineTime[msg.sender] = block.timestamp;
        blocksMined++;

        uint256 reward = calculateReward(msg.sender);
        neuronToken.mineTokens();
        neuronToken.transfer(msg.sender, reward);

        emit BlockMined(msg.sender, reward, difficulty);

        if (block.timestamp >= lastDifficultyAdjustment.add(1 days)) {
            adjustDifficulty();
        }
    }

    function verifyProofOfWork(uint256 nonce) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, nonce));
        uint256 hashValue = uint256(hash);
        return hashValue < (2**256).div(difficulty);
    }

    function adjustDifficulty() internal {
        uint256 timeElapsed = block.timestamp.sub(lastDifficultyAdjustment);
        uint256 expectedBlocks = timeElapsed.div(targetBlockTime);

        if (blocksMined > expectedBlocks) {
            difficulty = difficulty.mul(105).div(100); // Increase by 5%
        } else {
            difficulty = difficulty.mul(95).div(100); // Decrease by 5%
        }

        lastDifficultyAdjustment = block.timestamp;
        blocksMined = 0;

        emit DifficultyAdjusted(difficulty);
    }

    function updateMinerHashrate(address miner, uint256 hashrate) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Must have admin role to update hashrate");
        totalHashrate = totalHashrate.sub(minerHashrate[miner]).add(hashrate);
        minerHashrate[miner] = hashrate;
    }

    function setBlockReward(uint256 _blockReward) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Must have admin role to set block reward");
        blockReward = _blockReward;
    }

    function addMinerTier(uint256 minHashrate, uint256 rewardMultiplier) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Must have admin role to add miner tier");
        minerTiers.push(MinerTier(minHashrate, rewardMultiplier));
        emit MinerTierAdded(minHashrate, rewardMultiplier);
    }

    function calculateReward(address miner) internal view returns (uint256) {
        uint256 baseReward = blockReward;
        uint256 minerHashrate = minerHashrate[miner];

        for (uint256 i = minerTiers.length - 1; i >= 0; i--) {
            if (minerHashrate >= minerTiers[i].minHashrate) {
                return baseReward.mul(minerTiers[i].rewardMultiplier).div(100);
            }
        }

        return baseReward;
    }

    function pause() external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Must have admin role to pause");
        _pause();
    }

    function unpause() external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Must have admin role to unpause");
        _unpause();
    }
}