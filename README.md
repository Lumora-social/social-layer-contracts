# SuiNS Social Layer - Profile Contracts

Decentralized social profile system built on Sui blockchain with SuiNS integration.

## Overview

The SuiNS Social Layer Profile contracts provide a complete profile management system with features like:

- User profiles with customizable metadata
- SuiNS integration for identity verification
- Social account verification via oracle
- Achievement badges based on on-chain activity
- Secure multi-wallet management

## Core Modules

### Profile Management (`profile.move`)

Core profile structure and lifecycle management.

### Profile Registry (`social_layer_registry.move`)

Central registry for profile discovery and lookup.

### Social Verification (`social_verification.move`)

Oracle-based verification system for linking external social accounts (Twitter, GitHub, etc.).

### Profile Badges (`profile_badges.move`)

Achievement badge system that tracks on-chain activity and milestones.

### Secure Wallet Link (`secure_wallet_link.move`)

Secure management of multiple wallet addresses per profile.

### Configuration (`social_layer_config.move`)

Global configuration and access control for the social layer.

## Profile Actions

Entry functions for profile management:

**Profile Creation**
- `create_profile` - Create a new profile
- `create_profile_with_suins` - Create profile with SuiNS registration

**Profile Updates**
- `set_display_name` - Update display name
- `set_bio` - Set biography text
- `set_display_image_url` - Set profile picture
- `set_background_image_url` - Set profile banner
- `set_url` - Set profile URL

**Wallet Management**
- `add_wallet_address` - Link additional wallet
- `remove_wallet_address` - Unlink wallet

**Profile Lifecycle**
- `archive_profile` - Archive (deactivate) profile
- `unarchive_profile` - Restore archived profile
- `delete_profile` - Permanently delete profile

## Building

```bash
sui move build
```

## Testing

```bash
sui move test
```

## License

MIT
