# Contract Repository Audit & Analysis

**Date:** 2025-01-27  
**Scope:** Complete audit of `social-layer-contracts` repository  
**Focus Areas:** Bugs, Unused Code, Code Duplication, Code Quality

---

## Executive Summary

This audit analyzed all 15 Move source files in the contracts repository. The codebase is generally well-structured but contains several issues that should be addressed:

- **3 Critical Bugs** requiring immediate attention
- **5 Code Duplication Issues** that can be refactored
- **4 Unused Functions/Code** that should be removed
- **8 Code Quality Issues** for improvement
- **5 TODO Comments** that need resolution

---

## 1. Critical Bugs

### 1.1 Incorrect Object ID Conversion in `post.move` (Line 278)

**Location:** `sources/posts/post.move:278`

**Issue:**

```move
event::emit(DeletePostEvent {
    post_id: object::id_from_address(id.to_address()),
    owner,
    timestamp: clock::timestamp_ms(clock),
});
```

**Problem:** `object::id_from_address(id.to_address())` is incorrect. The `id` is already a `UID`, and converting it to an address and back to an ID is wrong. This should use `object::uid_to_inner(&id)` or store the ID before destructuring.

**Fix:**

```move
let post_id = object::id(&post);
// ... destructure ...
event::emit(DeletePostEvent {
    post_id,
    owner,
    timestamp: clock::timestamp_ms(clock),
});
```

**Severity:** 🔴 **CRITICAL** - This will cause incorrect event emissions.

---

### 1.2 Missing Future Timestamp Validation in `secure_wallet_link.move` (Line 92)

**Location:** `sources/secure_wallet_link.move:92`

**Issue:**

```move
let current_time = clock::timestamp_ms(clock);
assert!(current_time - timestamp <= SIGNATURE_VALIDITY_MS, ETimestampExpired);
```

**Problem:** This only checks if the timestamp is not too old, but doesn't verify that `timestamp <= current_time`. This allows future timestamps, which could be exploited.

**Fix:**

```move
let current_time = clock::timestamp_ms(clock);
assert!(current_time >= timestamp, ETimestampExpired);
assert!(current_time - timestamp <= SIGNATURE_VALIDITY_MS, ETimestampExpired);
```

**Severity:** 🔴 **CRITICAL** - Security vulnerability allowing replay attacks with future timestamps.

---

### 1.3 Duplicate Wallet Addresses Allowed in `profile.move` (Line 444)

**Location:** `sources/profile.move:444`

**Issue:**

```move
let found = std::vector::contains(addresses, &address);
// assert!(!std::vector::contains(addresses, &address), EWalletAddressAlreadyLinked);
if (!found) {
    std::vector::push_back(addresses, address);
}
```

**Problem:** The assertion that prevents duplicate addresses is commented out. This allows the same wallet address to be added multiple times to the same network, which may not be intended behavior.

**Fix:** Either uncomment the assertion or add a proper error code and handle it:

```move
assert!(!std::vector::contains(addresses, &address), EWalletAddressAlreadyLinked);
std::vector::push_back(addresses, address);
```

**Severity:** 🟡 **MEDIUM** - May cause data inconsistency issues.

---

## 2. Code Duplication

### 2.1 Duplicate `verify_oracle_signature` Function

**Locations:**

- `sources/social_verification.move:282-295`
- `sources/profile_badges.move:412-420`

**Issue:** Identical signature verification logic exists in two modules.

**Recommendation:** Extract to a shared utility module or create a common verification module:

```move
// Create: sources/utils/oracle_verification.move
module suins_social_layer::oracle_verification;

public fun verify_oracle_signature(
    message: &vector<u8>,
    public_key: &vector<u8>,
    signature: &vector<u8>,
    invalid_format_error: u64,
    invalid_signature_error: u64,
) {
    assert!(vector::length(public_key) == 32, invalid_format_error);
    assert!(vector::length(signature) == 64, invalid_format_error);
    let is_valid = ed25519::ed25519_verify(signature, public_key, message);
    assert!(is_valid, invalid_signature_error);
}
```

**Impact:** Reduces code duplication, makes maintenance easier, ensures consistent verification logic.

---

### 2.2 Duplicate Timestamp Validation Logic

**Locations:**

- `sources/social_verification.move:209-213`
- `sources/profile_badges.move:130-134`
- `sources/secure_wallet_link.move:92` (incomplete)

**Issue:** Similar timestamp validation patterns are repeated across modules with slight variations.

**Recommendation:** Create a shared timestamp validation function:

```move
// In utils module
public fun assert_timestamp_valid(
    current_time: u64,
    timestamp: u64,
    validity_window_ms: u64,
    expired_error: u64,
) {
    assert!(current_time >= timestamp, expired_error);
    assert!(current_time - timestamp <= validity_window_ms, expired_error);
}
```

---

### 2.3 Overlapping Display Name Validation Functions

**Location:** `sources/social_layer_config.move:136-161`

