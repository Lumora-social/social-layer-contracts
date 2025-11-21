module suins_social_layer::social_layer_registry_tests;

use sui::test_scenario::{Self, next_tx, ctx};
use suins_social_layer::social_layer_registry;

#[test]
fun test_create_registry() {
    let admin_address: address = @0xAD;

    let mut scenario = test_scenario::begin(admin_address);

    // Create registry
    social_layer_registry::create_registry_for_testing(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);

    // Verify registry exists
    // Test that we can check for non-existent entries
    assert!(
        !social_layer_registry::get_entry_display_name_registry(&registry, b"test".to_string()),
        0,
    );
    assert!(!social_layer_registry::get_entry_address_registry(&registry, @0x1), 1);

    test_scenario::return_shared(registry);
    test_scenario::end(scenario);
}

#[test]
fun test_display_name_registry_operations() {
    let admin_address: address = @0xAD;

    let mut scenario = test_scenario::begin(admin_address);

    // Create registry
    social_layer_registry::create_registry_for_testing(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);

    // Test display name registry operations
    let display_name = b"testuser".to_string();

    // Initially, display name should not exist
    assert!(!social_layer_registry::get_entry_display_name_registry(&registry, display_name), 0);

    // Add display name (using package function)
    next_tx(&mut scenario, admin_address);
    social_layer_registry::add_entry_display_name_registry(&mut registry, display_name);

    // Verify display name exists
    assert!(social_layer_registry::get_entry_display_name_registry(&registry, display_name), 1);

    // Remove display name
    social_layer_registry::remove_entry_display_name_registry(&mut registry, display_name);

    // Verify display name no longer exists
    assert!(!social_layer_registry::get_entry_display_name_registry(&registry, display_name), 2);

    test_scenario::return_shared(registry);
    test_scenario::end(scenario);
}

#[test]
fun test_address_registry_operations() {
    let admin_address: address = @0xAD;
    let test_address: address = @0x123;

    let mut scenario = test_scenario::begin(admin_address);

    // Create registry
    social_layer_registry::create_registry_for_testing(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);

    // Initially, address should not exist
    assert!(!social_layer_registry::get_entry_address_registry(&registry, test_address), 0);

    // Add address (using package function)
    next_tx(&mut scenario, admin_address);
    social_layer_registry::add_entry_address_registry(&mut registry, test_address);

    // Verify address exists
    assert!(social_layer_registry::get_entry_address_registry(&registry, test_address), 1);

    // Remove address
    social_layer_registry::remove_entry_address_registry(&mut registry, test_address);

    // Verify address no longer exists
    assert!(!social_layer_registry::get_entry_address_registry(&registry, test_address), 2);

    test_scenario::return_shared(registry);
    test_scenario::end(scenario);
}

#[test]
fun test_add_and_remove_entries() {
    let admin_address: address = @0xAD;
    let test_address: address = @0x456;
    let display_name = b"testuser2".to_string();

    let mut scenario = test_scenario::begin(admin_address);

    // Create registry
    social_layer_registry::create_registry_for_testing(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);

    // Add both entries together
    next_tx(&mut scenario, admin_address);
    social_layer_registry::add_entries(&mut registry, display_name, test_address);

    // Verify both exist
    assert!(social_layer_registry::get_entry_display_name_registry(&registry, display_name), 0);
    assert!(social_layer_registry::get_entry_address_registry(&registry, test_address), 1);

    // Remove both entries together
    social_layer_registry::remove_entries(&mut registry, display_name, test_address);

    // Verify both no longer exist
    assert!(!social_layer_registry::get_entry_display_name_registry(&registry, display_name), 2);
    assert!(!social_layer_registry::get_entry_address_registry(&registry, test_address), 3);

    test_scenario::return_shared(registry);
    test_scenario::end(scenario);
}


