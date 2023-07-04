// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "./Box.sol";


contract BoxV3 is Box{

uint public add;

function operations() external {
  add = value1 + (value2 ** 10);
}

function retrieve() external view returns (uint, uint) {
  return (value1, value2);
}

function retrieveOperations() external view returns (uint) {
  return add;
}

}