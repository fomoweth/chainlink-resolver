// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IChainLinkFeed} from "src/interfaces/IChainLinkFeed.sol";
import {ChainLinkLib} from "src/libraries/ChainLinkLib.sol";
import {Errors} from "src/libraries/Errors.sol";
import {PriceConverter} from "src/libraries/PriceConverter.sol";
import {FRXETHPriceFeed} from "./FRXETHPriceFeed.sol";

/// @title FraxETHPriceFeed
/// @notice Provides frxETH / FRAX price computed by using the price fetched from ChainLink FRAX / ETH feed and the exchange rate of frxETHCrv pool

contract FraxETHPriceFeed is IChainLinkFeed, FRXETHPriceFeed {
	using ChainLinkLib for address;
	using Errors for address;
	using PriceConverter for uint256;

	address public immutable baseFeed;

	constructor(
		address wETH,
		address frxETH,
		address frxETHCrv,
		address ETHUSDFeed
	) FRXETHPriceFeed(wETH, frxETH, frxETHCrv) {
		baseFeed = ETHUSDFeed.verifyNotZero("ETH/USD");
	}

	function latestRoundData()
		external
		view
		virtual
		override(IChainLinkFeed, FRXETHPriceFeed)
		returns (uint80, uint256, uint256, uint256, uint80)
	{
		(
			uint80 roundId,
			uint256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		) = baseFeed.latestRoundData();

		return (roundId, exchangeRate(answer), startedAt, updatedAt, answeredInRound);
	}

	function latestAnswer()
		external
		view
		virtual
		override(IChainLinkFeed, FRXETHPriceFeed)
		returns (uint256)
	{
		return exchangeRate(baseFeed.latestAnswer());
	}

	function latestTimestamp()
		external
		view
		virtual
		override(IChainLinkFeed, FRXETHPriceFeed)
		returns (uint256)
	{
		return baseFeed.latestTimestamp();
	}

	function latestRound() external view virtual override(IChainLinkFeed, FRXETHPriceFeed) returns (uint256) {
		return baseFeed.latestRound();
	}

	function exchangeRate(uint256 answer) internal view virtual override returns (uint256) {
		return getDy(frxETHCRV, 1, 0, 1 ether).derive(answer.inverse(18, 8), 18, 18, 8);
	}

	function description()
		external
		pure
		virtual
		override(IChainLinkFeed, FRXETHPriceFeed)
		returns (string memory)
	{
		return "FRXETH / USD";
	}

	function decimals() external pure virtual override(IChainLinkFeed, FRXETHPriceFeed) returns (uint8) {
		return 8;
	}
}
