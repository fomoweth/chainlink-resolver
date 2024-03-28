// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Bytes32Lib
/// @notice Provides functions to encode and decode feed configuration

library Bytes32Lib {
	function pack(
		address feed,
		uint8 baseId,
		uint8 quoteId,
		uint8 baseDecimals,
		uint8 quoteDecimals
	) internal pure returns (bytes32 data) {
		assembly ("memory-safe") {
			data := add(
				feed,
				add(
					shl(160, baseId),
					add(shl(168, quoteId), add(shl(176, baseDecimals), shl(184, quoteDecimals)))
				)
			)
		}
	}

	function unpack(
		bytes32 data
	)
		internal
		pure
		returns (address feed, uint8 baseId, uint8 quoteId, uint8 baseDecimals, uint8 quoteDecimals)
	{
		assembly ("memory-safe") {
			feed := and(data, 0xffffffffffffffffffffffffffffffffffffffff)
			baseId := and(shr(160, data), 0xff)
			quoteId := and(shr(168, data), 0xff)
			baseDecimals := and(shr(176, data), 0xff)
			quoteDecimals := and(shr(184, data), 0xff)
		}
	}

	function toAddress(bytes32 data) internal pure returns (address res) {
		assembly ("memory-safe") {
			res := data
		}
	}

	function isZero(bytes32 data) internal pure returns (bool res) {
		assembly ("memory-safe") {
			res := iszero(data)
		}
	}
}
