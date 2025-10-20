/// Module for securely linking Sui wallets to profiles using cryptographic signatures
///
/// Security Model:
/// 1. User signs a message with Wallet B (wallet to be linked)
/// 2. Message format: profile_id || wallet_B_address || timestamp || nonce
/// 3. Wallet A (profile owner) calls link_sui_wallet with the signature
/// 4. On-chain verification ensures Wallet B's owner authorized the link
/// 5. Prevents replay attacks and unauthorized linking
module suins_social_layer::secure_wallet_link;

use std::string::String;
use sui::clock::{Self, Clock};
use sui::event;
use sui::bcs;
use sui::ed25519;
use suins_social_layer::profile::{Self, Profile};
use suins_social_layer::social_layer_config::{Self as config, Config};

// === Errors ===
#[error]
const EInvalidSignature: u64 = 0;
const ETimestampExpired: u64 = 1;
const ESenderNotOwner: u64 = 2;
const ENonceAlreadyUsed: u64 = 3;
const EInvalidMessageFormat: u64 = 4;

// Signature validity window: 5 minutes (300,000 milliseconds)
const SIGNATURE_VALIDITY_MS: u64 = 300000;

// === Structs ===

/// Stores used nonces to prevent replay attacks
public struct NonceRegistry has key {
    id: UID,
    // Map of nonce => timestamp when used
    used_nonces: sui::table::Table<vector<u8>, u64>,
}

/// Initialization function
fun init(ctx: &mut TxContext) {
    let registry = NonceRegistry {
        id: object::new(ctx),
        used_nonces: sui::table::new(ctx),
    };
    transfer::share_object(registry);
}

// === Events ===

public struct SuiWalletLinkedEvent has copy, drop {
    profile_id: ID,
    profile_owner: address,
    linked_wallet: address,
    timestamp: u64,
}

public struct SuiWalletUnlinkedEvent has copy, drop {
    profile_id: ID,
    profile_owner: address,
    unlinked_wallet: address,
    timestamp: u64,
}

// === Public Functions ===

/// Links a Sui wallet to a profile with cryptographic proof
///
/// # Arguments
/// * `profile` - The profile to link the wallet to
/// * `wallet_to_link` - Address of the wallet being linked
/// * `public_key` - Ed25519 public key of wallet_to_link (32 bytes)
/// * `signature` - Ed25519 signature from wallet_to_link (64 bytes)
/// * `timestamp` - Timestamp when the message was signed
/// * `nonce` - Unique nonce to prevent replay attacks
/// * `nonce_registry` - Shared registry to track used nonces
/// * `config` - Config object
/// * `clock` - Clock for timestamp validation
/// * `ctx` - Transaction context
///
/// # Message Format
/// The signed message must be: profile_id || wallet_to_link || timestamp || nonce
/// where || represents concatenation
public entry fun link_sui_wallet(
    profile: &mut Profile,
    wallet_to_link: address,
    public_key: vector<u8>,
    signature: vector<u8>,
    timestamp: u64,
    nonce: vector<u8>,
    nonce_registry: &mut NonceRegistry,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    // 1. Verify sender is profile owner
    assert!(tx_context::sender(ctx) == profile::owner(profile), ESenderNotOwner);

    // 2. Verify config is up to date
    config::assert_interacting_with_most_up_to_date_package(config);

    // 3. Verify timestamp hasn't expired
    let current_time = clock::timestamp_ms(clock);
    assert!(
        current_time - timestamp <= SIGNATURE_VALIDITY_MS,
        ETimestampExpired
    );

    // 4. Verify nonce hasn't been used before
    assert!(
        !sui::table::contains(&nonce_registry.used_nonces, nonce),
        ENonceAlreadyUsed
    );

    // 5. Construct the message that should have been signed
    let message = construct_link_message(
        object::id(profile),
        wallet_to_link,
        timestamp,
        &nonce
    );

    // 6. Verify the signature
    verify_ed25519_signature(&message, &public_key, &signature);

    // 7. Mark nonce as used
    sui::table::add(&mut nonce_registry.used_nonces, nonce, current_time);

    // 8. Add wallet to profile
    // Generate unique key for this Sui wallet (sui, sui_2, sui_3, etc.)
    let wallet_address_str = sui::address::to_string(wallet_to_link);
    let wallet_addresses = profile::wallet_addresses(profile);

    let mut wallet_key = b"sui".to_string();
    let mut counter = 2u64; // Start from 2 for additional wallets

    // Find next available key
    while (sui::vec_map::contains(&wallet_addresses, &wallet_key)) {
        wallet_key = b"sui_".to_string();
        let counter_str = counter.to_string();
        wallet_key.append(counter_str);
        counter = counter + 1;
    };

    profile::add_wallet_address(profile, wallet_key, wallet_address_str, config, clock, ctx);

    // 9. Emit event
    event::emit(SuiWalletLinkedEvent {
        profile_id: object::id(profile),
        profile_owner: profile::owner(profile),
        linked_wallet: wallet_to_link,
        timestamp: current_time,
    });
}

/// Unlinks a Sui wallet from a profile
public entry fun unlink_sui_wallet(
    profile: &mut Profile,
    wallet_key: String,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    assert!(tx_context::sender(ctx) == profile::owner(profile), ESenderNotOwner);
    config::assert_interacting_with_most_up_to_date_package(config);

    profile::remove_wallet_address(profile, wallet_key, config, clock, ctx);

    event::emit(SuiWalletUnlinkedEvent {
        profile_id: object::id(profile),
        profile_owner: profile::owner(profile),
        unlinked_wallet: @0x0, // We don't have the address here
        timestamp: clock::timestamp_ms(clock),
    });
}

// === Helper Functions ===

/// Constructs the message to be signed
/// Format: profile_id || wallet_address || timestamp || nonce
fun construct_link_message(
    profile_id: ID,
    wallet_address: address,
    timestamp: u64,
    nonce: &vector<u8>,
): vector<u8> {
    let mut message = vector::empty<u8>();

    // Add profile ID
    let profile_id_bytes = object::id_to_bytes(&profile_id);
    vector::append(&mut message, profile_id_bytes);

    // Add wallet address
    let address_bytes = bcs::to_bytes(&wallet_address);
    vector::append(&mut message, address_bytes);

    // Add timestamp
    let timestamp_bytes = bcs::to_bytes(&timestamp);
    vector::append(&mut message, timestamp_bytes);

    // Add nonce
    vector::append(&mut message, *nonce);

    message
}

/// Verifies an Ed25519 signature
fun verify_ed25519_signature(
    message: &vector<u8>,
    public_key: &vector<u8>,
    signature: &vector<u8>,
) {
    // Validate lengths
    assert!(vector::length(public_key) == 32, EInvalidMessageFormat);
    assert!(vector::length(signature) == 64, EInvalidMessageFormat);

    // Verify signature
    let is_valid = ed25519::ed25519_verify(
        signature,
        public_key,
        message
    );

    assert!(is_valid, EInvalidSignature);
}

// === View Functions ===

/// Check if a nonce has been used
public fun is_nonce_used(registry: &NonceRegistry, nonce: vector<u8>): bool {
    sui::table::contains(&registry.used_nonces, nonce)
}

// === Test Helper Functions ===

#[test_only]
public fun create_test_registry(ctx: &mut TxContext): NonceRegistry {
    NonceRegistry {
        id: object::new(ctx),
        used_nonces: sui::table::new(ctx),
    }
}