**Issue:**

- `assert_display_name_length_is_valid` (lines 136-139) - checks length only
- `assert_display_name_is_valid` (lines 146-161) - checks length AND character validity

**Problem:** `assert_display_name_length_is_valid` is never used. The code always calls `assert_display_name_is_valid` which includes length checks.

**Recommendation:** Remove `assert_display_name_length_is_valid` since it's redundant.

---

### 2.4 Similar Message Construction Patterns

**Locations:**

- `sources/social_verification.move:247-279` - `construct_attestation_message`
- `sources/profile_badges.move:194-222` - `construct_badge_attestation_message`
- `sources/secure_wallet_link.move:228-257` - `construct_multichain_link_message`

**Issue:** All three functions construct messages by concatenating bytes with separators. The patterns are similar but not identical enough to merge directly.

**Recommendation:** Consider creating a generic message builder utility if more message types are added in the future.

---

## 3. Unused Code

### 3.1 Unused Function: `assert_display_name_length_is_valid`

**Location:** `sources/social_layer_config.move:136-139`

**Issue:** This function is defined but never called. All code uses `assert_display_name_is_valid` instead.

**Action:** Remove this function.

---

### 3.2 Commented Out Code in `message.move`

**Location:** `sources/messaging/message.move:78-81`

**Issue:**

```move
// public fun is_valid_message(sender: address, receiver: address, dm_whitelist: &DM_Whitelist): bool {
//     (sender == sender(dm_whitelist) && receiver == receiver(dm_whitelist)) ||
//     (sender == receiver(dm_whitelist) && receiver == sender(dm_whitelist))
// }
```

**Action:** Remove commented code or implement if needed.

---

### 3.3 Commented Out Event in `dm_whitelist.move`

**Location:** `sources/messaging/dm_whitelist.move:19-24`

**Issue:**

```move
// public struct DeleteDMWhitelistEvent has copy, drop {
//     conversation_id: ID,
//     sender: address,
//     receiver: address,
//     timestamp: u64,
// }
```

**Action:** Remove if not needed, or implement delete functionality if required.

---

### 3.4 Unused Import/Function

**Location:** Check all modules for unused imports

**Action:** Run `sui move lint` to identify unused imports and remove them.

---

## 4. Code Quality Issues

### 4.1 TODO Comments Requiring Attention

**Location:** Multiple files

1. **`social_verification.move:38`** - `//TODO: More than one?` (oracle public key)

   - **Action:** Decide if multiple oracle keys are needed. If not, remove TODO.

2. **`social_verification.move:45`** - `// TODO: Set actual backend public key during deployment`

   - **Action:** Document deployment process or add initialization parameter.

3. **`social_verification.move:256`** - `//TODO: Assert nummber of bytes is correcT????`

   - **Action:** Profile ID is always 32 bytes from `object::id_to_bytes()`. Add assertion or remove TODO.

4. **`profile.move:25`** - `//TODO: HAve is created via Suins here?`

   - **Action:** Clarify intent and either implement or document decision.

5. **`profile.move:196`** - `// TODO: Dangerous?`
   - **Action:** Review `uid_mut` function. If safe, remove TODO. If dangerous, add documentation or restrict access.

---

### 4.2 Inconsistent Error Handling

**Issue:** Some functions check conditions and return early, others use assertions. The pattern should be consistent.

**Examples:**

- `profile.move:444` - Uses `if (!found)` pattern
- `profile.move:290` - Uses `assert!()` pattern

**Recommendation:** Standardize on assertion-based error handling for consistency.

---

### 4.3 Missing Input Validation

**Location:** `sources/messaging/message.move:106`

**Issue:** `edit_message` doesn't validate that the sender is the message owner.

**Fix:**

```move
public fun edit_message(
    message: &mut Message,
    encryptedData: vector<u8>,
    clock: &Clock,
    ctx: &TxContext,
) {
    assert!(tx_context::sender(ctx) == message.sender, ESenderNotOwner);
    message.encryptedData = encryptedData;
    message.updated_at = clock::timestamp_ms(clock);
    emit_edit_message_event(message, clock);
}
```

---

### 4.4 Missing Input Validation in `delete_message`

**Location:** `sources/messaging/message.move:113`

**Issue:** `delete_message` doesn't verify the caller is the sender or receiver.

**Fix:** Add authorization check.

---

### 4.5 Inconsistent Clock Usage

**Issue:** Some functions take `&Clock`, others take `&mut Clock`. All should use `&Clock` unless mutation is required.

**Location:** Check all function signatures for consistency.

---

### 4.6 Magic Numbers

**Locations:**

- `sources/posts/post.move:15-16` - `MAX_CONTENT_LENGTH: u64 = 5000`, `MAX_ATTACHMENTS: u64 = 10`
- `sources/social_verification.move:29` - `ATTESTATION_VALIDITY_MS: u64 = 600000`
- `sources/secure_wallet_link.move:29` - `SIGNATURE_VALIDITY_MS: u64 = 300000`

