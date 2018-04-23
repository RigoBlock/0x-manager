pragma solidity ^0.4.22;

import { TokenTransferProxy } from "../protocol/TokenTransferProxy/TokenTransferProxy.sol";
import { Exchange } from "../protocol/Exchange/Exchange.sol";
import { WETH9 } from "../tokens/WETH9/WETH9.sol";
import { Token } from "../tokens/Token/Token.sol";

/// @notice this is a sample proxy with all possible reentrancy bugs
/// @notice this contract is used for testing transactions in an open environment
/// @notice works on 0x relayers, or just any 0x fork
contract FundProxy {

    address public ETHWRAPPER;
    address public EXCHANGE;

    uint public ethInProxy;
    
    constructor(
        address ethWrapper,
        address exchange)
        public
    {
        ETHWRAPPER = ethWrapper;
        EXCHANGE = exchange;
    }

    function() public payable {}
    
    function deposit() public payable {
        ethInProxy += msg.value;
    }
    
    function withdraw(uint amount) public {
        require(amount <= ethInProxy);
        msg.sender.transfer(amount);
        ethInProxy -= amount;
    }
    
    function setEthWrapper(
        address wrapper)
        public
    {
        ETHWRAPPER = wrapper;
    }

    function setExchange(
        address exchange)
        public
    {
        EXCHANGE = exchange;
    }

    function wrapEth(
        uint amount)
        public
    {
        WETH9 wrapper = WETH9(ETHWRAPPER);
        wrapper.deposit.value(amount)();
    }

    function unwrapEth(
        uint amount)
        public
    {
        WETH9 wrapper = WETH9(ETHWRAPPER);
        wrapper.withdraw(amount);
    }

    function setAllowances(
        address targetToken,
        address spender,
        uint amount)
        public
    {
        Token token = Token(targetToken);
        token.approve(spender, amount);
    }

    function fillOrder(
        address[5] orderAddresses,
        uint[6] orderValues,
        uint fillTakerTokenAmount,
        bool shouldThrowOnInsufficientBalanceOrAllowance,
        uint8 v,
        bytes32 r,
        bytes32 s)
        public
        returns (uint filledTakerTokenAmount)
    {
        Exchange exchange = Exchange(EXCHANGE);
        //address proxy = exchange.TOKEN_TRANSFER_PROXY_CONTRACT();
        //Token takerToken = Token(orderAddresses[3]);
        //takerToken.approve(proxy, orderValues[1]);
        filledTakerTokenAmount = exchange.fillOrder(
            orderAddresses,
            orderValues,
            fillTakerTokenAmount,
            shouldThrowOnInsufficientBalanceOrAllowance,
            v,
            r,
            s
        );
    }

/*
    function fillOrder(
        address[] orderAddresses,
        uint[] orderValues,
        uint fillTakerTokenAmount,
        bool shouldThrowOnInsufficientBalanceOrAllowance,
        uint8 v,
        bytes32 r,
        bytes32 s)
        public
        returns (uint filledTakerTokenAmount)
    {
        Exchange exchange = Exchange(EXCHANGE);
        //address proxy = exchange.TOKEN_TRANSFER_PROXY_CONTRACT();
        //Token takerToken = Token(orderAddresses[3]);
        //takerToken.approve(proxy, orderValues[1]);
        filledTakerTokenAmount = exchange.fillOrder(
            orderAddresses,
            orderValues,
            fillTakerTokenAmount,
            shouldThrowOnInsufficientBalanceOrAllowance,
            v,
            r,
            s
        );
    }
*/

    function thisBalance() public constant returns (uint) {
        return (address(this).balance);
    }
}