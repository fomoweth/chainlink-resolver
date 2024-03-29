// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Bytes32Arrays {
	function create(bytes32 arg) internal pure returns (bytes32[] memory res) {
		res = new bytes32[](1);
		res[0] = arg;
	}

	function create(bytes32 arg0, bytes32 arg1) internal pure returns (bytes32[] memory res) {
		res = new bytes32[](2);
		res[0] = arg0;
		res[1] = arg1;
	}

	function create(bytes32 arg0, bytes32 arg1, bytes32 arg2) internal pure returns (bytes32[] memory res) {
		res = new bytes32[](3);
		res[0] = arg0;
		res[1] = arg1;
		res[2] = arg2;
	}

	function create(
		bytes32 arg0,
		bytes32 arg1,
		bytes32 arg2,
		bytes32 arg3
	) internal pure returns (bytes32[] memory res) {
		res = new bytes32[](4);
		res[0] = arg0;
		res[1] = arg1;
		res[2] = arg2;
		res[3] = arg3;
	}

	function reverse(bytes32[] memory arr) internal pure returns (bytes32[] memory res) {
		uint256 length = arr.length;

		res = new bytes32[](length);

		for (uint256 i; i < length; ++i) {
			res[i] = arr[length - 1 - i];
		}
	}
}
