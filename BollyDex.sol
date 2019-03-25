pragma solidity ^0.4.9;

contract Ownable {
  address public owner;
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract SafeMath is Ownable {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}



// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
contract ERC20Interface {
    // Get the total token supply
    function totalSupply() public constant returns (uint256 totalSupply);

    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) public constant returns (uint256 balance);

    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool success);

    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) public returns (bool success);

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract BollyDex is SafeMath {
    
    address public bollyCoin = 0xCC4279faFd236D5A1d3883800ad85E53BA491Aef;
    
    event MakeBuyOrder(address indexed token, uint256 tokenAmount, address indexed buyer);

    event MakeSellOrder(address indexed token, uint256 tokenAmount, address indexed seller);
  
    mapping  (uint => Exchange) public exchanges;
    struct Exchange {
        address token;
        uint256 rate;
    }
    uint256 public count =0; 
    
    function addToken(address token, uint256 rate) onlyOwner {
        exchanges[count++] = Exchange(token, rate);
    }
    
    function updateToken(address token, uint256 rate, uint256 index) onlyOwner {
        exchanges[index].token = token;
        exchanges[index].rate = rate;
    }
    
    
    function updateBollyCoin(address bollyC) onlyOwner {
        bollyCoin = bollyC;
    }
    
   // The buy moves bollyCoins to the owner
//send the star coins to sender, and then increases the exchange rate.
    function buy(address token, uint256 index, uint256 tokenAmount) public {
       // require(tokenAmount != 0);
        
        if (!ERC20Interface(bollyCoin).transferFrom(msg.sender, owner, safeMul(exchanges[index].rate, tokenAmount))) {
            revert();
        }
        
        if (!ERC20Interface(token).transferFrom(owner, msg.sender, tokenAmount)) {
            revert();
        }
        
        exchanges[index].rate =  exchanges[index].rate + tokenAmount/10;
        MakeSellOrder(token, tokenAmount,  msg.sender);
    }

    // The sell moves star coin to the owner
//send the bollyCoins to sender, and then lowers the exchange rate.
    function sell(address token, uint256 index,  uint256 tokenAmount) public {
        require(tokenAmount != 0);
        
        if (!ERC20Interface(token).transferFrom(msg.sender, owner, tokenAmount)) {
            revert();
        }
        
        if (!ERC20Interface(bollyCoin).transferFrom(owner, msg.sender, exchanges[index].rate*tokenAmount)) {
            revert();
        }
        var reduce = exchanges[index].rate - tokenAmount/10;
        if (reduce > 1) {
              exchanges[index].rate =  reduce;
        } 
        // Notify all clients.
        MakeBuyOrder(token, tokenAmount,  msg.sender);
    }
    
}
