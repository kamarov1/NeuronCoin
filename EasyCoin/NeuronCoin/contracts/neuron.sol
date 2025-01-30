// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Neuron is ERC20, ERC20Burnable, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18; // 1 bilhão de tokens
    uint256 public immutable rewardHalvingPeriod;
    uint256 public immutable initialRewardPerBlock;
    uint256 public lastRewardBlock;
    uint256 public rewardPerBlock;

    struct StakeInfo {
        uint256 amount;
        uint256 lastUpdateBlock;
        uint256 rewardDebt;
    }

    mapping(address => StakeInfo) public stakes;
    uint256 public totalStaked;
    uint256 public accRewardPerShare;

    event TokensMined(address indexed miner, uint256 amount);
    event TokensStaked(address indexed staker, uint256 amount);
    event TokensUnstaked(address indexed staker, uint256 amount);
    event RewardsClaimed(address indexed staker, uint256 amount);
    event RewardUpdated(uint256 newRewardPerBlock);

    constructor(uint256 _initialSupply, uint256 _rewardPerBlock, uint256 _rewardHalvingPeriod)
        ERC20("Neuron", "NRN")
    {
        require(_initialSupply <= MAX_SUPPLY, "Initial supply exceeds max supply");
        _mint(msg.sender, _initialSupply);
        rewardPerBlock = _rewardPerBlock;
        initialRewardPerBlock = _rewardPerBlock;
        rewardHalvingPeriod = _rewardHalvingPeriod;
        lastRewardBlock = block.number;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(GOVERNANCE_ROLE, msg.sender);
    }

    function mineTokens() external nonReentrant {
        require(hasRole(MINTER_ROLE, msg.sender), "Must have minter role to mine");
        updateReward();

        uint256 blocksPassed = block.number.sub(lastRewardBlock);
        uint256 reward = blocksPassed.mul(rewardPerBlock);

        require(totalSupply().add(reward) <= MAX_SUPPLY, "Max supply exceeded");

        _mint(msg.sender, reward);
        lastRewardBlock = block.number;

        emit TokensMined(msg.sender, reward);
    }

    function stakeTokens(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot stake 0 tokens");
        updateReward();

        StakeInfo storage stake = stakes[msg.sender];
        if (stake.amount > 0) {
            uint256 pending = stake.amount.mul(accRewardPerShare).div(1e18).sub(stake.rewardDebt);
            if (pending > 0) {
                _mint(msg.sender, pending);
                emit RewardsClaimed(msg.sender, pending);
            }
        }

        _burn(msg.sender, amount);
        stake.amount = stake.amount.add(amount);
        totalStaked = totalStaked.add(amount);
        stake.rewardDebt = stake.amount.mul(accRewardPerShare).div(1e18);
        stake.lastUpdateBlock = block.number;

        emit TokensStaked(msg.sender, amount);
    }

    function unstakeTokens(uint256 amount) external nonReentrant {
        StakeInfo storage stake = stakes[msg.sender];
        require(stake.amount >= amount, "Insufficient staked balance");
        updateReward();

        uint256 pending = stake.amount.mul(accRewardPerShare).div(1e18).sub(stake.rewardDebt);
        if (pending > 0) {
            _mint(msg.sender, pending);
            emit RewardsClaimed(msg.sender, pending);
        }

        stake.amount = stake.amount.sub(amount);
        totalStaked = totalStaked.sub(amount);
        stake.rewardDebt = stake.amount.mul(accRewardPerShare).div(1e18);
        _mint(msg.sender, amount);

        emit TokensUnstaked(msg.sender, amount);
    }

    function claimRewards() external nonReentrant {
        updateReward();
        StakeInfo storage stake = stakes[msg.sender];
        uint256 pending = stake.amount.mul(accRewardPerShare).div(1e18).sub(stake.rewardDebt);
        require(pending > 0, "No rewards to claim");

        stake.rewardDebt = stake.amount.mul(accRewardPerShare).div(1e18);
        _mint(msg.sender, pending);

        emit RewardsClaimed(msg.sender, pending);
    }

    function updateReward() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (totalStaked == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 blocksPassed = block.number.sub(lastRewardBlock);
        uint256 reward = blocksPassed.mul(rewardPerBlock);
        accRewardPerShare = accRewardPerShare.add(reward.mul(1e18).div(totalStaked));
        lastRewardBlock = block.number;

        // Atualizar recompensa por bloco se necessário
        uint256 halvings = block.number.sub(lastRewardBlock).div(rewardHalvingPeriod);
        if (halvings > 0) {
            rewardPerBlock = initialRewardPerBlock.div(2**halvings);
            emit RewardUpdated(rewardPerBlock);
        }
    }

    function getStakeInfo(address staker) external view returns (uint256 amount, uint256 pendingRewards) {
        StakeInfo storage stake = stakes[staker];
        amount = stake.amount;
        uint256 _accRewardPerShare = accRewardPerShare;
        if (block.number > lastRewardBlock && totalStaked > 0) {
            uint256 blocksPassed = block.number.sub(lastRewardBlock);
            uint256 reward = blocksPassed.mul(rewardPerBlock);
            _accRewardPerShare = _accRewardPerShare.add(reward.mul(1e18).div(totalStaked));
        }
        pendingRewards = stake.amount.mul(_accRewardPerShare).div(1e18).sub(stake.rewardDebt);
    }

    function setRewardPerBlock(uint256 _rewardPerBlock) external {
        require(hasRole(GOVERNANCE_ROLE, msg.sender), "Must have governance role to set reward");
        updateReward();
        rewardPerBlock = _rewardPerBlock;
        emit RewardUpdated(_rewardPerBlock);
    }

    function burn(uint256 amount) public override {
        super.burn(amount);
        if (totalSupply() < MAX_SUPPLY.div(2)) {
            rewardPerBlock = rewardPerBlock.mul(2);
            emit RewardUpdated(rewardPerBlock);
        }
    }
}