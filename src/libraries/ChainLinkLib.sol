// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeCast} from "./SafeCast.sol";

/// @title ChainLinkLib
/// @notice Provides functionality of fetching price data from ChainLink Aggregator

library ChainLinkLib {
	using SafeCast for uint256;

	error InvalidRoundId();
	error RoundNotCompleted();

	uint256 internal constant PHASE_OFFSET = 64;
	uint256 internal constant PHASE_SIZE = 16;
	uint256 internal constant MAX_ID = 2 ** (PHASE_OFFSET + PHASE_SIZE) - 1;

	function getNextRoundId(address feed, uint256 roundId) internal view returns (uint80) {
		unchecked {
			(uint16 phase, uint64 aggregatorRoundId) = parseIds(roundId);

			if (getAnswer(feed, addPhase(phase, aggregatorRoundId + 1)) != 0) {
				++aggregatorRoundId;
			} else if (phase < phaseId(feed)) {
				++phase;
				aggregatorRoundId = 1;
			}

			return addPhase(phase, aggregatorRoundId);
		}
	}

	function getPreviousRoundId(address feed, uint256 roundId) internal view returns (uint80) {
		unchecked {
			(uint16 phase, uint64 aggregatorRoundId) = parseIds(roundId);

			if (aggregatorRoundId > 1) {
				--aggregatorRoundId;
			} else if (phase > 1) {
				--phase;
				aggregatorRoundId = latestRound(phaseAggregators(feed, phase)).toUint64();
			}

			return addPhase(phase, aggregatorRoundId);
		}
	}

	function getRoundData(address feed, uint40 timestamp) internal view returns (uint80, uint256) {
		(uint80 maxRoundId, uint256 answer, , uint256 maxUpdatedAt, ) = latestRoundData(feed);

		if (timestamp > maxUpdatedAt) revert RoundNotCompleted();

		uint80 minRoundId = ((uint256(maxRoundId >> PHASE_OFFSET) << PHASE_OFFSET) | 1).toUint80();

		if (minRoundId == maxRoundId) {
			if (answer == 0) revert RoundNotCompleted();
			return (maxRoundId, answer);
		}

		uint256 minUpdatedAt;
		(, answer, , minUpdatedAt, ) = getRoundData(feed, minRoundId);

		(uint80 midRoundId, uint256 midUpdatedAt) = (minRoundId, minUpdatedAt);
		uint256 guard = maxRoundId;

		if (minUpdatedAt >= timestamp && answer > 0 && minUpdatedAt > 0) {
			return (minRoundId, answer);
		} else if (minUpdatedAt < timestamp) {
			while (minRoundId <= maxRoundId) {
				midRoundId = (minRoundId + maxRoundId) / 2;

				(, answer, , midUpdatedAt, ) = getRoundData(feed, midRoundId);

				if (midUpdatedAt < timestamp) {
					minRoundId = midRoundId + 1;
				} else if (midUpdatedAt > timestamp) {
					maxRoundId = midRoundId - 1;
				} else if (answer == 0 || midUpdatedAt == 0) {
					break;
				} else {
					return (midRoundId, answer);
				}
			}
		}

		while (midUpdatedAt < timestamp || answer == 0 || midUpdatedAt == 0) {
			if (midRoundId >= guard) revert InvalidRoundId();

			unchecked {
				midRoundId = midRoundId + 1;
			}

			(, answer, , midUpdatedAt, ) = getRoundData(feed, midRoundId);
		}

		return (midRoundId, answer);
	}

	function getRoundData(
		address feed,
		uint80 roundId
	)
		internal
		view
		returns (uint80 round, uint256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
	{
		assembly ("memory-safe") {
			let ptr := mload(0x40)
			let res := add(ptr, 0x24)

			mstore(ptr, 0x9a6fc8f500000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), roundId)

			if iszero(staticcall(gas(), feed, ptr, 0x24, res, 0xa0)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			if iszero(slt(mload(add(res, 0x20)), 0x00)) {
				answer := mload(add(res, 0x20))
			}

			round := mload(res)
			startedAt := mload(add(res, 0x40))
			updatedAt := mload(add(res, 0x60))
			answeredInRound := mload(add(res, 0x80))
		}
	}

	function getAnswer(address feed, uint80 roundId) internal view returns (uint256 answer) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xb5ab58dc00000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), roundId)

			if iszero(staticcall(gas(), feed, ptr, 0x24, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			if iszero(slt(mload(0x00), 0x00)) {
				answer := mload(0x00)
			}
		}
	}

	function getTimestamp(address feed, uint80 roundId) internal view returns (uint256 ts) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xb5ab58dc00000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), roundId)

			if iszero(staticcall(gas(), feed, ptr, 0x24, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			ts := mload(0x00)
		}
	}

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

	function description(address feed) internal view returns (string memory) {
		bytes memory returndata;

		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x7284e41600000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), feed, ptr, 0x04, 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			mstore(0x40, add(returndata, add(returndatasize(), 0x20)))
			mstore(returndata, returndatasize())
			returndatacopy(add(returndata, 0x20), 0x00, returndatasize())
		}

		return abi.decode(returndata, (string));
	}

	function version(address feed) internal view returns (uint256 res) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x54fd4d5000000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), feed, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			res := mload(0x00)
		}
	}

	function phaseAggregators(address feed, uint16 phase) internal view returns (address aggregator) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xc159730400000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), phase)

			if iszero(staticcall(gas(), feed, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			aggregator := mload(0x00)
		}
	}

	function phaseId(address feed) internal view returns (uint16 phase) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x58303b1000000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), feed, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			phase := mload(0x00)
		}
	}

	function addPhase(uint16 phase, uint64 roundId) private pure returns (uint80) {
		return ((uint256(phase) << PHASE_OFFSET) | roundId).toUint80();
	}

	function parseIds(uint256 roundId) private pure returns (uint16 phase, uint64 aggregatorRoundId) {
		phase = (roundId >> PHASE_OFFSET).toUint16();
		aggregatorRoundId = roundId.toUint64();
	}
}
