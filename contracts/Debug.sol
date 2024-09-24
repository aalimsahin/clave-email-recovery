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
    {}

    function computeEmailAuthContractAddress(
        address recoveredAccount,
        bytes32 accountSalt,
        bytes memory initializationCode
    ) public view returns (address) {
        return
            L2ContractHelper.computeCreate2Address(
                address(this),
                accountSalt,
                bytes32(
                    0x01000079fe5d47bffb6ad03a28da66955df7842652c6be781d33bbcb757d1f5d
                ),
                keccak256(initializationCode)
            );
    }

    function deployEmailAuthProxyContract(
        address recoveredAccount,
        bytes32 accountSalt,
        bytes memory initializationCode
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
                        initializationCode
                    )
                )
            );
        require(success, "Failed to deploy email auth proxy contract");
        address payable proxyAddress = abi.decode(returnData, (address));

        return proxyAddress;
    }

    function computeEmailAuthAddressWithoutParameters(
        address recoveredAccount,
        bytes32 accountSalt
    ) public view returns (address) {
        return
            computeEmailAuthContractAddress(
                recoveredAccount,
                accountSalt,
                //! Only difference is the additional parameters passed to the initialize function
                abi.encode(emailAuthImplementation(), "")
            );
    }

    function deployEmailAuthProxyWithoutParameters(
        address recoveredAccount,
        bytes32 accountSalt
    ) public returns (address) {
        return
            deployEmailAuthProxyContract(
                recoveredAccount,
                accountSalt,
                //! Only difference is the additional parameters passed to the initialize function
                abi.encode(emailAuthImplementation(), "")
            );
    }

    address expectedAddressWithoutParameters;
    address deployedAddressWithoutParameters;

    function testWithoutParameters(
        address recoveredAccount,
        bytes32 accountSalt
    ) public {
        expectedAddressWithoutParameters = computeEmailAuthAddressWithoutParameters(
            recoveredAccount,
            accountSalt
        );
        deployedAddressWithoutParameters = deployEmailAuthProxyWithoutParameters(
            recoveredAccount,
            accountSalt
        );
    }

    function getAddressesWithoutParameters()
        public
        view
        returns (address, address)
    {
        return (
            expectedAddressWithoutParameters,
            deployedAddressWithoutParameters
        );
    }

    function computeEmailAuthAddressWithParams(
        address recoveredAccount,
        bytes32 accountSalt
    ) public view returns (address) {
        return
            computeEmailAuthContractAddress(
                recoveredAccount,
                accountSalt,
                //! Only difference is the additional parameters passed to the initialize function
                abi.encodeCall(
                    EmailAuth.initialize,
                    (recoveredAccount, accountSalt, address(this))
                )
            );
    }

    // TODO: Could not understand why this function is not working
    function deployEmailAuthProxyWithParams(
        address recoveredAccount,
        bytes32 accountSalt
    ) public returns (address) {
        return
            deployEmailAuthProxyContract(
                recoveredAccount,
                accountSalt,
                //! Only difference is the additional parameters passed to the initialize function
                abi.encodeCall(
                    EmailAuth.initialize,
                    (recoveredAccount, accountSalt, address(this))
                )
            );
    }

    address expectedAddressWithParams;
    address deployedAddressWithParams;

    function testWithParams(
        address recoveredAccount,
        bytes32 accountSalt
    ) public {
        expectedAddressWithParams = computeEmailAuthAddressWithParams(
            recoveredAccount,
            accountSalt
        );
        deployedAddressWithParams = deployEmailAuthProxyWithParams(
            recoveredAccount,
            accountSalt
        );
    }

    function getAddressesWithParams() public view returns (address, address) {
        return (expectedAddressWithParams, deployedAddressWithParams);
    }
}
