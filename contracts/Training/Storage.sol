// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**

@title Storage

@dev Store & retrieve value in a variable

@custom:dev-run-script ./scripts/deploy_with_ethers.ts
*/
contract Storage {

uint256 public number;

/**

@dev Constructor to set initial value of number
@param num value to initialize number
*/
constructor(uint256 num) {
number = num;
}
/**

@dev Store value in variable
@param num value to store
*/
function store(uint256 num) public {
number = num;
}
/**

@dev Return value
@return value of 'number'
*/
function retrieve() public view returns (uint256){
return number;
}
}
