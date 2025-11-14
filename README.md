# SuiNS Social Layer - Profile Contracts

Decentralized social profile system built on Sui blockchain with SuiNS integration.

## Overview

This package provides a comprehensive social layer protocol for the Sui blockchain, enabling users to create and manage decentralized profiles with social account verification, multi-wallet linking, and achievement badges. The system integrates with SuiNS (Sui Name Service) for identity verification and uses an oracle-based attestation system for secure off-chain verification.

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

## Security Model

The system uses a multi-layered security approach:

1. **Oracle Attestation**: All external verifications (social accounts, wallets, badges) use backend oracle signatures with Ed25519 cryptography
2. **Timestamp Validation**: Attestations include timestamps with validity windows (10 minutes) and clock skew protection (5 seconds)
3. **Ownership Verification**: All profile modifications require ownership verification
4. **Registry Protection**: Display names are globally unique and protected by a shared registry
5. **Config Validation**: All operations validate against the current configuration version
6. **Cooldown Periods**: Display name changes have cooldown periods to prevent shared object contention

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

## License

MIT
