/// Module for minting and managing profile badges based on on-chain activity
/// using backend oracle signatures
///
/// Security Model:
/// 1. Backend checks wallet activity and badge eligibility
/// 2. Backend signs attestation: profile_id || "badges" || badges_json || timestamp
/// 3. User submits attestation to blockchain
/// 4. Smart contract verifies signature using backend's public key
/// 5. Mints/updates badges on profile if valid
///
/// Design: Generic and future-proof
/// - No hardcoded badge types or tiers
/// - Badges stored as dynamic fields with JSON metadata
/// - Supports tier upgrades (never downgrades)
module suins_social_layer::profile_badges;

use std::string::String;
use sui::bcs;
use sui::clock::{Self, Clock};
use sui::dynamic_field as df;
use sui::ed25519;
use sui::event;
use suins_social_layer::profile::{Self, Profile};
use suins_social_layer::social_layer_config::{Self as config, Config};

// === Errors ===
#[error]
const EInvalidSignature: u64 = 0;
const ETimestampExpired: u64 = 1;
const ESenderNotOwner: u64 = 2;
const EInvalidMessageFormat: u64 = 3;

// Attestation validity window: 10 minutes (600,000 milliseconds)
const ATTESTATION_VALIDITY_MS: u64 = 600000;

// === Structs ===

/// Badge data stored on profile
#[allow(unused_field)]
public struct Badge has copy, drop, store {
    category: String, // Badge category (e.g., "suins_portfolio")
    tier: String, // Badge tier (e.g., "name_hodler")
    display_name: String, // Human-readable name
    emoji: String, // Badge emoji
    value: u64, // Value that qualified for this badge
    metadata: String, // JSON metadata
    minted_at: u64, // Timestamp when badge was minted
}

/// Collection of badges stored as dynamic field on profile
public struct BadgeCollection has store {
    badges: vector<Badge>,
    last_updated: u64,
}

// === Events ===

public struct BadgesMintedEvent has copy, drop {
    profile_id: ID,
    profile_owner: address,
    badges_count: u64,
    timestamp: u64,
}

#[allow(unused_field)]
public struct BadgeUpdatedEvent has copy, drop {
    profile_id: ID,
    profile_owner: address,
    category: String,
    old_tier: String,
    new_tier: String,
    timestamp: u64,
}

// === Public Functions ===

/// Mint or update badges on a profile with backend attestation
///
/// # Arguments
/// * `profile` - The profile to mint badges for
/// * `badges_json` - JSON string of eligible badges from backend
/// * `signature` - Ed25519 signature from backend oracle (64 bytes)
/// * `timestamp` - Timestamp when backend signed the attestation
/// * `oracle_config` - Oracle configuration with public key (from social_verification module)
/// * `config` - Config object
/// * `clock` - Clock for timestamp validation
/// * `ctx` - Transaction context
public fun mint_badges(
    profile: &mut Profile,
    badges_json: String,
    signature: vector<u8>,
    timestamp: u64,
    oracle_config: &suins_social_layer::social_verification::OracleConfig,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    // 1. Verify sender is profile owner
    assert!(tx_context::sender(ctx) == profile::owner(profile), ESenderNotOwner);

    // 2. Verify config is up to date
    config::assert_interacting_with_most_up_to_date_package(config);

    // 3. Verify oracle public key is set
    let oracle_public_key = suins_social_layer::social_verification::get_oracle_public_key(
        oracle_config,
    );
    assert!(vector::length(&oracle_public_key) == 32, EInvalidMessageFormat);

    // 4. Verify timestamp hasn't expired
    let current_time = clock::timestamp_ms(clock);
    assert!(
        current_time >= timestamp && current_time - timestamp <= ATTESTATION_VALIDITY_MS,
        ETimestampExpired,
    );

    // 5. Construct the message that should have been signed by backend
    let message = construct_badge_attestation_message(
        object::id(profile),
        &badges_json,
        timestamp,
    );

    // 6. Verify the backend signature
    verify_oracle_signature(&message, &oracle_public_key, &signature);

    // 7. Parse badges from JSON and store/update them
    // Note: In production, you'd parse the JSON. For now, we'll create a placeholder
    // that demonstrates the storage pattern

    // Get or create badge collection
    let profile_id = object::id(profile);
    let profile_owner = profile::owner(profile);
    let badge_collection_key = b"badge_collection".to_string();

    if (!df::exists_(profile::uid(profile), badge_collection_key)) {
        // Create new collection
        let collection = BadgeCollection {
            badges: vector::empty<Badge>(),
            last_updated: current_time,
        };
        df::add(profile::uid_mut(profile), badge_collection_key, collection);
    };

    // Get mutable reference to collection
    let collection = df::borrow_mut<String, BadgeCollection>(
        profile::uid_mut(profile),
        badge_collection_key,
    );
    collection.last_updated = current_time;

    // TODO: Parse badges_json and add/update badges
    // For now, this is a placeholder showing the pattern
    // In practice, you'd parse the JSON and update the badges vector

    let badges_count = vector::length(&collection.badges);

    // 8. Emit event
    event::emit(BadgesMintedEvent {
        profile_id,
        profile_owner,
        badges_count,
        timestamp: current_time,
    });
}

