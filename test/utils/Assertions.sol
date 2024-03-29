// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Bytes32Lib} from "src/libraries/Bytes32Lib.sol";
import {Denominations} from "src/libraries/Denominations.sol";
import {Errors} from "src/libraries/Errors.sol";
import {PercentageMath} from "src/libraries/PercentageMath.sol";
import {SafeCast} from "src/libraries/SafeCast.sol";
import {Bitmap} from "src/types/Bitmap.sol";
import {Owned} from "src/Owned.sol";
import {Deployer} from "./Deployer.sol";

abstract contract Assertions is Deployer {
	using Bytes32Lib for address;
	using Bytes32Lib for bytes32;
	using Denominations for address;
	using PercentageMath for uint256;
	using SafeCast for uint256;

	address immutable invalidSigner = makeAddr("InvalidSender");

	bytes callerErr = abi.encodeWithSelector(Owned.InvalidCaller.selector, invalidSigner);
	bytes feedErr = abi.encodeWithSelector(Errors.ZeroBytes32.selector, "feed");
	bytes bitmapErr = abi.encodeWithSelector(Errors.ZeroValue.selector, "bitmap");

	function assertFeed(address base, address quote, address feedExpected) internal view {
		(address feed, uint8 baseId, uint8 quoteId, uint8 baseDecimals, uint8 quoteDecimals) = resolver
			.getFeed(base, quote)
			.unpack();

		Bitmap baseMap = resolver.getConfiguration(base);
		Bitmap quoteMap = resolver.getConfiguration(quote);

		assertEq(feed, feedExpected);
		assertEq(feed.decimals(), quoteDecimals);

		assertEq(base, resolver.getAsset(baseId));
		assertEq(base.decimals(), baseDecimals);

		assertEq(quote, resolver.getAsset(quoteId));
		assertEq(quote.decimals(), quoteDecimals);

		assertFalse(baseMap.isEmpty());
		assertTrue(baseMap.get(quoteId));

		assertFalse(quoteMap.isEmpty());
		assertTrue(quoteMap.get(baseId));
	}

	function assertQuery(
		address base,
		address quote,
		bytes32[] memory pathExpected,
		uint256 answerExpected,
		bool snapshot,
		uint256 snapshotId
	) internal {
		(bytes32[] memory path, uint256 answer) = resolver.query(base, quote);

		if (pathExpected.length != 0) assertEq(path, pathExpected);

		if (answerExpected != 0) assertCloseTo(answer, answerExpected, 10);
		else assertGt(answer, 0);

		for (uint256 i; i < path.length; ++i) {
			(address feed, uint8 baseId, uint8 quoteId, uint8 baseDecimals, uint8 quoteDecimals) = path[i]
				.unpack();

			address baseAsset = resolver.getAsset(baseId);
			address quoteAsset = resolver.getAsset(quoteId);

			assertNotEq(feed, address(0));
			assertEq(feed.decimals(), quoteDecimals);
			assertEq(baseAsset.decimals(), baseDecimals);
			assertEq(quoteAsset.decimals(), quoteDecimals);

			if (i == 0) {
				assertTrue(base == baseAsset || base == quoteAsset);
			} else if (i == path.length - 1) {
				assertTrue(quote == baseAsset || quote == quoteAsset);
			}
		}

		if (snapshot) vm.revertTo(snapshotId);
	}

	function assertQuery(
		address base,
		address quote,
		uint256 answerExpected,
		bool snapshot,
		uint256 snapshotId
	) internal {
		assertQuery(base, quote, new bytes32[](0), answerExpected, snapshot, snapshotId);
	}

	function assertQuery(address base, address quote, uint256 answerExpected) internal {
		assertQuery(base, quote, answerExpected, false, 0);
	}

	function expectRevert(address base, address quote, bytes memory revertSig) internal {
		vm.expectRevert(revertSig);
		resolver.query(base, quote);
	}

	function assertCloseTo(uint256 result, uint256 expected, uint256 bips) internal pure {
		assertTrue(closeTo(result, expected, bips));
	}

	function closeTo(uint256 a, uint256 b, uint256 bips) internal pure returns (bool) {
		if (a == b) return true;

		uint256 maxDelta = a.percentMul(bips);
		uint256 delta = abs(a.toInt256() - b.toInt256());

		return maxDelta >= delta;
	}

	function abs(int256 n) internal pure returns (uint256) {
		unchecked {
			return uint256(n < 0 ? -n : n);
		}
	}
}
