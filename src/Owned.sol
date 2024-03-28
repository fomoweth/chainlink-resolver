// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Owned
/// @notice Provides basic access control mechanism
/// @dev Implementation from https://github.com/Uniswap/v4-core/blob/main/src/Owned.sol

contract Owned {
	event OwnerChanged(address indexed previousOwner, address indexed newOwner);

	error InvalidCaller(address);

	address private _owner;
	bytes12 private STORAGE_PLACEHOLDER;

	modifier onlyOwner() {
		verifyOwner(msg.sender);
		_;
	}

	constructor() {
		_owner = msg.sender;
		emit OwnerChanged(address(0), msg.sender);
	}

	function setOwner(address newOwner) external onlyOwner {
		emit OwnerChanged(owner(), newOwner);
		_owner = newOwner;
	}

	function owner() public view returns (address) {
		return _owner;
	}

	function verifyOwner(address caller) internal view {
		if (caller != owner()) revert InvalidCaller(caller);
	}
}
