// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IChainLinkFeed} from "src/interfaces/IChainLinkFeed.sol";
import {ChainLinkLib} from "src/libraries/ChainLinkLib.sol";
import {Errors} from "src/libraries/Errors.sol";
import {PriceConverter} from "src/libraries/PriceConverter.sol";

/// @title WSTETHPriceFeed
/// @notice Provides wstETH / ETH price, computed by using the price fetched from ChainLink stETH / ETH feed and exchange rate between wstETH / stETH provided by wstETH

contract WSTETHPriceFeed is IChainLinkFeed {
	using ChainLinkLib for address;
	using Errors for address;
	using PriceConverter for uint256;

	address public immutable STETH;

	address public immutable WSTETH;

	address public immutable baseFeed;

	constructor(address stETH, address wstETH, address stETHFeed) {
		STETH = stETH.verifyNotZero("stETH");
		WSTETH = wstETH.verifyNotZero("wstETH");
		baseFeed = stETHFeed.verifyNotZero("baseFeed");
	}

	function latestRoundData() external view returns (uint80, uint256, uint256, uint256, uint80) {
		(
			uint80 roundId,
			uint256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		) = baseFeed.latestRoundData();

		return (roundId, convert(answer), startedAt, updatedAt, answeredInRound);
	}

	function latestAnswer() external view returns (uint256) {
		return convert(baseFeed.latestAnswer());
	}

	function latestTimestamp() external view returns (uint256) {
		return baseFeed.latestTimestamp();
	}

	function latestRound() external view returns (uint256) {
		return baseFeed.latestRound();
	}

	function decimals() external pure returns (uint8) {
		return 18;
	}

	function description() external pure returns (string memory) {
		return "WSTETH / ETH";
	}

	function version() external pure returns (uint256) {
		return 1;
	}

	function convert(uint256 feedAnswer) internal view returns (uint256) {
		return stEthPerToken(WSTETH).derive(feedAnswer.inverse(18, 18), 18, 18, 18);
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
}
