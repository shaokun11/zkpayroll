// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IL1bridge {
    function deposit(
        address _l2Receiver,
        address _l1Token,
        uint256 _amount,
        uint256 _l2TxGasLimit,
        uint256 _l2TxGasPerPubdataByte,
        address _refundRecipient
    ) external payable returns (bytes32 txHash);
}

interface IZKSync {
    function l2TransactionBaseCost(
        uint256 _gasPrice,
        uint256 _l2GasLimit,
        uint256 _l2GasPerPubdataByteLimit
    ) external view returns (uint256);
}
//ERC20 0xF29678EA751F0EadCee11cE3627469CB0F9B42F5
//0x927ddfcc55164a59e0f33918d13a2d559bc10ce7
//0x4122342048f9dfc0e44E01d4EC61067B9e39e581

contract ZKPayRollL1 {
    event TransferCommited(address sender, uint totalAmount, address token, uint index, bytes32 l2TxHash);

    using SafeERC20 for IERC20;

    uint constant public gasPerPubdataByte = 800;
    address public bridge = 0x927DdFcc55164a59E0F33918D13a2D559bC10ce7;
    address public zkSync = 0x1908e2BF4a88F91E4eF0DC72f02b8Ea36BEa2319;

    function estimateGas(uint gasPrice, uint gasUsage) external view returns(uint fee) {
        fee = IZKSync(zkSync).l2TransactionBaseCost(gasPrice, gasUsage, gasPerPubdataByte);
    }

    function commitTransfer(address l2Contract, address token, uint index, uint amount, uint gasUsage) external payable {
        if(token != address(0)) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            IERC20(token).approve(address(bridge), amount);
            bytes32 txHash = IL1bridge(bridge).deposit{value: msg.value}(l2Contract, token, amount, gasUsage, gasPerPubdataByte, msg.sender);
            emit TransferCommited(msg.sender, amount, token, index, txHash);
        }
    }
}