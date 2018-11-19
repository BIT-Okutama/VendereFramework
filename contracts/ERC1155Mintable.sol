pragma solidity ^0.4.24;

import "./ERC1155.sol";

/**
    @dev Mintable form of ERC1155
    Shows how easy it is to mint new items
*/
contract ERC1155Mintable is ERC1155 {
    
    uint256 public nonce;
    mapping (uint256 => address) public minter;
    
    

    modifier minterOnly(uint256 _id) {
        require(minter[_id] == msg.sender);
        _;
    }
    
    function mint(string _name, uint256 _totalSupply, string _uri, uint256 _price)
    public returns(uint256 _id) {
        
        _id = ++nonce;
        minter[_id] = msg.sender; 
        items[_id].name = _name;
        items[_id].totalSupply = _totalSupply;
        items[_id].price = _price;
        metadataURIs[_id] = _uri;
        
        // Grant the items to the minter
        items[_id].balances[msg.sender] = _totalSupply;
    }

    function setURI(uint256 _id, string _uri) external minterOnly(_id) {
        metadataURIs[_id] = _uri;
    }
    
    function getMinter(uint256 _id) public view returns(address){
        return minter[_id];
    }
}