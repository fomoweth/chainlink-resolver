// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IChainLinkFeed {
	function latestRoundData()
		external
		view
		returns (
			uint80 roundId,
			uint256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		);

	function latestAnswer() external view returns (uint256);

	function latestTimestamp() external view returns (uint256);

	function latestRound() external view returns (uint256);

	function decimals() external view returns (uint8);

	function description() external view returns (string memory);

	function version() external view returns (uint256);
}
