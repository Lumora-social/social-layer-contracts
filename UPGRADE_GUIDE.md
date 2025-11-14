# Package Upgrade Guide

This guide provides step-by-step instructions for safely upgrading the SuiNSSocialLayer package.

---

## Overview

When upgrading a Sui Move package, the package code is updated but on-chain objects (like `Config`) retain their current state. The `Config` object has a `version` field that must be updated to match the new `PACKAGE_VERSION` after upgrade, otherwise all operations will fail.

**Critical:** The migration function **MUST** be called immediately after package upgrade.

---

## Pre-Upgrade Checklist

Before upgrading the package:

- [ ] Review all changes in the new package version
- [ ] Verify `PACKAGE_VERSION` constant in `social_layer_config.move`
- [ ] Test migration function on testnet
- [ ] Prepare migration transaction script
- [ ] Notify team of upgrade window
- [ ] Backup current package and Config object state

---

## Upgrade Process

### Step 1: Deploy New Package

Deploy the upgraded package to the network:

```bash
sui client publish --gas-budget 100000000
```

**Note:** Save the package ID and upgrade cap from the deployment output.

### Step 2: Immediately Call Migration Function

**CRITICAL:** This must be done immediately after deployment, before any user operations.

#### Option A: Using `update_config_to_latest_version()` (Recommended)

This convenience function automatically migrates to the current `PACKAGE_VERSION`:

```typescript
// TypeScript/JavaScript example
import { TransactionBlock } from "@mysten/sui.js";

const tx = new TransactionBlock();

// Get Config shared object ID and ConfigManagerCap
const configId = "0x..."; // Your Config shared object ID
const configManagerCapId = "0x..."; // Your ConfigManagerCap object ID

tx.moveCall({
  target: `${PACKAGE_ID}::social_layer_config::update_config_to_latest_version`,
  arguments: [tx.object(configManagerCapId), tx.object(configId)],
});

// Sign and execute
const result = await signer.signAndExecuteTransactionBlock({
  transactionBlock: tx,
});
```

#### Option B: Using `migrate_config()` (For Specific Version)

If you need to migrate to a specific version:

```typescript
const tx = new TransactionBlock();

tx.moveCall({
  target: `${PACKAGE_ID}::social_layer_config::migrate_config`,
  arguments: [
    tx.object(configManagerCapId),
    tx.object(configId),
    tx.pure(2), // Target version
  ],
});
```

### Step 3: Verify Migration

Verify that the Config version was updated:

```typescript
const config = await provider.getObject({
  id: configId,
  options: { showContent: true },
});

const version = config.data.content.fields.version;
console.log(`Config version: ${version}`);
console.log(`Expected version: ${PACKAGE_VERSION}`);

if (version !== PACKAGE_VERSION) {
  throw new Error("Migration failed!");
}
```

### Step 4: Test Critical Operations

Test that operations work correctly:

```typescript
// Test creating a profile
// Test updating a profile
// Test minting badges
// Test linking wallets/social accounts
```

---

## Migration Function Details

### `migrate_config()`

Migrates Config from one version to another.

**Parameters:**

- `config_manager_cap: &ConfigManagerCap` - Capability proving caller is config manager
- `config: &mut Config` - The Config shared object to migrate
- `target_version: u64` - Target version (must be <= PACKAGE_VERSION)
- `ctx: &mut TxContext` - Transaction context

**Aborts:**

- `EAddressIsNotConfigManager` - If caller is not the config manager
- `EInvalidMigrationVersion` - If target_version is invalid
- `EConfigAlreadyAtTargetVersion` - If config is already at target version

**Supported Migrations:**

- v1 → v2
- v2 → v3
- Step-by-step migration required (cannot skip versions)

### `update_config_to_latest_version()`

Convenience function that calls `migrate_config()` with `PACKAGE_VERSION`.

**Parameters:**

- `config_manager_cap: &ConfigManagerCap` - Capability proving caller is config manager
- `config: &mut Config` - The Config shared object to update
- `ctx: &mut TxContext` - Transaction context

---

## Version-Specific Migration Notes

### Migration v1 → v2

**When:** Package upgraded from v1 to v2

**Changes:**

- Config version field updated from 1 to 2
- No new fields added (if new fields are added in v2, they will be initialized here)

**Migration Code:**

```move
if (config.version == 1 && target_version == 2) {
    config.version = 2;
    // Add any new field initialization here if Config struct is extended in v2
    // Example: config.new_field = default_value;
}
```

### Migration v2 → v3

**When:** Package upgraded from v2 to v3

**Changes:**

- Config version field updated from 2 to 3
- Add any new field initialization if Config struct is extended

