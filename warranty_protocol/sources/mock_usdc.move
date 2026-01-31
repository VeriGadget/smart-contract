/// Module: warranty_protocol::mock_usdc
/// 
/// A mock USDC token for testing the escrow system on testnet.
/// This allows ANY user to mint test tokens for transactions (faucet-style).
module warranty_protocol::mock_usdc {
    use sui::coin::{Self, TreasuryCap};

    /// One-Time Witness for creating the MOCK_USDC coin type
    public struct MOCK_USDC has drop {}

    /// Shared wrapper for TreasuryCap so anyone can mint
    public struct MintCap has key {
        id: UID,
        treasury_cap: TreasuryCap<MOCK_USDC>,
    }

    /// Initialize the MOCK_USDC coin type with standard USDC-like metadata.
    /// TreasuryCap is wrapped and shared so anyone can mint.
    fun init(witness: MOCK_USDC, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency<MOCK_USDC>(
            witness,
            6,  // decimals (standard USDC)
            b"USDC",
            b"Mock USDC",
            b"Mock USDC token for testing Warranty on Chain escrow system",
            option::none(),
            ctx
        );

        // Freeze metadata - it won't change
        transfer::public_freeze_object(metadata);
        
        // Wrap TreasuryCap and share it so anyone can mint
        let mint_cap = MintCap {
            id: object::new(ctx),
            treasury_cap,
        };
        transfer::share_object(mint_cap);
    }

    /// Public faucet function - ANYONE can mint MOCK_USDC tokens.
    /// Mints to the caller's address.
    /// 
    /// Example: To mint 100 USDC (6 decimals), pass amount = 100_000_000
    public entry fun faucet(
        mint_cap: &mut MintCap,
        amount: u64,
        ctx: &mut TxContext
    ) {
        let coin = coin::mint(&mut mint_cap.treasury_cap, amount, ctx);
        transfer::public_transfer(coin, ctx.sender());
    }

    /// Mint MOCK_USDC tokens to a specified recipient.
    /// Anyone can call this function.
    /// 
    /// Example: To mint 100 USDC (6 decimals), pass amount = 100_000_000
    public entry fun mint(
        mint_cap: &mut MintCap,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let coin = coin::mint(&mut mint_cap.treasury_cap, amount, ctx);
        transfer::public_transfer(coin, recipient);
    }
}
