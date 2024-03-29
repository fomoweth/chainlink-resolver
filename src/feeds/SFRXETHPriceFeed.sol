// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IChainLinkFeed} from "src/interfaces/IChainLinkFeed.sol";
import {Errors} from "src/libraries/Errors.sol";
import {FRXETHPriceFeed} from "./FRXETHPriceFeed.sol";

/// @title SFRXETHPriceFeed
/// @notice Provides sfrxETH / ETH price, computed by using exchange rate between sfrxETH / frxETH provided by sfrxETH and the current price of frxETHCrv pool

contract SFRXETHPriceFeed is IChainLinkFeed, FRXETHPriceFeed {
	using Errors for address;

	address public immutable SFRXETH;

	constructor(
		address wETH,
		address frxETH,
		address sfrxETH,
		address frxETHCrv
	) FRXETHPriceFeed(wETH, frxETH, frxETHCrv) {
		SFRXETH = sfrxETH.verifyNotZero("sfrxETH");
	}

	function description()
		external
		pure
		virtual
		override(IChainLinkFeed, FRXETHPriceFeed)
		returns (string memory)
	{
		return "SFRXETH / ETH";
	}

	function exchangeRate() internal view virtual override returns (uint256) {
		return getDy(frxETHCRV, 1, 0, pricePerShare(SFRXETH));
	}

	function pricePerShare(address sfrxETH) internal view returns (uint256 rate) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x99530b0600000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), sfrxETH, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			rate := mload(0x00)
		}
	}
}
