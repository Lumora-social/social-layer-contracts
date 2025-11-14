/// Shared utilities for oracle signature verification
/// Used by profile_badges, social_verification, and wallet_linking modules
module suins_social_layer::oracle_utils;

use sui::clock::{Self, Clock};
use sui::ed25519;
use sui::event;

#[error]
const EInvalidMessageFormat: u64 = 1;
const ESenderNotOwner: u64 = 2;
const EInvalidSignature: u64 = 3;

/// Default public key (32 bytes) for the backend oracle
const DEFAULT_PUBLIC_KEY: vector<u8> =
    x"7f55f796aed7c4b78376223f0a3a7091a45d9fee9d5ae964ee0ca61b50c97556";

/// Backend oracle configuration
/// Stores the public key used to verify backend signatures
public struct OracleConfig has key {
    id: UID,
    // Ed25519 public key of the backend oracle (32 bytes)
    public_key: vector<u8>,
    // Admin who can update the public key
    admin: address,
}

public struct OraclePublicKeyUpdatedEvent has copy, drop {
    old_key: vector<u8>,
    new_key: vector<u8>,
    timestamp: u64,
}

/// Initialization function
fun init(ctx: &mut TxContext) {
    let oracle_config = OracleConfig {
        id: object::new(ctx),
        public_key: DEFAULT_PUBLIC_KEY, // Default public key (should be updated by admin for production)
        admin: tx_context::sender(ctx),
    };
    transfer::share_object(oracle_config);
}

// === Admin Functions ===

/// Updates the backend oracle's public key
/// Only the admin can call this
public fun update_oracle_public_key(
    oracle_config: &mut OracleConfig,
    new_public_key: vector<u8>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    assert!(tx_context::sender(ctx) == oracle_config.admin, ESenderNotOwner);
    assert!(vector::length(&new_public_key) == 32, EInvalidMessageFormat);

    let old_key = oracle_config.public_key;
    oracle_config.public_key = new_public_key;

    event::emit(OraclePublicKeyUpdatedEvent {
        old_key,
        new_key: new_public_key,
        timestamp: clock::timestamp_ms(clock),
    });
}

/// Transfers admin rights to a new address
public fun transfer_admin(
    oracle_config: &mut OracleConfig,
    new_admin: address,
    ctx: &mut TxContext,
) {
    assert!(tx_context::sender(ctx) == oracle_config.admin, ESenderNotOwner);
    oracle_config.admin = new_admin;
}

// === Public Functions ===

/// Verifies backend oracle Ed25519 signature
/// Validates public key (32 bytes) and signature (64 bytes) lengths
/// Then verifies the signature matches the message
public fun verify_oracle_signature(
    message: &vector<u8>,
    public_key: &vector<u8>,
    signature: &vector<u8>,
) {
    assert!(vector::length(public_key) == 32, EInvalidMessageFormat);
    assert!(vector::length(signature) == 64, EInvalidMessageFormat);
    let is_valid = ed25519::ed25519_verify(signature, public_key, message);
    assert!(is_valid, EInvalidSignature);
}

/// Validates that oracle public key is properly set (32 bytes)
public fun validate_oracle_public_key(public_key: &vector<u8>) {
    assert!(vector::length(public_key) == 32, EInvalidMessageFormat);
}

// === Getters ===

/// Get the oracle's public key
public fun get_oracle_public_key(oracle_config: &OracleConfig): vector<u8> {
    oracle_config.public_key
}

/// Get the oracle admin
public fun get_oracle_admin(oracle_config: &OracleConfig): address {
    oracle_config.admin
}

#[test_only]
public fun create_test_oracle_config(public_key: vector<u8>, ctx: &mut TxContext): OracleConfig {
    OracleConfig {
        id: object::new(ctx),
        public_key,
        admin: tx_context::sender(ctx),
    }
}

#[test_only]
public fun create_and_share_test_oracle_config(public_key: vector<u8>, ctx: &mut TxContext) {
    let oracle_config = OracleConfig {
        id: object::new(ctx),
        public_key,
        admin: tx_context::sender(ctx),
    };
    transfer::share_object(oracle_config);
}
