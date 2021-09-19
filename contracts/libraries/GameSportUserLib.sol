//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title GameSportUserLib
 *
 * @author PandaFarm
 */
library GameSportUserLib {


    struct GameSportUserData {
        //User address
        address userAddress;
        //TokenId of NFT
        uint256 tokenId;
        //The height of the last restricted block for the user to participate in the competition
        uint256 lastBlockHeight;
        //Users have participated in sessions from the height of the last restricted block so far
        uint256 joinTime;
    }

    event GameSportUserDataInit(uint256 blockHeight, address indexed userAddress, uint256 tokenId, uint256 joinTime);

    function initUserGlobal(
        GameSportUserLib.GameSportUserData storage _self,
        address _userAddress,
        uint256 _tokenId,
        uint256 _blockHeight,
        uint256 _joinTime
    ) internal {
        _self.userAddress = _userAddress;
        _self.tokenId = _tokenId;
        _self.lastBlockHeight = _blockHeight;
        _self.joinTime = _joinTime;

        emit GameSportUserDataInit(_blockHeight, _userAddress, _tokenId, _joinTime);
    }


}