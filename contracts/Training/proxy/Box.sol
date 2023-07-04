// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Box is Initializable, UUPSUpgradeable, OwnableUpgradeable{

  uint public value1;
  uint public value2;


  function initialize() public initializer {
     __Ownable_init();
  }

    function _authorizeUpgrade(address) internal override onlyOwner {}

//   //Emitted when the stired value chnages
//   event ValueChanged(uint256 newValue);

//   //Stores a new value in the changes
function store(uint firstValue, uint secondValue) external {
  value1 = firstValue;
  value2 = secondValue;
}

// function retrieve() public view returns (uint256) {
//   return value;
// }
}