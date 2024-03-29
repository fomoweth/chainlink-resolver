// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IChainLinkFeed} from "src/interfaces/IChainLinkFeed.sol";
import {Errors} from "src/libraries/Errors.sol";

/// @title WSTETHExchangeRateFeed
/// @notice Provides the exchange rate between wstETH / stETH, fetched from wstETH

contract WSTETHExchangeRateFeed is IChainLinkFeed {
	using Errors for address;

	address public immutable WSTETH;

	constructor(address wstETH) {
		WSTETH = wstETH.verifyNotZero("wstETH");
	}

	function latestRoundData() external view returns (uint80, uint256, uint256, uint256, uint80) {
		return (1, stEthPerToken(WSTETH), blockTimestamp(), blockTimestamp(), 1);
	}

	function latestAnswer() external view returns (uint256) {
		return stEthPerToken(WSTETH);
	}

	function latestTimestamp() external view returns (uint256) {
		return blockTimestamp();
	}

	function latestRound() external pure returns (uint256) {
		return 1;
	}

	function decimals() external pure returns (uint8) {
		return 18;
	}

	function description() external pure returns (string memory) {
		return "WSTETH / STETH";
	}

	function version() external pure returns (uint256) {
		return 1;
	}

	function stEthPerToken(address wstETH) internal view returns (uint256 rate) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x035faf8200000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), wstETH, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			rate := mload(0x00)
		}
	}

	function blockTimestamp() internal view returns (uint40 bts) {
		assembly ("memory-safe") {
			bts := mod(timestamp(), exp(0x02, 0x28))
		}
	}
}
