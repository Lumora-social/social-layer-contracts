module suins_social_layer::secure_wallet_link_tests;

use sui::clock;
use sui::test_scenario::{Self, next_tx, ctx};
use suins_social_layer::profile;
use suins_social_layer::profile_actions;
use suins_social_layer::social_layer_config;
use suins_social_layer::social_layer_registry;

// Note: NonceRegistry has 'key' ability and can only be transferred within its module.
// The create_test_registry function is for module-internal testing only.
// NonceRegistry functionality is tested through integration with wallet linking functions.

#[test]
fun test_unlink_wallet() {
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

    // Add wallet address (using package function)
    next_tx(&mut scenario, user_address);
    profile::add_wallet_address(
        &mut profile,
        b"ETH".to_string(),
        b"0x1234567890123456789012345678901234567890".to_string(),
        &config,
        &clock,
        ctx(&mut scenario),
    );

    // Remove wallet address (using package function)
    next_tx(&mut scenario, user_address);
    profile::remove_wallet_address(
        &mut profile,
        b"ETH".to_string(),
        b"0x1234567890123456789012345678901234567890".to_string(),
        &config,
        &clock,
        ctx(&mut scenario),
    );

    // Verify wallet was removed
    let wallets = profile::wallet_addresses(&profile);
    assert!(!sui::vec_map::contains(&wallets, &b"ETH".to_string()), 0);

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
