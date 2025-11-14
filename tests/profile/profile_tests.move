module suins_social_layer::profile_tests;

use sui::clock;
use sui::test_scenario::{Self, next_tx, ctx};
use suins_social_layer::profile;
use suins_social_layer::profile_actions;
use suins_social_layer::social_layer_config;
use suins_social_layer::social_layer_registry;

#[test]
fun test_create_profile() {
    let admin_address: address = @0xAD;
    let user_address: address = @0xA;

    let mut scenario = test_scenario::begin(admin_address);

    // Setup
    social_layer_config::test_create_config(ctx(&mut scenario));
    social_layer_registry::create_registry_for_testing(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Create profile
    next_tx(&mut scenario, user_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let profile = profile::create_profile_helper(
        b"testuser".to_string(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    // Verify profile properties
    assert!(profile::display_name(&profile) == b"testuser".to_string(), 0);
    assert!(profile::owner(&profile) == user_address, 1);
    assert!(!profile::is_archived(&profile), 2);
    assert!(option::is_none(&profile::bio(&profile)), 3);
    assert!(option::is_none(&profile::url(&profile)), 4);

    // Cleanup
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
    test_scenario::return_shared(registry);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_create_profile_with_bio_and_url() {
    let admin_address: address = @0xAD;
    let user_address: address = @0xA;

    let mut scenario = test_scenario::begin(admin_address);

    // Setup
    social_layer_config::test_create_config(ctx(&mut scenario));
    social_layer_registry::create_registry_for_testing(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Create profile with bio and URL
    next_tx(&mut scenario, user_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let profile = profile::create_profile_helper(
        b"testuser2".to_string(),
        option::some(b"https://example.com".to_string()),
        option::some(b"This is a test bio".to_string()),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    // Verify profile properties
    assert!(profile::display_name(&profile) == b"testuser2".to_string(), 0);
    assert!(option::is_some(&profile::bio(&profile)), 1);
    assert!(option::is_some(&profile::url(&profile)), 2);
    let bio = option::extract(&mut profile::bio(&profile));
    assert!(bio == b"This is a test bio".to_string(), 3);
    let url = option::extract(&mut profile::url(&profile));
    assert!(url == b"https://example.com".to_string(), 4);

    // Cleanup
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
    test_scenario::return_shared(registry);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_update_profile_bio() {
    let admin_address: address = @0xAD;
    let user_address: address = @0xA;

    let mut scenario = test_scenario::begin(admin_address);

    // Setup
    social_layer_config::test_create_config(ctx(&mut scenario));
    social_layer_registry::create_registry_for_testing(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Create profile
    next_tx(&mut scenario, user_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let mut profile = profile::create_profile_helper(
        b"testuser3".to_string(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    // Update bio
    next_tx(&mut scenario, user_address);
    profile_actions::set_bio(
        &mut profile,
        b"Updated bio text".to_string(),
        &config,
        &clock,
        ctx(&mut scenario),
    );

    // Verify bio was updated
    assert!(option::is_some(&profile::bio(&profile)), 0);
    let bio = option::extract(&mut profile::bio(&profile));
    assert!(bio == b"Updated bio text".to_string(), 1);

    // Remove bio
    next_tx(&mut scenario, user_address);
    profile_actions::remove_bio(
        &mut profile,
        &config,
        &clock,
        ctx(&mut scenario),
    );

    // Verify bio was removed
    assert!(option::is_none(&profile::bio(&profile)), 2);

    // Cleanup
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
    test_scenario::return_shared(registry);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_archive_and_unarchive_profile() {
    let admin_address: address = @0xAD;
    let user_address: address = @0xA;

    let mut scenario = test_scenario::begin(admin_address);

    // Setup
    social_layer_config::test_create_config(ctx(&mut scenario));
    social_layer_registry::create_registry_for_testing(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Create profile
    next_tx(&mut scenario, user_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let mut profile = profile::create_profile_helper(
        b"testuser4".to_string(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    // Verify profile is not archived
    assert!(!profile::is_archived(&profile), 0);

    // Archive profile
    next_tx(&mut scenario, user_address);
    profile_actions::archive_profile(
        &mut profile,
        &config,
        &clock,
        ctx(&mut scenario),
    );

    // Verify profile is archived
    assert!(profile::is_archived(&profile), 1);

    // Unarchive profile
    next_tx(&mut scenario, user_address);
    profile_actions::unarchive_profile(
        &mut profile,
        &config,
        &clock,
        ctx(&mut scenario),
    );

    // Verify profile is not archived
    assert!(!profile::is_archived(&profile), 2);

    // Cleanup
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
    test_scenario::return_shared(registry);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}
