// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IMarketplace.sol";
import "../token/NativeToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MarketplaceCore is IMarketplaceCore, Ownable, ReentrancyGuard {
    uint256 private _itemIdCounter;
    uint256 private _transactionIdCounter;
    
    NativeToken public immutable nativeToken;
    address public escrowContract;
    address public feeManager;
    
    mapping(uint256 => Item) public items;
    mapping(uint256 => Transaction) public transactions;
    mapping(address => uint256[]) public userItems;
    mapping(address => uint256[]) public userTransactions;
    
    event ItemListed(uint256 indexed itemId, address indexed seller, uint256 price, string category);
    event ItemPurchased(uint256 indexed itemId, uint256 indexed transactionId, address indexed buyer, uint256 price);
    event BatchPurchased(uint256[] itemIds, uint256[] transactionIds, address indexed buyer);
    event ItemCancelled(uint256 indexed itemId, address indexed seller);
    event DeliveryConfirmed(uint256 indexed transactionId, address indexed buyer);
    
    modifier onlyEscrow() {
        require(msg.sender == escrowContract, "Only escrow can call");
        _;
    }
    
    modifier onlyFeeManager() {
        require(msg.sender == feeManager, "Only fee manager can call");
        _;
    }
    
    constructor(address _nativeToken) Ownable(msg.sender) {
        nativeToken = NativeToken(_nativeToken);
    }
    
    function setEscrowContract(address _escrow) external onlyOwner {
        require(_escrow != address(0), "Invalid escrow address");
        escrowContract = _escrow;
    }
    
    function setFeeManager(address _feeManager) external onlyOwner {
        require(_feeManager != address(0), "Invalid fee manager address");
        feeManager = _feeManager;
    }
    
    function listItem(
        uint256 price,
        string calldata metadataURI,
        string calldata category
    ) external override returns (uint256) {
        require(price > 0, "Price must be greater than 0");
        require(bytes(metadataURI).length > 0, "Metadata URI required");
        require(bytes(category).length > 0, "Category required");
        
        _itemIdCounter++;
        uint256 newItemId = _itemIdCounter;
        
        items[newItemId] = Item({
            id: newItemId,
            seller: msg.sender,
            price: price,
            metadataURI: metadataURI,
            category: category,
            isActive: true,
            createdAt: block.timestamp
        });
        
        userItems[msg.sender].push(newItemId);
        
        emit ItemListed(newItemId, msg.sender, price, category);
        return newItemId;
    }
    
    function buyItem(uint256 itemId) external override nonReentrant returns (uint256) {
        Item storage item = items[itemId];
        require(item.isActive, "Item not available");
        require(item.seller != msg.sender, "Cannot buy own item");
        require(nativeToken.balanceOf(msg.sender) >= item.price, "Insufficient balance");
        
        // Create transaction
        _transactionIdCounter++;
        uint256 newTransactionId = _transactionIdCounter;
        
        transactions[newTransactionId] = Transaction({
            id: newTransactionId,
            itemId: itemId,
            buyer: msg.sender,
            seller: item.seller,
            amount: item.price,
            timestamp: block.timestamp,
            isConfirmed: false,
            isDisputed: false
        });
        
        // Deactivate item
        item.isActive = false;
        
        // Transfer tokens to escrow
        require(nativeToken.transferFrom(msg.sender, escrowContract, item.price), "Transfer failed");
        
        // Lock funds in escrow
        IEscrow(escrowContract).lockFunds(newTransactionId, msg.sender, item.seller, item.price);
        
        userTransactions[msg.sender].push(newTransactionId);
        userTransactions[item.seller].push(newTransactionId);
        
        emit ItemPurchased(itemId, newTransactionId, msg.sender, item.price);
        return newTransactionId;
    }
    
    function buyBatch(uint256[] calldata itemIds) external override nonReentrant returns (uint256[] memory) {
        require(itemIds.length > 0, "Empty batch");
        require(itemIds.length <= 50, "Batch too large"); // Reasonable limit
        
        uint256 totalAmount = 0;
        uint256[] memory transactionIds = new uint256[](itemIds.length);
        
        // Calculate total amount and validate items
        for (uint256 i = 0; i < itemIds.length; i++) {
            Item storage item = items[itemIds[i]];
            require(item.isActive, "Item not available");
            require(item.seller != msg.sender, "Cannot buy own item");
            totalAmount += item.price;
        }
        
        require(nativeToken.balanceOf(msg.sender) >= totalAmount, "Insufficient balance");
        
        // Process each purchase
        for (uint256 i = 0; i < itemIds.length; i++) {
            Item storage item = items[itemIds[i]];
            
            _transactionIdCounter++;
            uint256 newTransactionId = _transactionIdCounter;
            transactionIds[i] = newTransactionId;
            
            transactions[newTransactionId] = Transaction({
                id: newTransactionId,
                itemId: itemIds[i],
                buyer: msg.sender,
                seller: item.seller,
                amount: item.price,
                timestamp: block.timestamp,
                isConfirmed: false,
                isDisputed: false
            });
            
            item.isActive = false;
            
            userTransactions[msg.sender].push(newTransactionId);
            userTransactions[item.seller].push(newTransactionId);
        }
        
        // Transfer total amount to escrow
        require(nativeToken.transferFrom(msg.sender, escrowContract, totalAmount), "Transfer failed");
        
        // Lock funds for each transaction
        for (uint256 i = 0; i < itemIds.length; i++) {
            Item storage item = items[itemIds[i]];
            IEscrow(escrowContract).lockFunds(transactionIds[i], msg.sender, item.seller, item.price);
        }
        
        emit BatchPurchased(itemIds, transactionIds, msg.sender);
        return transactionIds;
    }
    
    function cancelListing(uint256 itemId) external override {
        Item storage item = items[itemId];
        require(item.seller == msg.sender, "Not the seller");
        require(item.isActive, "Item not active");
        
        item.isActive = false;
        
        emit ItemCancelled(itemId, msg.sender);
    }
    
    function confirmDelivery(uint256 transactionId) external override {
        Transaction storage transaction = transactions[transactionId];
        require(transaction.buyer == msg.sender, "Not the buyer");
        require(!transaction.isConfirmed, "Already confirmed");
        require(!transaction.isDisputed, "Transaction disputed");
        
        transaction.isConfirmed = true;
        
        // Release funds from escrow
        IEscrow(escrowContract).releaseFunds(transactionId);
        
        emit DeliveryConfirmed(transactionId, msg.sender);
    }
    
    function getItemDetails(uint256 itemId) external view override returns (Item memory) {
        return items[itemId];
    }
    
    function getActiveListings() external view override returns (Item[] memory) {
        uint256 activeCount = 0;
        uint256 totalItems = _itemIdCounter;
        
        // Count active items
        for (uint256 i = 1; i <= totalItems; i++) {
            if (items[i].isActive) {
                activeCount++;
            }
        }
        
        Item[] memory activeItems = new Item[](activeCount);
        uint256 currentIndex = 0;
        
        // Populate active items
        for (uint256 i = 1; i <= totalItems; i++) {
            if (items[i].isActive) {
                activeItems[currentIndex] = items[i];
                currentIndex++;
            }
        }
        
        return activeItems;
    }
    
    function getUserItems(address user) external view returns (uint256[] memory) {
        return userItems[user];
    }
    
    function getUserTransactions(address user) external view returns (uint256[] memory) {
        return userTransactions[user];
    }
    
    function getTransactionDetails(uint256 transactionId) external view returns (Transaction memory) {
        return transactions[transactionId];
    }
    
    function getTotalItems() external view returns (uint256) {
        return _itemIdCounter;
    }
    
    function getTotalTransactions() external view returns (uint256) {
        return _transactionIdCounter;
    }
}
