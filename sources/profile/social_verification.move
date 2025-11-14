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
use suins_social_layer::oracle_utils::{Self, OracleConfig};
use suins_social_layer::profile::{Self, Profile};
use suins_social_layer::social_layer_config::{Self as config, Config};

// === Errors ===
#[error]
const ETimestampExpired: u64 = 0;
const ESenderNotOwner: u64 = 1;

// Attestation validity window: 10 minutes (600,000 milliseconds)
const ATTESTATION_VALIDITY_MS: u64 = 600000;

// === Public Functions ===

/// Unified function to link any social account to a profile with backend attestation
/// Validates that the platform is in the allowed list from config
public(package) fun link_social_account(
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
    // Validate platform is allowed
    config::assert_social_platform_is_allowed(config, &platform);

    link_social_account_internal(
        profile,
        platform,
        username,
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

    let oracle_public_key = oracle_utils::get_oracle_public_key(oracle_config);
    oracle_utils::validate_oracle_public_key(&oracle_public_key);

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
        &oracle_public_key,
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
    ctx: &TxContext,
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
