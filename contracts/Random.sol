pragma solidity ^0.4.24;


contract Random{
    
    uint256 anyNum = 0;
    
    //Temporary Deterministic Randomizer
    function getRandom(uint256 threshold) public returns(uint256){
        
        anyNum += 7;
        
        if (threshold < anyNum){
            anyNum = anyNum - threshold;
        }
        
        return anyNum;
    }
    
   
    
}