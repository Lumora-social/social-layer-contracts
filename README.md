# SuiNS Social Layer - Profile Contracts

Decentralized social profile system built on Sui blockchain with SuiNS integration.

## Overview

This package provides a comprehensive social layer protocol for the Sui blockchain, enabling users to create and manage decentralized profiles with social account verification, multi-wallet linking, and achievement badges. The system integrates with SuiNS (Sui Name Service) for identity verification and uses an oracle-based attestation system for secure off-chain verification.

## Tech Stack

- **Language**: Move (Sui blockchain)
- **Platform**: Sui
- **Edition**: 2024.beta
- **Dependencies**: 
  - SuiNS contracts (MystenLabs/suins-contracts)
  - Sui standard library

## Features

- **User Profiles**: Customizable profiles with display names, bios, images, and metadata
- **SuiNS Integration**: Identity verification through SuiNS domain ownership
- **Social Account Verification**: Secure linking of Twitter, Discord, Telegram, Google, and other social accounts via backend oracle attestation
- **Multi-Wallet Support**: Link wallets from multiple chains (SUI, ETH, SOL, BTC) to a single profile
- **Achievement Badges**: Dynamic badge system based on on-chain activity with tier upgrades
- **Following & Blocking**: Social graph management with follow and block functionality
- **Configurable System**: Admin-controlled configuration for validation rules and allowed platforms

## Module Structure

### Core Modules

#### `app`

The main entry point module that initializes the package and creates the `AdminCap` capability. This capability is required for administrative operations across the system.

#### `profile`

The core profile management module. Handles:

- Profile creation and ownership
- Display name management with uniqueness enforcement and cooldown periods
- Profile metadata (bio, images, URLs)
- Social graph operations (following, blocking)
- Profile archival
- Integration with SuiNS for identity verification

**Key Features:**
- Linked to SuiNS registration (SuinsRegistration NFT)
- Display name cooldown (10 minutes between changes)
- Social accounts stored as VecMap<String, String>
- Wallet addresses by chain (Bitcoin, Ethereum, Solana, etc.)
- Following and block lists using Table<address, bool>

#### `social_layer_registry`

A shared registry that maintains:

- **Display Name Registry**: Ensures display name uniqueness across all profiles
- **Address Registry**: Tracks which addresses have created profiles

This module prevents duplicate display names and provides a global lookup mechanism for profile existence.

#### `social_layer_config`

Configuration management module that defines:

- Validation rules (display name length, bio length)
- Allowed wallet keys (SUI, ETH, SOL, BTC)
- Allowed social platforms (Twitter, Discord, Telegram, Google)
- Version management for package upgrades
- Config manager capabilities for admin operations

#### `social_layer_constants`

Centralized constants for:

- Wallet key identifiers
- Social platform identifiers
- Length validation limits
- Helper functions for accessing constants

### Verification & Linking Modules

#### `oracle_utils`

Shared utilities for oracle signature verification used across verification modules. Provides:

- `OracleConfig`: Stores the backend oracle's Ed25519 public key
- Signature verification functions
- Timestamp validation utilities
- Admin functions for updating oracle public keys

This module is the foundation for all oracle-based attestation systems in the package.

#### `social_verification`

Secure social account linking using backend oracle attestation:

- Users verify social account ownership off-chain
- Backend creates and signs attestations with oracle private key
- Smart contract verifies signatures on-chain
- Supports Twitter, Discord, Telegram, Google, and other platforms
- Includes timestamp validation to prevent replay attacks

#### `wallet_linking`

Secure wallet linking for multiple blockchain networks:

- Links wallets from ETH, BTC, SOL, and SUI chains
- Uses backend oracle attestation for verification
- Users sign messages with external wallets off-chain
- Backend verifies signatures and creates attestations
- Smart contract validates attestations on-chain

#### `profile_badges`

Dynamic badge system for on-chain achievements:

- Generic badge structure with categories, tiers, and metadata
- Badges stored as dynamic fields on profiles
- Supports tier upgrades (never downgrades)
- Backend oracle signs badge eligibility attestations
- JSON metadata support for flexible badge definitions
- Badge minting and update operations

### Action Modules

#### `profile_actions`

High-level action module that combines multiple modules to provide convenient entry points:

- `create_profile`: Creates a new profile with basic information
- `create_profile_with_suins`: Creates a profile with SuiNS domain matching display name
- `link_social_account`: Links a social account to a profile
- `link_wallet`: Links a wallet to a profile
- `update_badges`: Updates profile badges
- `update_profile`: Updates profile metadata
- `follow_profile`: Follow another profile
- `unfollow_profile`: Unfollow a profile
- `block_profile`: Block a profile
- `unblock_profile`: Unblock a profile
- `archive_profile`: Archive a profile

This module provides a simplified API for common operations that would otherwise require multiple transactions.

## Project Structure

```
social-layer-contracts/
├── sources/
│   ├── profile/
│   │   ├── profile.move                   # Core profile module
│   │   ├── social_layer_registry.move     # Global registry
│   │   ├── social_layer_config.move       # Configuration
│   │   ├── social_layer_constants.move    # Constants
│   │   ├── social_verification.move       # Social verification
│   │   ├── wallet_linking.move            # Wallet linking
│   │   ├── profile_badges.move            # Badge system
│   │   └── oracle_utils.move              # Oracle utilities
│   ├── actions/
│   │   └── profile_actions.move           # Entry functions
│   └── app.move                           # App initialization
├── Move.toml                              # Package manifest
└── README.md
```

