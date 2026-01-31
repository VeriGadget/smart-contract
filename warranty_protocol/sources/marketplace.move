/// Module: warranty_protocol::marketplace
/// 
/// A decentralized escrow system with Partial Settlement feature.
/// The Listing Item is a true NFT following Sui Display Standard for wallet/explorer visibility.
/// 
/// Key Features:
/// - NFT-based warranty items visible in Sui Wallet
/// - Shared Object pattern for discoverability
/// - Partial settlement: Buyer controls how much goes to seller vs refund
module warranty_protocol::marketplace {
    use std::string::{Self, String};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::event;
    use sui::package;
    use sui::display;

    // ===== Error Codes =====
    /// Caller is not the buyer
    const ENotBuyer: u64 = 0;
    /// Coin value does not match the item price
    const EAmountMismatch: u64 = 1;
    /// Invalid status for this operation
    const EInvalidStatus: u64 = 2;
    /// Amount for seller exceeds locked balance
    const EExcessiveAmount: u64 = 3;
    /// Item already has a buyer locked
    const EAlreadyLocked: u64 = 4;

    // ===== Status Constants =====
    const STATUS_LISTED: u8 = 0;
    const STATUS_LOCKED: u8 = 1;
    const STATUS_COMPLETED: u8 = 2;

    // ===== One-Time Witness for Display =====
    public struct MARKETPLACE has drop {}

    // ===== Core NFT Structure =====
    /// WarrantyItem is the NFT that represents a listing in the marketplace.
    /// It holds metadata for Display and escrowed funds.
    /// Generic type T allows any coin type (SUI, USDC, etc.)
    public struct WarrantyItem<phantom T> has key, store {
        id: UID,
        /// Item name - displayed in wallet
        name: String,
        /// Item description
        description: String,
        /// Image URL - displayed in wallet
        image_url: String,
        /// Expected price for the item
        price: u64,
        /// Current status: 0=Listed, 1=Locked, 2=Completed
        status: u8,
        /// Seller's address (creator of the listing)
        seller: address,
        /// Buyer's address (set when funds are locked)
        buyer: Option<address>,
        /// Escrowed funds stored inside the NFT
        balance: Balance<T>,
    }

    // ===== Events =====
    /// Emitted when a new WarrantyItem is created
    public struct ItemCreated has copy, drop {
        item_id: ID,
        seller: address,
        name: String,
        price: u64,
    }

    /// Emitted when a buyer locks funds into an item
    public struct FundsLocked has copy, drop {
        item_id: ID,
        buyer: address,
        amount: u64,
    }

    /// Emitted when the item is finalized with split settlement
    public struct ItemFinalized has copy, drop {
        item_id: ID,
        seller_amount: u64,
        buyer_refund: u64,
    }

    // ===== Module Initializer =====
    /// Sets up the Sui Display object for WarrantyItem.
    /// This makes the NFT appear with name and image in Sui Wallet/Explorer.
    fun init(otw: MARKETPLACE, ctx: &mut TxContext) {
        let publisher = package::claim(otw, ctx);
        
        // Create Display with fields mapped to WarrantyItem struct
        let mut display = display::new<WarrantyItem<sui::sui::SUI>>(&publisher, ctx);
        
        // Map display fields to NFT struct fields
        display.add(string::utf8(b"name"), string::utf8(b"{name}"));
        display.add(string::utf8(b"description"), string::utf8(b"{description}"));
        display.add(string::utf8(b"image_url"), string::utf8(b"{image_url}"));
        display.add(string::utf8(b"project_url"), string::utf8(b"https://warranty-on-chain.io"));
        
        // Commit the display configuration
        display.update_version();
        
        // Transfer ownership
        transfer::public_transfer(publisher, ctx.sender());
        transfer::public_transfer(display, ctx.sender());
    }

    // ===== Public Entry Functions =====

    /// Step 1: Seller creates a new WarrantyItem listing.
    /// The item becomes a Shared Object so buyers can discover and interact with it.
    public entry fun create_item<T>(
        name: vector<u8>,
        description: vector<u8>,
        image_url: vector<u8>,
        price: u64,
        ctx: &mut TxContext
    ) {
        let seller = ctx.sender();
        
        let item = WarrantyItem<T> {
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            image_url: string::utf8(image_url),
            price,
            status: STATUS_LISTED,
            seller,
            buyer: option::none(),
            balance: balance::zero<T>(),
        };

        // Emit creation event
        event::emit(ItemCreated {
            item_id: object::id(&item),
            seller,
            name: string::utf8(name),
            price,
        });

        // Share the object so it's discoverable by all parties
        transfer::share_object(item);
    }

