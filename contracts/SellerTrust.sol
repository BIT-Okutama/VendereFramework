pragma solidity ^0.4.24;

contract SellerTrust {
    
    struct SellerVote {
        uint128 upVotes;
        uint128 downVotes; 
        mapping (address => int) voteState;
    }
    
    mapping (address => SellerVote) public sellerVotes;
    
    
     //If down voted, it deducts it and adds to up votes;
    function upVoteSeller(address _seller) public {
        
        int _voteState = sellerVotes[_seller].voteState[msg.sender];
        require(_voteState == -1 || _voteState == 0);
        
        if(_voteState == -1){
            sellerVotes[_seller].downVotes--;
        }
        sellerVotes[_seller].voteState[msg.sender] = 1;
        sellerVotes[_seller].upVotes++;
    }
    
    //If up voted, it deducts it and adds to down votes;
    function downVoteSeller(address _seller) public {
        
        int _voteState = sellerVotes[_seller].voteState[msg.sender];
        require(_voteState == 1 || _voteState == 0);
        
        if(_voteState == 1){
            sellerVotes[_seller].upVotes--;
        }
        sellerVotes[_seller].voteState[msg.sender] = -1;
        sellerVotes[_seller].downVotes--;
    }
    
    function removeVote(address _seller) public {
        
        if(sellerVotes[_seller].voteState[msg.sender] == 1){
            sellerVotes[_seller].upVotes--;    
        }
        
        else if(sellerVotes[_seller].voteState[msg.sender] == -1){
            sellerVotes[_seller].downVotes--;
        }
        
        sellerVotes[_seller].voteState[msg.sender] = 0;
        
    }
    
    function getVotes(address _seller) public view returns(uint128 _upVotes, uint128 _downVotes){
        _upVotes = sellerVotes[_seller].upVotes;
        _downVotes = sellerVotes[_seller].downVotes;
    }
    
    function getSellerWeight(address _seller) public view returns(uint256){
        if(sellerVotes[_seller].upVotes > sellerVotes[_seller].downVotes){
            return sellerVotes[_seller].upVotes - sellerVotes[_seller].downVotes;
        }
        else{
            return 1;
        }
    }
    
}