// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ChainLinkResolver} from "src/ChainLinkResolver.sol";
import {FraxETHPriceFeed} from "src/feeds/FraxETHPriceFeed.sol";
import {FRXETHPriceFeed} from "src/feeds/FRXETHPriceFeed.sol";
import {SFRXETHExchangeRateFeed} from "src/feeds/SFRXETHExchangeRateFeed.sol";
import {SFRXETHPriceFeed} from "src/feeds/SFRXETHPriceFeed.sol";
import {WSTETHExchangeRateFeed} from "src/feeds/WSTETHExchangeRateFeed.sol";
import {WSTETHPriceFeed} from "src/feeds/WSTETHPriceFeed.sol";
import {Constants} from "./Constants.sol";

abstract contract Deployer is Test, Constants {
	ChainLinkResolver resolver;
	FraxETHPriceFeed fraxETHFeed;
	FRXETHPriceFeed frxETHFeed;
	SFRXETHPriceFeed sfrxETHFeed;
	SFRXETHExchangeRateFeed sfrxETHRateFeed;
	WSTETHPriceFeed wstETHFeed;
	WSTETHExchangeRateFeed wstETHRateFeed;

	function fork(bool forkOnBlock) internal {
		if (forkOnBlock) {
			vm.createSelectFork(vm.envString("RPC_ETHEREUM"), FORK_BLOCK);
		} else {
			vm.createSelectFork(vm.envString("RPC_ETHEREUM"));
		}
	}

	function deployAll() internal {
		resolver = deployResolver();

		(fraxETHFeed, frxETHFeed, sfrxETHFeed, sfrxETHRateFeed) = deployFrxETHFeeds();

		(wstETHFeed, wstETHRateFeed) = deployWstETHFeeds();
	}

	function deployResolver() internal returns (ChainLinkResolver) {
		return new ChainLinkResolver(WETH, ETH_USD_FEED, WBTC, BTC_USD_FEED, USDC, USDC_USD_FEED);
	}

	function deployFrxETHFeeds()
		internal
		returns (FraxETHPriceFeed, FRXETHPriceFeed, SFRXETHPriceFeed, SFRXETHExchangeRateFeed)
	{
		return (
			new FraxETHPriceFeed(WETH, FRXETH, FRXETH_CRV, ETH_USD_FEED),
			new FRXETHPriceFeed(WETH, FRXETH, FRXETH_CRV),
			new SFRXETHPriceFeed(WETH, FRXETH, SFRXETH, FRXETH_CRV),
			new SFRXETHExchangeRateFeed(SFRXETH)
		);
	}

	function deployWstETHFeeds() internal returns (WSTETHPriceFeed, WSTETHExchangeRateFeed) {
		return (new WSTETHPriceFeed(STETH, WSTETH, STETH_ETH_FEED), new WSTETHExchangeRateFeed(WSTETH));
	}

	function registerAll() internal {
		resolver.register(ETH_BTC_FEED, ETH, BTC, true);

		resolver.register(BTC_ETH_FEED, BTC, ETH, true);

		resolver.register(USDC_ETH_FEED, USDC, ETH, true);

		resolver.register(USDT_ETH_FEED, USDT, ETH, true);
		resolver.register(USDT_USD_FEED, USDT, USD, true);

		resolver.register(LINK_ETH_FEED, LINK, ETH, true);
		resolver.register(LINK_USD_FEED, LINK, USD, true);

		resolver.register(FRAX_ETH_FEED, FRAX, ETH, true);
		resolver.register(FRAX_USD_FEED, FRAX, USD, true);

		resolver.register(FXS_USD_FEED, FXS, USD, true);

		resolver.register(address(frxETHFeed), FRXETH, ETH, true);
		resolver.register(address(fraxETHFeed), FRXETH, USD, true);
		resolver.register(address(sfrxETHFeed), SFRXETH, ETH, true);
		resolver.register(address(sfrxETHRateFeed), SFRXETH, FRXETH, true);

		resolver.register(STETH_ETH_FEED, STETH, ETH, true);
		resolver.register(STETH_USD_FEED, STETH, USD, true);

		resolver.register(address(wstETHRateFeed), WSTETH, STETH, true);
		resolver.register(address(wstETHFeed), WSTETH, ETH, true);
	}
}
