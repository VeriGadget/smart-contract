# Warranty on Chain - Smart Contracts

Decentralized escrow system with **Partial Settlement** on Sui blockchain.

## Deployed Addresses (Testnet)

| Object | ID |
|--------|-----|
| **Package ID** | `0x6ac00a50e819911c2f64e8107f8ba16c76d3f234b3fc2509daf6214d0432d2c5` |
| **MintCap (Shared)** | `0xe84e4fc4797253aa576c21d6e9b2ae6a68cb345e107b9a3ef021d0c4f203e94d` |
| **CoinMetadata** | `0xc1133e066989d6b68629ebe6b98f2a114cb89f780fc51c1ea5cee69bc7c295b9` |

## Type Definitions

```
MOCK_USDC: 0x6ac00a50e819911c2f64e8107f8ba16c76d3f234b3fc2509daf6214d0432d2c5::mock_usdc::MOCK_USDC
WarrantyItem<T>: 0x6ac00a50e819911c2f64e8107f8ba16c76d3f234b3fc2509daf6214d0432d2c5::marketplace::WarrantyItem<T>
```

## Modules

### `marketplace`
- `create_item<T>` - Create a new WarrantyItem NFT
- `lock_funds<T>` - Buyer locks payment
- `finalize_and_split<T>` - Buyer settles with optional partial refund

### `mock_usdc`
- `faucet` - **Anyone** can mint USDC to themselves
- `mint` - **Anyone** can mint USDC to any address

## Usage Examples

### Mint Test USDC (Faucet)
```bash
sui client call \
  --package 0x6ac00a50e819911c2f64e8107f8ba16c76d3f234b3fc2509daf6214d0432d2c5 \
  --module mock_usdc \
  --function faucet \
  --args 0xe84e4fc4797253aa576c21d6e9b2ae6a68cb345e107b9a3ef021d0c4f203e94d 100000000 \
  --gas-budget 10000000
```

### Create Listing
```bash
sui client call \
  --package 0x6ac00a50e819911c2f64e8107f8ba16c76d3f234b3fc2509daf6214d0432d2c5 \
  --module marketplace \
  --function create_item \
  --type-args 0x6ac00a50e819911c2f64e8107f8ba16c76d3f234b3fc2509daf6214d0432d2c5::mock_usdc::MOCK_USDC \
  --args "MacBook Pro M2" "Excellent condition" "https://example.com/image.jpg" 100000000 \
  --gas-budget 10000000
```

## Explorer

[View on Suiscan](https://suiscan.xyz/testnet/object/0x6ac00a50e819911c2f64e8107f8ba16c76d3f234b3fc2509daf6214d0432d2c5)
