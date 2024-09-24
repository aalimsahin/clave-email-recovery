// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {EmailRecoveryModule} from "./EmailRecoveryModule.sol";
import {EmailAuth} from "@zk-email/ether-email-auth-contracts/src/EmailAuth.sol";
import {L2ContractHelper} from '@matterlabs/zksync-contracts/l2/contracts/L2ContractHelper.sol';
import {DEPLOYER_SYSTEM_CONTRACT} from '@matterlabs/zksync-contracts/l2/system-contracts/Constants.sol';
import {SystemContractsCaller} from '@matterlabs/zksync-contracts/l2/system-contracts/libraries/SystemContractsCaller.sol';

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                       TEST PURPOSE                         */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

contract Debug is  EmailRecoveryModule {

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

    function computeEmailAuthAddressTest(
        address recoveredAccount,
        bytes32 accountSalt
    ) public view returns (address) {
        return
                L2ContractHelper.computeCreate2Address(
                    address(this),
                    accountSalt,
                    bytes32(0x01000079c82404627fc5a2f9658c02f7007f9914bf092673dc6c094fe7ff346b),
                    keccak256(abi.encode(emailAuthImplementation(),""))
                );
    }

    function deployEmailAuthProxyTest(
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
                    0x01000079c82404627fc5a2f9658c02f7007f9914bf092673dc6c094fe7ff346b,
                    abi.encode(emailAuthImplementation(),"")
                )
            )
        );
        require(success, "Failed to deploy email auth proxy");
        address payable proxyAddress = abi.decode(returnData, (address));
        EmailAuth guardianEmailAuth = EmailAuth(proxyAddress);
        return proxyAddress;
    }

    address a;
    address b;

    function test(
        address recoveredAccount,
        bytes32 accountSalt
    ) public returns (bool) {
        address guardian = computeEmailAuthAddressTest(recoveredAccount, accountSalt);
        address deployed = deployEmailAuthProxyTest(recoveredAccount, accountSalt);
        a = guardian;
        b = deployed;
        return guardian == deployed;
    }



    function addresses() public view returns (address, address) {
        return (a, b);
    }
}
