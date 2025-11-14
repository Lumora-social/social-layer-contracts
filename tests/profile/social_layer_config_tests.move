module suins_social_layer::social_layer_config_tests;

use sui::test_scenario::{Self, next_tx, ctx};
use sui::transfer;
use suins_social_layer::app;
use suins_social_layer::social_layer_config;

#[test]
fun test_migrate_config_v1_to_v2() {
    let admin_address: address = @0xAD;
    let config_manager_address: address = @0xCM;

    let mut scenario = test_scenario::begin(admin_address);

    // Setup: Create config
    social_layer_config::test_create_config(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let mut config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Verify initial version is 1
    assert!(social_layer_config::version(&config) == 1, 0);

    // Assign config manager
    next_tx(&mut scenario, admin_address);
    let admin_cap = test_scenario::take_from_sender<suins_social_layer::app::AdminCap>(&scenario);
    social_layer_config::assign_config_manager(
        &admin_cap,
        &mut config,
        config_manager_address,
        ctx(&mut scenario),
    );
    transfer::public_transfer(admin_cap, admin_address);
    next_tx(&mut scenario, admin_address);

    // Config manager receives the cap
    next_tx(&mut scenario, config_manager_address);
    let config_manager_cap = test_scenario::take_from_sender<social_layer_config::ConfigManagerCap>(&scenario);

    // Migrate from v1 to v2
    next_tx(&mut scenario, config_manager_address);
    social_layer_config::migrate_config(
        &config_manager_cap,
        &mut config,
        2,
        ctx(&mut scenario),
    );

    // Verify version is now 2
    assert!(social_layer_config::version(&config) == 2, 1);

    // Cleanup
    transfer::public_transfer(config_manager_cap, config_manager_address);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
#[expected_failure(abort_code = suins_social_layer::social_layer_config::EConfigAlreadyAtTargetVersion)]
fun test_migrate_config_already_at_version() {
    let admin_address: address = @0xAD;
    let config_manager_address: address = @0xCM;

    let mut scenario = test_scenario::begin(admin_address);

    // Setup: Create config
    social_layer_config::test_create_config(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let mut config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Assign config manager
    next_tx(&mut scenario, admin_address);
    let admin_cap = test_scenario::take_from_sender<suins_social_layer::app::AdminCap>(&scenario);
    social_layer_config::assign_config_manager(
        &admin_cap,
        &mut config,
        config_manager_address,
        ctx(&mut scenario),
    );
    transfer::public_transfer(admin_cap, admin_address);
    next_tx(&mut scenario, admin_address);

    // Config manager receives the cap
    next_tx(&mut scenario, config_manager_address);
    let config_manager_cap = test_scenario::take_from_sender<social_layer_config::ConfigManagerCap>(&scenario);

    // Try to migrate to version 1 (already at version 1) - should fail
    next_tx(&mut scenario, config_manager_address);
    social_layer_config::migrate_config(
        &config_manager_cap,
        &mut config,
        1,
        ctx(&mut scenario),
    );

    // Cleanup (won't reach here)
    transfer::public_transfer(config_manager_cap, config_manager_address);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
#[expected_failure(abort_code = suins_social_layer::social_layer_config::EInvalidMigrationVersion)]
fun test_migrate_config_invalid_target_version() {
    let admin_address: address = @0xAD;
    let config_manager_address: address = @0xCM;

    let mut scenario = test_scenario::begin(admin_address);

    // Setup: Create config
    social_layer_config::test_create_config(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let mut config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Assign config manager
    next_tx(&mut scenario, admin_address);
    let admin_cap = test_scenario::take_from_sender<suins_social_layer::app::AdminCap>(&scenario);
    social_layer_config::assign_config_manager(
        &admin_cap,
        &mut config,
        config_manager_address,
        ctx(&mut scenario),
    );
    transfer::public_transfer(admin_cap, admin_address);
    next_tx(&mut scenario, admin_address);

    // Config manager receives the cap
    next_tx(&mut scenario, config_manager_address);
    let config_manager_cap = test_scenario::take_from_sender<social_layer_config::ConfigManagerCap>(&scenario);

    // Try to migrate to version 10 (greater than PACKAGE_VERSION = 1) - should fail
    next_tx(&mut scenario, config_manager_address);
    social_layer_config::migrate_config(
        &config_manager_cap,
        &mut config,
        10,
        ctx(&mut scenario),
    );

    // Cleanup (won't reach here)
    transfer::public_transfer(config_manager_cap, config_manager_address);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_update_config_to_latest_version() {
    let admin_address: address = @0xAD;
    let config_manager_address: address = @0xCM;

    let mut scenario = test_scenario::begin(admin_address);

    // Setup: Create config
    social_layer_config::test_create_config(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let mut config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Assign config manager
    next_tx(&mut scenario, admin_address);
    let admin_cap = test_scenario::take_from_sender<suins_social_layer::app::AdminCap>(&scenario);
    social_layer_config::assign_config_manager(
        &admin_cap,
        &mut config,
        config_manager_address,
        ctx(&mut scenario),
    );
    transfer::public_transfer(admin_cap, admin_address);
    next_tx(&mut scenario, admin_address);

    // Config manager receives the cap
    next_tx(&mut scenario, config_manager_address);
    let config_manager_cap = test_scenario::take_from_sender<social_layer_config::ConfigManagerCap>(&scenario);

    // Update to latest version (currently PACKAGE_VERSION = 1, so no change)
    // This test verifies the function works, even if version doesn't change
    next_tx(&mut scenario, config_manager_address);
    social_layer_config::update_config_to_latest_version(
        &config_manager_cap,
        &mut config,
        ctx(&mut scenario),
    );

    // Verify version is still 1 (PACKAGE_VERSION)
    assert!(social_layer_config::version(&config) == 1, 0);

    // Cleanup
    transfer::public_transfer(config_manager_cap, config_manager_address);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

