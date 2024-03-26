// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FullMath} from "./FullMath.sol";

/// @title PriceConverter
/// @notice Provides functions to perform price conversions

library PriceConverter {
	function derive(
		uint256 basePrice,
		uint256 quotePrice,
		uint8 priceDecimals,
		uint8 assetDecimals
	) internal pure returns (uint256 derived) {
		unchecked {
			if (basePrice != 0 && quotePrice != 0) {
				derived = FullMath.mulDiv(
					scale(basePrice, priceDecimals, assetDecimals),
					10 ** assetDecimals,
					scale(quotePrice, priceDecimals, assetDecimals)
				);
			}
		}
	}

	function inverse(
		uint256 price,
		uint8 baseDecimals,
		uint8 quoteDecimals
	) internal pure returns (uint256 inversed) {
		assembly ("memory-safe") {
			if gt(price, 0x00) {
				inversed := div(exp(10, add(baseDecimals, quoteDecimals)), price)
			}
		}
	}

	function scale(
		uint256 price,
		uint8 priceDecimals,
		uint8 assetDecimals
	) internal pure returns (uint256 scaled) {
		assembly ("memory-safe") {
			switch or(iszero(price), eq(priceDecimals, assetDecimals))
			case 0x00 {
				switch lt(priceDecimals, assetDecimals)
				case 0x00 {
					scaled := div(price, exp(10, sub(priceDecimals, assetDecimals)))
				}
				default {
					scaled := mul(price, exp(10, sub(assetDecimals, priceDecimals)))
				}
			}
			default {
				scaled := price
			}
		}
	}
}
