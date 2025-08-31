// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SmartAccount.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SmartAccountFactory
 * @dev Factory para crear SmartAccounts de manera determinística
 * @notice Permite crear SmartAccounts usando CREATE2 para direcciones predecibles
 */
contract SmartAccountFactory is Ownable {
    
    event SmartAccountCreated(
        address indexed smartAccount, 
        address indexed owner, 
        bytes32 indexed salt
    );
    
    mapping(address => address[]) public userAccounts;
    mapping(address => bool) public isSmartAccount;
    
    constructor() Ownable(msg.sender) {}
    
    /**
     * @dev Crea una SmartAccount usando CREATE2
     * @param owner Dirección del propietario inicial
     * @param salt Salt único para generar dirección determinística
     * @return smartAccount Dirección de la SmartAccount creada
     */
    function createSmartAccount(
        address owner, 
        bytes32 salt
    ) external returns (address smartAccount) {
        require(owner != address(0), "Invalid owner address");
        
        bytes memory bytecode = abi.encodePacked(
            type(SmartAccount).creationCode
        );
        
        smartAccount = Create2.deploy(0, salt, bytecode);
        
        // Inicializar la SmartAccount
        SmartAccount(payable(smartAccount)).initialize(owner);
        
        // Registrar la cuenta
        userAccounts[owner].push(smartAccount);
        isSmartAccount[smartAccount] = true;
        
        emit SmartAccountCreated(smartAccount, owner, salt);
        
        return smartAccount;
    }
    
    /**
     * @dev Predice la dirección de una SmartAccount antes de crearla
     * @param salt Salt único
     * @return Dirección donde se desplegará la SmartAccount
     */
    function getSmartAccountAddress(
        bytes32 salt
    ) external view returns (address) {
        bytes memory bytecode = abi.encodePacked(
            type(SmartAccount).creationCode
        );
        
        return Create2.computeAddress(salt, keccak256(bytecode));
    }
    
    /**
     * @dev Crea una SmartAccount con salt automático basado en el owner
     * @param owner Dirección del propietario
     * @return smartAccount Dirección de la SmartAccount creada
     */
    function createSmartAccountAutoSalt(
        address owner
    ) external returns (address smartAccount) {
        bytes32 salt = keccak256(abi.encodePacked(
            owner, 
            userAccounts[owner].length,
            block.timestamp
        ));
        
        return this.createSmartAccount(owner, salt);
    }
    
    /**
     * @dev Obtiene todas las SmartAccounts de un usuario
     * @param user Dirección del usuario
     * @return Array de direcciones de SmartAccounts
     */
    function getUserAccounts(address user) external view returns (address[] memory) {
        return userAccounts[user];
    }
    
    /**
     * @dev Verifica si una dirección es una SmartAccount creada por esta factory
     * @param account Dirección a verificar
     * @return true si es una SmartAccount válida
     */
    function isValidSmartAccount(address account) external view returns (bool) {
        return isSmartAccount[account];
    }
    
    /**
     * @dev Obtiene el número de SmartAccounts creadas por un usuario
     * @param user Dirección del usuario
     * @return Número de SmartAccounts
     */
    function getUserAccountCount(address user) external view returns (uint256) {
        return userAccounts[user].length;
    }
}
