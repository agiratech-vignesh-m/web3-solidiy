// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "./Box.sol";


contract BoxV2 is Box{

uint public add;

function increment() external {
   value1 += 1;
   value1 += 4;

}

function operations() external {
  add = value1 + value2;
}

function retrieve() external view returns (uint, uint) {
  return (value1, value2);
}

}