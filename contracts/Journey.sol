// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./external/libraries/TransferHelper.sol";

import "./interfaces/ITaxHelper.sol";
import "./interfaces/IMigrate.sol";
import "./MultiSig.sol";

/**
 * @dev
 */
contract Journey is ERC20, MultiSig, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public buyTax;
    uint256 public sellTax;
    bool public taxesOn;

    ITaxHelper public taxHelper;

    EnumerableSet.AddressSet private taxableHolders;

    constructor(address _taxHelper, address _deployer)
        ERC20("$Journey", "$Journey")
    {
        taxHelper = ITaxHelper(_taxHelper);
        _mint(_deployer, 1000000 * 10**decimals());
    }

    function updateTaxHelperAddress(address _taxHelper) external requireQuorum {
        require(_taxHelper != address(0), "nopeitty nope");
        taxHelper = ITaxHelper(_taxHelper);
    }

    function updateTaxableHolders(address _address, bool _add)
        external
        requireQuorum
    {
        if (_add) {
            taxableHolders.add(_address);
        } else {
            taxableHolders.remove(_address);
        }
    }

    function switchTaxes() external requireQuorum {
        taxesOn = !taxesOn;
    }

    function updateTaxes(uint256 _buyTax, uint256 _sellTax)
        external
        requireQuorum
    {
        buyTax = _buyTax;
        sellTax = _sellTax;
    }

    function isTransferTaxable(address _from, address _to)
        private
        view
        returns (bool)
    {
        return (!(taxableHolders.contains(_from) ||
            taxableHolders.contains(_to)) && taxesOn);
    }

    function transfer(address _to, uint256 _amount)
        public
        override
        returns (bool)
    {
        // what to do here?
        return super.transfer(_to, _amount);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public override returns (bool) {
        uint256 amountAfterTax = _amount;
        if (isTransferTaxable(_from, _to)) {
            uint256 taxSize = taxableHolders.contains(_from) ? buyTax : sellTax;
            uint256 taxedAmount = (_amount * 1000) / taxSize;
            amountAfterTax = _amount - taxedAmount;
            super.transfer(address(taxHelper), taxedAmount);
            taxHelper.handleTax(taxedAmount);
        }
        return super.transferFrom(_from, _to, amountAfterTax);
    }
}