**Status:** ✅ These are properly defined as constants, which is good practice.

---

### 4.7 Redundant Checks

**Location:** `sources/social_layer_config.move:46-50`

**Issue:** `assert_address_is_config_manager` checks both `config_manager_cap.config_manager` and `config.config_manager` against sender. The second check is redundant if the cap is trusted.

**Recommendation:** Document why both checks are needed, or remove redundant check.

---

### 4.8 Missing Archive Check in Some Functions

**Issue:** Some profile getter functions check `is_archived`, but not all functions that modify profiles check this.

**Example:** `follow_user`, `unfollow_user`, `block_user`, `unblock_user` check `is_archived`, which is good. But `add_wallet_address` and similar functions don't check if profile is archived.

**Recommendation:** Review all profile modification functions to ensure archived profiles cannot be modified (or document intentional exceptions).

---

## 5. Security Considerations

### 5.1 Oracle Public Key Initialization

**Location:** `sources/social_verification.move:44-52`

**Issue:** Oracle config is initialized with empty public key. Admin must set it later.

**Recommendation:**

- Add validation in `update_oracle_public_key` to ensure key is set before allowing social account linking
- Or require public key as init parameter

---

### 5.2 Nonce Registry Growth

**Location:** `sources/secure_wallet_link.move:34-47`

**Issue:** `NonceRegistry` stores all used nonces indefinitely, which will grow unbounded.

**Recommendation:** Consider implementing nonce expiration or cleanup mechanism for old nonces.

---

### 5.3 Registry Growth

**Location:** `sources/social_layer_registry.move:11-15`

**Issue:** `Registry` tables grow indefinitely as profiles are created.

**Recommendation:** Document this as expected behavior, or implement cleanup for deleted profiles (already done in `delete_profile`).

---

## 6. Architecture & Design

### 6.1 Module Organization

**Status:** ✅ Good separation of concerns:

- `profile.move` - Core profile logic
- `profile_actions.move` - Public entry points
- `post.move` - Post logic
- `post_actions.move` - Public entry points

This pattern is consistent and well-designed.

---

### 6.2 Event Emission

**Status:** ✅ Good event coverage for important state changes.

**Minor Issue:** Some events don't include all relevant fields. Review event structures for completeness.

---

### 6.3 Dynamic Fields Usage

**Status:** ✅ Good use of dynamic fields for extensibility (badges, custom profile data).

---

## 7. Testing Coverage

### 7.1 Test Files Present

**Status:** ✅ Test files exist for most modules:

- `profile_tests.move`
- `post_tests_simple.move`
- `profile_badges_tests_simple.move`
- `social_verification_tests_simple.move`
- `secure_wallet_link_tests_simple.move`
- `messaging_tests_simple.move`
- `social_interactions_tests.move`
- `social_layer_config_tests.move`

**Recommendation:** Ensure all critical paths are covered, especially:

- Error conditions
- Edge cases (empty strings, max lengths, etc.)
- Security-critical functions (signature verification, authorization)

---

## 8. Recommendations Summary

### Immediate Actions (Critical Bugs)

1. ✅ Fix `object::id_from_address` bug in `post.move:278`
2. ✅ Add future timestamp validation in `secure_wallet_link.move:92`
3. ✅ Decide on duplicate wallet address handling in `profile.move:444`

### High Priority (Code Quality)

4. ✅ Extract duplicate `verify_oracle_signature` to shared module
5. ✅ Remove unused `assert_display_name_length_is_valid` function
6. ✅ Add authorization checks to `edit_message` and `delete_message`
7. ✅ Resolve all TODO comments

### Medium Priority (Refactoring)

8. ✅ Extract timestamp validation to shared utility
9. ✅ Remove commented-out code
10. ✅ Standardize error handling patterns
11. ✅ Document nonce registry growth behavior

### Low Priority (Enhancements)

12. ✅ Consider generic message builder utility
13. ✅ Review all profile modification functions for archive checks
14. ✅ Add validation for oracle public key before use

---

## 9. Code Metrics

- **Total Modules:** 15
- **Total Functions:** ~150+
- **Code Duplication:** ~5 instances
- **Unused Code:** 4 items
- **TODO Comments:** 5
- **Critical Bugs:** 3
- **Test Files:** 8

---

## 10. Sui Upgrade Compatibility Analysis

### 10.1 Understanding Sui Package Upgrades

**Key Concepts:**

- Once published, packages are **immutable** - cannot be directly modified
- Upgrades create a **new package object** on-chain, leaving the original intact
- Old and new package versions can coexist
- **UpgradeCap** controls upgrade authority (must be secured or burned)
- **Upgrade Policies** control what changes are allowed:
  - **Compatible**: Add new functions/structs, maintain public compatibility
  - **Additive**: Only additions, no modifications to existing code
  - **Dependency-only**: Only update dependencies
  - **Immutable**: No future upgrades (irreversible)

