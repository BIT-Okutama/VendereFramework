pragma solidity ^0.4.24;

contract Admin {
    
    
    mapping (address => bool) public admins;
    
    address superAdmin;
    
    constructor(address firstAdmin) public{
        admins[firstAdmin] = true;
        superAdmin = firstAdmin;
    }
    
    modifier adminOnly(){
        require(admins[msg.sender] == true);
        _;
    }
    
    modifier superAdminOnly(){
        require(msg.sender == superAdmin);
        _;
    }
    
    function addAdmin(address newAdmin) public adminOnly() {
        admins[newAdmin] = true;
        
    }
    
    function removeAdmin(address adminAddress) public superAdminOnly() {
        admins[adminAddress] = false;
    }
    
    
    
}