**Migration Code:**

```move
else if (config.version == 2 && target_version == 3) {
    config.version = 3;
    // Add migration logic for v2 -> v3 here
}
```

---

## Post-Upgrade Verification

After migration, verify:

1. **Config Version:**

   ```bash
   sui client object <CONFIG_ID>
   ```

   Verify `version` field matches `PACKAGE_VERSION`.

2. **Operations Work:**

   - Create a test profile
   - Update profile fields
   - Mint badges
   - Link wallets/social accounts

3. **Monitor Error Rates:**
   - Check for `ENotLatestVersion` errors
   - Monitor transaction success rates
   - Check event logs

---

## Rollback Procedure

If upgrade fails or issues are discovered:

1. **Stop User Operations:**

   - Pause frontend if possible
   - Notify users

2. **Revert Package:**

   - Deploy previous package version
   - Call migration function to revert Config version if needed

3. **Investigate:**
   - Review error logs
   - Test on testnet
   - Fix issues before retry

---

## Common Issues

### Issue: Migration Function Fails

**Error:** `EAddressIsNotConfigManager`

**Solution:** Ensure you're using the correct `ConfigManagerCap` and the sender is the config manager.

### Issue: Operations Still Failing After Migration

**Error:** `ENotLatestVersion`

**Possible Causes:**

1. Migration not called
2. Migration failed silently
3. Config version not updated

**Solution:**

1. Verify Config version: `sui client object <CONFIG_ID>`
2. Check migration transaction succeeded
3. Re-run migration if needed

### Issue: Cannot Migrate to Target Version

**Error:** `EInvalidMigrationVersion`

**Possible Causes:**

1. Target version > PACKAGE_VERSION
2. Trying to skip versions (e.g., v1 → v3)

**Solution:**

1. Migrate step-by-step (v1 → v2, then v2 → v3)
2. Ensure target_version <= PACKAGE_VERSION

---

## Best Practices

1. **Always Test on Testnet First:**

   - Deploy to testnet
   - Test migration function
   - Verify all operations work

2. **Schedule Upgrade Window:**

   - Choose low-traffic period
   - Notify users in advance
   - Have rollback plan ready

3. **Monitor After Upgrade:**

   - Watch error rates
   - Monitor transaction success
   - Check Config version

4. **Document Changes:**

   - Keep changelog
   - Document breaking changes
   - Update this guide

5. **Automate When Possible:**
   - Create migration script
   - Automate verification
   - Set up monitoring alerts

---

## Example Migration Script

```typescript
// migrate-config.ts
import { SuiClient, getFullnodeUrl } from "@mysten/sui.js/client";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { fromB64 } from "@mysten/sui.js/utils";

const PACKAGE_ID = process.env.PACKAGE_ID!;
const CONFIG_ID = process.env.CONFIG_ID!;
const CONFIG_MANAGER_CAP_ID = process.env.CONFIG_MANAGER_CAP_ID!;
const PRIVATE_KEY = process.env.PRIVATE_KEY!;

async function migrateConfig() {
  const client = new SuiClient({ url: getFullnodeUrl("mainnet") });
  const keypair = Ed25519Keypair.fromSecretKey(fromB64(PRIVATE_KEY));

  // Get current Config version
  const config = await client.getObject({
    id: CONFIG_ID,
    options: { showContent: true },
  });
  const currentVersion = config.data?.content?.fields?.version;
  console.log(`Current Config version: ${currentVersion}`);

  // Create migration transaction
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::social_layer_config::update_config_to_latest_version`,
    arguments: [tx.object(CONFIG_MANAGER_CAP_ID), tx.object(CONFIG_ID)],
  });

  // Execute transaction
  console.log("Executing migration...");
  const result = await client.signAndExecuteTransactionBlock({
    signer: keypair,
    transactionBlock: tx,
    options: {
      showEffects: true,
      showEvents: true,
    },
  });

  console.log("Migration transaction:", result.digest);

  // Verify migration
  const updatedConfig = await client.getObject({
    id: CONFIG_ID,
    options: { showContent: true },
  });
  const newVersion = updatedConfig.data?.content?.fields?.version;
  console.log(`New Config version: ${newVersion}`);

  if (newVersion === currentVersion) {
    throw new Error("Migration failed - version not updated!");
  }

  console.log("✅ Migration successful!");
}

migrateConfig().catch(console.error);
```

---

## Support

For issues or questions:

1. Check this guide first
2. Review error messages
3. Test on testnet
4. Contact development team

---

**Last Updated:** After implementing migration functions  
**Package Version:** 1.0.0
