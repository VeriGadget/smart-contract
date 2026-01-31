# Warranty on Chain - Smart Contract

Decentralized escrow system with **Partial Settlement** feature on Sui blockchain.

## 📦 Deployed Addresses (Testnet)

| Object | Address |
|--------|---------|
| **Package ID** | `0xbf20685a067656c10214bd81e2297a6871cb472a5462f43367c946e4f65e6418` |
| **TreasuryCap (USDC)** | `0xc26c0b361ccf368bda4a94f6ad08a5bfc657bc5d09a408c27989174b7f18447b` |
| **CoinMetadata (USDC)** | `0x6652bae8c6fd7b9a24131dd457be184f105135f3f94447ecbb6542e904afa2a6` |
| **Display Object** | `0x27cad91f2c3df0db3466554ce8c420cdd9e044b44f92e0d4ca02dd62ff048113` |
| **UpgradeCap** | `0x7505fe3e8353232550246a1a159cd45982c1a00558c8d7bd884a740f60b211c2` |
| **Publisher** | `0xfdb686a87fafd1ced735ccfed36dfe43826a403ae4e4a5c8f17853bc06cc8cd1` |

## 🔧 Type Definitions

```
MOCK_USDC: 0xbf20685a067656c10214bd81e2297a6871cb472a5462f43367c946e4f65e6418::mock_usdc::MOCK_USDC
WarrantyItem: 0xbf20685a067656c10214bd81e2297a6871cb472a5462f43367c946e4f65e6418::marketplace::WarrantyItem<T>
```

## 📝 Modules

- `marketplace` - Main escrow logic (create_item, lock_funds, finalize_and_split)
- `mock_usdc` - Test token with mint function

## 🔗 Explorer

[View on Sui Explorer](https://suiscan.xyz/testnet/object/0xbf20685a067656c10214bd81e2297a6871cb472a5462f43367c946e4f65e6418)
