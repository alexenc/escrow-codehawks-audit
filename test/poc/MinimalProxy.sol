// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import "../../src/minimalProxie/EscrowProxieFactory.sol";
import "../../src/minimalProxie/EscrowImplementation.sol";
import "../../src/Escrow.sol";
import "../../src/EscrowFactory.sol";
import "../EscrowTestBase.t.sol";



contract EscrowFactoryProxyTest is Test, EscrowTestBase {
    EscrowFactoryProxy public factoryProxy;
    EscrowImplementation public escrowProxieImplementation;
    EscrowFactory public normalEscrowFactory;


    function setUp() public {        
        escrowProxieImplementation = new EscrowImplementation();
        factoryProxy = new EscrowFactoryProxy(address(escrowProxieImplementation));        

        normalEscrowFactory = new EscrowFactory();


    }

    function testProxyGas() public {
        vm.startPrank(BUYER);
        ERC20Mock(address(i_tokenContract)).mint(BUYER, PRICE * 100);        
        i_tokenContract.approve(address(factoryProxy),PRICE * 100 );
        // deploy 50 escrows to see the real benefict of minimal proxies and compare with the cost
        // of the same 50 deployments using the normal implementation

        for (uint i = 0; i < 50; i++) {            
            factoryProxy.newEscrow(
                PRICE,
                i_tokenContract,
                BUYER,
                SELLER,
                ARBITER,
                ARBITER_FEE
            );        
        }
        vm.stopPrank();
    }

    function testProxieCodeWorks() public {
        vm.startPrank(BUYER);
        ERC20Mock(address(i_tokenContract)).mint(BUYER, PRICE * 100);        
        i_tokenContract.approve(address(factoryProxy),PRICE * 100 );

        IEscrow escrowtotest = factoryProxy.newEscrow(
                PRICE,
                i_tokenContract,
                BUYER,
                SELLER,
                ARBITER,
                ARBITER_FEE
        ); 

        escrowtotest.confirmReceipt();

        assertEq(i_tokenContract.balanceOf(SELLER), PRICE);
        assertEq(escrowtotest.getArbiter(), ARBITER);         

    }

    function testNormalGas() public {
          vm.startPrank(BUYER);
        ERC20Mock(address(i_tokenContract)).mint(BUYER, PRICE * 100);        
        i_tokenContract.approve(address(normalEscrowFactory),PRICE * 100 );
        for (uint i = 0; i < 50; i++) {
            
            normalEscrowFactory.newEscrow(
                PRICE,
                i_tokenContract,                
                SELLER,
                ARBITER,
                ARBITER_FEE,
                keccak256(abi.encodePacked(i))
            );        

        }
        vm.stopPrank();

    }
}