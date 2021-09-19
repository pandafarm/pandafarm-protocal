//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title GameSportLib
 *
 * @author PandaFarm
 */
library GameSportLib {

    struct SportUserData {
        //User address
        address userAddress;
        //TokenId of NFT
        uint256 tokenId;
        //User's personal game factor
        uint256 goal;
        //The height of the last restricted block for the user to participate in the competition
        uint256 blockHeight;
        //NFT game attribute of users participating in the competition
        uint256[] attribute;
    }

    struct SportData {
        //The height of the last restricted block for the user to participate in the competition
        uint256 startBlockHeight;
        //Last scroll to the asset balance of the current game
        uint256 lastGameBalance;
        //Total ticket assets of the current competition
        uint256 currentRaceBalance;
        //Number of NFTs currently participating in the competition
        uint256 currentNFTCount;
        //The weather of the current game is due to
        uint256 weatherTotal;
        //isComplete = true means the race has been activated and properly configured
        bool isComplete;
        //First corresponding NFT tokenId
        uint256 firstTokenId;
        //Second corresponding NFT tokenId
        uint256 secondTokenId;
        //Third corresponding NFT tokenId
        uint256 thirdTokenId;
        //First corresponding goal
        uint256 firstGoal;
        //Second corresponding goal
        uint256 secondGoal;
        //Third corresponding goal
        uint256 thirdGoal;
        //FT track information for the current race
        uint256 [] participateUser;
    }

    event SportDataInit(uint256 blockHeight, uint256 lastGameBalance);

    function initSport(
        GameSportLib.SportData storage _self,
        uint256 _blockHeight,
        uint256 _lastGameBalance
    ) internal {
        _self.startBlockHeight = _blockHeight;
        _self.lastGameBalance = _lastGameBalance;
        _self.currentRaceBalance = 0;
        _self.currentNFTCount = 0;
        _self.weatherTotal;
        _self.isComplete = false;
        _self.firstTokenId = 0;
        _self.secondTokenId = 0;
        _self.thirdTokenId = 0;
        _self.firstGoal = 0;
        _self.secondGoal = 0;
        _self.thirdGoal = 0;

        emit SportDataInit(_blockHeight, _lastGameBalance);
    }




}