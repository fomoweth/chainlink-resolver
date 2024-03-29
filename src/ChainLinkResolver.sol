// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IChainLinkResolver} from "src/interfaces/IChainLinkResolver.sol";
import {Bytes32Lib} from "src/libraries/Bytes32Lib.sol";
import {ChainLinkLib} from "src/libraries/ChainLinkLib.sol";
import {Denominations} from "src/libraries/Denominations.sol";
import {Errors} from "src/libraries/Errors.sol";
import {PriceConverter} from "src/libraries/PriceConverter.sol";
import {Bitmap} from "src/types/Bitmap.sol";
import {Owned} from "./Owned.sol";

/// @title ChainLinkResolver
/// @notice A registry contract of ChainLink type of oracle contracts that can provide the price data for multiple feeds

contract ChainLinkResolver is IChainLinkResolver, Owned {
	using Bytes32Lib for address;
	using Bytes32Lib for bytes32;
	using ChainLinkLib for address;
	using Denominations for address;
	using Errors for address;
	using Errors for bytes32;
	using PriceConverter for uint256;

	mapping(address base => mapping(address quote => bytes32 feed)) internal _feeds;
	mapping(address asset => Bitmap configuration) internal _assetConfigs;
	mapping(address asset => uint8 id) internal _assetIds;
	mapping(uint256 id => address asset) internal _assets;

	uint8 internal _numAssets;

	address public immutable WETH;
	address public immutable WBTC;
	address public immutable USDC;

	uint8 internal constant MAX_ASSETS = 255;
	uint8 internal constant MAX_HOP = 4;

	constructor(
		address weth,
		address ethToUsd,
		address wbtc,
		address btcToUsd,
		address usdc,
		address usdcToUsd
	) {
		_register(ethToUsd, unwrap(WETH = weth.verifyContract()), Denominations.USD);
		_register(btcToUsd, unwrap(WBTC = wbtc.verifyContract()), Denominations.USD);
		_register(usdcToUsd, unwrap(USDC = usdc.verifyContract()), Denominations.USD);
	}

	function register(address feed, address base, address quote, bool overwrite) external onlyOwner {
		// verify that given base and quote are not identical nor zero addresses and unwrap if neccessary
		if ((base = unwrap(base)) == (quote = unwrap(quote))) revert Errors.IdenticalAddresses();

		// verify that feed does not exist for given base and quote when it's not overwriting
		if (!overwrite && !_feeds[base][quote].isZero()) revert Errors.ExistsAlready();

		// verify that given feed is a contract then register
		_register(feed.verifyContract(), base, quote);
	}

	function deregister(address base, address quote) external onlyOwner {
		// verify that given base and quote are not identical nor zero addresses and unwrap if neccessary
		if ((base = unwrap(base)) == (quote = unwrap(quote))) revert Errors.IdenticalAddresses();

		// get the bitmap configurations of both base and quote; revert if empty
		Bitmap baseConfig = _assetConfigs[base].verifyNotZero();
		Bitmap quoteConfig = _assetConfigs[quote].verifyNotZero();

		// get the ids of both base and quote
		uint8 baseId = _assetIds[base];
		uint8 quoteId = _assetIds[quote];

		// verify that base and quote exist on each other's configuration
		if (!baseConfig.get(quoteId)) revert Errors.NotExists("base");
		if (!quoteConfig.get(baseId)) revert Errors.NotExists("quote");

		// update the configurations
		_assetConfigs[base] = baseConfig.set(quoteId, false);
		_assetConfigs[quote] = quoteConfig.set(baseId, false);

		// verify that feed exists
		bytes32 feed = _feeds[base][quote].verifyNotZero("feed");

		// remove the feed from mapping
		delete _feeds[base][quote];

		// emit event
		emit FeedDeregistered(feed.toAddress(), base, quote);
	}

	function _register(address feed, address base, address quote) internal {
		// get the bitmap configurations of both base and quote
		Bitmap baseConfig = _assetConfigs[base];
		Bitmap quoteConfig = _assetConfigs[quote];

		// get the ids of both base and quote; register the asset if not exists
		uint8 baseId = baseConfig.isEmpty() ? _registerAsset(base) : _assetIds[base];
		uint8 quoteId = quoteConfig.isEmpty() ? _registerAsset(quote) : _assetIds[quote];

		// update the configurations
		_assetConfigs[base] = baseConfig.set(quoteId, true);
		_assetConfigs[quote] = quoteConfig.set(baseId, true);

		// encode the feed configuration and store
		_feeds[base][quote] = feed.verifyContract().pack(baseId, quoteId, base.decimals(), quote.decimals());

		// emit event
		emit FeedRegistered(feed, base, quote);
	}

	function _registerAsset(address asset) internal returns (uint8 id) {
		// revert if the number of stored assets reaches max limit
		if ((id = numAssets()) > MAX_ASSETS) revert Errors.ExceededMaxLimit();

		// store the asset to the mappings
		_assets[id] = asset;
		_assetIds[asset] = id;

		// increment the number of stored assets
		unchecked {
			_numAssets = id + 1;
		}

		// emit event
		emit AssetRegistered(asset, id);
	}

	function query(address base, address quote) external view returns (bytes32[] memory, uint256) {
		// verify that given base and quote are not identical nor zero addresses and unwrap if neccessary
		if ((base = unwrap(base)) == (quote = unwrap(quote))) revert Errors.IdenticalAddresses();

		// initialize the path with the length of max limit; unused elements will be removed at the end of the iteration
		return _query(base, quote, 0, 0, 0, new bytes32[](MAX_HOP));
	}

	function _query(
		address base,
		address quote,
		uint256 acc,
		uint8 unit,
		uint8 i,
		bytes32[] memory cached
	) internal view returns (bytes32[] memory, uint256) {
		if (i != 0) {
			// revert if the number of iteration reaches max limit
			if (i == MAX_HOP) revert Errors.ExceededMaxLimit();

			// revert if invalid price data were stored from previous iteration
			if (acc == 0) revert Errors.ZeroValue("acc");
			if (unit == 0) revert Errors.ZeroValue("unit");
		}

		// assign quote to the destination
		address destination = quote;

		// query and cache path at current index for given base and quote
		if ((cached[i] = _queryFeed(base, quote)).isZero()) {
			// determine whether the intersection feed for base and quote exists or not
			Bitmap baseBitmap = _assetConfigs[base].verifyNotZero();
			Bitmap quoteBitmap = _assetConfigs[quote].verifyNotZero();
			Bitmap intersection = baseBitmap.and(quoteBitmap);

			// find the asset associated with either both base & quote or base alone, then replace quote with it
			quote = _assets[!intersection.isEmpty() ? intersection.getFirst() : baseBitmap.getFirst()];

			// cache new path and overwrite at current index
			cached[i] = _queryFeed(base, quote).verifyNotZero("feed");
		}

		// accumulate the answer
		acc = reducer(i, cached[i], base, quote, acc, unit);

		if (destination != quote) {
			// move onto the next iteration
			return _query(quote, destination, acc, quote.decimals(), i + 1, cached);
		} else {
			// slice cached path if it contains unused elements by reducing its length
			assembly ("memory-safe") {
				if lt(i, MAX_HOP) {
					mstore(cached, add(i, 0x01))
				}
			}

			// return cached path and accumulated answer
			return (cached, acc);
		}
	}

	function reducer(
		uint8 i,
		bytes32 data,
		address base,
		address quote,
		uint256 acc,
		uint8 unit
	) internal view returns (uint256 answer) {
		// decode the feed configuration
		(address feed, uint8 baseId, uint8 quoteId, uint8 baseDecimals, uint8 quoteDecimals) = data.unpack();

		// determine whether the reversed price is desired or not
		bool reversed;

		if (i != 0) {
			// swap asset positions if current index of the iteration is not equal to 0
			reversed = _assetIds[quote] == quoteId && _assetIds[base] == baseId;
		} else {
			reversed = _assetIds[base] == quoteId && _assetIds[quote] == baseId;
		}

		// fetch the current price from feed and inverse if neccessary
		answer = reversed ? feed.latestAnswer().inverse(quoteDecimals, baseDecimals) : feed.latestAnswer();

		if (acc != 0) {
			// derive the accumulated answer from prices fetched currently and passed from previous iteration
			answer = acc.derive(answer, unit, reversed ? baseDecimals : quoteDecimals, quote.decimals());
		}
	}

	function numAssets() public view returns (uint8) {
		return _numAssets;
	}

	function fetch(address feed) external view returns (uint256) {
		return feed.latestAnswer();
	}

	function getAsset(uint8 id) external view returns (address) {
		return _assets[id];
	}

	function getAssetId(address asset) external view returns (uint8) {
		return _assetIds[unwrap(asset)];
	}

	function getConfiguration(address asset) external view returns (Bitmap) {
		return _assetConfigs[unwrap(asset)];
	}

	function getFeed(address base, address quote) external view returns (bytes32) {
		// verify that given base and quote are not identical nor zero addresses and unwrap if neccessary
		if ((base = unwrap(base)) == (quote = unwrap(quote))) revert Errors.IdenticalAddresses();

		return _feeds[base][quote];
	}

	function _queryFeed(address base, address quote) internal view returns (bytes32 feed) {
		// get feed configuration for given base and quote; swap positions if not exists
		if ((feed = _feeds[base][quote]) == bytes32(0)) feed = _feeds[quote][base];
	}

	function unwrap(address asset) internal view returns (address) {
		// unwrap if given asset is either equal to WETH or WBTC then verify is not zero address
		if (asset == WETH) asset = Denominations.ETH;
		else if (asset == WBTC) asset = Denominations.BTC;

		return asset.verifyNotZero("unwrapped");
	}
}
