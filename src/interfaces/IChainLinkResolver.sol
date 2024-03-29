// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Bitmap} from "src/types/Bitmap.sol";

interface IChainLinkResolver {
	event FeedRegistered(address indexed feed, address indexed base, address indexed quote);

	event FeedDeregistered(address indexed feed, address indexed base, address indexed quote);

	event AssetRegistered(address indexed asset, uint8 indexed id);

	function query(address base, address quote) external view returns (bytes32[] memory path, uint256 answer);

	function fetch(address feed) external view returns (uint256);

	function getFeed(address base, address quote) external view returns (bytes32);

	function getAsset(uint8 id) external view returns (address);

	function getAssetId(address asset) external view returns (uint8);

	function getConfiguration(address asset) external view returns (Bitmap);

	function numAssets() external view returns (uint8);

	function register(address feed, address base, address quote, bool force) external;

	function deregister(address base, address quote) external;
}
