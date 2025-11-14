module suins_social_layer::social_verification_tests;

use sui::clock;
use sui::test_scenario::{Self, next_tx, ctx};
use suins_social_layer::profile;
use suins_social_layer::profile_actions;
use suins_social_layer::social_layer_config;
use suins_social_layer::social_layer_registry;
use suins_social_layer::social_verification;

// Note: OracleConfig has 'key' ability and can only be transferred within its module.
// The create_test_oracle_config function is for module-internal testing only.
// OracleConfig functionality is tested through integration with other modules.

// Note: OracleConfig tests are limited because it has 'key' ability
// and must be managed within its module. The create_test_oracle_config
// function exists for module-internal testing.

#[test]
fun test_unlink_social_account() {
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

    // Link social account (using package function for testing)
    next_tx(&mut scenario, user_address);
    profile::link_social_account(
        &mut profile,
        b"twitter".to_string(),
        b"testuser".to_string(),
        &config,
        &clock,
        ctx(&mut scenario),
    );

    // Unlink social account
    next_tx(&mut scenario, user_address);
    social_verification::unlink_social_account(
        &mut profile,
        b"twitter".to_string(),
        &config,
        &clock,
        ctx(&mut scenario),
    );

    // Verify account was unlinked
    let username = profile::get_social_account_username(&profile, &b"twitter".to_string());
    assert!(option::is_none(&username), 0);

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