### 10.2 Current Upgrade Readiness Assessment

#### ✅ **GOOD: Modules with Versioning**

**1. `dm_whitelist.move`**

- ✅ Has `VERSION` constant (line 9)
- ✅ Has `version` field in struct (line 28)
- ✅ Checks version before use (line 72)
- ✅ Ready for upgrades

**2. `group_whitelist.move`**

- ✅ Has `VERSION` constant (line 11)
- ✅ Has `version` field in struct (line 15)
- ✅ Checks version before use (line 79)
- ✅ Has `Cap` for migration (lines 68-69 comment)
- ✅ Ready for upgrades

**3. `subscription_whitelist.move`**

- ✅ Has `VERSION` constant (line 11)
- ✅ Has `PackageVersion` shared object (line 14)
- ✅ Has `PackageVersionCap` for migration (line 19)
- ✅ Checks version before use (line 128)
- ✅ **EXCELLENT** - Follows Sui best practices

#### ⚠️ **NEEDS IMPROVEMENT: Modules Without Proper Versioning**

**1. `social_layer_config.move` - Config Object**

- ⚠️ Has `version` field (line 23) but hardcoded to `1` (line 58)
- ⚠️ Checks `config.version == 1` (line 38) - **BREAKS on upgrade**
- ❌ No migration function to update version
- ❌ No `CURRENT_VERSION` constant

**Problem:** When upgrading to v2, all existing Config objects will fail the `version == 1` check, breaking the system.

**Fix Required:**

```move
const CURRENT_VERSION: u64 = 1;

public fun assert_interacting_with_most_up_to_date_package(config: &Config) {
    assert!(config.version == CURRENT_VERSION, ENotLatestVersion);
}

// Migration function for upgrades
public entry fun migrate_config_to_v2(
    _admin_cap: &AdminCap,
    config: &mut Config,
) {
    assert!(config.version == 1, EWrongVersion);
    config.version = 2;
    // Add any new fields or migration logic here
}
```

**2. `social_layer_registry.move` - Registry Object**

- ❌ No version field
- ❌ No version checks
- ⚠️ Shared object that will persist across upgrades

**Fix Required:**

```move
const VERSION: u64 = 1;

public struct Registry has key, store {
    id: UID,
    version: u64,  // ADD THIS
    display_name_registry: Table<String, bool>,
    address_registry: Table<address, bool>,
}

// Add version check in critical functions
public(package) fun add_entries(self: &mut Registry, ...) {
    assert!(self.version == VERSION, EWrongVersion);
    // ... rest of function
}
```

**3. `secure_wallet_link.move` - NonceRegistry**

- ❌ No version field
- ❌ No version checks
- ⚠️ Shared object that will persist across upgrades

**Fix Required:** Add versioning similar to Registry.

**4. `social_verification.move` - OracleConfig**

- ❌ No version field
- ❌ No version checks
- ⚠️ Shared object that will persist across upgrades

**Fix Required:** Add versioning similar to Registry.

#### ⚠️ **OWNED OBJECTS: Profile and Post**

**Profile (`profile.move`)**

- ✅ Uses dynamic fields for extensibility (good for upgrades)
- ⚠️ Struct has `store` ability - can be transferred (consider if this is desired)
- ⚠️ No version field in Profile struct
- ✅ Can add new fields via dynamic fields without breaking existing profiles

**Recommendation:**

- Keep using dynamic fields for new features
- Consider adding optional version field for tracking
- Document that Profile struct fields cannot be changed (only additions via DF)

**Post (`post.move`)**

- ✅ Similar to Profile - owned objects
- ✅ Can extend via dynamic fields if needed
- ⚠️ No version field

### 10.3 What CAN Be Changed During Upgrades

#### ✅ **SAFE Changes (Compatible Policy)**

1. **Add new public functions** - Safe, additive
2. **Add new structs** - Safe, additive
3. **Add new constants** - Safe
4. **Add new events** - Safe
5. **Add optional fields to shared objects** (with migration function)
6. **Add new modules** - Safe
7. **Update dependencies** (if using dependency-only policy)

#### ❌ **BREAKING Changes (Cannot Do)**

1. **Remove public functions** - Breaks clients
2. **Modify function signatures** - Breaks clients
3. **Remove struct fields** - Breaks existing objects
4. **Change struct field types** - Breaks existing objects
5. **Add required fields to owned objects** - Breaks existing objects
6. **Change error codes** - Breaks client error handling
7. **Modify existing function logic** (if it changes behavior)

### 10.4 Upgrade Strategy Recommendations

#### **Strategy 1: Versioned Shared Objects (RECOMMENDED)**

**For:** Config, Registry, NonceRegistry, OracleConfig

