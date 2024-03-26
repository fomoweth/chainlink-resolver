// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SafeCast
/// @notice Contains methods for safely casting between types
/// @dev Implementation from https://github.com/Uniswap/v4-core/blob/main/src/libraries/SafeCast.sol

library SafeCast {
	error SafeCastFailed();

	function toUint16(uint256 value) internal pure returns (uint16 casted) {
		if ((casted = uint16(value)) != value) revert SafeCastFailed();
	}

	function toUint64(uint256 value) internal pure returns (uint64 casted) {
		if ((casted = uint64(value)) != value) revert SafeCastFailed();
	}

	function toUint80(uint256 value) internal pure returns (uint80 casted) {
		if ((casted = uint80(value)) != value) revert SafeCastFailed();
	}

	function toUint96(uint256 value) internal pure returns (uint96 casted) {
		if ((casted = uint96(value)) != value) revert SafeCastFailed();
	}

	function toUint128(uint256 value) internal pure returns (uint128 casted) {
		if ((casted = uint128(value)) != value) revert SafeCastFailed();
	}

	function toUint160(uint256 value) internal pure returns (uint160 casted) {
		if ((casted = uint160(value)) != value) revert SafeCastFailed();
	}

	function toUint256(int256 value) internal pure returns (uint256 casted) {
		if (int256(casted = uint256(value)) < 0) revert SafeCastFailed();
	}

	function toInt256(uint256 value) internal pure returns (int256 casted) {
		if (uint256(casted = int256(value)) > uint256(type(int256).max)) revert SafeCastFailed();
	}
}
