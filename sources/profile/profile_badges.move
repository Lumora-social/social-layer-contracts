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
use sui::event;
use suins_social_layer::oracle_utils::{Self, OracleConfig};
use suins_social_layer::profile::{Self, Profile};
use suins_social_layer::social_layer_config::{Self as config, Config};

// === Errors ===
#[error]
const ETimestampExpired: u64 = 1;
const ESenderNotOwner: u64 = 2;

// Attestation validity window: 10 minutes (600,000 milliseconds)
const ATTESTATION_VALIDITY_MS: u64 = 600000;

// Badge collection dynamic field key
const BADGE_COLLECTION_KEY: vector<u8> = b"badge_collection";

// === Structs ===

/// Badge data stored on profile
#[allow(unused_field)]
public struct Badge has copy, drop, store {
    category: String, // Badge category (e.g., "suins_portfolio")
    tier: String, // Badge tier (e.g., "name_hodler")
    display_name: String, // Human-readable name
    description: String, // Badge description
    image_url: Option<String>, // Badge image URL (optional)
    tier_number: u8, // Tier level for comparison (0 = lowest, higher = better)
    minted_at: u64, // Timestamp when badge was minted
}

/// Collection of badges stored as dynamic field on profile
public struct BadgeCollection has store {
    badges: vector<Badge>,
    last_updated: u64,
}

// === Events ===

/// Detailed event emitted for each badge that is newly minted
public struct BadgeMintedEvent has copy, drop {
    profile_id: ID,
    profile_owner: address,
    category: String,
    tier: String,
    display_name: String,
    description: String,
    image_url: Option<String>,
    tier_number: u8,
    timestamp: u64,
}

/// Detailed event emitted when a badge is upgraded to a higher tier
public struct BadgeUpdatedEvent has copy, drop {
    profile_id: ID,
    profile_owner: address,
    category: String,
    old_tier: String,
    new_tier: String,
    old_tier_number: u8,
    new_tier_number: u8,
    display_name: String,
    description: String,
    image_url: Option<String>,
    timestamp: u64,
}

// === Public Functions ===

/// Mint or update badges on a profile with backend attestation
public fun mint_badges(
    profile: &mut Profile,
    badges_bcs: vector<u8>,
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

    // 3. Verify oracle public key is set
    let oracle_public_key = oracle_utils::get_oracle_public_key(oracle_config);
    oracle_utils::validate_oracle_public_key(&oracle_public_key);

    // 4. Verify timestamp hasn't expired
    let current_time = clock::timestamp_ms(clock);
    assert!(
        current_time >= timestamp && current_time - timestamp <= ATTESTATION_VALIDITY_MS,
        ETimestampExpired,
    );

    // 5. Construct the message that should have been signed by backend
    let message = construct_badge_attestation_message(
        object::id(profile),
        &badges_bcs,
        timestamp,
    );

    // 6. Verify the backend signature
    oracle_utils::verify_oracle_signature(&message, &oracle_public_key, &signature);

    // 7. Deserialize badges from BCS and store/update them
    let badges = deserialize_badges(&badges_bcs, current_time);

    // Get or create badge collection
    let profile_id = object::id(profile);
    let profile_owner = profile::owner(profile);
    let badge_collection_key = BADGE_COLLECTION_KEY.to_string();

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

    // Update badges (replace or add new) and emit detailed events
    update_badge_collection_with_events(
        collection,
        badges,
        profile_id,
        profile_owner,
        current_time,
    );
    collection.last_updated = current_time;
}

// === Helper Functions ===

/// Constructs the badge attestation message
/// Format: profile_id || "badges" || "||" || badges_bcs || "||" || timestamp
fun construct_badge_attestation_message(
    profile_id: ID,
    badges_bcs: &vector<u8>,
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

    // Add BCS-encoded badges
    vector::append(&mut message, *badges_bcs);

    // Add separator
    vector::append(&mut message, b"||");

    // Add timestamp (8 bytes, little-endian)
    let timestamp_bytes = bcs::to_bytes(&timestamp);
    vector::append(&mut message, timestamp_bytes);

    message
}

