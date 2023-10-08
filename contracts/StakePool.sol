// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakePool is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    IERC20 public xld;
    uint public remainReward;

    address public rewarder;

    mapping (address => uint) public stakes;
    mapping (address => uint) public rewards;

    event SetRewarder(address rewarder);
    event Stake(address user, uint amount);
    event Withdraw(address user, uint amount);
    event Claim(address user, uint amount);
    event AddReward(uint current, uint add);
    event SetReward(address[] users, uint[] amounts, uint total);

    constructor(IERC20 _xld) {
        xld = _xld;
    }

    function setRewarder(address _rewarder) external onlyOwner {
        rewarder = _rewarder;
        emit SetRewarder(_rewarder);
    }

    function stake(uint amount) external  {
        xld.safeTransferFrom(msg.sender, address(this), amount);
        stakes[msg.sender] = stakes[msg.sender].add(amount);
        emit Stake(msg.sender, amount);
    }

    function withdraw(uint amount) external {
        stakes[msg.sender] = stakes[msg.sender].sub(amount);
        xld.safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function claim(uint amount) external {
        rewards[msg.sender] = rewards[msg.sender].sub(amount);
        xld.safeTransfer(msg.sender, amount);
        emit Claim(msg.sender, amount);
    }

    function addReward(uint amount) external {
        uint current = remainReward;
        xld.safeTransferFrom(msg.sender, address(this), amount);
        remainReward = current.add(amount);
        emit AddReward(current, amount);
    }

    function setRewards(uint[] memory amounts, address[] memory users) external {
        require(msg.sender == rewarder, "Caller is not rewarder");
        require(amounts.length == users.length, "Length not match");
        uint len = amounts.length;
        uint total = 0;
        for(uint i = 0; i < len;i++) {
            rewards[users[i]] = rewards[users[i]].add(amounts[i]);
            total = total.add(amounts[i]);
        }

        require(remainReward >= total, "Remain reward not enough");
        remainReward = remainReward.sub(total); 
        emit SetReward(users, amounts, total);  
    }
}