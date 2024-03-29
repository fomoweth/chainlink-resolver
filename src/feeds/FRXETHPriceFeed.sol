// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IChainLinkFeed} from "src/interfaces/IChainLinkFeed.sol";
import {Errors} from "src/libraries/Errors.sol";

/// @title FRXETHPriceFeed
/// @notice Provides the current exchange rate of frxETHCrv pool

contract FRXETHPriceFeed is IChainLinkFeed {
	using Errors for address;

	error InvalidFrxETHCrvPool();

	address public immutable WETH;

	address public immutable FRXETH;

	address public immutable frxETHCRV;

	constructor(address wETH, address frxETH, address frxETHCrv) {
		WETH = wETH.verifyNotZero("WETH");
		FRXETH = frxETH.verifyNotZero("frxETH");
		frxETHCRV = verifyPool(frxETHCrv.verifyNotZero("frxETHCRV"), wETH, frxETH);
	}

	function latestRoundData() external view returns (uint80, uint256, uint256, uint256, uint80) {
		return (1, exchangeRate(), blockTimestamp(), blockTimestamp(), 1);
	}

	function latestAnswer() external view returns (uint256) {
		return exchangeRate();
	}

	function latestTimestamp() external view returns (uint256) {
		return blockTimestamp();
	}

	function latestRound() external pure returns (uint256) {
		return 1;
	}

	function decimals() external pure returns (uint8) {
		return 18;
	}

	function description() external pure virtual returns (string memory) {
		return "FRXETH / ETH";
	}

	function version() external pure returns (uint256) {
		return 1;
	}

	function exchangeRate() internal view virtual returns (uint256) {
		return getDy(frxETHCRV, 1, 0, 1 ether);
	}

	function getDy(address crvPool, uint256 i, uint256 j, uint256 dx) internal view returns (uint256 dy) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x5e0d443f00000000000000000000000000000000000000000000000000000000) // get_dy(int128,int128,uint256)

			mstore(add(ptr, 0x04), i)
			mstore(add(ptr, 0x24), j)
			mstore(add(ptr, 0x44), dx)

			if iszero(staticcall(gas(), crvPool, ptr, 0x64, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			dy := mload(0x00)
		}
	}

	function verifyPool(address crvPool, address wETH, address frxETH) internal view returns (address) {
		bool verified;

		assembly ("memory-safe") {
			let ptr := mload(0x40)
			let res := add(ptr, 0x24)

			mstore(ptr, 0xc661065700000000000000000000000000000000000000000000000000000000) // coins(uint256)
			mstore(add(ptr, 0x04), 0x00)

			if iszero(staticcall(gas(), crvPool, ptr, 0x24, res, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			mstore(add(ptr, 0x04), 0x01)

			if iszero(staticcall(gas(), crvPool, ptr, 0x24, add(res, 0x20), 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			verified := and(
				or(eq(mload(res), 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE), eq(mload(res), wETH)),
				eq(mload(add(res, 0x20)), frxETH)
			)
		}

		if (!verified) revert InvalidFrxETHCrvPool();

		return crvPool;
	}

	function blockTimestamp() internal view returns (uint40 bts) {
		assembly ("memory-safe") {
			bts := mod(timestamp(), exp(0x02, 0x28))
		}
	}
}