## Move.toml Configuration

```toml
[package]
name = "SuiNSSocialLayer"
version = "0.0.1"
edition = "2024.beta"

[dependencies]
suins = { git = "https://github.com/MystenLabs/suins-contracts", rev = "releases/core/4", subdir = "packages/suins", override = true }

[addresses]
suins_social_layer = "0x0"
```

## Profile Object Structure

```move
public struct Profile has key, store {
    id: UID,
    owner: address,
    display_name: String,
    display_image_url: Option<String>,
    background_image_url: Option<String>,
    url: Option<String>,
    bio: Option<String>,
    social_accounts: VecMap<String, String>,  // platform -> handle
    wallet_addresses: VecMap<String, vector<String>>,  // chain -> addresses
    following: Table<address, bool>,
    block_list: Table<address, bool>,
    is_archived: bool,
    created_at: u64,
    updated_at: u64,
    last_display_name_change_at: u64,
}
```

## Key Functions

### Profile Management
```move
// Create a new profile
public entry fun create_profile(
    suins_registration: &SuinsRegistration,
    display_name: String,
    display_image_url: Option<String>,
    background_image_url: Option<String>,
    url: Option<String>,
    bio: Option<String>,
    clock: &Clock,
    ctx: &mut TxContext
)

// Update profile metadata
public entry fun update_profile(
    profile: &mut Profile,
    display_image_url: Option<String>,
    background_image_url: Option<String>,
    url: Option<String>,
    bio: Option<String>,
    clock: &Clock,
    ctx: &mut TxContext
)

// Change display name (with cooldown)
public entry fun change_display_name(
    profile: &mut Profile,
    registry: &mut Registry,
    new_display_name: String,
    clock: &Clock,
    ctx: &mut TxContext
)
```

### Social Features
```move
// Add social account
public entry fun add_social_account(
    profile: &mut Profile,
    platform: String,
    handle: String,
    clock: &Clock,
    ctx: &mut TxContext
)

// Follow a user
public entry fun follow(
    profile: &mut Profile,
    target: address,
    clock: &Clock,
    ctx: &mut TxContext
)

// Block a user
public entry fun block(
    profile: &mut Profile,
    target: address,
    clock: &Clock,
    ctx: &mut TxContext
)
```

### Wallet Linking
```move
// Link Bitcoin address
public entry fun link_bitcoin_address(
    profile: &mut Profile,
    address: String,
    signature: vector<u8>,
    message: String,
    clock: &Clock,
    ctx: &mut TxContext
)
```

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 0 | EArchivedProfile | Profile is archived |
| 1 | ESenderNotOwner | Caller is not profile owner |
| 2 | EProfileAlreadyExists | Profile already exists for this address |
| 3 | EDisplayNameNotMatching | Display name doesn't match SuiNS name |
| 4 | EDisplayNameTaken | Display name already taken |
| 5 | EDisplayNameAlreadyTaken | Display name exists in registry |
| 6 | ESuinsRegistrationExpired | SuiNS registration has expired |
| 7 | EWalletKeyDoesNotExist | Wallet key not found |
| 8 | EDisplayNameChangeCooldown | Display name change cooldown active |

## Constants

- **Display Name Change Cooldown**: 600,000 ms (10 minutes)

## Building

```bash
sui move build
```

## Testing

```bash
sui move test
```

Run linting:

```bash
sui move lint
```

## Security Model

The system uses a multi-layered security approach:

1. **Oracle Attestation**: All external verifications (social accounts, wallets, badges) use backend oracle signatures with Ed25519 cryptography
2. **Timestamp Validation**: Attestations include timestamps with validity windows (10 minutes) and clock skew protection (5 seconds)
3. **Ownership Verification**: All profile modifications require ownership verification
4. **Registry Protection**: Display names are globally unique and protected by a shared registry
5. **Config Validation**: All operations validate against the current configuration version
6. **Cooldown Periods**: Display name changes have cooldown periods to prevent shared object contention

## Module Dependencies

```
app
├── profile
│   ├── social_layer_config
│   ├── social_layer_registry
│   └── social_layer_constants
├── social_verification
│   ├── oracle_utils
│   ├── profile
│   └── social_layer_config
├── wallet_linking
│   ├── oracle_utils
│   ├── profile
│   └── social_layer_config
├── profile_badges
│   ├── oracle_utils
│   ├── profile
│   └── social_layer_config
└── profile_actions
    ├── profile
    ├── social_verification
    ├── wallet_linking
    └── profile_badges
```

## Integration with SDK

These contracts are designed to work with the `lumora-social-layer-sdk` TypeScript package. The SDK provides:
- Transaction building
- Profile data fetching
- Event listening
- Wallet integration

## Events

The contracts emit events for:
- Profile creation
- Profile updates
- Display name changes
- Social account additions/removals
- Follow/unfollow actions
- Block/unblock actions
- Badge minting

## Security Considerations

- Profile ownership verified via transaction sender
- Display name changes rate-limited to prevent spam
- SuiNS registration must be valid and not expired
- Wallet linking requires cryptographic proof
- Oracle attestations for social verification

## License

MIT

## Related Projects

- [Lumora Social Layer SDK](../social-layer-sdk) - TypeScript SDK
- [Lumora Social APIs](../social-layer-apis) - API server
- [Lumora Indexer](../social-layer-indexer) - Blockchain indexer
- [Lumora Backend](../social-media-backend) - Backend services
- [Lumora UI](../social-media-ui) - Frontend application
