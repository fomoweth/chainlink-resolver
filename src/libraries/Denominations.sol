// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Denominations
/// @notice A library for handling currency identifiers

library Denominations {
	address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
	address internal constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
	address internal constant USD = 0x0000000000000000000000000000000000000348;

	function decimals(address target) internal view returns (uint8 unit) {
		assembly ("memory-safe") {
			switch eq(target, ETH)
			case 0x00 {
				switch or(eq(target, USD), eq(target, BTC))
				case 0x00 {
					let ptr := mload(0x40)

					mstore(ptr, 0x313ce56700000000000000000000000000000000000000000000000000000000)

					if iszero(staticcall(gas(), target, ptr, 0x04, 0x00, 0x20)) {
						returndatacopy(ptr, 0x00, returndatasize())
						revert(ptr, returndatasize())
					}

					unit := mload(0x00)
				}
				default {
					unit := 8 // equivalent to decimals of BTC and USD ChainLink Aggregators
				}
			}
			default {
				unit := 18 // equivalent to decimals of ETH and ETH ChainLink Aggregators
			}
		}
	}
}
