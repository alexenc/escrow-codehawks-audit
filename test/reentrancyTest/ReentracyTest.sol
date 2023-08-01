// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {ReentrantVulnerable, Attacker} from "../../src/ReentrantExample/Reentrant.sol";

contract Reentrancytest is Test {
    address public constant USER_1 = address(1);
    address public constant USER_2 = address(2);
    address public constant USER_3 = address(3);
    ReentrantVulnerable public target;
    Attacker public attacker;

    function setUp() public {
      target = new ReentrantVulnerable();
      attacker = new Attacker(target);
      vm.deal(USER_1, 5 ether);
      vm.deal(USER_2, 5 ether);
      vm.deal(USER_3, 5 ether);

   
    }

    function test_reentrancy() public {
        vm.startPrank(USER_1);
        target.deposit{value: USER_1.balance}();     
        vm.stopPrank();
        vm.startPrank(USER_2);
        target.deposit{value: USER_2.balance}();
        vm.stopPrank();
        vm.startPrank(USER_3);

        attacker.prepararAtaque{value: 1 ether}();
        attacker.ejecutarAtaque();
        
        console.log(target.getUserBalance(USER_1));
        assertEq(USER_3.balance, 15 ether);
    }

    function invariant_reentrant() external {
    assertEq(target.totalBalance(), address(target).balance);
    }
}