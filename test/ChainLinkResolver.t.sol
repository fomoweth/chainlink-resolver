// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Bytes32Lib} from "src/libraries/Bytes32Lib.sol";
import {ChainLinkLib} from "src/libraries/ChainLinkLib.sol";
import {Denominations} from "src/libraries/Denominations.sol";
import {Errors} from "src/libraries/Errors.sol";
import {PriceConverter} from "src/libraries/PriceConverter.sol";
import {Bitmap} from "src/types/Bitmap.sol";
import {Assertions} from "./utils/Assertions.sol";
import {Bytes32Arrays} from "./utils/Bytes32Arrays.sol";
import {ExchangeRates} from "./utils/ExchangeRates.sol";

contract ChainLinkResolverTest is Assertions {
	using Bytes32Arrays for bytes32;
	using Bytes32Arrays for bytes32[];
	using Bytes32Lib for bytes32;
	using ChainLinkLib for address;
	using Denominations for address;
	using ExchangeRates for address;
	using PriceConverter for uint256;

	function setUp() public {
		fork(true);

		deployAll();
	}

	function testDeployment() public virtual {
		assertEq(resolver.WETH(), WETH);
		assertFeed(ETH, USD, ETH_USD_FEED);

		assertEq(resolver.WBTC(), WBTC);
		assertFeed(BTC, USD, BTC_USD_FEED);

		assertEq(resolver.USDC(), USDC);
		assertFeed(USDC, USD, USDC_USD_FEED);

		assertEq(resolver.numAssets(), 4);
	}

	function testRegister_revertIfNotOwner() public {
		vm.expectRevert(callerErr);

		vm.prank(invalidSigner);

		resolver.register(LINK_ETH_FEED, LINK, ETH, true);
	}

	function testRegister() public {
		resolver.register(LINK_ETH_FEED, LINK, ETH, true);

		assertFeed(LINK, ETH, LINK_ETH_FEED);
		assertEq(resolver.numAssets(), 5);
	}

	function testRegisterAll() public {
		resolver.register(ETH_BTC_FEED, ETH, BTC, true);
		assertFeed(ETH, BTC, ETH_BTC_FEED);

		resolver.register(BTC_ETH_FEED, BTC, ETH, true);
		assertFeed(BTC, ETH, BTC_ETH_FEED);

		resolver.register(USDC_ETH_FEED, USDC, ETH, true);
		assertFeed(USDC, ETH, USDC_ETH_FEED);

		resolver.register(USDT_ETH_FEED, USDT, ETH, true);
		assertFeed(USDT, ETH, USDT_ETH_FEED);

		resolver.register(USDT_USD_FEED, USDT, USD, true);
		assertFeed(USDT, USD, USDT_USD_FEED);

		resolver.register(LINK_ETH_FEED, LINK, ETH, true);
		assertFeed(LINK, ETH, LINK_ETH_FEED);

		resolver.register(LINK_USD_FEED, LINK, USD, true);
		assertFeed(LINK, USD, LINK_USD_FEED);

		resolver.register(FRAX_ETH_FEED, FRAX, ETH, true);
		assertFeed(FRAX, ETH, FRAX_ETH_FEED);

		resolver.register(FRAX_USD_FEED, FRAX, USD, true);
		assertFeed(FRAX, USD, FRAX_USD_FEED);

		resolver.register(FXS_USD_FEED, FXS, USD, true);
		assertFeed(FXS, USD, FXS_USD_FEED);

		resolver.register(address(frxETHFeed), FRXETH, ETH, true);
		assertFeed(FRXETH, ETH, address(frxETHFeed));

		resolver.register(address(fraxETHFeed), FRXETH, USD, true);
		assertFeed(FRXETH, USD, address(fraxETHFeed));

		resolver.register(address(sfrxETHFeed), SFRXETH, ETH, true);
		assertFeed(SFRXETH, ETH, address(sfrxETHFeed));

		resolver.register(address(sfrxETHRateFeed), SFRXETH, FRXETH, true);
		assertFeed(SFRXETH, FRXETH, address(sfrxETHRateFeed));

		resolver.register(STETH_ETH_FEED, STETH, ETH, true);
		assertFeed(STETH, ETH, STETH_ETH_FEED);
		resolver.register(STETH_USD_FEED, STETH, USD, true);

		assertFeed(STETH, USD, STETH_USD_FEED);

		resolver.register(address(wstETHRateFeed), WSTETH, STETH, true);
		assertFeed(WSTETH, STETH, address(wstETHRateFeed));

		resolver.register(address(wstETHFeed), WSTETH, ETH, true);
		assertFeed(WSTETH, ETH, address(wstETHFeed));
	}

	function testDeregister_revertIfNotOwner() public {
		resolver.register(LINK_ETH_FEED, LINK, ETH, true);

		vm.expectRevert(callerErr);

		vm.prank(invalidSigner);

		resolver.deregister(LINK, ETH);
	}

	function testDeregister() public {
		resolver.register(LINK_ETH_FEED, LINK, ETH, true);

		uint8 linkId = resolver.getAssetId(LINK);
		uint8 ethId = resolver.getAssetId(ETH);

		assertNotEq(resolver.getFeed(LINK, ETH), bytes32(0));
		assertTrue(resolver.getConfiguration(LINK).get(ethId));
		assertTrue(resolver.getConfiguration(ETH).get(linkId));

		resolver.deregister(LINK, ETH);

		assertEq(resolver.getFeed(LINK, ETH), bytes32(0));
		assertFalse(resolver.getConfiguration(LINK).get(ethId));
		assertFalse(resolver.getConfiguration(ETH).get(linkId));
	}

	function testQueryForWrappedAssets() public {
		resolver.register(ETH_BTC_FEED, ETH, BTC, true);

		(bytes32[] memory WETHToWBTCPath, uint256 WETHToWBTCAnswer) = resolver.query(WETH, WBTC);
		(bytes32[] memory WETHToBTCPath, uint256 WETHToBTCAnswer) = resolver.query(WETH, BTC);
		(bytes32[] memory ETHToWBTCPath, uint256 ETHToWBTCAnswer) = resolver.query(ETH, WBTC);
		(bytes32[] memory ETHToBTCPath, uint256 ETHToBTCAnswer) = resolver.query(ETH, BTC);

		assertEq(WETHToWBTCPath, WETHToBTCPath);
		assertEq(WETHToBTCPath, ETHToWBTCPath);
		assertEq(ETHToWBTCPath, ETHToBTCPath);

		assertEq(WETHToWBTCAnswer, WETHToBTCAnswer);
		assertEq(WETHToBTCAnswer, ETHToWBTCAnswer);
		assertEq(ETHToWBTCAnswer, ETHToBTCAnswer);
	}

	function testQuery(
		address feed,
		address base,
		address quote,
		bytes32[] memory pathExpected,
		uint256 answerExpected,
		uint256 snapshotId
	) internal {
		vm.revertTo(snapshotId);

		resolver.register(feed, base, quote, true);

		(bytes32[] memory path, uint256 answer) = resolver.query(base, quote);

		if (pathExpected.length != 0) assertEq(path, pathExpected);

		if (answerExpected != 0) assertCloseTo(answer, answerExpected, 10);
		else assertGt(answer, 0);
	}

	function testQueryPrice() public {
		uint256 ethUsdAnswer = ETH_USD_FEED.latestAnswer();
		uint256 ethBtcAnswer = ETH_BTC_FEED.latestAnswer();

		uint256 btcUsdAnswer = BTC_USD_FEED.latestAnswer();
		uint256 btcEthAnswer = BTC_ETH_FEED.latestAnswer();

		uint256 usdcUsdAnswer = USDC_USD_FEED.latestAnswer();
		uint256 usdcEthAnswer = USDC_ETH_FEED.latestAnswer();

		uint256 fraxEthAnswer = FRAX_ETH_FEED.latestAnswer();
		uint256 fraxUsdAnswer = FRAX_USD_FEED.latestAnswer();

		uint256 fxsUsdAnswer = FXS_USD_FEED.latestAnswer();

		uint256 linkEthAnswer = LINK_ETH_FEED.latestAnswer();
		uint256 linkUsdAnswer = LINK_USD_FEED.latestAnswer();

		uint256 snapshotId = vm.snapshot();

		assertQuery(ETH, USD, ethUsdAnswer);
		assertQuery(USD, ETH, ethUsdAnswer.inverse(8, 18));
		assertQuery(ETH, BTC, ethUsdAnswer.derive(btcUsdAnswer, 8, 8, 8));

		assertQuery(BTC, USD, btcUsdAnswer);
		assertQuery(USD, BTC, btcUsdAnswer.inverse(8, 8));
		assertQuery(BTC, ETH, btcUsdAnswer.derive(ethUsdAnswer, 8, 8, 18));

		assertQuery(USDC, USD, usdcUsdAnswer);
		assertQuery(USD, USDC, usdcUsdAnswer.inverse(8, 6));
		assertQuery(USDC, ETH, usdcEthAnswer);

		resolver.register(FRAX_ETH_FEED, FRAX, ETH, true);
		assertQuery(FRAX, ETH, fraxEthAnswer);

		resolver.register(FRAX_USD_FEED, FRAX, USD, true);
		assertQuery(FRAX, USD, fraxUsdAnswer);

		resolver.register(FXS_USD_FEED, FXS, USD, true);
		assertQuery(FXS, USD, fxsUsdAnswer);

		assertQuery(
			FXS,
			ETH,
			Bytes32Arrays.create(resolver.queryFeed(FXS, USD), resolver.queryFeed(ETH, USD)),
			fxsUsdAnswer.derive(ethUsdAnswer, 8, 8, 18),
			false,
			snapshotId
		);

		assertQuery(
			FXS,
			BTC,
			Bytes32Arrays.create(resolver.queryFeed(FXS, USD), resolver.queryFeed(BTC, USD)),
			fxsUsdAnswer.derive(btcUsdAnswer, 8, 8, 8),
			true,
			snapshotId
		);

		resolver.register(LINK_ETH_FEED, LINK, ETH, true);
		assertQuery(LINK, ETH, linkEthAnswer, true, snapshotId);

		resolver.register(LINK_USD_FEED, LINK, USD, true);
		assertQuery(LINK, USD, linkUsdAnswer, true, snapshotId);

		resolver.register(LINK_USD_FEED, LINK, USD, true);

		assertQuery(
			LINK,
			BTC,
			Bytes32Arrays.create(resolver.queryFeed(LINK, USD), resolver.queryFeed(BTC, USD)),
			linkUsdAnswer.derive(btcUsdAnswer, 8, 8, 8),
			true,
			snapshotId
		);

		resolver.register(BTC_ETH_FEED, BTC, ETH, true);
		resolver.register(LINK_ETH_FEED, LINK, ETH, true);

		assertQuery(
			LINK,
			BTC,
			Bytes32Arrays.create(resolver.queryFeed(LINK, ETH), resolver.queryFeed(BTC, ETH)),
			linkEthAnswer.derive(btcEthAnswer, 18, 18, 8),
			true,
			snapshotId
		);

		resolver.register(ETH_BTC_FEED, ETH, BTC, true);
		resolver.register(LINK_ETH_FEED, LINK, ETH, true);

		assertQuery(
			LINK,
			BTC,
			Bytes32Arrays.create(resolver.queryFeed(LINK, ETH), resolver.queryFeed(ETH, BTC)),
			linkEthAnswer.derive(ethBtcAnswer.inverse(8, 18), 18, 18, 8),
			true,
			snapshotId
		);
	}

	function testQueryForFraxETHFeeds() public {
		expectRevert(FRXETH, ETH, bitmapErr);
		expectRevert(SFRXETH, ETH, bitmapErr);
		expectRevert(FRXETH, SFRXETH, bitmapErr);

		resolver.register(FRAX_ETH_FEED, FRAX, ETH, true);
		resolver.register(FRAX_USD_FEED, FRAX, USD, true);
		resolver.register(FXS_USD_FEED, FXS, USD, true);
		resolver.register(LINK_USD_FEED, LINK, USD, true);

		uint256 snapshotId = vm.snapshot();

		resolver.register(address(frxETHFeed), FRXETH, ETH, true);
		resolver.register(address(fraxETHFeed), FRXETH, USD, true);
		resolver.register(address(sfrxETHFeed), SFRXETH, ETH, true);
		resolver.register(address(sfrxETHRateFeed), SFRXETH, FRXETH, true);

		assertQuery(FRXETH, ETH, FRXETH_CRV.getDy(1, 0, 1 ether));
		assertQuery(ETH, FRXETH, FRXETH_CRV.getDy(0, 1, 1 ether));

		assertQuery(SFRXETH, ETH, sfrxETHFeed.latestAnswer());
		assertQuery(ETH, SFRXETH, sfrxETHFeed.latestAnswer().inverse(18, 18));

		assertQuery(SFRXETH, FRXETH, SFRXETH.pricePerShare());
		assertQuery(FRXETH, SFRXETH, SFRXETH.pricePerShare().inverse(18, 18));

		testQueryForFraxETH(ETH, snapshotId);
		testQueryForFraxETH(USD, snapshotId);
		testQueryForFraxETH(BTC, snapshotId);
		testQueryForFraxETH(USDC, snapshotId);
		testQueryForFraxETH(FXS, snapshotId);
		testQueryForFraxETH(LINK, snapshotId);
	}

	function testQueryForFraxETH(address quote, uint256 snapshotId) internal {
		vm.revertTo(snapshotId);

		resolver.register(address(sfrxETHRateFeed), SFRXETH, FRXETH, true);

		if (quote == ETH) {
			resolver.register(address(fraxETHFeed), FRXETH, USD, true);

			testQueryFor(
				FRXETH,
				ETH,
				Bytes32Arrays.create(resolver.queryFeed(FRXETH, USD), resolver.queryFeed(ETH, USD))
			);

			resolver.register(address(frxETHFeed), FRXETH, ETH, true);

			testQueryFor(FRXETH, ETH, Bytes32Arrays.create(resolver.queryFeed(FRXETH, ETH)));

			testQueryFor(
				SFRXETH,
				ETH,
				Bytes32Arrays.create(resolver.queryFeed(SFRXETH, FRXETH), resolver.queryFeed(FRXETH, ETH))
			);

			resolver.register(address(sfrxETHFeed), SFRXETH, ETH, true);

			testQueryFor(SFRXETH, ETH, Bytes32Arrays.create(resolver.queryFeed(SFRXETH, ETH)));
		} else if (quote == USD) {
			resolver.register(address(frxETHFeed), FRXETH, ETH, true);

			testQueryFor(
				FRXETH,
				USD,
				Bytes32Arrays.create(resolver.queryFeed(FRXETH, ETH), resolver.queryFeed(ETH, USD))
			);

			resolver.register(address(sfrxETHFeed), SFRXETH, ETH, true);

			testQueryFor(
				SFRXETH,
				USD,
				Bytes32Arrays.create(resolver.queryFeed(SFRXETH, ETH), resolver.queryFeed(ETH, USD))
			);

			resolver.register(address(fraxETHFeed), FRXETH, USD, true);

			testQueryFor(FRXETH, USD, Bytes32Arrays.create(resolver.queryFeed(FRXETH, USD)));
		} else {
			resolver.register(address(frxETHFeed), FRXETH, ETH, true);

			testQueryFor(
				FRXETH,
				quote,
				Bytes32Arrays.create(
					resolver.queryFeed(FRXETH, ETH),
					resolver.queryFeed(ETH, USD),
					resolver.queryFeed(quote, USD)
				)
			);

			testQueryFor(
				SFRXETH,
				quote,
				Bytes32Arrays.create(
					resolver.queryFeed(SFRXETH, FRXETH),
					resolver.queryFeed(FRXETH, ETH),
					resolver.queryFeed(ETH, USD),
					resolver.queryFeed(quote, USD)
				)
			);

			resolver.register(address(fraxETHFeed), FRXETH, USD, true);

			testQueryFor(
				FRXETH,
				quote,
				Bytes32Arrays.create(resolver.queryFeed(FRXETH, USD), resolver.queryFeed(quote, USD))
			);

			testQueryFor(
				SFRXETH,
				quote,
				Bytes32Arrays.create(
					resolver.queryFeed(SFRXETH, FRXETH),
					resolver.queryFeed(FRXETH, USD),
					resolver.queryFeed(quote, USD)
				)
			);
		}
	}

	function testQueryForFrxETH(
		address base,
		address quote,
		bytes32[] memory pathShort,
		bytes32[] memory pathLong,
		uint256 snapshotId
	) internal {
		vm.revertTo(snapshotId);

		resolver.register(address(frxETHFeed), FRXETH, ETH, true);
		resolver.register(address(sfrxETHFeed), SFRXETH, ETH, true);
		resolver.register(address(sfrxETHRateFeed), SFRXETH, FRXETH, true);

		testQueryFor(base, quote, pathShort);
		testQueryFor(quote, base, pathShort.reverse());

		testQueryFor(base, quote, pathLong);
		testQueryFor(quote, base, pathLong.reverse());
	}

	function testQueryForStETHFeeds() public {
		expectRevert(STETH, ETH, bitmapErr);
		expectRevert(STETH, USD, bitmapErr);
		expectRevert(STETH, WSTETH, bitmapErr);

		resolver.register(address(wstETHRateFeed), WSTETH, STETH, true);

		resolver.register(STETH_ETH_FEED, STETH, ETH, true);
		resolver.register(STETH_USD_FEED, STETH, USD, true);

		assertQuery(WSTETH, STETH, WSTETH.stEthPerToken());
		assertQuery(STETH, WSTETH, WSTETH.tokensPerStEth());

		assertQuery(STETH, ETH, STETH_ETH_FEED.latestAnswer());
		assertQuery(ETH, STETH, STETH_ETH_FEED.latestAnswer().inverse(18, 18));

		assertQuery(STETH, USD, STETH_USD_FEED.latestAnswer());
		assertQuery(USD, STETH, STETH_USD_FEED.latestAnswer().inverse(8, 18));

		testQueryForStETH(
			ETH,
			USD,
			Bytes32Arrays.create(resolver.queryFeed(STETH, ETH)),
			Bytes32Arrays.create(resolver.queryFeed(STETH, USD), resolver.queryFeed(ETH, USD))
		);

		testQueryForStETH(
			USD,
			ETH,
			Bytes32Arrays.create(resolver.queryFeed(STETH, USD)),
			Bytes32Arrays.create(resolver.queryFeed(STETH, ETH), resolver.queryFeed(ETH, USD))
		);

		testQueryForStETH(
			BTC,
			USD,
			Bytes32Arrays.create(resolver.queryFeed(STETH, USD), resolver.queryFeed(BTC, USD)),
			Bytes32Arrays.create(
				resolver.queryFeed(STETH, ETH),
				resolver.queryFeed(ETH, USD),
				resolver.queryFeed(BTC, USD)
			)
		);

		testQueryForStETH(
			USDC,
			USD,
			Bytes32Arrays.create(resolver.queryFeed(STETH, USD), resolver.queryFeed(USDC, USD)),
			Bytes32Arrays.create(
				resolver.queryFeed(STETH, ETH),
				resolver.queryFeed(ETH, USD),
				resolver.queryFeed(USDC, USD)
			)
		);
	}

	function testQueryForStETH(
		address quote,
		address bridge,
		bytes32[] memory pathShort,
		bytes32[] memory pathLong
	) internal {
		uint256 snapshotId = vm.snapshot();

		if (quote != ETH && quote != USD) resolver.deregister(STETH, bridge);
		else resolver.deregister(STETH, quote);

		assertQuery(STETH, quote, pathLong, 0, true, vm.snapshot());
		assertQuery(quote, STETH, pathLong.reverse(), 0, true, snapshotId);

		assertQuery(STETH, quote, pathShort, 0, true, snapshotId);
		assertQuery(quote, STETH, pathShort.reverse(), 0, true, snapshotId);
	}

	function testQueryForWstETHFeeds() public {
		expectRevert(WSTETH, ETH, bitmapErr);
		expectRevert(WSTETH, STETH, bitmapErr);

		uint256 snapshotId = vm.snapshot();

		resolver.register(address(wstETHRateFeed), WSTETH, STETH, true);
		resolver.register(address(wstETHFeed), WSTETH, ETH, true);

		uint256 stethRate = WSTETH.tokensPerStEth();
		uint256 wstethRate = WSTETH.stEthPerToken();

		assertQuery(WSTETH, STETH, wstethRate, false, snapshotId);
		assertQuery(STETH, WSTETH, stethRate, false, snapshotId);

		assertQuery(WSTETH, ETH, wstethRate, false, snapshotId);
		assertQuery(ETH, WSTETH, stethRate, true, snapshotId);

		testQueryForWstETH(ETH, snapshotId);
		testQueryForWstETH(USD, snapshotId);
		testQueryForWstETH(BTC, snapshotId);
		testQueryForWstETH(USDC, snapshotId);

		resolver.register(LINK_USD_FEED, LINK, USD, true);
		testQueryForWstETH(LINK, snapshotId);
	}

	function testQueryForWstETH(address quote, uint256 snapshotId) internal {
		if (quote == ETH) {
			resolver.register(address(wstETHRateFeed), WSTETH, STETH, true);

			resolver.register(STETH_USD_FEED, STETH, USD, true);

			testQueryFor(
				WSTETH,
				ETH,
				Bytes32Arrays.create(
					resolver.queryFeed(WSTETH, STETH),
					resolver.queryFeed(STETH, USD),
					resolver.queryFeed(ETH, USD)
				)
			);

			resolver.register(STETH_ETH_FEED, STETH, ETH, true);

			testQueryFor(
				WSTETH,
				ETH,
				Bytes32Arrays.create(resolver.queryFeed(WSTETH, STETH), resolver.queryFeed(STETH, ETH))
			);

			resolver.register(address(wstETHFeed), WSTETH, ETH, true);

			testQueryFor(WSTETH, ETH, Bytes32Arrays.create(resolver.queryFeed(WSTETH, ETH)));
		} else if (quote == USD) {
			resolver.register(address(wstETHRateFeed), WSTETH, STETH, true);

			resolver.register(STETH_ETH_FEED, STETH, ETH, true);

			testQueryFor(
				WSTETH,
				USD,
				Bytes32Arrays.create(
					resolver.queryFeed(WSTETH, STETH),
					resolver.queryFeed(STETH, ETH),
					resolver.queryFeed(ETH, USD)
				)
			);

			resolver.register(STETH_USD_FEED, STETH, USD, true);

			testQueryFor(
				WSTETH,
				USD,
				Bytes32Arrays.create(resolver.queryFeed(WSTETH, STETH), resolver.queryFeed(STETH, USD))
			);

			resolver.register(address(wstETHFeed), WSTETH, ETH, true);

			testQueryFor(
				WSTETH,
				USD,
				Bytes32Arrays.create(resolver.queryFeed(WSTETH, ETH), resolver.queryFeed(ETH, USD))
			);
		} else {
			resolver.register(address(wstETHRateFeed), WSTETH, STETH, true);

			resolver.register(STETH_ETH_FEED, STETH, ETH, true);

			testQueryFor(
				WSTETH,
				quote,
				Bytes32Arrays.create(
					resolver.queryFeed(WSTETH, STETH),
					resolver.queryFeed(STETH, ETH),
					resolver.queryFeed(ETH, USD),
					resolver.queryFeed(quote, USD)
				)
			);

			resolver.register(STETH_USD_FEED, STETH, USD, true);

			testQueryFor(
				WSTETH,
				quote,
				Bytes32Arrays.create(
					resolver.queryFeed(WSTETH, STETH),
					resolver.queryFeed(STETH, USD),
					resolver.queryFeed(quote, USD)
				)
			);

			address ethFeed;

			uint256 optionalId = vm.snapshot();

			if (quote == BTC) ethFeed = BTC_ETH_FEED;
			else if (quote == LINK) ethFeed = LINK_ETH_FEED;
			else if (quote == USDC) ethFeed = USDC_ETH_FEED;

			if (ethFeed != address(0)) {
				resolver.register(ethFeed, quote, ETH, true);

				testQueryFor(
					WSTETH,
					quote,
					Bytes32Arrays.create(
						resolver.queryFeed(WSTETH, STETH),
						resolver.queryFeed(STETH, ETH),
						resolver.queryFeed(quote, ETH)
					)
				);

				resolver.register(address(wstETHFeed), WSTETH, ETH, true);

				testQueryFor(
					WSTETH,
					quote,
					Bytes32Arrays.create(resolver.queryFeed(WSTETH, ETH), resolver.queryFeed(quote, ETH))
				);

				vm.revertTo(optionalId);
			}

			resolver.register(address(wstETHFeed), WSTETH, ETH, true);

			testQueryFor(
				WSTETH,
				quote,
				Bytes32Arrays.create(
					resolver.queryFeed(WSTETH, ETH),
					resolver.queryFeed(ETH, USD),
					resolver.queryFeed(quote, USD)
				)
			);
		}

		vm.revertTo(snapshotId);
	}

	function testQueryFor(address base, address quote, bytes32[] memory path) internal {
		assertQuery(base, quote, path, 0, false, 0);
		assertQuery(quote, base, path.reverse(), 0, false, 0);
	}
}
