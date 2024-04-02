# ChainLink Resolver

ChainLink-Resolver is a registry of ChainLink type price feed contracts. It provides the capability to either directly fetch price data from a feed or to compute price data for asset pairs denominated differently, drawing from multiple feeds.

## Contract Overview

### [ChainLinkResolver.sol](https://github.com/fomoweth/chainlink-resolver/blob/main/src/ChainLinkResolver.sol)

#### Query

Case 1) `LINK / ETH`: if there is a feed registered for the given base and quote assets, the ChainLinkResolver will fetch and return the price from it.

Case 2) `LINK / BTC`:

- fetch the current price of `LINK / ETH`.
- fetch the current price of `BTC / ETH`.
- derive `LINK / BTC` using `LINK / ETH` and `BTC / ETH`.

Case 3) `LINK / USDC`:

- fetch the current price of `LINK / ETH`.
- fetch the current price of `ETH / USD` then inverse to compute reversed price: `USD / ETH`.
- derive `LINK / USD` using `LINK / ETH` and `USD / ETH`.
- fetch the current price of `USDC / USD`.
- derive `LINK / USDC` using `LINK / USD` and `USDC / USD`.

#### Feed

```solidity
mapping(address base => mapping(address quote => bytes32 feed)) internal _feeds;
```

A feed can be registered by the owner of the contract. It can be mapped by the addresses of the base and quote assets. The ids and decimals of base and quote assets along with the address of the feed will be encoded and stored in bytes32 format at registration.

#### Asset

```solidity
mapping(address asset => Bitmap configuration) internal _assetConfigs;
mapping(address asset => uint8 id) internal _assetIds;
mapping(uint256 id => address asset) internal _assets;

uint8 internal _numAssets;

uint8 internal constant MAX_ASSETS = 255;
```

An asset will be registered at feed registration if it's not registered already. There is a max limit for number of assets that can be registered which is 255.

The value of `_assetConfigs` is used for determining whether a common feed exists between a pair of assets or not.

### [Bitmap.sol](https://github.com/fomoweth/chainlink-resolver/blob/main/src/types/Bitmap.sol)

The `Bitmap` is user defined type represents `uint256` and the `BitmapLibrary` provides functions for it.

### [Bytes32Lib.sol](https://github.com/fomoweth/chainlink-resolver/blob/main/src/libraries/Bytes32Lib.sol)

The `Bytes32Lib` contract is a library for encoding and decoding the feed configuration.

```solidity
function pack(
	address feed,
	uint8 baseId,
	uint8 quoteId,
	uint8 baseDecimals,
	uint8 quoteDecimals
) internal pure returns (bytes32 data) {
	assembly ("memory-safe") {
		data := add(
			feed,
			add(
				shl(160, baseId),
				add(
					shl(168, quoteId),
					add(
						shl(176, baseDecimals), shl(184, quoteDecimals)
					)
				)
			)
		)
	}
}

function unpack(
	bytes32 data
)
	internal
	pure
	returns (address feed, uint8 baseId, uint8 quoteId, uint8 baseDecimals, uint8 quoteDecimals)
{
	assembly ("memory-safe") {
		feed := and(data, 0xffffffffffffffffffffffffffffffffffffffff)
		baseId := and(shr(160, data), 0xff)
		quoteId := and(shr(168, data), 0xff)
		baseDecimals := and(shr(176, data), 0xff)
		quoteDecimals := and(shr(184, data), 0xff)
	}
}
```

### [Denominations.sol](https://github.com/fomoweth/chainlink-resolver/blob/main/src/libraries/Denominations.sol)

The `Denominations` is a library for handling currency identifiers. The function `decimals(address)` returns hard coded value if given target is equal to either `ETH`, `BTC`, or `USD` for gas efficiency.

```solidity
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
				unit := 8
			}
		}
		default {
			unit := 18
		}
	}
}
```

### [PriceConverter.sol](https://github.com/fomoweth/chainlink-resolver/blob/main/src/libraries/PriceConverter.sol)

The `PriceConverter` is a library for handling the price computation.

## Usage

Create `.env` file with the following content:

```text
INFURA_API_KEY=YOUR_INFURA_API_KEY
RPC_ETHEREUM="https://mainnet.infura.io/v3/${INFURA_API_KEY}"

ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY
ETHERSCAN_URL="https://api.etherscan.io/api"
```

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```
