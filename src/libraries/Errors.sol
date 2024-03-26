// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Errors
/// @notice Library for custom errors and error handlers

library Errors {
	error AccessDenied(address);

	error EmptyCode(address);

	error ExceededMaxLimit();

	error FeedNotExists();

	error IdenticalAddresses();

	error OutOfBounds();

	error ZeroAddress(string);

	error ZeroValue(string);

	function isContract(address target) internal view returns (bool res) {
		assembly ("memory-safe") {
			res := gt(extcodesize(target), 0x00)
		}
	}

	function verifyContract(address target) internal view returns (address) {
		if (!isContract(target)) revert EmptyCode(target);
		return target;
	}

	function verifyCaller(address target, address expected) internal pure returns (address) {
		if (target != expected) revert AccessDenied(target);
		return target;
	}

	function verifyNotZero(address target, string memory parameterName) internal pure returns (address) {
		if (isZero(uint160(target))) revert ZeroAddress(parameterName);
		return target;
	}

	function verifyNotZero(uint256 value, string memory parameterName) internal pure returns (uint256) {
		if (isZero(value)) revert ZeroValue(parameterName);
		return value;
	}

	function isZero(uint256 value) internal pure returns (bool res) {
		assembly ("memory-safe") {
			res := iszero(value)
		}
	}
}
