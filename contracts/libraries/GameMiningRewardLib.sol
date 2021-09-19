//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title StakingRewardLib
 *
 * @author PandaFarm
 */
library GameMiningRewardLib {

    struct RewardData {
        //reward address
        address rewardAddress;
        //Maximum reward per unit time
        uint256 rewardBalancePerUnit;
        //Maximum reward per unit time
        uint256 blockPerUnit;
        //Maximum reward
        uint256 maxRewardBalance;
        //Total reward of current address
        uint256 totalRewardBalance;
        //Residual reward
        uint256 residualReward;
        //Height of last reward block
        uint256 lastBlockHeight;
        //Reward switch
        bool isActive;
    }

    function init(
        RewardData storage _self,
        address _rewardAddress,
        uint256 _rewardBalancePerUnit,
        uint256 _blockPerUnit,
        uint256 _maxRewardBalance,
        bool _isActive
    ) internal {
        require(_rewardAddress != address(0), "The user address cannot be a 0 address");
        _self.rewardAddress = _rewardAddress;
        _self.rewardBalancePerUnit = _rewardBalancePerUnit;
        _self.blockPerUnit = _blockPerUnit;
        _self.maxRewardBalance = _maxRewardBalance;
        _self.residualReward = _maxRewardBalance;
        _self.isActive = _isActive;
        _self.totalRewardBalance = 0;
        _self.lastBlockHeight = block.number;
    }

    function update(
        RewardData storage _self,
        uint256 _rewardBalancePerUnit,
        uint256 _blockPerUnit,
        uint256 _maxRewardBalance,
        bool _isActive
    ) internal {
        _self.rewardBalancePerUnit = _rewardBalancePerUnit;
        _self.blockPerUnit = _blockPerUnit;
        _self.maxRewardBalance = _maxRewardBalance;
        _self.isActive = _isActive;
    }

    function getReward(
        RewardData storage _self
    ) internal returns(uint256 rewardBalance){
        uint256 diffBlockHeight = block.number - _self.lastBlockHeight;
        require(diffBlockHeight > 0, "The reward value exceeds the maximum value of the reward pool");
        uint256 rewardBalanceTmp = diffBlockHeight * _self.rewardBalancePerUnit;
        require(_self.maxRewardBalance >= (_self.totalRewardBalance + rewardBalanceTmp), "The reward value exceeds the maximum value of the reward pool");
        require(_self.residualReward >= rewardBalanceTmp, "The reward value exceeds the remaining value of the reward pool");
        require(_self.maxRewardBalance >= rewardBalanceTmp, "The reward value is greater than the maximum limit each time");

        _self.residualReward -= rewardBalanceTmp;
        _self.totalRewardBalance += rewardBalanceTmp;
        _self.lastBlockHeight = block.number;
        return rewardBalanceTmp;
    }

}