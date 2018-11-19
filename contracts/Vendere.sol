pragma solidity ^0.4.24;

import './ERC1155Mintable.sol';
import './Admin.sol';
import './SellerTrust.sol';
import './Random.sol';


contract Vendere is ERC1155Mintable, Admin, SellerTrust, Random {
    
    address currentOwner;
    address[] overallSellers;
    mapping (address => int) public sellers;
    
    uint256 MINIMUM_FEE = 200000000000000000;
    uint8 ADMIN_PERMISSION_LIMIT = 1;
    uint256 approvalThreshold = 0; 
    string public version = "0.5";
    
    struct PendingSeller{
        address sellerAddress;
        uint256 approvalVotes;
        mapping(address => bool) sellersVoted;
    }
    
    mapping(uint256 => PendingSeller) public pending;
    uint256 pendingSellerCtr;
  
    constructor() public ERC1155Mintable() Admin(msg.sender) SellerTrust() {
        currentOwner = msg.sender;
    }
    
    function () payable public {
       
    }
       
     modifier sellerOnly(){
        require(sellers[msg.sender] == 1);
        _;
    }
    
    
    //OTHERS
    
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function getContractOwner() public view returns(address){
        return currentOwner;
    }
    
    function getApprovalThreshold() public view returns(uint256){
        return approvalThreshold;
    }
    
    function getItemNonce() public view returns(uint256) {
        return nonce;
    }
    
    function getAppVersion() public view returns(string) {
        return version;
    }
    
    
    //SELLER
    
    function incentivizeSeller() private {
        uint256 selected; //24 
        selected = getRandom(approvalThreshold);
        //A = 10, B = 12, C = 14
        //A: 24-10 -> B: 14-12 -> C: 2 -> C is chosen one!  
        for(uint256 i=0 ; i < overallSellers.length ; i++){
            
            if(sellers[overallSellers[i]] == -1 || sellers[overallSellers[i]] == 0)
                continue;
            
            uint256 weight = getSellerWeight(overallSellers[i]); 
            if(selected > weight){
                selected -= weight;
            }
            else{
                overallSellers[i].transfer(200000000000000000);
                break;
            }
        }
    }
    
    function registerAsSeller() public payable {
        require(msg.value >= MINIMUM_FEE);
        pendingSellerCtr++;
        pending[pendingSellerCtr] = PendingSeller({sellerAddress: msg.sender, approvalVotes: 0});
        
        for(uint256 i = 0; i < overallSellers.length ; i++){
            if(sellers[overallSellers[i]] == 1){
                approvalThreshold += getSellerWeight(overallSellers[i]);    
            }
        }
    }
    
    function setMeAsInactive() public sellerOnly() {
        sellers[msg.sender] = -1;
    }
    
    function setMeAsActive() public {
        require(sellers[msg.sender] == -1);
        sellers[msg.sender] = 1;
    }
    
    function approveSellerByAdmin(address merchantAddress) public adminOnly() {
        require(ADMIN_PERMISSION_LIMIT > 0);
        sellers[merchantAddress] = 1;
        sellerVotes[merchantAddress] = SellerVote({upVotes:0, downVotes:0});
        
        overallSellers.push(merchantAddress);
        ADMIN_PERMISSION_LIMIT--;
    }
    
    
    function approveSeller(uint256 _index) public sellerOnly() {
        require(ADMIN_PERMISSION_LIMIT == 0);
        require(pending[_index].sellersVoted[msg.sender] == false);
        pending[_index].approvalVotes += getSellerWeight(pending[_index].sellerAddress);   
        pending[_index].sellersVoted[msg.sender] = true;
        
        if(pending[_index].approvalVotes >= (approvalThreshold.div(2))){
            sellers[pending[_index].sellerAddress] = 1;
            sellerVotes[pending[_index].sellerAddress] = SellerVote({upVotes:0, downVotes:0});
            overallSellers.push(pending[_index].sellerAddress);
            incentivizeSeller();
        }
    }
    
    function addItem(string _name, uint256 _totalSupply, string _uri, uint256 _price) public sellerOnly() {
        mint(_name, _totalSupply, _uri, _price);
    }
    
    function getPendingDetails(uint256 _index) public view returns(address _id, uint256 _approvalVotes){
        _id = pending[_index].sellerAddress;
        _approvalVotes = pending[_index].approvalVotes;
    }
    
    function getPendingCount() public view returns(uint256){
        return pendingSellerCtr;
    }
    
    //WISHLIST
    
    function addToWishList(uint256 _id) public {
        items[_id].wishlist[msg.sender] = true;
    }
    
    function removeFromWishList(uint256 _id) public {
        items[_id].wishlist[msg.sender] = false;
    }
    
    //BUYER
    
    function buyItem(uint256 _id, uint256 _quantity) public payable{
        require(msg.value >= items[_id].price*_quantity);
        super.approve(getMinter(_id), _id, _quantity);
        super.transferFrom(getMinter(_id), msg.sender, _id, _quantity);
        currentOwner.transfer(msg.value);
    }
      
    function buyBatchItems(uint256[] _ids, uint256[] _quantities) public payable {
        uint256 grandTotal = 0;
        for(uint256 i=0; i<_ids.length; i++){
            grandTotal = grandTotal + items[_ids[i]].price*_quantities[i];
            
        }
        require(msg.value >= grandTotal);
        
        
        for(uint256 j=0; j<_ids.length; j++){
            super.approve(getMinter(_ids[j]), _ids[j], _quantities[j]);
        }
        
        super.batchTransferFrom(getMinter(_ids[0]), msg.sender, _ids, _quantities);
    }
    
    //TRADING
    
    function giveItem(address _to, uint256 _id, uint256 _quantity) public {
        super.transfer(_to, _id, _quantity);
    }
    
    function giveBatchItems(address _to, uint256[] _ids, uint256[] _quantities) public {
        super.batchTransfer(_to, _ids, _quantities);
    }
    
    function giveItemsToRecipients(address[] _to, uint256[] _ids, uint256[] _values) public {
        super.multicastTransfer(_to, _ids, _values);
    }
    
    //GETTERS
    
    function getShopItem(uint256 _id) public view returns(uint256 id, string itemName, uint256 itemPrice, uint256 currentSupply){
        id = _id;
        itemName = items[id].name;
        itemPrice = items[id].price;
        currentSupply = items[id].balances[currentOwner];
    }
    
    function getInventoryItem(uint256 _id) public view returns(uint256 id, string itemName, uint256 itemPrice, uint256 itemQuantity){
        id = _id;
        itemName = items[id].name;
        itemPrice = items[id].price;
        itemQuantity = items[id].balances[msg.sender];
    }
   
    
}