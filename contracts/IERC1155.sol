pragma solidity ^0.4.24;

/// @dev Note: the ERC-165 identifier for this interface is 0xf23a6e61.
interface IERC1155TokenReceiver {
    /// @notice Handle the receipt of an ERC1155 type
    /// @dev The smart contract calls this function on the recipient
    ///  after a `safeTransfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _id The identifier of the item being transferred
    /// @param _value The amount of the item being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    ///  unless throwing
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value) external returns(bytes4);
}

interface IERC1155 {
    event Approval(address indexed _owner, address indexed _spender, uint256 indexed _id, uint256 _oldValue, uint256 _value);
    event Transfer(address _spender, address indexed _from, address indexed _to, uint256 indexed _id, uint256 _value);
    function balanceOf(uint256 _id, address _owner) external view returns (uint256);
    function allowance(uint256 _id, address _owner, address _spender) external view returns (uint256);
}


interface IERC1155BatchTransfer {
    function batchApprove(address _spender, uint256[] _ids, uint256[] _values) external;
}


interface IERC1155Views {
    function totalSupply(uint256 _id) external view returns (uint256);
    function name(uint256 _id) external view returns (string);
    function uri(uint256 _id) external view returns (string);
    function price(uint256 _id) external view returns (uint256);
}