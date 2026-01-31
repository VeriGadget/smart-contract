/// Module: warranty_protocol::mock_usdc
/// 
/// A mock USDC token for testing the escrow system on testnet.
/// This allows users to mint test tokens for transactions.
module warranty_protocol::mock_usdc {
    use sui::coin::{Self, TreasuryCap};

    /// One-Time Witness for creating the MOCK_USDC coin type
    public struct MOCK_USDC has drop {}

    /// Initialize the MOCK_USDC coin type with standard USDC-like metadata.
    /// TreasuryCap is transferred to the deployer for minting.
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
        
        // Transfer TreasuryCap to deployer for minting
        transfer::public_transfer(treasury_cap, ctx.sender());
    }

    /// Mint MOCK_USDC tokens to a specified recipient.
    /// Only the holder of TreasuryCap can mint.
    /// 
    /// Example: To mint 100 USDC (6 decimals), pass amount = 100_000_000
    public entry fun mint(
        treasury_cap: &mut TreasuryCap<MOCK_USDC>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let coin = coin::mint(treasury_cap, amount, ctx);
        transfer::public_transfer(coin, recipient);
    }
}
