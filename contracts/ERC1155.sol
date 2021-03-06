pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC1155.sol";

contract ERC1155 is IERC1155, IERC1155BatchTransfer {
    using SafeMath for uint256;
    using Address for address;

    // Variables
    struct Items {
        string name;
        uint256 totalSupply;
        uint256 price;
        mapping (address => uint256) balances;
        mapping (address => bool) wishlist;
    }

    mapping (uint256 => mapping(address => mapping(address => uint256))) public allowances;
    mapping (uint256 => Items) public items;
    mapping (uint256 => string) public metadataURIs;
    
    bytes4 constant private ERC1155_RECEIVED = 0xf23a6e61;
    
/////////////////////////////////////////// IERC1155 //////////////////////////////////////////////

    // Events
    event Approval(address indexed _owner, address indexed _spender, uint256 indexed _id, uint256 _value);
    event Transfer(address _spender, address indexed _from, address indexed _to, uint256 indexed _id, uint256 _value);

    function transferFrom(address _from, address _to, uint256 _id, uint256 _value) public {
        if(_from != msg.sender) {
            //require(allowances[_id][_from][msg.sender] >= _value);
            allowances[_id][_from][msg.sender] = allowances[_id][_from][msg.sender].sub(_value);
        }

        items[_id].balances[_from] = items[_id].balances[_from].sub(_value);
        items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

        emit Transfer(msg.sender, _from, _to, _id, _value);
        require(_checkAndCallSafeTransfer(_from, _to, _id, _value));
    }

    function approve(address owner, uint256 _id, uint256 _value) public {
        allowances[_id][owner][msg.sender] = _value;
        emit Approval(owner, msg.sender, _id, _value);
    }

    function balanceOf(uint256 _id, address _owner) external view returns (uint256) {
        return items[_id].balances[_owner];
    }

    function allowance(uint256 _id, address _owner, address _spender) external view returns (uint256) {
        return allowances[_id][_owner][_spender];
    }

/////////////////////////////////////// IERC1155Extended //////////////////////////////////////////

    function transfer(address _to, uint256 _id, uint256 _value) public {

        items[_id].balances[msg.sender] = items[_id].balances[msg.sender].sub(_value);
        items[_id].balances[_to] = _value.add(items[_id].balances[_to]);
        emit Transfer(msg.sender, msg.sender, _to, _id, _value);
        require(_checkAndCallSafeTransfer(msg.sender, _to, _id, _value));
    }


//////////////////////////////////// IERC1155BatchTransfer ////////////////////////////////////////

    function batchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values) public {
        uint256 _id;
        uint256 _value;

        if(_from == msg.sender) {
            for (uint256 i = 0; i < _ids.length; ++i) {
                _id = _ids[i];
                _value = _values[i];

                items[_id].balances[_from] = items[_id].balances[_from].sub(_value);
                items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

                emit Transfer(msg.sender, _from, _to, _id, _value);
                require(_checkAndCallSafeTransfer(_from, _to, _ids[i], _values[i]));
            }
        }
        else {
            for (i = 0; i < _ids.length; ++i) {
                _id = _ids[i];
                _value = _values[i];

                allowances[_id][_from][msg.sender] = allowances[_id][_from][msg.sender].sub(_value);

                items[_id].balances[_from] = items[_id].balances[_from].sub(_value);
                items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

                emit Transfer(msg.sender, _from, _to, _id, _value);
                require(_checkAndCallSafeTransfer(_from, _to, _ids[i], _values[i]));
            }
        }
    }


    function batchApprove(address _spender, uint256[] _ids,  uint256[] _values) external {
        uint256 _id;
        uint256 _value;

        for (uint256 i = 0; i < _ids.length; ++i) {
            _id = _ids[i];
            _value = _values[i];

            require(_value == 0 );
            allowances[_id][msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _id, _value);
        }
    }

//////////////////////////////// IERC1155BatchTransferExtended ////////////////////////////////////

    function batchTransfer(address _to, uint256[] _ids, uint256[] _values) public {
        uint256 _id;
        uint256 _value;

        for (uint256 i = 0; i < _ids.length; ++i) {
            _id = _ids[i];
            _value = _values[i];

            items[_id].balances[msg.sender] = items[_id].balances[msg.sender].sub(_value);
            items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

            emit Transfer(msg.sender, msg.sender, _to, _id, _value);
            require(_checkAndCallSafeTransfer(msg.sender, _to, _ids[i], _values[i]));
        }
    }

////////////////////////////////////////// OPTIONALS //////////////////////////////////////////////


    function multicastTransfer(address[] _to, uint256[] _ids, uint256[] _values) public {
        for (uint256 i = 0; i < _to.length; ++i) {
            uint256 _id = _ids[i];
            uint256 _value = _values[i];
            address _dst = _to[i];

            items[_id].balances[msg.sender] = items[_id].balances[msg.sender].sub(_value);
            items[_id].balances[_dst] = _value.add(items[_id].balances[_dst]);

            emit Transfer(msg.sender, msg.sender, _dst, _id, _value);
            require(_checkAndCallSafeTransfer(msg.sender, _to[i], _ids[i], _values[i]));
        }
    }


////////////////////////////////////////// INTERNAL //////////////////////////////////////////////

    function _checkAndCallSafeTransfer(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value
    )
    internal
    returns (bool)
    {
        if (!_to.isContract()) {
            return true;
        }
        bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received(
            msg.sender, _from, _id, _value);
        return (retval == ERC1155_RECEIVED);
    }
    
//////////////////////////////// IERC1155BatchTransferExtended ////////////////////////////////////

    // Optional meta data view Functions
    // consider multi-lingual support for name?
    function name(uint256 _id) external view returns (string) {
        return items[_id].name;
    }

    function totalSupply(uint256 _id) external view returns (uint256) {
        return items[_id].totalSupply;
    }

    function uri(uint256 _id) external view returns (string) {
        return metadataURIs[_id];
    }
    
    function price(uint256 _id) external view returns (uint256) {
        return items[_id].price;
    }

}


