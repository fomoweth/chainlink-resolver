// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ChainLinkLib
/// @notice Provides functionality of fetching price data from ChainLink Aggregator

library ChainLinkLib {
	function latestRoundData(
		address feed
	)
		internal
		view
		returns (uint80 round, uint256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
	{
		assembly ("memory-safe") {
			let ptr := mload(0x40)
			let res := add(ptr, 0x04)

			mstore(ptr, 0xfeaf968c00000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), feed, ptr, 0x04, res, 0xa0)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			round := mload(res)
			answer := mload(add(res, 0x20))
			startedAt := mload(add(res, 0x40))
			updatedAt := mload(add(res, 0x60))
			answeredInRound := mload(add(res, 0x80))

			if iszero(sgt(answer, 0x00)) {
				invalid()
			}
		}
	}

	function latestAnswer(address feed) internal view returns (uint256 answer) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x50d25bcd00000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), feed, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			answer := mload(0x00)

			if iszero(sgt(answer, 0x00)) {
				invalid()
			}
		}
	}

	function latestTimestamp(address feed) internal view returns (uint256 ts) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x50d25bcd00000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), feed, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			ts := mload(0x00)
		}
	}

	function latestRound(address feed) internal view returns (uint256 roundId) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x668a0f0200000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), feed, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			roundId := mload(0x00)
		}
	}
}
