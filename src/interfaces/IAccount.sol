// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAccountFactory {
    function createAccount(address owner, uint256 salt) external returns (address);
    function getAccountAddress(address owner, uint256 salt) external view returns (address);
    function isAccountDeployed(address account) external view returns (bool);
}

interface ISmartAccount {
    function execute(address target, uint256 value, bytes calldata data) external returns (bytes memory);
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external returns (bytes[] memory);
    function validateUserOp(
        bytes32 userOpHash,
        uint256 maxCost
    ) external view returns (uint256 validationData);
    function addOwner(address newOwner) external;
    function removeOwner(address owner) external;
    function setGuardian(address guardian) external;
}

interface IPaymaster {
    function validatePaymasterUserOp(
        bytes32 userOpHash,
        uint256 maxCost
    ) external view returns (bytes memory context, uint256 validationData);
    function postOp(
        uint8 mode,
        bytes calldata context,
        uint256 actualGasCost
    ) external;
    function depositFor(address account, uint256 amount) external;
    function withdrawTo(address recipient, uint256 amount) external;
}
