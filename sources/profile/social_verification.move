/// Module for securely linking external social accounts to profiles using backend attestation
///
/// Security Model:
/// 1. User verifies social account ownership off-chain
/// 2. Backend verifies the social account ownership
/// 3. Backend creates attestation: profile_id || platform || username || timestamp
/// 4. Backend signs attestation with oracle private key (Ed25519)
/// 5. User submits attestation to blockchain
/// 6. Smart contract verifies backend's signature
/// 7. Social account is linked to profile if valid
module suins_social_layer::social_verification;

use std::string::String;
use sui::bcs;
use sui::clock::{Self, Clock};
use suins_social_layer::oracle_utils::{Self, OracleConfig};
use suins_social_layer::profile::{Self, Profile};
use suins_social_layer::social_layer_config::{Self as config, Config};

// === Errors ===
#[error]
const ETimestampExpired: u64 = 1;
const ESenderNotOwner: u64 = 2;

// Attestation validity window: 10 minutes (600,000 milliseconds)
const ATTESTATION_VALIDITY_MS: u64 = 600000;
// Maximum allowed clock skew: 5 seconds (5,000 milliseconds)
// This prevents accepting attestations with timestamps too far in the future
const MAX_CLOCK_SKEW_MS: u64 = 5000;

// === Public Functions ===

/// Link a social account to a profile using backend attestation
/// Supports Twitter, Discord, Telegram, Google, etc.
public(package) fun link_social_account(
    profile: &mut Profile,
    platform: String,
    username: String,
    signature: vector<u8>,
    timestamp: u64,
    oracle_config: &OracleConfig,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // 1. Verify sender is profile owner
    assert!(tx_context::sender(ctx) == profile::owner(profile), ESenderNotOwner);

    // 2. Verify config is up to date
    config::assert_interacting_with_most_up_to_date_package(config);

    // 3. Verify platform is allowed
    config::assert_social_platform_is_allowed(config, &platform);

    // 4. Verify oracle public key is set
    let oracle_public_key = oracle_utils::get_oracle_public_key(oracle_config);
    oracle_utils::validate_oracle_public_key(&oracle_public_key);

    // 5. Verify timestamp is valid (not too far in future, not expired)
    let current_time = clock::timestamp_ms(clock);
    // Reject timestamps too far in the future (clock skew protection)
    assert!(timestamp <= current_time + MAX_CLOCK_SKEW_MS, ETimestampExpired);
    // Reject expired timestamps (older than validity window)
    assert!(current_time - timestamp <= ATTESTATION_VALIDITY_MS, ETimestampExpired);

    // 6. Construct the message that should have been signed by backend
    let message = construct_social_link_attestation_message(
        object::id(profile),
        &platform,
        &username,
        timestamp,
    );

    // 7. Verify the backend signature
    oracle_utils::verify_oracle_signature(&message, &oracle_public_key, &signature);

    // 8. Link social account to profile
    profile::link_social_account(
        profile,
        platform,
        username,
        config,
        clock,
        ctx,
    );
}

/// Unlink a social account from a profile
/// No oracle verification needed for unlinking
public(package) fun unlink_social_account(
    profile: &mut Profile,
    platform: &String,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::unlink_social_account(
        profile,
        platform,
        config,
        clock,
        ctx,
    );
}

/// Constructs the social link attestation message
/// Format: profile_id || platform || "||" || username || "||" || timestamp
/// This MUST match the backend message construction exactly
fun construct_social_link_attestation_message(
    profile_id: object::ID,
    platform: &String,
    username: &String,
    timestamp: u64,
): vector<u8> {
    let mut message = vector::empty<u8>();

    // Add profile ID (32 bytes)
    let profile_id_bytes = object::id_to_bytes(&profile_id);
    vector::append(&mut message, profile_id_bytes);

    // Add platform name (UTF-8 bytes)
    let platform_bytes = platform.as_bytes();
    vector::append(&mut message, *platform_bytes);

    // Add separator
    vector::append(&mut message, b"||");

    // Add username (UTF-8 bytes)
    let username_bytes = username.as_bytes();
    vector::append(&mut message, *username_bytes);

    // Add separator
    vector::append(&mut message, b"||");

    // Add timestamp (8 bytes, little-endian)
    let timestamp_bytes = bcs::to_bytes(&timestamp);
    vector::append(&mut message, timestamp_bytes);

    message
}
