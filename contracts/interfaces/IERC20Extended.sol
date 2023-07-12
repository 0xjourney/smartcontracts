// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Extension of the ERC20 standard as defined in the EIP. Adds the decimals() function to perform normalized math.
 */
interface IERC20Extended is IERC20 {
    /**
     * @dev Returns the number of decimals places
     */
    function decimals() external view returns (uint8);
}
