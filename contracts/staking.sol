// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Staking is ReentrancyGuard, Ownable, Pausable {
    using SafeMath for uint256;

    IERC20 public neuronToken;

    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 lastClaimTime;
        uint256 tier;
    }

    mapping(address => StakeInfo) public stakes;
    uint256 public totalStaked;
    uint256[] public rewardRates; // Tokens per second per staked token for each tier
    uint256[] public tierThresholds; // Minimum amount for each tier
    uint256 public constant MAX_TIERS = 5;

    uint256 public constant CLAIM_INTERVAL = 1 days;
    uint256 public constant UNSTAKE_LOCK_PERIOD = 7 days;

    event Staked(address indexed user, uint256 amount, uint256 tier);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event TierUpgraded(address indexed user, uint256 newTier);

    constructor(address _neuronToken) {
        neuronToken = IERC20(_neuronToken);

        // Initialize tiers and reward rates
        tierThresholds = [0, 1000 ether, 5000 ether, 10000 ether, 50000 ether];
        rewardRates = [1e15, 2e15, 3e15, 4e15, 5e15]; // 0.001 to 0.005 tokens per second per staked token
    }

    function stake(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Cannot stake 0 tokens");

        if (stakes[msg.sender].amount > 0) {
            claimReward();
        }

        neuronToken.transferFrom(msg.sender, address(this), amount);
        uint256 newStakeAmount = stakes[msg.sender].amount.add(amount);
        uint256 newTier = getTier(newStakeAmount);

        stakes[msg.sender].amount = newStakeAmount;
        stakes[msg.sender].startTime = block.timestamp;
        stakes[msg.sender].lastClaimTime = block.timestamp;
        stakes[msg.sender].tier = newTier;

        totalStaked = totalStaked.add(amount);

        emit Staked(msg.sender, amount, newTier);
        if (newTier > stakes[msg.sender].tier) {
            emit TierUpgraded(msg.sender, newTier);
        }
    }

    function unstake(uint256 amount) external nonReentrant whenNotPaused {
        require(stakes[msg.sender].amount >= amount, "Insufficient staked balance");
        require(block.timestamp >= stakes[msg.sender].startTime.add(UNSTAKE_LOCK_PERIOD), "Tokens are still locked");

        claimReward();

        stakes[msg.sender].amount = stakes[msg.sender].amount.sub(amount);
        totalStaked = totalStaked.sub(amount);
        neuronToken.transfer(msg.sender, amount);

        uint256 newTier = getTier(stakes[msg.sender].amount);
        stakes[msg.sender].tier = newTier;

        emit Unstaked(msg.sender, amount);
    }

    function claimReward() public nonReentrant whenNotPaused {
        require(block.timestamp >= stakes[msg.sender].lastClaimTime.add(CLAIM_INTERVAL), "Claim interval not reached");

        uint256 reward = calculateReward(msg.sender);
        require(reward > 0, "No rewards to claim");

        stakes[msg.sender].lastClaimTime = block.timestamp;
        neuronToken.transfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    function calculateReward(address user) public view returns (uint256) {
        uint256 stakedTime = block.timestamp.sub(stakes[user].lastClaimTime);
        uint256 rate = rewardRates[stakes[user].tier];
        return stakes[user].amount.mul(rate).mul(stakedTime).div(1e18);
    }

    function getTier(uint256 amount) public view returns (uint256) {
        for (uint256 i = MAX_TIERS - 1; i >= 0; i--) {
            if (amount >= tierThresholds[i]) {
                return i;
            }
        }
        return 0;
    }

    function setRewardRates(uint256[] memory _rewardRates) external onlyOwner {
        require(_rewardRates.length == MAX_TIERS, "Invalid reward rates length");
        rewardRates = _rewardRates;
    }

    function setTierThresholds(uint256[] memory _tierThresholds) external onlyOwner {
        require(_tierThresholds.length == MAX_TIERS, "Invalid tier thresholds length");
        tierThresholds = _tierThresholds;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getStakeInfo(address user) external view returns (uint256 amount, uint256 tier, uint256 pendingReward) {
        StakeInfo memory userStake = stakes[user];
        return (userStake.amount, userStake.tier, calculateReward(user));
    }
}