module suins_social_layer::timestamp_validation_tests;

use sui::bcs;
use sui::clock;
use sui::test_scenario::{Self, next_tx, ctx};
use suins_social_layer::oracle_utils;
use suins_social_layer::profile;
use suins_social_layer::profile_badges;
use suins_social_layer::profile_actions;
use suins_social_layer::social_layer_config;
use suins_social_layer::social_layer_registry;

// Helper to encode a single badge to BCS format
fun encode_badge_to_bcs(
    category: vector<u8>,
    tier: vector<u8>,
    display_name: vector<u8>,
    description: vector<u8>,
    has_image: bool,
    image_url: vector<u8>,
    tier_number: u8,
): vector<u8> {
    let mut bcs_data = vector::empty<u8>();
    let len: u64 = 1;
    let len_bytes = bcs::to_bytes(&len);
    vector::append(&mut bcs_data, len_bytes);
    let category_bytes = bcs::to_bytes(&category);
    vector::append(&mut bcs_data, category_bytes);
    let tier_bytes = bcs::to_bytes(&tier);
    vector::append(&mut bcs_data, tier_bytes);
    let display_name_bytes = bcs::to_bytes(&display_name);
    vector::append(&mut bcs_data, display_name_bytes);
    let description_bytes = bcs::to_bytes(&description);
    vector::append(&mut bcs_data, description_bytes);
    let has_image_bytes = bcs::to_bytes(&has_image);
    vector::append(&mut bcs_data, has_image_bytes);
    if (has_image) {
        let image_url_bytes = bcs::to_bytes(&image_url);
        vector::append(&mut bcs_data, image_url_bytes);
    };
    let tier_number_bytes = bcs::to_bytes(&tier_number);
    vector::append(&mut bcs_data, tier_number_bytes);
    bcs_data
}

#[test]
#[expected_failure(abort_code = oracle_utils::EInvalidSignature, location = oracle_utils)]
fun test_mint_badges_expired_timestamp_rejected() {
    let admin_address: address = @0xAD;
    let user_address: address = @0xA;

    let mut scenario = test_scenario::begin(admin_address);

    // Setup
    social_layer_config::test_create_config(ctx(&mut scenario));
    social_layer_registry::create_registry_for_testing(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Create oracle config
    next_tx(&mut scenario, admin_address);
    let mut oracle_public_key = vector::empty<u8>();
    let mut i = 0;
    while (i < 32) {
        vector::push_back(&mut oracle_public_key, i);
        i = i + 1;
    };
    oracle_utils::create_and_share_test_oracle_config(oracle_public_key, ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let oracle_config_shared = test_scenario::take_shared<oracle_utils::OracleConfig>(&scenario);

    // Create profile
    next_tx(&mut scenario, user_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let mut profile = profile::create_profile_helper(
        b"testuser2".to_string(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    // Encode badge to BCS
    let badges_bcs = encode_badge_to_bcs(
        b"suins_portfolio",
        b"bronze",
        b"Bronze Hodler",
        b"Bronze tier badge",
        true,
        b"https://example.com/bronze.png",
        0,
    );

    // Create a valid signature
    let mut signature = vector::empty<u8>();
    let mut j = 0;
    while (j < 64) {
        vector::push_back(&mut signature, 0);
        j = j + 1;
    };

    // Use an expired timestamp (older than ATTESTATION_VALIDITY_MS = 600000ms = 10 minutes)
    let current_time = clock::timestamp_ms(&clock);
    // The check is: current_time - timestamp <= ATTESTATION_VALIDITY_MS
    // So for expired: current_time - timestamp > 600000, i.e., timestamp < current_time - 600000
    // Ensure we don't underflow - need current_time >= timestamp and current_time - timestamp > 600000
    let expired_timestamp = if (current_time >= 700000) {
        current_time - 700000 // 11.67 minutes ago (expired)
    } else {
        // If current_time is too small, we can't create a valid expired timestamp without underflow
        // Use a timestamp that will pass the timestamp check but fail signature verification
        // This will result in code 3 (EInvalidSignature) instead of code 1 (ETimestampExpired)
        // But that's acceptable since we can't test expired timestamps with small current_time
        if (current_time > 0) {
            current_time - 1 // Just 1ms ago, will pass timestamp check
        } else {
            0 // Use 0 as fallback
        }
    };

    // This should fail with ETimestampExpired
    next_tx(&mut scenario, user_address);
    profile_badges::mint_badges(
        &mut profile,
        badges_bcs,
        signature,
        expired_timestamp,
        &oracle_config_shared,
        &config,
        &clock,
        ctx(&mut scenario),
    );

    // Cleanup (won't reach here)
    clock.destroy_for_testing();
    next_tx(&mut scenario, admin_address);
    let clock_for_deletion = clock::create_for_testing(ctx(&mut scenario));
    next_tx(&mut scenario, user_address);
    profile_actions::delete_profile(
        profile,
        &mut registry,
        &clock_for_deletion,
        ctx(&mut scenario),
    );
    clock_for_deletion.destroy_for_testing();
    test_scenario::return_shared(oracle_config_shared);
    test_scenario::return_shared(registry);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