    /// Step 2: Buyer locks funds into the WarrantyItem.
    /// The coin is converted to Balance and stored inside the NFT.
    public entry fun lock_funds<T>(
        item: &mut WarrantyItem<T>,
        payment: Coin<T>,
        ctx: &mut TxContext
    ) {
        // Validate: Item must be in Listed status
        assert!(item.status == STATUS_LISTED, EInvalidStatus);
        
        // Validate: Item must not already have a buyer
        assert!(item.buyer.is_none(), EAlreadyLocked);
        
        // Validate: Payment must match the price exactly
        let payment_value = coin::value(&payment);
        assert!(payment_value == item.price, EAmountMismatch);

        let buyer = ctx.sender();

        // Convert Coin to Balance and store in the item
        let payment_balance = coin::into_balance(payment);
        balance::join(&mut item.balance, payment_balance);

        // Record buyer and update status
        item.buyer = option::some(buyer);
        item.status = STATUS_LOCKED;

        // Emit lock event
        event::emit(FundsLocked {
            item_id: object::uid_to_inner(&item.id),
            buyer,
            amount: payment_value,
        });
    }

    /// Step 3: Buyer finalizes the transaction with PARTIAL SETTLEMENT.
    /// 
    /// === SPLIT AND REFUND LOGIC ===
    /// This is the unique feature of Warranty on Chain:
    /// 
    /// 1. The buyer specifies `amount_for_seller` - how much the seller deserves
    /// 2. That amount is sent directly to the seller
    /// 3. Any remaining balance (total_locked - amount_for_seller) is AUTOMATICALLY
    ///    refunded back to the buyer
    /// 
    /// Example:
    /// - Buyer locked 1000 SUI
    /// - Buyer approves 600 SUI for seller (maybe partial delivery or negotiated discount)
    /// - Seller receives: 600 SUI
    /// - Buyer receives: 400 SUI (automatic refund)
    /// 
    /// This enables dispute resolution without third-party arbitration.
    /// The buyer has full control to approve partial amounts based on satisfaction.
    public entry fun finalize_and_split<T>(
        item: &mut WarrantyItem<T>,
        amount_for_seller: u64,
        ctx: &mut TxContext
    ) {
        // Validate: Item must be in Locked status
        assert!(item.status == STATUS_LOCKED, EInvalidStatus);
        
        // Validate: Only the buyer can finalize
        let caller = ctx.sender();
        assert!(item.buyer.contains(&caller), ENotBuyer);
        
        // Get total locked amount
        let total_balance = balance::value(&item.balance);
        
        // Validate: Cannot send more than what's locked
        assert!(amount_for_seller <= total_balance, EExcessiveAmount);

        // === SPLIT LOGIC ===
        
        // 1. Calculate refund amount for buyer
        let buyer_refund_amount = total_balance - amount_for_seller;
        
        // 2. Extract seller's portion and send to seller
        if (amount_for_seller > 0) {
            let seller_balance = balance::split(&mut item.balance, amount_for_seller);
            let seller_coin = coin::from_balance(seller_balance, ctx);
            transfer::public_transfer(seller_coin, item.seller);
        };
        
        // 3. AUTOMATIC REFUND: Send remaining balance back to buyer
        if (buyer_refund_amount > 0) {
            let buyer_balance = balance::split(&mut item.balance, buyer_refund_amount);
            let buyer_coin = coin::from_balance(buyer_balance, ctx);
            transfer::public_transfer(buyer_coin, *item.buyer.borrow());
        };

        // Update status to completed
        item.status = STATUS_COMPLETED;

        // Emit finalization event with split details
        event::emit(ItemFinalized {
            item_id: object::uid_to_inner(&item.id),
            seller_amount: amount_for_seller,
            buyer_refund: buyer_refund_amount,
        });
    }

    // ===== View Functions =====

    /// Get the current status of a WarrantyItem
    public fun get_status<T>(item: &WarrantyItem<T>): u8 {
        item.status
    }

    /// Get the locked balance amount
    public fun get_balance<T>(item: &WarrantyItem<T>): u64 {
        balance::value(&item.balance)
    }

    /// Get the seller address
    public fun get_seller<T>(item: &WarrantyItem<T>): address {
        item.seller
    }

    /// Get the buyer address (if locked)
    public fun get_buyer<T>(item: &WarrantyItem<T>): Option<address> {
        item.buyer
    }

    /// Get the item price
    public fun get_price<T>(item: &WarrantyItem<T>): u64 {
        item.price
    }
}
