// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {EmailRecoveryModule} from "./EmailRecoveryModule.sol";
import {EmailAuth} from "@zk-email/ether-email-auth-contracts/src/EmailAuth.sol";
import {L2ContractHelper} from "@matterlabs/zksync-contracts/l2/contracts/L2ContractHelper.sol";
import {DEPLOYER_SYSTEM_CONTRACT} from "@matterlabs/zksync-contracts/l2/system-contracts/Constants.sol";
import {SystemContractsCaller} from "@matterlabs/zksync-contracts/l2/system-contracts/libraries/SystemContractsCaller.sol";

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                       TEST PURPOSE                         */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

contract Debug is EmailRecoveryModule {
    address emailAuthImpl;

    constructor(
        address _verifier,
        address _dkimRegistry,
        address _emailAuthImpl,
        address _commandHandler,
        address _factoryAddr
    )
        EmailRecoveryModule(
            _verifier,
            _dkimRegistry,
            _emailAuthImpl,
            _commandHandler,
            _factoryAddr
        )
    {
        emailAuthImpl = address(new EmailAuth());
    }

    function computeEmailAuthContractAddress(
        address recoveredAccount,
        bytes32 accountSalt
    ) public view returns (address) {
        return
            L2ContractHelper.computeCreate2Address(
                address(this),
                accountSalt,
                bytes32(
                    0x01000079fe5d47bffb6ad03a28da66955df7842652c6be781d33bbcb757d1f5d
                ),
                keccak256(
                    abi.encode(
                        emailAuthImpl,
                        abi.encodeWithSelector(
                            EmailAuth.initialize.selector,
                            recoveredAccount,
                            accountSalt,
                            address(this)
                        )
                    )
                )
            );
    }

    function deployEmailAuthProxyContract(
        address recoveredAccount,
        bytes32 accountSalt
    ) public returns (address) {
        (bool success, bytes memory returnData) = SystemContractsCaller
            .systemCallWithReturndata(
                uint32(gasleft()),
                address(DEPLOYER_SYSTEM_CONTRACT),
                uint128(0),
                abi.encodeCall(
                    DEPLOYER_SYSTEM_CONTRACT.create2,
                    (
                        accountSalt,
                        0x01000079fe5d47bffb6ad03a28da66955df7842652c6be781d33bbcb757d1f5d,
                        abi.encode(
                            emailAuthImpl,
                            abi.encodeWithSelector(
                                EmailAuth.initialize.selector,
                                recoveredAccount,
                                accountSalt,
                                address(this)
                            )
                        )
                    )
                )
            );
        require(success, "Failed to deploy email auth proxy contract");
        address payable proxyAddress = abi.decode(returnData, (address));

        return proxyAddress;
    }

    address expectedAddress;
    address deployedAddress;
    bytes32 initedSalt;

    function test(address recoveredAccount, bytes32 accountSalt) public {
        expectedAddress = computeEmailAuthContractAddress(
            recoveredAccount,
            accountSalt
        );
        deployedAddress = deployEmailAuthProxyContract(
            recoveredAccount,
            accountSalt
        );
        EmailAuth emailAuth = EmailAuth(deployedAddress);
        initedSalt = emailAuth.accountSalt();
    }

    function getAddresses() public view returns (address, address, bytes32) {
        return (expectedAddress, deployedAddress, initedSalt);
    }
}
