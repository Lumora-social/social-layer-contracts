# Why the System Will Be Broken After Upgrade

## The Failure Scenario

### Current State (Package v1)
- **Package code**: `PACKAGE_VERSION = 1`
- **Config object on-chain**: `version: 1`
- **Result**: ✅ Everything works - `1 == 1` passes the check

### After Package Upgrade (Package v2)
- **Package code**: `PACKAGE_VERSION = 2` (updated in new package)
- **Config object on-chain**: `version: 1` (unchanged - objects persist across upgrades)
- **Result**: ❌ **Everything breaks** - `1 == 2` fails the check

## What Breaks?

The `assert_interacting_with_most_up_to_date_package(config)` check is called in **22 places** across **5 modules**:

### 1. Profile Operations (14 calls)
- `set_display_name_helper` - Can't change display name
- `set_bio` - Can't set bio
- `remove_bio` - Can't remove bio
- `set_display_image_url` - Can't set profile image
- `remove_display_image_url` - Can't remove profile image
- `set_background_image_url` - Can't set background image
- `remove_background_image_url` - Can't remove background image
- `set_url` - Can't set URL
- `remove_url` - Can't remove URL
- `add_wallet_address` - Can't add wallet addresses
- `update_wallet_address` - Can't update wallet addresses
- `remove_wallet_address` - Can't remove wallet addresses
- `archive_profile` - Can't archive profiles
- `unarchive_profile` - Can't unarchive profiles

### 2. Badge Operations (1 call)
- `mint_badges` - Can't mint badges

### 3. Social Verification (2 calls)
- `link_twitter_account`, `link_discord_account`, `link_telegram_account`, `link_google_account` - Can't link social accounts
- `unlink_social_account` - Can't unlink social accounts

### 4. Wallet Linking (3 calls)
- `link_sui_wallet` - Can't link Sui wallets
- `link_evm_wallet` - Can't link EVM wallets
- `link_solana_wallet` - Can't link Solana wallets
- `unlink_wallet` - Can't unlink wallets

### 5. Config Operations (2 calls)
- `assign_config_manager` - Can't assign config manager

## The Exact Failure

When any of these functions are called:

```move
public fun set_bio(
    profile: &mut Profile,
    bio: String,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);  // ❌ FAILS HERE
    // ... rest of function never executes
}
```

The check fails:
```move
public fun assert_interacting_with_most_up_to_date_package(config: &Config) {
    assert!(config.version == PACKAGE_VERSION, ENotLatestVersion);
    // config.version = 1 (from on-chain object)
    // PACKAGE_VERSION = 2 (from new package code)
    // 1 == 2 → FALSE → Assertion fails → Transaction aborts
}
```

## Why Objects Don't Auto-Update

In Sui Move:
- **Package code** is upgraded (new bytecode deployed)
- **On-chain objects** remain unchanged (they persist with their current state)
- The Config object on-chain still has `version: 1` after the package upgrade
- You must explicitly call a function to update the object's version

## Solutions

### Option 1: Migration Function (Recommended)
Create a migration function that updates the Config version:

```move
public fun migrate_config_v1_to_v2(
    config: &mut Config,
    admin_cap: &AdminCap,
    ctx: &mut TxContext,
) {
    assert!(config.version == 1, ENotLatestVersion);
    config.version = 2;
    // Handle any new fields if added
}
```

**Process**:
1. Deploy new package (v2) with migration function
2. Call `migrate_config_v1_to_v2` to update Config object
3. Now all operations work again

### Option 2: Simple Version Bump Function
If you're not adding new fields to Config, you could add a simple function:

```move
public fun update_config_version(
    config: &mut Config,
    config_manager_cap: &ConfigManagerCap,
    new_version: u64,
    ctx: &mut TxContext,
) {
    assert_address_is_config_manager(config_manager_cap, config, ctx);
    config.version = new_version;
}
```

**Process**:
1. Deploy new package (v2)
2. Call `update_config_version(config, 2)` to bump version
3. Now all operations work again

### Option 3: Allow Version Range (Not Recommended for Your Use Case)
If you wanted old configs to work, you'd change the check to allow a range:

```move
public fun assert_interacting_with_most_up_to_date_package(config: &Config) {
    assert!(
        config.version >= MIN_SUPPORTED_VERSION && 
        config.version <= PACKAGE_VERSION,
        ENotLatestVersion
    );
}
```

But you said you **don't want old configs to work**, so this option doesn't apply.

## Timeline of Failure

1. **Before upgrade**: System works fine ✅
2. **Package upgrade deployed**: New code with `PACKAGE_VERSION = 2` is live
3. **Config object still has `version: 1`**: On-chain state unchanged
4. **User tries to update profile**: Transaction fails with `ENotLatestVersion` ❌
5. **User tries to mint badge**: Transaction fails with `ENotLatestVersion` ❌
6. **User tries to link wallet**: Transaction fails with `ENotLatestVersion` ❌
7. **System is completely broken** until Config is migrated

## The Critical Point

**You MUST migrate the Config object BEFORE users try to use the system after upgrade.**

If you don't:
- Every user transaction will fail
- The system is unusable
- You have a production outage

## Recommendation

Implement migration functions **in the new package version** before deploying, then:
1. Deploy package v2
2. Immediately call migration function(s) to update all shared objects
3. Verify migrations succeeded
4. System is now operational

This ensures zero downtime if done correctly.

