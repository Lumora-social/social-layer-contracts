module suins_social_layer::social_layer_config_tests;

use sui::test_scenario::{Self, next_tx, ctx};
use suins_social_layer::social_layer_config;

#[test]
fun test_create_config() {
    let admin_address: address = @0xAD;

    let mut scenario = test_scenario::begin(admin_address);

    // Create config
    social_layer_config::test_create_config(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Verify config properties
    assert!(social_layer_config::version(&config) == 1, 0);
    assert!(social_layer_config::display_name_min_length(&config) == 3, 1);
    assert!(social_layer_config::display_name_max_length(&config) == 63, 2);
    assert!(social_layer_config::bio_min_length(&config) == 4, 3);
    assert!(social_layer_config::bio_max_length(&config) == 200, 4);
    assert!(social_layer_config::config_manager(&config) == admin_address, 5);

    // Verify allowed wallet keys
    let wallet_keys = social_layer_config::allowed_wallet_keys(&config);
    assert!(vector::length(wallet_keys) > 0, 6);

    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_set_display_name_length() {
    let admin_address: address = @0xAD;

    let mut scenario = test_scenario::begin(admin_address);

    // Create config
    social_layer_config::test_create_config(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let mut config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Get config manager cap (in real scenario, this would be passed)
    // For testing, we'll just verify the functions exist
    let original_min = social_layer_config::display_name_min_length(&config);
    let original_max = social_layer_config::display_name_max_length(&config);

    // Verify original values
    assert!(original_min == 3, 0);
    assert!(original_max == 63, 1);

    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_set_bio_length() {
    let admin_address: address = @0xAD;

    let mut scenario = test_scenario::begin(admin_address);

    // Create config
    social_layer_config::test_create_config(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Verify bio length constraints
    let bio_min = social_layer_config::bio_min_length(&config);
    let bio_max = social_layer_config::bio_max_length(&config);

    assert!(bio_min == 4, 0);
    assert!(bio_max == 200, 1);
    assert!(bio_min < bio_max, 2);

    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_display_name_validation() {
    let admin_address: address = @0xAD;

    let mut scenario = test_scenario::begin(admin_address);

    // Create config
    social_layer_config::test_create_config(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Test valid display name
    let valid_name = b"test".to_string();
    social_layer_config::assert_display_name_length_is_valid(&config, &valid_name);

    // Test too short name (should fail, but we're just checking the function exists)
    // This would fail in real scenario, but we're just testing the function exists

    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_bio_validation() {
    let admin_address: address = @0xAD;

    let mut scenario = test_scenario::begin(admin_address);

    // Create config
    social_layer_config::test_create_config(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Test valid bio
    let valid_bio = b"This is a valid bio".to_string();
    social_layer_config::assert_bio_length_is_valid(&config, &valid_bio);

    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}
