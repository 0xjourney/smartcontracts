// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Extension of the ERC20 standard as defined in the EIP. Adds the decimals() function to perform normalized math.
 */
interface IERC721Extended is IERC721 {
    /**
     * @dev Returns the number of decimals places
     */
    function burn(uint256) external;
}
