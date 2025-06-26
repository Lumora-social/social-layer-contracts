module suins_social_layer::profile_tests;

use std::string::String;
use sui::clock;
use sui::test_scenario::{Self, next_tx, ctx};
use sui::test_utils::assert_eq;
use suins_social_layer::profile::Profile;
use suins_social_layer::social_layer_config;
use suins_social_layer::social_layer_registry;

#[test]
fun test_profile_operations() {
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
    let display_name = b"initial_name".to_string();
    let url = option::some(b"initial_url".to_string());
    let bio = option::some(b"Initial bio".to_string());
    let display_image_blob_id = option::some(b"initial_image_url".to_string());
    let background_image_blob_id = option::some(b"initial_background_image_url".to_string());
    let walrus_site_id = option::some(b"initial_walrus_site_id".to_string());
    let mut user_address_with_hex_prefix = b"0x".to_string();
    std::string::append(&mut user_address_with_hex_prefix, user_address.to_string());
    suins_social_layer::profile_actions::create_profile_without_suins(
        user_address_with_hex_prefix,
        display_name,
        url,
        bio,
        display_image_blob_id,
        background_image_blob_id,
        walrus_site_id,
        &config,
        &mut registry,
        &clock,
        test_scenario::ctx(&mut scenario),
    );

    // Test 2: Verify initial profile state
    next_tx(&mut scenario, user_address);
    let mut profile = test_scenario::take_from_sender<Profile>(&scenario);
    assert_eq(profile.user_name(), user_address_with_hex_prefix);
    assert_eq(profile.display_name(), b"initial_name".to_string());
    assert_eq(profile.url(), option::some(b"initial_url".to_string()));
    assert_eq(profile.bio(), option::some(b"Initial bio".to_string()));
    assert_eq(profile.display_image_blob_id(), option::some(b"initial_image_url".to_string()));
    assert_eq(
        profile.background_image_blob_id(),
        option::some(b"initial_background_image_url".to_string()),
    );
    assert_eq(profile.walrus_site_id(), option::some(b"initial_walrus_site_id".to_string()));

    // Test 3: Update display name
    let new_display_image_blob_id = b"new_image_url".to_string();
    suins_social_layer::profile_actions::set_display_image_blob_id(
        &mut profile,
        new_display_image_blob_id,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.display_image_blob_id(), option::some(b"new_image_url".to_string()));

    // Test 4: Update bio
    let new_background_image_blob_id = b"new_background_image_url".to_string();
    suins_social_layer::profile_actions::set_background_image_blob_id(
        &mut profile,
        new_background_image_blob_id,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(
        profile.background_image_blob_id(),
        option::some(b"new_background_image_url".to_string()),
    );

    // Test 5: Remove bio
    suins_social_layer::profile_actions::remove_background_image_blob_id(
        &mut profile,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.background_image_blob_id(), option::none<String>());

    // Test 6: Update image URL
    let new_display_image_blob_id = b"new_image_url".to_string();
    suins_social_layer::profile_actions::set_display_image_blob_id(
        &mut profile,
        new_display_image_blob_id,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.display_image_blob_id(), option::some(b"new_image_url".to_string()));

    // Test 7: Remove image URL
    suins_social_layer::profile_actions::remove_display_image_blob_id(
        &mut profile,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.display_image_blob_id(), option::none<String>());

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
    let new_background_image_blob_id = b"new_background_image_url".to_string();
    suins_social_layer::profile_actions::set_background_image_blob_id(
        &mut profile,
        new_background_image_blob_id,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(
        profile.background_image_blob_id(),
        option::some(b"new_background_image_url".to_string()),
    );

    // Test 9: Remove URL
    suins_social_layer::profile_actions::remove_url(
        &mut profile,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.url(), option::none<String>());

    // Test 10: set walrus_site_id
    let new_walrus_site_id = b"new_walrus_site_id".to_string();
    suins_social_layer::profile_actions::set_walrus_site_id(
        &mut profile,
        new_walrus_site_id,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.walrus_site_id(), option::some(b"new_walrus_site_id".to_string()));

    // Test 11: remove walrus_site_id
    suins_social_layer::profile_actions::remove_walrus_site_id(
        &mut profile,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.walrus_site_id(), option::none<String>());

    // Test 12: Archive profile
    suins_social_layer::profile_actions::archive_profile(
        &mut profile,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert!(profile.is_archived());

    // Test 13: Unarchive profile
    suins_social_layer::profile_actions::unarchive_profile(
        &mut profile,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert!(!profile.is_archived());

    // Test 14: Delete profile
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
#[expected_failure(abort_code = suins_social_layer::profile::EUserNameAlreadyExists)]
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
    let display_name = b"initial_name".to_string();
    let url = option::some(b"initial_url".to_string());
    let bio = option::some(b"Initial bio".to_string());
    let display_image_blob_id = option::some(b"initial_image_url".to_string());
    let background_image_blob_id = option::some(b"initial_background_image_url".to_string());
    let walrus_site_id = option::some(b"initial_walrus_site_id".to_string());
    let mut user_address_with_hex_prefix = b"0x".to_string();
    std::string::append(&mut user_address_with_hex_prefix, user_address.to_string());

    // Create first profile
    suins_social_layer::profile_actions::create_profile_without_suins(
        user_address_with_hex_prefix,
        display_name,
        url,
        bio,
        display_image_blob_id,
        background_image_blob_id,
        walrus_site_id,
        &config,
        &mut registry,
        &clock,
        test_scenario::ctx(&mut scenario),
    );

    // Try to create duplicate profile
    next_tx(&mut scenario, user_address);
    suins_social_layer::profile_actions::create_profile_without_suins(
        user_address_with_hex_prefix,
        display_name,
        url,
        bio,
        display_image_blob_id,
        background_image_blob_id,
        walrus_site_id,
        &config,
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