```move
// Step 1: Add version field
public struct Config has key {
    id: UID,
    version: u64,  // ADD THIS
    // ... existing fields
}

// Step 2: Add version constant
const CURRENT_VERSION: u64 = 1;

// Step 3: Check version in all functions
public fun assert_interacting_with_most_up_to_date_package(config: &Config) {
    assert!(config.version == CURRENT_VERSION, ENotLatestVersion);
}

// Step 4: Add migration function for upgrades
public entry fun migrate_config_to_v2(
    _admin_cap: &AdminCap,
    config: &mut Config,
) {
    assert!(config.version == 1, EWrongVersion);
    config.version = 2;
    // Add any new fields or data transformations here
}
```

#### **Strategy 2: Dynamic Fields for Extensibility**

**For:** Profile, Post (owned objects)

```move
// Instead of adding fields to struct, use dynamic fields
// This allows upgrades without breaking existing objects

// In upgrade v2:
public fun add_new_feature_to_profile(
    profile: &mut Profile,
    new_data: NewFeatureData,
) {
    df::add(&mut profile.id, b"new_feature", new_data);
}
```

#### **Strategy 3: Deprecation Pattern**

**For:** Functions that need to be replaced

```move
// Old function - mark as deprecated
#[deprecated]
public fun old_function(...) { ... }

// New function - add alongside old one
public fun new_function(...) { ... }
```

### 10.5 Critical Upgrade Issues to Fix

#### 🔴 **CRITICAL: Config Version Hardcoding**

**Location:** `social_layer_config.move:38`

**Issue:**

```move
assert!(config.version == 1, ENotLatestVersion);
```

**Problem:** This will break all existing Config objects when upgrading to v2.

**Fix:**

```move
const CURRENT_VERSION: u64 = 1;

public fun assert_interacting_with_most_up_to_date_package(config: &Config) {
    assert!(config.version == CURRENT_VERSION, ENotLatestVersion);
}

// Add migration function
public entry fun migrate_config(
    _admin_cap: &AdminCap,
    config: &mut Config,
    target_version: u64,
) {
    assert!(target_version == config.version + 1, EInvalidVersion);
    assert!(target_version <= CURRENT_VERSION, EInvalidVersion);

    if (target_version == 2) {
        // Migration logic for v2
        config.version = 2;
    };
}
```

#### 🟡 **HIGH: Missing Version Fields**

**Shared Objects Missing Versioning:**

1. `Registry` - `social_layer_registry.move`
2. `NonceRegistry` - `secure_wallet_link.move`
3. `OracleConfig` - `social_verification.move`

**Action:** Add version fields and checks to all shared objects.

#### 🟡 **MEDIUM: No Migration Functions**

**Issue:** No migration functions exist for any shared objects.

**Action:** Create migration functions for:

- Config
- Registry (when versioning is added)
- NonceRegistry (when versioning is added)
- OracleConfig (when versioning is added)

### 10.6 Upgrade Best Practices Checklist

#### ✅ **Before First Deployment:**

- [ ] Decide on upgrade policy (Compatible recommended)
- [ ] Secure UpgradeCap (multisig for production)
- [ ] Add version fields to all shared objects
- [ ] Add version constants and checks
- [ ] Use dynamic fields for extensibility in owned objects
- [ ] Document upgrade strategy

#### ✅ **For Each Upgrade:**

- [ ] Update `CURRENT_VERSION` constant
- [ ] Create migration function for shared objects
- [ ] Test migration on testnet first
- [ ] Verify compatibility with `--verify-compatibility` flag
- [ ] Update SDK/client code if needed
- [ ] Document breaking changes

#### ✅ **Code Patterns:**

- [x] Use version constants instead of hardcoded numbers
- [x] Check versions before accessing shared objects
- [x] Use dynamic fields for new features
- [x] Keep AdminCap for privileged operations
- [x] Document what can/cannot be changed

### 10.7 Upgrade Compatibility Matrix

| Component              | Current State  | Upgrade Ready? | Action Required                         |
| ---------------------- | -------------- | -------------- | --------------------------------------- |
| Config                 | Hardcoded v1   | ❌ NO          | Add CURRENT_VERSION, migration function |
| Registry               | No version     | ❌ NO          | Add version field and checks            |
| NonceRegistry          | No version     | ❌ NO          | Add version field and checks            |
| OracleConfig           | No version     | ❌ NO          | Add version field and checks            |
| DM_Whitelist           | ✅ Versioned   | ✅ YES         | None - ready                            |
| Group_Whitelist        | ✅ Versioned   | ✅ YES         | None - ready                            |
| Subscription_Whitelist | ✅ Versioned   | ✅ YES         | None - ready                            |
| Profile                | Dynamic fields | ⚠️ PARTIAL     | Consider optional version field         |
| Post                   | No version     | ⚠️ PARTIAL     | Consider optional version field         |

### 10.8 Recommended Upgrade Policy

**Recommended:** Use **"Compatible"** upgrade policy

**Reasoning:**

- Allows adding new functions and structs
- Maintains backward compatibility
- Most flexible for future development
- Can be made more restrictive later (but not less)

