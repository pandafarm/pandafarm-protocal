//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../access/OperatorAccessControl.sol";
import "../tokenization/PandaFarm721.sol";
import "../tokenization/BambooERC20.sol";
import "../core/DataProvider.sol";
import "../libraries/GameMiningRewardLib.sol";


contract GameMiningRewardConfigV1 is OperatorAccessControl {

    using GameMiningRewardLib for GameMiningRewardLib.RewardData;

    event DataProviderUpdated(address indexed addr);
    event GameMiningRewardSendReward(address indexed rewardAddress,uint256 rewardBalance,uint256 maxRewardBalance);

    DataProvider internal dataProvider;

    //Different reward pool configurations
    mapping(address => GameMiningRewardLib.RewardData) internal address2RewardData;

    event GameMiningRewardConfigChange(
        address indexed rewardAddress,
        uint256 maxRewardBalancePerUnit,
        uint256 blockPerUnit,
        uint256 maxRewardBalance,
        bool isActive);

    event GameMiningRewardUpdated(
        uint256 tokenId,
        uint256 exp,
        uint256 stamina,
        uint256 tooth,
        uint256 digestion);
    constructor(address dataProvider_) {
        dataProvider = DataProvider(dataProvider_);
    }

    function update(
        address _rewardAddress,
        uint256 _rewardBalancePerUnit,
        uint256 _blockPerUnit,
        uint256 _maxRewardBalance,
        bool _isActive
    ) public isOperatorOrOwner {
        require(_rewardAddress != address(0), "The user address cannot be a 0x address");

        if (address2RewardData[_rewardAddress].rewardAddress == address(0)) {
            address2RewardData[_rewardAddress].
            init(_rewardAddress, _rewardBalancePerUnit, _blockPerUnit, _maxRewardBalance, _isActive);
        } else {
            address2RewardData[_rewardAddress]
            .update(_rewardBalancePerUnit, _blockPerUnit, _maxRewardBalance, _isActive);
        }

        emit GameMiningRewardConfigChange(_rewardAddress, _rewardBalancePerUnit, _blockPerUnit, _maxRewardBalance, _isActive);
    }

    /**
    * Send rewards to the game contract address
    */
    function sendReward(
        address _rewardAddress
    ) public isOperatorOrOwner {
        require(_rewardAddress != address(0), "The user address cannot be a 0 address");
        IERC20 _bambooERC20 = IERC20(dataProvider.getTokenBambooAddress());
        uint256 rewardBalance = address2RewardData[_rewardAddress].getReward();
        //The number of awards cannot exceed the upper limit
        uint256 maxReward = address2RewardData[_rewardAddress].maxRewardBalance;
        rewardBalance = rewardBalance > maxReward ? maxReward : rewardBalance;
        _bambooERC20.transfer(_rewardAddress, rewardBalance);
        emit GameMiningRewardSendReward(_rewardAddress,rewardBalance,maxReward);
    }

    function setDataProvider(address _addr) public isOperatorOrOwner {
        dataProvider = DataProvider(_addr);
        emit DataProviderUpdated(_addr);
    }

    function getDataProvider() public view returns (address) {
        return address(dataProvider);
    }


}