/// Deserialize badges from BCS encoding
/// Note: BCS deserialization must match the backend encoding exactly
fun deserialize_badges(badges_bcs: &vector<u8>, minted_at: u64): vector<Badge> {
    // Create BCS reader
    let mut bcs_reader = bcs::new(*badges_bcs);

    // Deserialize vector length
    let badges_count = bcs::peel_vec_length(&mut bcs_reader);

    let mut badges = vector::empty<Badge>();
    let mut i = 0;

    while (i < badges_count) {
        // Deserialize each badge field in order
        let category = bcs::peel_vec_u8(&mut bcs_reader).to_string();
        let tier = bcs::peel_vec_u8(&mut bcs_reader).to_string();
        let display_name = bcs::peel_vec_u8(&mut bcs_reader).to_string();
        let description = bcs::peel_vec_u8(&mut bcs_reader).to_string();

        // Deserialize optional image_url (Option<String>)
        let has_image_url = bcs::peel_bool(&mut bcs_reader);
        let image_url = if (has_image_url) {
            option::some(bcs::peel_vec_u8(&mut bcs_reader).to_string())
        } else {
            option::none()
        };

        // Deserialize tier_number (u8)
        let tier_number = bcs::peel_u8(&mut bcs_reader);

        let badge = Badge {
            category,
            tier,
            display_name,
            description,
            image_url,
            tier_number,
            minted_at,
        };

        vector::push_back(&mut badges, badge);
        i = i + 1;
    };

    badges
}

/// Helper: Check if badge should be updated based on NO-DOWNGRADE RULE
/// Only updates if new badge tier_number is higher than existing
fun should_update_badge(new_badge: &Badge, existing_badge: &Badge): bool {
    new_badge.tier_number > existing_badge.tier_number
}

/// Helper: Find existing badge by category, returns (found, index)
fun find_badge_by_category(collection: &BadgeCollection, category: &String): (bool, u64) {
    let mut i = 0;
    let len = vector::length(&collection.badges);
    while (i < len) {
        let badge = vector::borrow(&collection.badges, i);
        if (badge.category == *category) {
            return (true, i)
        };
        i = i + 1;
    };
    (false, 0)
}

/// Update badge collection with new badges and emit detailed events
/// Replaces existing badges of the same category or adds new ones
/// NO-DOWNGRADE RULE: Only updates if new badge value is higher than existing
fun update_badge_collection_with_events(
    collection: &mut BadgeCollection,
    new_badges: vector<Badge>,
    profile_id: ID,
    profile_owner: address,
    timestamp: u64,
) {
    let mut i = 0;
    let len = vector::length(&new_badges);

    while (i < len) {
        let new_badge = vector::borrow(&new_badges, i);
        let (found, existing_idx) = find_badge_by_category(collection, &new_badge.category);

        if (found) {
            let existing_badge = vector::borrow_mut(&mut collection.badges, existing_idx);
            if (should_update_badge(new_badge, existing_badge)) {
                // Emit update event
                let old_tier = existing_badge.tier;
                let old_tier_number = existing_badge.tier_number;
                event::emit(BadgeUpdatedEvent {
                    profile_id,
                    profile_owner,
                    category: new_badge.category,
                    old_tier,
                    new_tier: new_badge.tier,
                    old_tier_number,
                    new_tier_number: new_badge.tier_number,
                    display_name: new_badge.display_name,
                    description: new_badge.description,
                    image_url: new_badge.image_url,
                    timestamp,
                });
                // Update to higher tier badge
                *existing_badge = *new_badge;
            };
        } else {
            // If not found, add new badge and emit mint event
            event::emit(BadgeMintedEvent {
                profile_id,
                profile_owner,
                category: new_badge.category,
                tier: new_badge.tier,
                display_name: new_badge.display_name,
                description: new_badge.description,
                image_url: new_badge.image_url,
                tier_number: new_badge.tier_number,
                timestamp,
            });
            vector::push_back(&mut collection.badges, *new_badge);
        };

        i = i + 1;
    };
}

/// Update badge collection with new badges (test-only, no events)
/// Replaces existing badges of the same category or adds new ones
/// NO-DOWNGRADE RULE: Only updates if new badge value is higher than existing
#[test_only]
fun update_badge_collection(collection: &mut BadgeCollection, new_badges: vector<Badge>) {
    let mut i = 0;
    let len = vector::length(&new_badges);

    while (i < len) {
        let new_badge = vector::borrow(&new_badges, i);
        let (found, existing_idx) = find_badge_by_category(collection, &new_badge.category);

        if (found) {
            let existing_badge = vector::borrow_mut(&mut collection.badges, existing_idx);
            if (should_update_badge(new_badge, existing_badge)) {
                *existing_badge = *new_badge;
            };
        } else {
            vector::push_back(&mut collection.badges, *new_badge);
        };

        i = i + 1;
    };
}

// === View Functions ===

/// Get all badges for a profile
public fun get_badges(profile: &Profile): vector<Badge> {
    let badge_collection_key = BADGE_COLLECTION_KEY.to_string();

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
    description: String,
    image_url: Option<String>,
    tier_number: u8,
    minted_at: u64,
): Badge {
    Badge {
        category,
        tier,
        display_name,
        description,
        image_url,
        tier_number,
        minted_at,
    }
}