**UpgradeCap Management:**

- **Development:** Keep locally for rapid iteration
- **Testnet:** Store in secure wallet
- **Mainnet:** Transfer to multisig wallet or burn if immutability desired

### 10.9 Migration Function Template

```move
// Template for migrating shared objects
public entry fun migrate_to_version_2(
    _admin_cap: &AdminCap,
    shared_object: &mut SharedObject,
) {
    assert!(shared_object.version == 1, EWrongVersion);

    // Perform any data transformations
    // Add new fields if needed
    // Update version
    shared_object.version = 2;

    // Emit migration event
    event::emit(MigrationEvent {
        from_version: 1,
        to_version: 2,
        timestamp: clock::timestamp_ms(clock),
    });
}
```

---

## 11. Badge Flow Explanation

### 11.1 Overview

The badge system allows users to earn on-chain badges based on their wallet activity (e.g., SuiNS holdings, portfolio value). Badges are minted through a secure oracle-based attestation system where the backend verifies eligibility and signs attestations that users submit to the blockchain.

**Key Design Principles:**

- **Oracle-based verification**: Backend checks wallet activity off-chain
- **Cryptographic attestation**: Backend signs attestations with Ed25519
- **No-downgrade rule**: Users can never lose a higher-tier badge
- **Generic design**: No hardcoded badge types, extensible via metadata
- **Dynamic field storage**: Badges stored as dynamic fields on profiles

### 11.2 Complete Badge Flow

#### **Step 1: User Requests Badge Check**

User initiates badge minting through the frontend/SDK:

```typescript
// Frontend calls backend API
const attestation = await checkBadgeEligibility(
  profileId,
  walletAddress,
  linkedWallets
);
```

#### **Step 2: Backend Checks Eligibility**

Backend service checks wallet activity:

```typescript
// Backend checks on-chain data
const eligibleBadges = await badgeService.checkEligibility(
  walletAddress,
  linkedWallets
);
// Example: Checks SuiNS holdings, portfolio value, etc.
```

**Eligibility Criteria Examples:**

- SuiNS Portfolio badges: Based on number of SuiNS domains owned
- Value-based badges: Based on total portfolio value
- Activity badges: Based on transaction history

#### **Step 3: Backend Applies No-Downgrade Rule**

Backend fetches existing badges and ensures users never lose higher-tier badges:

```typescript
// Fetch existing badges from blockchain
const existingBadges = await fetchExistingBadges(profileId);

// Apply no-downgrade rule
const finalBadges = applyNoDowngradeRule(eligibleBadges, existingBadges);
```

**No-Downgrade Logic:**

- If user has "whale" badge (value: 1000) and now qualifies for "shrimp" (value: 100)
- Backend keeps "whale" badge, doesn't include "shrimp"
- Prevents users from losing achievements

#### **Step 4: Backend Constructs Attestation Message**

Backend constructs the message that will be signed:

```
Message Format: profile_id || "badges" || "||" || badges_bcs || "||" || timestamp
```

**Message Construction:**

1. Profile ID (32 bytes) - hex-encoded object ID
2. Platform identifier: `"badges"` (string)
3. Separator: `"||"` (prevents collision attacks)
4. Badges BCS: BCS-encoded vector of badge structs
5. Separator: `"||"`
6. Timestamp (8 bytes) - BCS-encoded u64

**Badge BCS Structure:**
Each badge is encoded as:

- `category` (String) - e.g., "suins_portfolio"
- `tier` (String) - e.g., "name_hodler", "whale"
- `display_name` (String) - e.g., "SuiNS Holder"
- `description` (String) - e.g., "Owns 5+ SuiNS domains"
- `image_url` (String) - Optional badge image URL
- `value` (u64) - Optional numeric value that qualified

#### **Step 5: Backend Signs Attestation**

Backend signs the message with Ed25519 private key:

```typescript
const message = constructBadgeAttestationMessage(
  profileId,
  finalBadges,
  timestamp
);

const signature = await signAttestation(message);
// Returns 64-byte Ed25519 signature
```

**Security:**

- Uses backend's Ed25519 keypair
- Signature is 64 bytes (no scheme byte prefix)
- Private key never leaves backend

#### **Step 6: User Submits Attestation to Blockchain**

User calls `mint_badges` function with the attestation:

```move
public fun mint_badges(
    profile: &mut Profile,
    badges_bcs: vector<u8>,      // BCS-encoded badges
    signature: vector<u8>,       // 64-byte Ed25519 signature
    timestamp: u64,              // When backend signed
    oracle_config: &OracleConfig, // Backend's public key
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
)
```

#### **Step 7: Contract Validations**

Contract performs multiple security checks:

**7.1 Authorization Check:**

```move
assert!(tx_context::sender(ctx) == profile::owner(profile), ESenderNotOwner);
```

- Only profile owner can mint badges

**7.2 Config Version Check:**

```move
config::assert_interacting_with_most_up_to_date_package(config);
```

