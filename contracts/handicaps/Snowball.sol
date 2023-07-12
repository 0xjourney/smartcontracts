// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "../external/libraries/TransferHelper.sol";

import "./Handicap.sol";
import "../interfaces/IHnP.sol";

contract Snowball is Handicap, ERC721 {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public counter;
    uint256 public mintPrice = 15 ether / 100;

    address public immutable treasury;
    address private priceAdmin;

    EnumerableSet.UintSet private nonTransferrableSnowballs;
    mapping(address => bool) private receivedFree3Snowballs;

    modifier onlyTreasury() {
        require(msg.sender == treasury, "forbiddin");
        _;
    }

    // TODO implement random on-screen claimable snowballs
    constructor(
        address _hnp,
        address _nftRegistry,
        address _treasury
    ) ERC721("Snowball", "SNBL") Handicap(_hnp, _nftRegistry, 6 hours, 0, 0) {
        priceAdmin = msg.sender;
        treasury = _treasury;
    }

    /**
     * @notice updates mint price
     */
    function updateMintPrice(uint256 _newPrice) external {
        require(msg.sender == priceAdmin, "bruh");
        mintPrice = _newPrice;
    }

    /**
     * @notice returns true if player can receive a free 3-pack of snowballs for being new to the game
     */
    function canMint3FreeSnowballs() external view returns (bool) {
        return !receivedFree3Snowballs[msg.sender];
    }

    /**
     * @notice mints 3 snowballs for new players for free
     */
    function newPlayer3SnowballMint() external {
        require(!receivedFree3Snowballs[msg.sender], "u already gotten");
        for (uint256 i = 0; i < 3; i++) {
            _mint(msg.sender, counter);
            nftRegistry.registerNewNFT(msg.sender, counter);
            nonTransferrableSnowballs.add(counter);
            counter += 1;
        }
        receivedFree3Snowballs[msg.sender] = true;
    }

    /**
     * @notice for minting 20-pack snowballs
     */
    function mint20Pack() external payable {
        require(msg.value >= mintPrice, "moar pls");
        if (msg.value > mintPrice) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - mintPrice);
        }
        TransferHelper.safeTransferETH(treasury, mintPrice);
        for (uint256 i = 0; i < 20; i++) {
            _mint(msg.sender, counter);
            nftRegistry.registerNewNFT(msg.sender, counter);
            counter += 1;
        }
    }

    function freeMint(address _to) external onlyTreasury {
        _mint(_to, counter);
        nftRegistry.registerNewNFT(msg.sender, counter);
        counter += 1;
    }

    /**
     * @notice mints new handicap NFT
     */
    function mint() external {
        // TODO accept signed txn from off-chain
        _mint(msg.sender, counter);
        nftRegistry.registerNewNFT(msg.sender, counter);
        counter += 1;
    }

    /**
     * @notice deploys handicap targeting player
     */
    function deployHandicap(address _target, uint256 _id) external {
        require(msg.sender != _target, "cannot target self");
        require(ownerOf(_id) == msg.sender, "thou dost not owneth this");
        registerHandicap(_target, msg.sender, _id);
    }

    /**
     * @notice for performing checks before transferring snowball nfts
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(
            !nonTransferrableSnowballs.contains(tokenId),
            "u can not transfer dis"
        );
        nftRegistry.registerNFTTransfer(from, to, tokenId);
    }
}
