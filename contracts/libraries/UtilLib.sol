//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title UtilLib
 *
 * @author PandaFarm
 */
library UtilLib {

    /**
    * @dev returns the address used within the protocol to identify
    * @return the address assigned to Main
     */
    function mainAddress() internal pure returns(address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

}