pragma solidity ^0.4.23;
pragma experimental "v0.5.0";

import { TokenTransferProxy } from "../protocol/TokenTransferProxy/TokenTransferProxy.sol";
import { Exchange } from "../protocol/Exchange/Exchange.sol";
import { WETH9 } from "../tokens/WETH9/WETH9.sol";
import { Token } from "../tokens/Token/Token.sol";

import { SafeMath_v1 as SafeMath } from "../../previous/SafeMath/SafeMath_v1.sol";

/// @notice this is a sample proxy with all possible reentrancy bugs
/// @notice this contract is used for testing transactions in an open environment
/// @notice works on 0x relayers, or just any 0x fork
contract FundProxy is SafeMath {

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

    function() external payable {}
    
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
        require(filledTakerTokenAmount != 0);
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

    /// @dev Cancels the input order.
    /// @param orderAddresses Array of order's maker, taker, makerToken, takerToken, and feeRecipient.
    /// @param orderValues Array of order's makerTokenAmount, takerTokenAmount, makerFee, takerFee, expirationTimestampInSec, and salt.
    /// @param cancelTakerTokenAmount Desired amount of takerToken to cancel in order.
    /// @return Amount of takerToken cancelled.
    function cancelOrder(
        address[5] orderAddresses,
        uint[6] orderValues,
        uint cancelTakerTokenAmount)
        public
        returns (uint)
    {
        return Exchange(EXCHANGE).cancelOrder(
            orderAddresses,
            orderValues,
            cancelTakerTokenAmount
        );
    }

    /// @dev Fills an order with specified parameters and ECDSA signature, throws if specified amount not filled entirely.
    /// @param orderAddresses Array of order's maker, taker, makerToken, takerToken, and feeRecipient.
    /// @param orderValues Array of order's makerTokenAmount, takerTokenAmount, makerFee, takerFee, expirationTimestampInSec, and salt.
    /// @param fillTakerTokenAmount Desired amount of takerToken to fill.
    /// @param v ECDSA signature parameter v.
    /// @param r ECDSA signature parameters r.
    /// @param s ECDSA signature parameters s.
    function fillOrKillOrder(
        address[5] orderAddresses,
        uint[6] orderValues,
        uint fillTakerTokenAmount,
        uint8 v,
        bytes32 r,
        bytes32 s)
        public
    {
        require(fillOrder(
            orderAddresses,
            orderValues,
            fillTakerTokenAmount,
            false,
            v,
            r,
            s
        ) == fillTakerTokenAmount);
    }
    
    /// @dev Synchronously executes multiple fill orders in a single transaction.
    /// @param orderAddresses Array of address arrays containing individual order addresses.
    /// @param orderValues Array of uint arrays containing individual order values.
    /// @param fillTakerTokenAmounts Array of desired amounts of takerToken to fill in orders.
    /// @param shouldThrowOnInsufficientBalanceOrAllowance Test if transfers will fail before attempting.
    /// @param v Array ECDSA signature v parameters.
    /// @param r Array of ECDSA signature r parameters.
    /// @param s Array of ECDSA signature s parameters.
    function batchFillOrders(
        address[5][] orderAddresses,
        uint[6][] orderValues,
        uint[] fillTakerTokenAmounts,
        bool shouldThrowOnInsufficientBalanceOrAllowance,
        uint8[] v,
        bytes32[] r,
        bytes32[] s)
        public
    {
        for (uint i = 0; i < orderAddresses.length; i++) {
            fillOrder(
                orderAddresses[i],
                orderValues[i],
                fillTakerTokenAmounts[i],
                shouldThrowOnInsufficientBalanceOrAllowance,
                v[i],
                r[i],
                s[i]
            );
        }
    }
    
    /// @dev Synchronously executes multiple fillOrKill orders in a single transaction.
    /// @param orderAddresses Array of address arrays containing individual order addresses.
    /// @param orderValues Array of uint arrays containing individual order values.
    /// @param fillTakerTokenAmounts Array of desired amounts of takerToken to fill in orders.
    /// @param v Array ECDSA signature v parameters.
    /// @param r Array of ECDSA signature r parameters.
    /// @param s Array of ECDSA signature s parameters.
    function batchFillOrKillOrders(
        address[5][] orderAddresses,
        uint[6][] orderValues,
        uint[] fillTakerTokenAmounts,
        uint8[] v,
        bytes32[] r,
        bytes32[] s)
        public
    {
        for (uint i = 0; i < orderAddresses.length; i++) {
            fillOrKillOrder(
                orderAddresses[i],
                orderValues[i],
                fillTakerTokenAmounts[i],
                v[i],
                r[i],
                s[i]
            );
        }
    }
    
    /// @dev Synchronously executes multiple fill orders in a single transaction until total fillTakerTokenAmount filled.
    /// @param orderAddresses Array of address arrays containing individual order addresses.
    /// @param orderValues Array of uint arrays containing individual order values.
    /// @param fillTakerTokenAmount Desired total amount of takerToken to fill in orders.
    /// @param shouldThrowOnInsufficientBalanceOrAllowance Test if transfers will fail before attempting.
    /// @param v Array ECDSA signature v parameters.
    /// @param r Array of ECDSA signature r parameters.
    /// @param s Array of ECDSA signature s parameters.
    /// @return Total amount of fillTakerTokenAmount filled in orders.
    function fillOrdersUpTo(
        address[5][] orderAddresses,
        uint[6][] orderValues,
        uint fillTakerTokenAmount,
        bool shouldThrowOnInsufficientBalanceOrAllowance,
        uint8[] v,
        bytes32[] r,
        bytes32[] s)
        public
        returns (uint)
    {
        uint filledTakerTokenAmount = 0;
        for (uint i = 0; i < orderAddresses.length; i++) {
            require(orderAddresses[i][3] == orderAddresses[0][3]); // takerToken must be the same for each order
            filledTakerTokenAmount = safeAdd(filledTakerTokenAmount, fillOrder(
                orderAddresses[i],
                orderValues[i],
                safeSub(fillTakerTokenAmount, filledTakerTokenAmount),
                shouldThrowOnInsufficientBalanceOrAllowance,
                v[i],
                r[i],
                s[i]
            ));
            if (filledTakerTokenAmount == fillTakerTokenAmount) break;
        }
        return filledTakerTokenAmount;
    }
    
    /// @dev Synchronously cancels multiple orders in a single transaction.
    /// @param orderAddresses Array of address arrays containing individual order addresses.
    /// @param orderValues Array of uint arrays containing individual order values.
    /// @param cancelTakerTokenAmounts Array of desired amounts of takerToken to cancel in orders.
    function batchCancelOrders(
        address[5][] orderAddresses,
        uint[6][] orderValues,
        uint[] cancelTakerTokenAmounts)
        public
    {
        for (uint i = 0; i < orderAddresses.length; i++) {
            cancelOrder(
                orderAddresses[i],
                orderValues[i],
                cancelTakerTokenAmounts[i]
            );
        }
    }

    function thisBalance() public constant returns (uint) {
        return (address(this).balance);
    }
    
    // THE FUNDPROXY ACTS AS EXTENSION LIBRARY TO DRAGO
    // THE BELOW FUNCTIONS GET IMPLEMENTED IN THE DRAGO DIRECTLY
    
    /// @dev Allows approved exchange to send a transaction to exchange
    /// @dev With data of signed/unsigned transaction
    /// @param _exchange Address of the exchange
    /// @param _assembledTransaction Bytes of the parameters of the call
    function operateOnExchange(address _exchange, bytes _assembledTransaction)
        external
        //whenApprovedExchange(msg.sender)
    {
        require(_exchange.call(_assembledTransaction));
    }
    
    function delegateTheCall(address _exchange, bytes _assembledTransaction)
        external
        //whenApprovedExchange(msg.sender)
    {
        require(_exchange.delegatecall(_assembledTransaction));
    }

    /// this function is used for debugging, direct operations on excange is for
    /// approved exchanges only
    function operateOnExchangeDirectly(address _exchange, bytes _assembledTransaction)
        external
        //ownerOrApprovedExchange()
        //whenApprovedExchange(_exchange)
    {
        bytes memory _data = _assembledTransaction;
        address _target = _exchange;
        bytes memory response;
        bool failed;
        assembly {
            let succeeded := call(sub(gas, 5000), _target, 0, add(_data, 0x20), mload(_data), 0, 0)
            response := mload(0)      // load delegatecall output
            failed := iszero(succeeded)
        }
        require(!failed);
    }

    function UseFundAsPureProxy(address _target, bytes _assembledTransaction)
        //external
        public
        //ownerOrApprovedExchange()
        //whenApprovedExchange(_exchange)
    {
        bytes memory _data = _assembledTransaction;
        //address _target = _exchange;
        //bytes memory response;
        //bool failed;
        assembly {
            let success := delegatecall(
                gas,                // gas
                _target,            // target address
                add(_data, 0x20),   // pointer to start of input
                mload(_data),       // length of input
                0,                  // put value if want to write output over input
                0)                  // output size (we have no output here)
            let size:= returndatasize

            let pointer := mload(0x40)
            //response := mload(0)      // load delegatecall output
            returndatacopy(pointer, 0, size)
            
            switch success
            case 0 {
                revert(pointer, size)
            }
            default {
                return(pointer, size)
            }
        }
    }
}

/*
    function isContract(address _target) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }
*/