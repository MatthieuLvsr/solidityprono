// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract Register {
    address payable public owner;
    mapping (address => string) public users;
    constructor (){
        owner = payable(msg.sender);
    }

    function register(string memory login)public{
        require(bytes(users[msg.sender]).length == 0, "You have already register");
        users[msg.sender] = login;
    }

    function getUser(address user) public view returns(string memory){
        return users[user];
    }
}