- Ensures using latest package version

**7.3 Oracle Public Key Validation:**

```move
let oracle_public_key = get_oracle_public_key(oracle_config);
assert!(vector::length(&oracle_public_key) == 32, EInvalidMessageFormat);
```

- Verifies oracle key is set (32 bytes for Ed25519)

**7.4 Timestamp Validation:**

```move
let current_time = clock::timestamp_ms(clock);
assert!(
    current_time >= timestamp &&
    current_time - timestamp <= ATTESTATION_VALIDITY_MS,
    ETimestampExpired,
);
```

- Prevents replay attacks
- Attestation valid for 10 minutes (600,000 ms)
- Rejects future timestamps

**7.5 Message Reconstruction:**

```move
let message = construct_badge_attestation_message(
    object::id(profile),
    &badges_bcs,
    timestamp,
);
```

- Reconstructs exact message backend should have signed
- Must match backend's construction exactly

**7.6 Signature Verification:**

```move
verify_oracle_signature(&message, &oracle_public_key, &signature);
```

- Verifies Ed25519 signature
- Ensures attestation came from authorized backend
- Prevents forgery

#### **Step 8: Badge Deserialization**

Contract deserializes badges from BCS:

```move
let badges = deserialize_badges(&badges_bcs, current_time);
```

**Deserialization Process:**

1. Read vector length (number of badges)
2. For each badge:
   - Deserialize category (String)
   - Deserialize tier (String)
   - Deserialize display_name (String)
   - Deserialize description (String)
   - Deserialize image_url (Option<String>)
   - Deserialize value (Option<u64>)
   - Set `minted_at` to current time

#### **Step 9: Badge Collection Update**

Contract updates or creates badge collection:

**9.1 Get or Create Collection:**

```move
if (!df::exists_(profile::uid(profile), badge_collection_key)) {
    let collection = BadgeCollection {
        badges: vector::empty<Badge>(),
        last_updated: current_time,
    };
    df::add(profile::uid_mut(profile), badge_collection_key, collection);
}
```

**9.2 Update Badges with No-Downgrade Rule:**

```move
update_badge_collection_with_events(
    collection,
    badges,
    profile_id,
    profile_owner,
    current_time,
);
```

**Update Logic:**

- For each new badge:
  - Check if badge category already exists
  - If exists:
    - Compare values (if both have values)
    - **Only update if new value > existing value**
    - Emit `BadgeUpdatedEvent` if upgraded
  - If not exists:
    - Add new badge
    - Emit `BadgeMintedEvent`

**No-Downgrade Rule (Contract Side):**

```move
let should_update = if (
    option::is_some(&new_badge.value) &&
    option::is_some(&existing_badge.value)
) {
    let new_val = *option::borrow(&new_badge.value);
    let existing_val = *option::borrow(&existing_badge.value);
    new_val > existing_val  // Only upgrade, never downgrade
} else {
    true  // If no values, allow update
};
```

#### **Step 10: Event Emission**

Contract emits events for indexers:

**10.1 Per-Badge Events:**

- `BadgeMintedEvent` - When new badge is added
- `BadgeUpdatedEvent` - When existing badge is upgraded

**10.2 Summary Event:**

- `BadgesMintedEvent` - Backward compatibility, includes total badge count

### 11.3 Security Features

#### **1. Cryptographic Verification**

- Ed25519 signature ensures attestation authenticity
- Public key stored on-chain in `OracleConfig`
- Only backend with private key can create valid attestations

#### **2. Timestamp Expiration**

- 10-minute validity window prevents replay attacks
- Clock object ensures accurate time checking
- Future timestamps rejected

#### **3. Authorization**

- Only profile owner can mint badges
- Prevents unauthorized badge minting

#### **4. No-Downgrade Protection**

- Applied both on backend and contract
- Users never lose higher-tier badges
- Prevents gaming the system

#### **5. Message Format Protection**

- Separators (`||`) prevent collision attacks
- Fixed format ensures message integrity
- BCS encoding ensures type safety

### 11.4 Data Structures

#### **Badge Struct:**

```move
public struct Badge has copy, drop, store {
    category: String,           // Badge category identifier
    tier: String,               // Badge tier (e.g., "name_hodler")
    display_name: String,        // Human-readable name
    description: String,         // Badge description
    image_url: Option<String>,   // Optional badge image
    value: Option<u64>,         // Optional qualifying value
    minted_at: u64,             // When badge was minted
}
```

#### **BadgeCollection:**

```move
public struct BadgeCollection has store {
    badges: vector<Badge>,      // All badges for this profile
    last_updated: u64,          // Last update timestamp
}
```

**Storage:**

- Stored as dynamic field on Profile
- Key: `"badge_collection"` (String)
- Allows extensibility without struct changes

### 11.5 View Functions

#### **Get All Badges:**

```move
public fun get_badges(profile: &Profile): vector<Badge>
```

- Returns all badges for a profile
- Returns empty vector if no badges