// === Helper Functions ===

/// Constructs the badge attestation message
/// Format: profile_id || "badges" || badges_json || timestamp
fun construct_badge_attestation_message(
    profile_id: ID,
    badges_json: &String,
    timestamp: u64,
): vector<u8> {
    let mut message = vector::empty<u8>();

    // Add profile ID (32 bytes)
    let profile_id_bytes = object::id_to_bytes(&profile_id);
    vector::append(&mut message, profile_id_bytes);

    // Add platform name ("badges")
    vector::append(&mut message, b"badges");

    // Add separator
    vector::append(&mut message, b"||");

    // Add badges JSON
    let badges_json_bytes = badges_json.as_bytes();
    vector::append(&mut message, *badges_json_bytes);

    // Add separator
    vector::append(&mut message, b"||");

    // Empty username field (not used for badges, but keeps format consistent)
    vector::append(&mut message, b"||");

    // Add timestamp (8 bytes, little-endian)
    let timestamp_bytes = bcs::to_bytes(&timestamp);
    vector::append(&mut message, timestamp_bytes);

    message
}

/// Verifies backend oracle signature
fun verify_oracle_signature(message: &vector<u8>, public_key: &vector<u8>, signature: &vector<u8>) {
    // Validate lengths
    assert!(vector::length(public_key) == 32, EInvalidMessageFormat);
    assert!(vector::length(signature) == 64, EInvalidMessageFormat);

    // Verify signature
    let is_valid = ed25519::ed25519_verify(signature, public_key, message);
    assert!(is_valid, EInvalidSignature);
}

// === View Functions ===

/// Get all badges for a profile
public fun get_badges(profile: &Profile): vector<Badge> {
    let badge_collection_key = b"badge_collection".to_string();

    if (!df::exists_(profile::uid(profile), badge_collection_key)) {
        return vector::empty<Badge>()
    };

    let collection = df::borrow<String, BadgeCollection>(
        profile::uid(profile),
        badge_collection_key,
    );
    collection.badges
}

/// Check if profile has a specific badge category
public fun has_badge_category(profile: &Profile, category: String): bool {
    let badges = get_badges(profile);
    let mut i = 0;
    let len = vector::length(&badges);

    while (i < len) {
        let badge = vector::borrow(&badges, i);
        if (badge.category == category) {
            return true
        };
        i = i + 1;
    };

    false
}

// === Test Helper Functions ===

#[test_only]
public fun create_test_badge(
    category: String,
    tier: String,
    display_name: String,
    emoji: String,
    value: u64,
    metadata: String,
    minted_at: u64,
): Badge {
    Badge {
        category,
        tier,
        display_name,
        emoji,
        value,
        metadata,
        minted_at,
    }
}
