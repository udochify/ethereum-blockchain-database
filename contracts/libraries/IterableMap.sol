// SPDX-License-Identifier: GPL-3.0
// Author: Enwerem C. Udochukwu
// contact: udoinui@gmail.com
// date: 03/01/2023 7:37am

pragma solidity >=0.8.9 <0.9.0;

library IterableMap {
    // Iterable mapping from address to uint: like mapping(address => uint);
    struct Map {
        address[] keys; // keep track of addresses; could be of Files or of Users
        mapping(address => uint) indexOf; // mapping of addresses (of File or Users) to their index in keys
        mapping(address => bool) inserted; // Keep track of all inserted keys
    }

    modifier indexWithinRange(address[] storage arr, uint index) {
        require(index < arr.length, "Index is out of range.");
        _;
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function insert(Map storage map, address key) public {
        if (!map.inserted[key]) {
            map.inserted[key] = true;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (map.inserted[key]) {
            delete map.inserted[key];

            uint index = map.indexOf[key];
            uint lastIndex = map.keys.length - 1;
            address lastKey = map.keys[lastIndex];

            map.indexOf[lastKey] = index;
            delete map.indexOf[key];

            map.keys[index] = lastKey;
            map.keys.pop();
        }
    }

    function clear(Map storage map) public {
        for (uint i = 0; i < map.keys.length; i++) {
            delete map.indexOf[map.keys[i]];
            delete map.inserted[map.keys[i]];
        }
        delete map.keys;
    }

    function contains(Map storage map, address key) public view returns (bool) {
        return map.inserted[key];
    }

    function getKeyAtIndex(Map storage map, uint index) public indexWithinRange(map.keys, index) view returns (address) {
        return map.keys[index];
    }

    function getAllKeys(Map storage map) public view returns (address[] memory) {
        return map.keys;
    }
}