#### **Check Badge Category:**

```move
public fun has_badge_category(profile: &Profile, category: String): bool
```

- Checks if profile has a specific badge category
- Useful for conditional logic

### 11.6 Error Handling

**Error Codes:**

- `EInvalidSignature` (0) - Signature verification failed
- `ETimestampExpired` (1) - Attestation expired (>10 minutes)
- `ESenderNotOwner` (2) - Caller is not profile owner
- `EInvalidMessageFormat` (3) - Invalid message format or lengths

### 11.7 Upgrade Considerations

**Badge System Upgrade-Friendliness:**

- ✅ Uses dynamic fields (extensible)
- ✅ Generic badge structure (no hardcoded types)
- ✅ Event-based (indexers can track changes)
- ⚠️ BCS format must remain compatible
- ⚠️ Message format must remain compatible

**What Can Change:**

- Add new badge categories (backend-side)
- Add new badge tiers (backend-side)
- Modify eligibility criteria (backend-side)
- Add new fields to Badge struct (with migration)

**What Cannot Change:**

- Message construction format (breaks signature verification)
- BCS encoding format (breaks deserialization)
- Badge struct field order/types (breaks existing badges)

### 11.8 Flow Diagram

```
┌─────────┐
│  User   │
└────┬────┘
     │ 1. Request badges
     ▼
┌─────────────────┐
│   Frontend/SDK  │
└────┬────────────┘
     │ 2. API call
     ▼
┌─────────────────┐
│     Backend     │
│  ┌───────────┐  │
│  │ Check     │  │ 3. Check wallet activity
│  │ Eligibility│  │
│  └─────┬─────┘  │
│        │        │
│  ┌─────▼─────┐  │
│  │ Apply     │  │ 4. Apply no-downgrade rule
│  │ No-Down-  │  │
│  │ grade     │  │
│  └─────┬─────┘  │
│        │        │
│  ┌─────▼─────┐  │
│  │ Construct │  │ 5. Build attestation message
│  │ Message   │  │
│  └─────┬─────┘  │
│        │        │
│  ┌─────▼─────┐  │
│  │ Sign with │  │ 6. Sign with Ed25519
│  │ Private   │  │
│  │ Key       │  │
│  └─────┬─────┘  │
└────────┼────────┘
         │ 7. Return attestation
         ▼
┌─────────────────┐
│   Frontend/SDK  │
└────┬────────────┘
     │ 8. Submit transaction
     ▼
┌─────────────────┐
│  Smart Contract │
│  ┌───────────┐  │
│  │ Verify    │  │ 9. Validate signature
│  │ Signature │  │
│  └─────┬─────┘  │
│        │        │
│  ┌─────▼─────┐  │
│  │ Deserialize│ │ 10. Parse badges
│  │ Badges    │  │
│  └─────┬─────┘  │
│        │        │
│  ┌─────▼─────┐  │
│  │ Update    │  │ 11. Apply no-downgrade
│  │ Collection│  │    and store badges
│  └─────┬─────┘  │
│        │        │
│  ┌─────▼─────┐  │
│  │ Emit      │  │ 12. Emit events
│  │ Events    │  │
│  └───────────┘  │
└─────────────────┘
```

### 11.9 Best Practices

1. **Backend:**

   - Always apply no-downgrade rule before signing
   - Use consistent message construction
   - Validate all inputs before signing
   - Keep private key secure

2. **Contract:**

   - Always verify signature before processing
   - Apply no-downgrade rule again (defense in depth)
   - Emit detailed events for indexers
   - Validate all inputs

3. **Frontend:**
   - Cache attestations to avoid expiration
   - Handle errors gracefully
   - Show badge status to users
   - Refresh badges periodically

---

## 11. Conclusion

The contract codebase is well-structured with good separation of concerns and consistent patterns. However, there are several critical bugs that must be fixed before production deployment, and some code quality improvements that would enhance maintainability.

**Overall Assessment:** 🟡 **GOOD** with room for improvement

**Critical Issues:**

1. **Upgrade Compatibility:** Config version hardcoding will break on upgrade
2. **Missing Versioning:** Several shared objects lack version fields
3. **No Migration Functions:** Cannot upgrade shared objects safely

**Priority Actions:**

1. Fix the 3 critical bugs immediately
2. **Add versioning to all shared objects**
3. **Replace hardcoded version checks with CURRENT_VERSION constant**
4. **Create migration functions for shared objects**
5. Remove unused code and resolve TODOs
6. Extract duplicate code to shared utilities
7. Add missing authorization checks

**Upgrade Readiness:** 🟡 **PARTIAL**

- Some modules (whitelists) are upgrade-ready
- Core modules (Config, Registry) need versioning fixes
- Migration infrastructure needs to be added

The codebase follows Sui Move best practices in many areas but needs upgrade compatibility improvements before production deployment. With the recommended fixes, it will be production-ready and upgrade-friendly.
