module suins_social_layer::profile_tests;

use std::string::String;
use sui::clock;
use sui::dynamic_field as df;
use sui::test_scenario::{Self, next_tx, ctx};
use sui::test_utils::assert_eq;
use suins_social_layer::profile;
use suins_social_layer::profile_actions::delete_profile;
use suins_social_layer::social_layer_config;
use suins_social_layer::social_layer_registry;

#[test]
fun test_profile_operations() {
    let user_address: address = @0xA;
    let admin_address: address = @0xB;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));
    social_layer_registry::create_registry_for_testing((ctx(&mut scenario)));

    next_tx(&mut scenario, admin_address);
    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);

    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Test 1: Create profile
    next_tx(&mut scenario, user_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let display_name = b"display-name".to_string();
    let url = option::some(b"initial_url".to_string());
    let bio = option::some(b"Initial bio".to_string());
    let display_image_blob_id = option::some(b"initial_image_url".to_string());
    let background_image_blob_id = option::some(b"initial_background_image_url".to_string());
    let mut profile = suins_social_layer::profile::create_profile_helper(
        display_name,
        url,
        bio,
        display_image_blob_id,
        background_image_blob_id,
        &config,
        &mut registry,
        &clock,
        test_scenario::ctx(&mut scenario),
    );

    // Test 2: Verify initial profile state
    next_tx(&mut scenario, user_address);
    assert_eq(profile.display_name(), b"display-name".to_string());
    assert_eq(profile.url(), option::some(b"initial_url".to_string()));
    assert_eq(profile.bio(), option::some(b"Initial bio".to_string()));
    assert_eq(profile.display_image_url(), option::some(b"initial_image_url".to_string()));
    assert_eq(
        profile.background_image_url(),
        option::some(b"initial_background_image_url".to_string()),
    );

    // Test 3: Update display name
    let new_display_image_url = b"new_image_url".to_string();
    suins_social_layer::profile_actions::set_display_image_url(
        &mut profile,
        new_display_image_url,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.display_image_url(), option::some(b"new_image_url".to_string()));

    // Test 4: Update bio
    let new_background_image_url = b"new_background_image_url".to_string();
    suins_social_layer::profile_actions::set_background_image_url(
        &mut profile,
        new_background_image_url,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(
        profile.background_image_url(),
        option::some(b"new_background_image_url".to_string()),
    );

    // Test 5: Remove bio
    suins_social_layer::profile_actions::remove_background_image_url(
        &mut profile,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.background_image_url(), option::none<String>());

    // Test 6: Update image URL
    let new_display_image_url = b"new_image_url".to_string();
    suins_social_layer::profile_actions::set_display_image_url(
        &mut profile,
        new_display_image_url,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.display_image_url(), option::some(b"new_image_url".to_string()));

    // Test 7: Remove image URL
    suins_social_layer::profile_actions::remove_display_image_url(
        &mut profile,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.display_image_url(), option::none<String>());

    // Test 8: Update URL
    let new_url = b"new_url".to_string();
    suins_social_layer::profile_actions::set_url(
        &mut profile,
        new_url,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.url(), option::some(b"new_url".to_string()));

    // Test 9: Update blobID
    let new_background_image_url = b"new_background_image_url".to_string();
    suins_social_layer::profile_actions::set_background_image_url(
        &mut profile,
        new_background_image_url,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(
        profile.background_image_url(),
        option::some(b"new_background_image_url".to_string()),
    );

    // Test 10: Remove URL
    suins_social_layer::profile_actions::remove_url(
        &mut profile,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.url(), option::none<String>());

    // Test 13: Add wallet address
    let network = b"ETH".to_string();
    let address = b"0x1234567890123456789012345678901234567890".to_string();
    suins_social_layer::profile_actions::add_wallet_address(
        &mut profile,
        network,
        address,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );

    let wallet_addresses = profile.wallet_addresses();
    assert!(sui::vec_map::contains(&wallet_addresses, &b"ETH".to_string()));
    assert_eq(
        *sui::vec_map::get(&wallet_addresses, &b"ETH".to_string()),
        b"0x1234567890123456789012345678901234567890".to_string(),
    );

    // Test 14: Update wallet address
    let new_address = b"0x0987654321098765432109876543210987654321".to_string();
    suins_social_layer::profile_actions::update_wallet_address(
        &mut profile,
        b"ETH".to_string(),
        new_address,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );

    let wallet_addresses = profile.wallet_addresses();
    assert_eq(
        *sui::vec_map::get(&wallet_addresses, &b"ETH".to_string()),
        b"0x0987654321098765432109876543210987654321".to_string(),
    );

    // Test 15: Remove wallet address
    suins_social_layer::profile_actions::remove_wallet_address(
        &mut profile,
        b"ETH".to_string(),
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );

    let wallet_addresses = profile.wallet_addresses();
    assert!(!sui::vec_map::contains(&wallet_addresses, &b"ETH".to_string()));

    // Test 16: Set bio
    let new_bio = b"This is a new bio for testing".to_string();
    suins_social_layer::profile_actions::set_bio(
        &mut profile,
        new_bio,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.bio(), option::some(b"This is a new bio for testing".to_string()));

    // Test 17: Remove bio
    suins_social_layer::profile_actions::remove_bio(
        &mut profile,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.bio(), option::none<String>());

    // Test 18: Archive profile
    suins_social_layer::profile_actions::archive_profile(
        &mut profile,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert!(profile.is_archived());

    // Test 19: Unarchive profile
    suins_social_layer::profile_actions::unarchive_profile(
        &mut profile,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert!(!profile.is_archived());

    // Test 20: Delete profile
    suins_social_layer::profile_actions::delete_profile(
        profile,
        &mut registry,
        &clock,
        test_scenario::ctx(&mut scenario),
    );

    clock.destroy_for_testing();
    next_tx(&mut scenario, admin_address);
    test_scenario::return_shared(config);
    test_scenario::return_shared(registry);
    test_scenario::end(scenario);
}

#[test]
#[expected_failure(abort_code = suins_social_layer::profile::EDisplayNameAlreadyTaken)]
fun test_duplicate_profile_creation() {
    let user_address: address = @0xA;
    let admin_address: address = @0xB;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));
    social_layer_registry::create_registry_for_testing(ctx(&mut scenario));

    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);
    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);

    // Test 1: Create profile
    next_tx(&mut scenario, user_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let display_name = b"display-name".to_string();
    let url = option::some(b"initial_url".to_string());
    let bio = option::some(b"Initial bio".to_string());
    let display_image_url = option::some(b"initial_image_url".to_string());
    let background_image_url = option::some(b"initial_background_image_url".to_string());
    // Create first profile
    let profile1 = suins_social_layer::profile::create_profile_helper(
        display_name,
        url,
        bio,
        display_image_url,
        background_image_url,
        &config,
        &mut registry,
        &clock,
        test_scenario::ctx(&mut scenario),
    );

    // Try to create duplicate profile
    next_tx(&mut scenario, user_address);
    let profile2 = suins_social_layer::profile::create_profile_helper(
        display_name,
        url,
        bio,
        display_image_url,
        background_image_url,
        &config,
        &mut registry,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    delete_profile(profile1, &mut registry, &clock, test_scenario::ctx(&mut scenario));
    delete_profile(profile2, &mut registry, &clock, test_scenario::ctx(&mut scenario));

    clock.destroy_for_testing();
    next_tx(&mut scenario, admin_address);
    test_scenario::return_shared(config);
    test_scenario::return_shared(registry);
    test_scenario::end(scenario);
}

#[test]
fun test_dynamic_fields() {
    let user_address: address = @0xA;
    let admin_address: address = @0xB;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));
    social_layer_registry::create_registry_for_testing((ctx(&mut scenario)));

    next_tx(&mut scenario, admin_address);
    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);

    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Test 1: Create profile
    next_tx(&mut scenario, user_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let display_name = b"display-name".to_string();
    let url = option::some(b"initial_url".to_string());
    let bio = option::some(b"Initial bio".to_string());
    let display_image_url = option::some(b"initial_image_url".to_string());
    let background_image_url = option::some(b"initial_background_image_url".to_string());
    let mut profile = suins_social_layer::profile::create_profile_helper(
        display_name,
        url,
        bio,
        display_image_url,
        background_image_url,
        &config,
        &mut registry,
        &clock,
        test_scenario::ctx(&mut scenario),
    );

    let mut df_key = b"test_df_key".to_string();
    let mut df_value = b"test_df_value".to_string();
    suins_social_layer::profile_actions::add_df_to_profile(&mut profile, df_key, df_value, &clock);
    let df_value_retrieved = df::borrow<String, String>(profile::uid(&profile), df_key);
    assert!(df_value_retrieved == df_value);

    suins_social_layer::profile_actions::remove_df_from_profile<String, String>(
        &mut profile,
        df_key,
        &clock,
    );
    assert!(!df::exists_(profile::uid(&profile), df_key));

    df_value = b"new_df_value".to_string();
    suins_social_layer::profile_actions::add_df_to_profile(&mut profile, df_key, df_value, &clock);
    let df_value_retrieved = df::borrow<String, String>(profile::uid(&profile), df_key);
    assert!(df_value_retrieved == df_value);

    df_key = b"test_df_key_2".to_string();
    suins_social_layer::profile_actions::add_df_to_profile(&mut profile, df_key, df_value, &clock);
    let df_value_retrieved = df::borrow<String, String>(profile::uid(&profile), df_key);
    assert!(df_value_retrieved == df_value);

    suins_social_layer::profile_actions::delete_profile(
        profile,
        &mut registry,
        &clock,
        test_scenario::ctx(&mut scenario),
    );

    clock.destroy_for_testing();
    next_tx(&mut scenario, admin_address);
    test_scenario::return_shared(config);
    test_scenario::return_shared(registry);
    test_scenario::end(scenario);
}
