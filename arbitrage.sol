
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: triarbflash.sol

//SPDX-License-Identifier: Unlicense, just give the credit where its due
pragma solidity ^0.8.4;

//import "hardhat/console.sol";


interface IERC20 {
	function totalSupply() external view returns (uint);
	function balanceOf(address account) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}

interface IDODO {
    // Dodo flashloan interface, we need this to initate the flash loan.
    function flashLoan(
        uint256 baseAmount,
        uint256 quoteAmount,
        address assetTo,
        bytes calldata data
    ) external;

    function _BASE_TOKEN_() external view returns (address);
}


interface IUniswapV2Router {
    // Uniswap v2 interface, allows us to call uniswap v2 fork routers
  function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
   function getAmountsIn(uint256 amountOut, address[] memory path) external view returns (uint256[] memory amounts);
  function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    // uniswap v2 pair interface, allows us to query token pairs (ie liquidity pools)
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(uint256 amount0Out,	uint256 amount1Out,	address to,	bytes calldata data) external;
  function getReserves() external view returns (uint112, uint112, uint32);
}

contract Arb is Ownable {
    /* The start of the arbitrage contract,
    as this file was flattened to make easier to
    publish source.
    */
    address _owner_;
     address [] public routers;
     address [] public tokens;
     address [] public stables;
     bool public lock;


    constructor() {
        _owner_ = payable(msg.sender);
    }


  function addRouters(address[] calldata _routers) external onlyOwner {
      /* These functions are for the instaTrade, which I still need to modify to use
      flash loans.*/
    for (uint i=0; i<_routers.length; i++) {
      routers.push(_routers[i]);
    }
  }

  function addTokens(address[] calldata _tokens) external onlyOwner {
    for (uint i=0; i<_tokens.length; i++) {
      tokens.push(_tokens[i]);
    }
  }

  function addStables(address[] calldata _stables) external onlyOwner {
    for (uint i=0; i<_stables.length; i++) {
      stables.push(_stables[i]);
    }
  }

    function instaSearch(address _router, address _baseAsset, uint256 _amount) external view returns (uint256,address,address,address) {
        /* Special thanks to James Bachini (https://jamesbachini.com/) for writing this
        TOOO: implement flashloans for interexchange trades*/
        uint256 amtBack;
        address token1;
        address token2;
        address token3;
        for (uint i1=0; i1<tokens.length; i1++) {
        for (uint i2=0; i2<stables.length; i2++) {
            for (uint i3=0; i3<tokens.length; i3++) {
            amtBack = getAmountOutMin(_router, _baseAsset, tokens[i1], _amount);
            amtBack = getAmountOutMin(_router, tokens[i1], stables[i2], amtBack);
            amtBack = getAmountOutMin(_router, stables[i2], tokens[i3], amtBack);
            amtBack = getAmountOutMin(_router, tokens[i3], _baseAsset, amtBack);
            if (amtBack > _amount) {
                token1 = tokens[i1];
                token2 = tokens[i2];
                token3 = tokens[i3];
                break;
            }
            }
        }
        }
        return (amtBack,token1,token2,token3);
    }

    function _instaTrade(address _router1, address _token1, address _token2, address _token3, address _token4, uint256 _amount) internal {
        uint startBalance = IERC20(_token1).balanceOf(address(this));
        uint token2InitialBalance = IERC20(_token2).balanceOf(address(this));
        uint token3InitialBalance = IERC20(_token3).balanceOf(address(this));
        uint token4InitialBalance = IERC20(_token4).balanceOf(address(this));
        swap(_router1,_token1, _token2, _amount);
        uint tradeableAmount2 = IERC20(_token2).balanceOf(address(this)) - token2InitialBalance;
        swap(_router1,_token2, _token3, tradeableAmount2);
        uint tradeableAmount3 = IERC20(_token3).balanceOf(address(this)) - token3InitialBalance;
        swap(_router1,_token3, _token4, tradeableAmount3);
        uint tradeableAmount4 = IERC20(_token4).balanceOf(address(this)) - token4InitialBalance;
        swap(_router1,_token4, _token1, tradeableAmount4);
        require(IERC20(_token1).balanceOf(address(this)) > startBalance, "Trade Reverted, No Profit Made");
    }

    function instaTrade(address _router1, address _token1, address _token2, address _token3, address _token4, uint256 _amount) external onlyOwner {
        _instaTrade(_router1, _token1, _token2, _token3, _token4, _amount);

    }


	function swap(address router, address _tokenIn, address _tokenOut, uint256 _amount) private {
        /*Swap function for our dual and tri dex trades*/
		IERC20(_tokenIn).approve(router, _amount);
		address[] memory path;
		path = new address[](2);
		path[0] = _tokenIn;
		path[1] = _tokenOut;
		uint deadline = block.timestamp + 300;
		IUniswapV2Router(router).swapExactTokensForTokens(_amount, 1, path, address(this), deadline);
	}

	 function getAmountOutMin(address router, address _tokenIn, address _tokenOut, uint256 _amount) public view returns (uint256) {
		address[] memory path;
		path = new address[](2);
		path[0] = _tokenIn;
		path[1] = _tokenOut;
		uint256[] memory amountOutMins = IUniswapV2Router(router).getAmountsOut(_amount, path);
		return amountOutMins[path.length -1];
	}

    function getAmountInMin(address router, address _tokenIn, address _tokenOut, uint256 _amount) public view returns (uint256[] memory) {
		address[] memory path;
		path = new address[](2);
		path[0] = _tokenIn;
		path[1] = _tokenOut;
		uint256[] memory amountInMins = IUniswapV2Router(router).getAmountsIn(_amount, path);
		return amountInMins;
	}

  function estimateDualDexTrade(address _router1, address _router2, address _token1, address _token2, uint256 _amount) external view returns (uint256) {
		uint256 amtBack1 = getAmountOutMin(_router1, _token1, _token2, _amount);
		uint256 amtBack2 = getAmountOutMin(_router2, _token2, _token1, amtBack1);
		return amtBack2;
	}



  function _dualDexTrade(address _router1, address _router2, address _token1, address _token2, uint256 _amount) external {
    uint startBalance = IERC20(_token1).balanceOf(address(this));
    uint token2InitialBalance = IERC20(_token2).balanceOf(address(this));
    swap(_router1,_token1, _token2,_amount);
    uint token2Balance = IERC20(_token2).balanceOf(address(this));
    uint tradeableAmount = token2Balance - token2InitialBalance;
    swap(_router2,_token2, _token1,tradeableAmount);
    uint endBalance = IERC20(_token1).balanceOf(address(this));
    require(endBalance > startBalance, "Trade Reverted, No Profit Made");
  }




  function _triDexTrade(address _router1, address _router2, address _router3,
  address _token1, address _token2, address _token3, uint256 _amount) external {
    //require(msg.sender == flashLoanPool, "Invalid password");
    uint startBalance = IERC20(_token1).balanceOf(address(this));
    uint token2InitialBalance = IERC20(_token2).balanceOf(address(this));
    uint token3InitialBalance = IERC20(_token3).balanceOf(address(this));
    swap(_router1,_token1, _token2,_amount);
    uint token2Balance = IERC20(_token2).balanceOf(address(this));
    uint tradeableAmount = token2Balance - token2InitialBalance;
    swap(_router2,_token2, _token3,tradeableAmount);
    uint token3Balance = IERC20(_token3).balanceOf(address(this));
    uint tradeableAmount_token3 = token3Balance - token3InitialBalance;
    swap(_router3,_token3, _token1, tradeableAmount_token3);
    uint endBalance = IERC20(_token1).balanceOf(address(this));
    require(endBalance > startBalance, "Trade Reverted, No Profit Made");
  }

    function dualDexTrade(address _router1, address _router2, address _token1, address _token2, uint256 _amount) external onlyOwner{
        _dualDexTrade(_router1, _router2, _token1, _token2, _amount);
    }

  function triDexTrade(address _router1, address _router2, address _router3,
      address _token1, address _token2, address _token3, uint256 _amount) external onlyOwner {
      _triDexTrade(_token1, _token2, _token3, _router1, _router2, _router3, _amount);
  }


	function estimateTriDexTrade(address _router1, address _router2, address _router3, address _token1, address _token2, address _token3, uint256 _amount) external view returns (uint256) {
		uint amtBack1 = getAmountOutMin(_router1, _token1, _token2, _amount);
		uint amtBack2 = getAmountOutMin(_router2, _token2, _token3, amtBack1);
		uint amtBack3 = getAmountOutMin(_router3, _token3, _token1, amtBack2);
		return amtBack3;
	}

	function getBalance (address _tokenContractAddress) external view  returns (uint256) {
		uint balance = IERC20(_tokenContractAddress).balanceOf(address(this));
		return balance;
	}

    function recoverEth() external onlyOwner  {
        /*Withdraw eth from contract*/
        require(!lock, "Reentrency blocked!");
        lock = true;
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
        lock = false;
        }

	/*function recoverEth() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}*/

	function recoverTokens(address tokenAddress) external onlyOwner {
        // withdraw tokens from contract
        // NOTE: need to test this after modifications, be careful
        require(! lock, "Reentrency blocked!");
        lock = true;
		IERC20 token = IERC20(tokenAddress);
		token.transfer(msg.sender, token.balanceOf(address(this)));
        lock = false;
	}

	receive() external payable {}

     function dodoFlashLoan(
     /* We call this function to initiate a flash loan.
      It encodes our arguments and sends them to the dodo pool.
      They then calculate and make sure they are not loosing money,
      then they send the requested funds to our contract.
      We then complete the trade and pay it back. */


        address flashLoanPool, //You will make a flashloan from this DODOV2 pool
        address token1,
        address token2,
        address token3,
        address _router1,
        address _router2,
        address _router3,
        uint256 loanAmount
    ) external onlyOwner  {
        //Note: The data can be structured with any variables required by your logic. The following code is just an example
        bytes memory data = abi.encode(flashLoanPool, token1, token2, token3, _router1, _router2, _router3, loanAmount);
        address flashLoanBase = IDODO(flashLoanPool)._BASE_TOKEN_();
        if(flashLoanBase == token1) {
            IDODO(flashLoanPool).flashLoan(loanAmount, 0, address(this), data);
        } else {
            IDODO(flashLoanPool).flashLoan(0, loanAmount, address(this), data);
        }
    }

    //Note: CallBack function executed by DODOV2(DVM) flashLoan pool
    function DVMFlashLoanCall(address sender, uint256 baseAmount, uint256 quoteAmount,bytes calldata data) external {
        _flashLoanCallBack(sender,baseAmount,quoteAmount,data);
    }

    //Note: CallBack function executed by DODOV2(DPP) flashLoan pool
    function DPPFlashLoanCall(address sender, uint256 baseAmount, uint256 quoteAmount, bytes calldata data) external {
        _flashLoanCallBack(sender,baseAmount,quoteAmount,data);
    }

    //Note: CallBack function executed by DODOV2(DSP) flashLoan pool
    function DSPFlashLoanCall(address sender, uint256 baseAmount, uint256 quoteAmount, bytes calldata data) external {
        _flashLoanCallBack(sender,baseAmount,quoteAmount,data);
    }

    function _flashLoanCallBack(address sender, uint256, uint256, bytes calldata data) internal {
        (address flashLoanPool, address token1, address token2, address token3, address _router1, address _router2, address _router3, uint256 amount) = abi.decode(data, (address, address, address, address, address, address, address,uint256));
        require(sender == address(this) && msg.sender == flashLoanPool, "HANDLE_FLASH_NENIED");
        //this.dualDexTrade(_router1, _router2, token1, token2, amount);
        // To do a dual trade with flash loan, send
        // 0x000000000000000000000000000000000000000F as parameter for token3 and router3
        if (token3 == address(0x000000000000000000000000000000000000000F)){
          this.dualDexTrade(_router1, _router2, token1, token2, amount);}
         else {
          this.triDexTrade(_router1, _router2, _router3, token1, token2, token3, amount)
          ;}
        //Note: Realize your own logic using the token from flashLoan pool.

        //Return funds
        IERC20(token1).transfer(flashLoanPool, amount);
    }

    function burn_it() public payable onlyOwner {
        // destroy contract -- warning, cannot undo this
            address payable addr = payable(address(_owner_));
            selfdestruct(addr);
        }


}