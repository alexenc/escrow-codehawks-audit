// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;


import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EscrowImplementation} from "./EscrowImplementation.sol";
import {IEscrowFactory} from "../IEscrowFactory.sol";
import {IEscrow} from "../IEscrow.sol";
import {Escrow} from "../Escrow.sol";



contract ProxieDeployerBase {
    using SafeERC20 for IERC20;
     
    address[] public proxies;

    function deployClone(
        address _implementationContract, 
        uint256 price,
        IERC20 tokenContract,
        address buyer,
        address seller,
        address arbiter,
        uint256 arbiterFee
    ) internal returns (address) {
        // convert the address to 20 bytes
        bytes20 implementationContractInBytes = bytes20(_implementationContract);
        //address to assign a cloned proxy
        address proxy;
        
    
        // as stated earlier, the minimal proxy has this bytecode
        // <3d602d80600a3d3981f3363d3d373d3d3d363d73><address of implementation contract><5af43d82803e903d91602b57fd5bf3>

        // <3d602d80600a3d3981f3> == creation code which copies runtime code into memory and deploys it

        // <363d3d373d3d3d363d73> <address of implementation contract> <5af43d82803e903d91602b57fd5bf3> == runtime code that makes a delegatecall to the implentation contract
 

        assembly {
            /*
            reads the 32 bytes of memory starting at the pointer stored in 0x40
            In solidity, the 0x40 slot in memory is special: it contains the "free memory pointer"
            which points to the end of the currently allocated memory.
            */
            let clone := mload(0x40)
            // store 32 bytes to memory starting at "clone"
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )

            /*
              |              20 bytes                |
            0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
                                                      ^
                                                      pointer
            */
            // store 32 bytes to memory starting at "clone" + 20 bytes
            // 0x14 = 20
            mstore(add(clone, 0x14), implementationContractInBytes)

            /*
              |               20 bytes               |                 20 bytes              |
            0x3d602d80600a3d3981f3363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe
                                                                                              ^
                                                                                              pointer
            */
            // store 32 bytes to memory starting at "clone" + 40 bytes
            // 0x28 = 40
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            /*
            |                 20 bytes                  |          20 bytes          |           15 bytes          |
            0x3d602d80600a3d3981f3363d3d373d3d3d363d73b<implementationContractInBytes>5af43d82803e903d91602b57fd5bf3 == 45 bytes in total
            */
            
            
            // create a new contract
            // send 0 Ether
            // code starts at the pointer stored in "clone"
            // code size == 0x37 (55 bytes)
            proxy := create(0, clone, 0x37)
        }
        // transfer Token to implementation address 
        tokenContract.safeTransferFrom(msg.sender, proxy, price);

        // Call initialization
        EscrowImplementation(proxy).initializer(
            price,
            tokenContract,
            buyer,
            seller,
            arbiter,
            arbiterFee
        );
        proxies.push(proxy);
        return proxy;
    }
}

/// @author Cyfrin
/// @title EscrowFactory
/// @notice Factory contract for deploying Escrow contracts.
contract EscrowFactoryProxy is  ProxieDeployerBase {
    using SafeERC20 for IERC20;
    address immutable EscrowImplementationAddress;

    event EscrowCreated(address indexed escrowAddress, address indexed buyer, address indexed seller, address arbiter);


    constructor(address _escrowImplementationAddress) {
        EscrowImplementationAddress = _escrowImplementationAddress;
    }    

    function newEscrow(
        uint256 price,
        IERC20 tokenContract,
        address buyer,
        address seller,
        address arbiter,
        uint256 arbiterFee
    ) external returns (IEscrow) {
        address escrow = deployClone(
            EscrowImplementationAddress, 
            price,
            tokenContract,
            buyer,
            seller,
            arbiter,
            arbiterFee
        );
        emit EscrowCreated(address(escrow), msg.sender, seller, arbiter);
        return IEscrow(escrow);
    }

    /// @dev See https://docs.soliditylang.org/en/latest/control-structures.html#salted-contract-creations-create2
    function computeEscrowAddress(
        bytes memory byteCode,
        address deployer,
        uint256 salt,
        uint256 price,
        IERC20 tokenContract,
        address buyer,
        address seller,
        address arbiter,
        uint256 arbiterFee
    ) public pure returns (address) {
        address predictedAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            deployer,
                            salt,
                            keccak256(
                                abi.encodePacked(
                                    byteCode, abi.encode(price, tokenContract, buyer, seller, arbiter, arbiterFee)
                                )
                            )
                        )
                    )
                )
            )
        );
        return predictedAddress;
    }
}



