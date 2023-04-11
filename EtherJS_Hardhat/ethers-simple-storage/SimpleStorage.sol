// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    // initialised as "0"
    uint256 favouriteNumber;

    // creating an struct, and storing it in an Array
    struct People {
        uint256 favouriteNumber;
        string name;
    }
    People[] public people;

    // create a mapping 
    mapping( string => uint256) public nameToFavouriteNumber;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
        retrieve();
    }

    function retrieve() public view returns(uint) {
        return favouriteNumber;
    }

    function addPerson( string memory _name, uint256 _favouriteNumber) public {
        
        // Storing it in an Array---------
        //  1st method
        // people.push(People(_favouriteNumber,_name));

        // 2nd method
        People memory newPerson = People({name : _name, favouriteNumber : _favouriteNumber});
        // this below code also works, but u have to put it in the same order of the struct
        // People memory newPerson = People(_favouriteNumber, _name);
        people.push(newPerson);
        // Storing in array (end) ---------

        // now also add this to the mapping.
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}

