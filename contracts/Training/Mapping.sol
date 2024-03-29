// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


// mapping (keyType => valueType)
// ketType can be build on any type like ( byte string) 
// valueType ony be array or mapping

contract Mapping {
// Mapping from address to uint

mapping(address => uint) public myMap;

function get(address _addr) public view returns (uint){
    // Mapping always returns a value.
    //If the values was never set, it will return the default value.
    return myMap[_addr];
}

function set(address _addr, uint _i) public {
// Update the value at this address
    myMap[_addr] = _i;
}

function remove(address _addr) public {
// Reset the value to the default address
    delete myMap[_addr];
}

}

contract NestedMapping {
    mapping(address => mapping (uint => bool)) public nested;

function get(address _addr1, uint _i) public view returns (bool){
    return nested[_addr1][_i];
}

function set(
    address _addr1, 
    uint _i,
    bool _boo) public {

    nested[_addr1][_i] = _boo;
}

function remove(address _addr1, uint _i) public {
    delete nested[_addr1][_i];
}

}