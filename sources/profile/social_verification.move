/// Module for verifying social media accounts (Twitter, Discord, Telegram)
/// using backend oracle signatures
///
/// Security Model:
/// 1. Backend performs OAuth with social platform
/// 2. Backend verifies user owns the account
/// 3. Backend signs attestation: profile_id || platform || username || timestamp
/// 4. User submits attestation to blockchain
/// 5. Smart contract verifies signature using backend's public key
/// 6. Links social account to profile if valid
module suins_social_layer::social_verification;

use std::string::String;
use sui::bcs;
use sui::clock::{Self, Clock};
use sui::event;
use suins_social_layer::oracle_utils;
use suins_social_layer::profile::{Self, Profile};
use suins_social_layer::social_layer_config::{Self as config, Config};

// === Errors ===
#[error]
const ETimestampExpired: u64 = 0;
const ESenderNotOwner: u64 = 1;
const EInvalidMessageFormat: u64 = 2;

// Attestation validity window: 10 minutes (600,000 milliseconds)
const ATTESTATION_VALIDITY_MS: u64 = 600000;

// === Structs ===

/// Backend oracle configuration
/// Stores the public key used to verify backend signatures
public struct OracleConfig has key {
    id: UID,
    // Ed25519 public key of the backend oracle (32 bytes)
    public_key: vector<u8>,
    // Admin who can update the public key
    admin: address,
}

/// Initialization function
fun init(ctx: &mut TxContext) {
    let oracle_config = OracleConfig {
        id: object::new(ctx),
        public_key: vector::empty<u8>(), // To be set by admin
        admin: tx_context::sender(ctx),
    };
    transfer::share_object(oracle_config);
}

// === Events ===

public struct OraclePublicKeyUpdatedEvent has copy, drop {
    old_key: vector<u8>,
    new_key: vector<u8>,
    timestamp: u64,
}

// === Admin Functions ===

/// Updates the backend oracle's public key
/// Only the admin can call this
public fun update_oracle_public_key(
    oracle_config: &mut OracleConfig,
    new_public_key: vector<u8>,
    ctx: &mut TxContext,
) {
    assert!(tx_context::sender(ctx) == oracle_config.admin, ESenderNotOwner);
    assert!(vector::length(&new_public_key) == 32, EInvalidMessageFormat);

    let old_key = oracle_config.public_key;
    oracle_config.public_key = new_public_key;

    event::emit(OraclePublicKeyUpdatedEvent {
        old_key,
        new_key: new_public_key,
        timestamp: 0, // Clock not needed here
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

/// Links a Twitter account to a profile with backend attestation
public fun link_twitter_account(
    profile: &mut Profile,
    twitter_username: String,
    signature: vector<u8>,
    timestamp: u64,
    oracle_config: &OracleConfig,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    link_social_account_internal(
        profile,
        b"twitter".to_string(),
        twitter_username,
        signature,
        timestamp,
        oracle_config,
        config,
        clock,
        ctx,
    );
}

/// Links a Discord account to a profile with backend attestation
public fun link_discord_account(
    profile: &mut Profile,
    discord_username: String,
    signature: vector<u8>,
    timestamp: u64,
    oracle_config: &OracleConfig,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    link_social_account_internal(
        profile,
        b"discord".to_string(),
        discord_username,
        signature,
        timestamp,
        oracle_config,
        config,
        clock,
        ctx,
    );
}

/// Links a Telegram account to a profile with backend attestation
public fun link_telegram_account(
    profile: &mut Profile,
    telegram_username: String,
    signature: vector<u8>,
    timestamp: u64,
    oracle_config: &OracleConfig,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    link_social_account_internal(
        profile,
        b"telegram".to_string(),
        telegram_username,
        signature,
        timestamp,
        oracle_config,
        config,
        clock,
        ctx,
    );
}

/// Links a Google account to a profile with backend attestation
public fun link_google_account(
    profile: &mut Profile,
    google_email: String,
    signature: vector<u8>,
    timestamp: u64,
    oracle_config: &OracleConfig,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    link_social_account_internal(
        profile,
        b"google".to_string(),
        google_email,
        signature,
        timestamp,
        oracle_config,
        config,
        clock,
        ctx,
    );
}

/// Internal function to link social accounts
fun link_social_account_internal(
    profile: &mut Profile,
    platform: String,
    username: String,
    signature: vector<u8>,
    timestamp: u64,
    oracle_config: &OracleConfig,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    assert!(tx_context::sender(ctx) == profile::owner(profile), ESenderNotOwner);

    config::assert_interacting_with_most_up_to_date_package(config);

    oracle_utils::validate_oracle_public_key(&oracle_config.public_key);

    let current_time = clock::timestamp_ms(clock);
    assert!(
        current_time >= timestamp && current_time - timestamp <= ATTESTATION_VALIDITY_MS,
        ETimestampExpired,
    );

    let message = construct_attestation_message(
        object::id(profile),
        &platform,
        &username,
        timestamp,
    );

    oracle_utils::verify_oracle_signature(
        &message,
        &oracle_config.public_key,
        &signature,
    );

    profile::link_social_account(profile, platform, username, clock);
}

/// Unlinks a social account from a profile
public fun unlink_social_account(
    profile: &mut Profile,
    platform: String,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    assert!(tx_context::sender(ctx) == profile::owner(profile), ESenderNotOwner);
    config::assert_interacting_with_most_up_to_date_package(config);

    profile::unlink_social_account(profile, &platform, clock);
}

/// Constructs the attestation message
/// Format: profile_id || platform || username || timestamp
fun construct_attestation_message(
    profile_id: ID,
    platform: &String,
    username: &String,
    timestamp: u64,
): vector<u8> {
    let mut message = vector::empty<u8>();

    // Add profile ID (32 bytes)
    let profile_id_bytes = object::id_to_bytes(&profile_id);
    vector::append(&mut message, profile_id_bytes);

    // Add platform name
    let platform_bytes = platform.as_bytes();
    vector::append(&mut message, *platform_bytes);

    // Add separator (to prevent collision attacks)
    vector::append(&mut message, b"||");

    // Add username
    let username_bytes = username.as_bytes();
    vector::append(&mut message, *username_bytes);

    // Add separator
    vector::append(&mut message, b"||");

    // Add timestamp (8 bytes, little-endian)
    let timestamp_bytes = bcs::to_bytes(&timestamp);
    vector::append(&mut message, timestamp_bytes);

    message
}

// === View Functions ===

/// Get the oracle's public key
public fun get_oracle_public_key(oracle_config: &OracleConfig): vector<u8> {
    oracle_config.public_key
}

/// Get the oracle admin
public fun get_oracle_admin(oracle_config: &OracleConfig): address {
    oracle_config.admin
}

// === Test Helper Functions ===

#[test_only]
public fun create_test_oracle_config(public_key: vector<u8>, ctx: &mut TxContext): OracleConfig {
    OracleConfig {
        id: object::new(ctx),
        public_key,
        admin: tx_context::sender(ctx),
    }
}
