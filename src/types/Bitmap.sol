// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Errors} from "src/libraries/Errors.sol";

type Bitmap is uint256;

using BitmapLibrary for Bitmap global;

/// @title BitmapLibrary
/// @notice Provides functionality of custom type Bitmap

library BitmapLibrary {
	function set(Bitmap bitmap, uint256 offset, bool value) internal pure returns (Bitmap res) {
		assembly ("memory-safe") {
			switch value
			case 0x00 {
				res := and(bitmap, not(shl(and(offset, 0xff), 0x01)))
			}
			default {
				res := or(bitmap, shl(and(offset, 0xff), 0x01))
			}
		}
	}

	function and(Bitmap a, Bitmap b) internal pure returns (Bitmap res) {
		assembly ("memory-safe") {
			res := and(a, b)
		}
	}

	function get(Bitmap bitmap, uint256 offset) internal pure returns (bool res) {
		assembly ("memory-safe") {
			res := and(bitmap, shl(and(offset, 0xff), 0x01))
		}
	}

	function getFirst(Bitmap bitmap) internal pure returns (uint8 i) {
		assembly ("memory-safe") {
			for {
				let pos := and(bitmap, not(sub(bitmap, 0x01)))
			} gt(pos, 0x01) {
				pos := shr(pos, 0x01)
			} {
				i := add(i, 0x01)
			}
		}
	}

	function isEmpty(Bitmap bitmap) internal pure returns (bool res) {
		assembly ("memory-safe") {
			res := iszero(bitmap)
		}
	}

	function verifyNotZero(Bitmap bitmap) internal pure returns (Bitmap) {
		if (bitmap.isEmpty()) revert Errors.ZeroValue("bitmap");

		return bitmap;
	}
}
