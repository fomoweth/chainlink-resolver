// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FullMath} from "src/libraries/FullMath.sol";

library ExchangeRates {
	error InvalidTick();

	int24 internal constant MIN_TICK = -887272;
	int24 internal constant MAX_TICK = -MIN_TICK;

	// Uniswap V3

	function getQuoteAtTick(
		address pool,
		uint32 period,
		uint8 baseUnit,
		bool zeroForOne
	) internal view returns (uint256) {
		(int56[] memory tickCumulatives, ) = observe(pool, period);

		int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

		int24 arithmeticMeanTick = int24(tickCumulativesDelta / int32(period));

		if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int32(period) != 0)) {
			--arithmeticMeanTick;
		}

		if (!zeroForOne) arithmeticMeanTick = -arithmeticMeanTick;

		uint160 sqrtPriceX96 = getSqrtRatioAtTick(arithmeticMeanTick);

		if (sqrtPriceX96 > type(uint128).max) {
			uint256 ratioX128 = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, 1 << 64);

			return
				zeroForOne
					? FullMath.mulDiv(ratioX128, 10 ** baseUnit, 1 << 128)
					: FullMath.mulDiv(1 << 128, 10 ** baseUnit, ratioX128);
		} else {
			uint256 ratioX192 = uint256(sqrtPriceX96) * sqrtPriceX96;

			return
				zeroForOne
					? FullMath.mulDiv(ratioX192, 10 ** baseUnit, 1 << 192)
					: FullMath.mulDiv(1 << 192, 10 ** baseUnit, ratioX192);
		}
	}

	function observe(
		address pool,
		uint32 period
	)
		internal
		view
		returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s)
	{
		bytes memory returndata;

		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x883bdbfd00000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), 0x20)
			mstore(add(ptr, 0x24), 0x02)
			mstore(add(ptr, 0x44), period)
			mstore(add(ptr, 0x64), 0x00)

			if iszero(staticcall(gas(), pool, ptr, 0x84, 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			mstore(0x40, add(returndata, add(returndatasize(), 0x20)))
			mstore(returndata, returndatasize())
			returndatacopy(add(returndata, 0x20), 0x00, returndatasize())
		}

		return abi.decode(returndata, (int56[], uint160[]));
	}

	function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
		unchecked {
			uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
			if (absTick > uint256(int256(MAX_TICK))) revert InvalidTick();

			uint256 ratio = absTick & 0x1 != 0
				? 0xfffcb933bd6fad37aa2d162d1a594001
				: 0x100000000000000000000000000000000;
			if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
			if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
			if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
			if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
			if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
			if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
			if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
			if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
			if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
			if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
			if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
			if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
			if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
			if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
			if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
			if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
			if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
			if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
			if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

			if (tick > 0) ratio = type(uint256).max / ratio;

			sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
		}
	}

	// Curve

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

	function getDx(address crvPool, uint256 i, uint256 j, uint256 dy) internal view returns (uint256 dx) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x67df02ca00000000000000000000000000000000000000000000000000000000) // get_dx(int128,int128,uint256)

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

	// sfrxETH (ERC4626)

	function convertToAssets(address sfrxETH, uint256 shares) internal view returns (uint256 assets) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x07a2d13a00000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), shares)

			if iszero(staticcall(gas(), sfrxETH, ptr, 0x24, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			assets := mload(0x00)
		}
	}

	function convertToShares(address sfrxETH, uint256 assets) internal view returns (uint256 shares) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xc6e6f59200000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), assets)

			if iszero(staticcall(gas(), sfrxETH, ptr, 0x24, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			shares := mload(0x00)
		}
	}

	function pricePerShare(address sfrxETH) internal view returns (uint256 rate) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x99530b0600000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), sfrxETH, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			rate := mload(0x00)
		}
	}

	// wstETH

	function stEthPerToken(address wstETH) internal view returns (uint256 rate) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x035faf8200000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), wstETH, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			rate := mload(0x00)
		}
	}

	function tokensPerStEth(address wstETH) internal view returns (uint256 rate) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x9576a0c800000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), wstETH, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			rate := mload(0x00)
		}
	}
}
