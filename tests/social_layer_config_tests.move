module suins_social_layer::social_layer_config_tests;

use sui::test_scenario::{Self, next_tx, ctx};
use sui::test_utils::assert_eq;
use suins_social_layer::app::AdminCap;
use suins_social_layer::social_layer_config::{Self, Config, ConfigManagerCap};
use suins_social_layer::social_layer_constants;

#[test]
fun test_config_creation() {
    let admin_address: address = @0xA;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));

    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<Config>(&scenario);

    // Test initial config values
    assert_eq(social_layer_config::version(&config), 1);
    assert_eq(
        social_layer_config::display_name_min_length(&config),
        social_layer_constants::display_name_min_length(),
    );
    assert_eq(
        social_layer_config::display_name_max_length(&config),
        social_layer_constants::display_name_max_length(),
    );
    assert_eq(
        social_layer_config::user_name_min_length(&config),
        social_layer_constants::user_name_min_length(),
    );
    assert_eq(
        social_layer_config::user_name_max_length(&config),
        social_layer_constants::user_name_max_length(),
    );
    assert_eq(
        social_layer_config::bio_min_length(&config),
        social_layer_constants::bio_min_length(),
    );
    assert_eq(
        social_layer_config::bio_max_length(&config),
        social_layer_constants::bio_max_length(),
    );
    assert_eq(social_layer_config::config_manager(&config), admin_address);

    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_assign_config_manager() {
    let admin_address: address = @0xA;
    let new_config_manager: address = @0xB;

    let mut scenario = test_scenario::begin(admin_address);
    suins_social_layer::app::test_init(ctx(&mut scenario));
    social_layer_config::test_create_config(ctx(&mut scenario));

    next_tx(&mut scenario, admin_address);
    let admin_cap = test_scenario::take_from_sender<AdminCap>(&scenario);
    let mut config = test_scenario::take_shared<Config>(&scenario);

    // Assign new config manager
    social_layer_config::assign_config_manager(
        &admin_cap,
        &mut config,
        new_config_manager,
        ctx(&mut scenario),
    );
    test_scenario::return_to_sender(&scenario, admin_cap);

    // Verify config manager was updated
    assert_eq(social_layer_config::config_manager(&config), new_config_manager);

    // Verify ConfigManagerCap was transferred to new manager
    next_tx(&mut scenario, new_config_manager);
    let config_manager_cap = test_scenario::take_from_sender<ConfigManagerCap>(&scenario);
    test_scenario::return_to_sender(&scenario, config_manager_cap);

    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_set_all_config_values() {
    let admin_address: address = @0xA;

    let mut scenario = test_scenario::begin(admin_address);
    suins_social_layer::app::test_init(ctx(&mut scenario));
    social_layer_config::test_create_config(ctx(&mut scenario));

    next_tx(&mut scenario, admin_address);
    let admin_cap = test_scenario::take_from_sender<AdminCap>(&scenario);
    let mut config = test_scenario::take_shared<Config>(&scenario);

    // Assign new config manager
    social_layer_config::assign_config_manager(
        &admin_cap,
        &mut config,
        admin_address,
        ctx(&mut scenario),
    );
    test_scenario::return_to_sender(&scenario, admin_cap);

    next_tx(&mut scenario, admin_address);
    let config_manager_cap = test_scenario::take_from_sender<ConfigManagerCap>(&scenario);

    // Test setting display name min length
    let new_display_name_min_length = 5;
    social_layer_config::set_display_name_min_length(
        &config_manager_cap,
        &mut config,
        new_display_name_min_length,
        ctx(&mut scenario),
    );
    assert_eq(social_layer_config::display_name_min_length(&config), new_display_name_min_length);

    // Test setting display name max length
    let new_display_name_max_length = 50;
    social_layer_config::set_display_name_max_length(
        &config_manager_cap,
        &mut config,
        new_display_name_max_length,
        ctx(&mut scenario),
    );
    assert_eq(social_layer_config::display_name_max_length(&config), new_display_name_max_length);

    // Test setting bio min length
    let new_bio_min_length = 10;
    social_layer_config::set_bio_min_length(
        &config_manager_cap,
        &mut config,
        new_bio_min_length,
        ctx(&mut scenario),
    );
    assert_eq(social_layer_config::bio_min_length(&config), new_bio_min_length);

    // Test setting bio max length
    let new_bio_max_length = 300;
    social_layer_config::set_bio_max_length(
        &config_manager_cap,
        &mut config,
        new_bio_max_length,
        ctx(&mut scenario),
    );
    assert_eq(social_layer_config::bio_max_length(&config), new_bio_max_length);

    test_scenario::return_to_sender(&scenario, config_manager_cap);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_display_name_validation() {
    let admin_address: address = @0xA;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));

    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<Config>(&scenario);

    // Test valid display name
    let valid_display_name = b"Valid Name".to_string();
    social_layer_config::assert_display_name_length_is_valid(&config, &valid_display_name);

    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
#[expected_failure(abort_code = social_layer_config::EDisplayNameTooShort)]
fun test_display_name_too_short() {
    let admin_address: address = @0xA;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));

    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<Config>(&scenario);

    // Test display name too short
    let short_display_name = b"ab".to_string();
    social_layer_config::assert_display_name_length_is_valid(&config, &short_display_name);

    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
#[expected_failure(abort_code = social_layer_config::EDisplayNameTooLong)]
fun test_display_name_too_long() {
    let admin_address: address = @0xA;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));

    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<Config>(&scenario);

    // Test display name too long
    let long_display_name = b"This is a very long display name that exceeds the maximum length".to_string();
    social_layer_config::assert_display_name_length_is_valid(&config, &long_display_name);

    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_bio_validation() {
    let admin_address: address = @0xA;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));

    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<Config>(&scenario);

    // Test valid bio
    let valid_bio = b"This is a valid bio with reasonable length.".to_string();
    social_layer_config::assert_bio_length_is_valid(&config, &valid_bio);

    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
#[expected_failure(abort_code = social_layer_config::EBioTooShort)]
fun test_bio_too_short() {
    let admin_address: address = @0xA;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));

    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<Config>(&scenario);

    // Test bio too short (empty string)
    let short_bio = b"".to_string();
    social_layer_config::assert_bio_length_is_valid(&config, &short_bio);

    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
#[expected_failure(abort_code = social_layer_config::EBioTooLong)]
fun test_bio_too_long() {
    let admin_address: address = @0xA;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));

    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<Config>(&scenario);

    // Test bio too long
    let long_bio = b"This is a very long bio that exceeds the maximum allowed length. It contains many characters and should definitely be longer than the maximum bio length limit. This bio is designed to test the validation logic and ensure that bios that are too long are properly rejected by the system.".to_string();
    social_layer_config::assert_bio_length_is_valid(&config, &long_bio);

    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_user_name_validation() {
    let admin_address: address = @0xA;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));

    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<Config>(&scenario);

    // Test valid usernames
    let valid_usernames = vector[
        b"validuser".to_string(),
        b"user123".to_string(),
        b"user-name".to_string(),
        b"user-name-123".to_string(),
        b"abc".to_string(), // minimum length
        b"verylongusername123".to_string(), // maximum length
    ];

    let mut i = 0;
    while (i < valid_usernames.length()) {
        social_layer_config::assert_user_name_is_valid(&config, &valid_usernames[i]);
        i = i + 1;
    };

    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
#[expected_failure(abort_code = social_layer_config::EUserNameTooShort)]
fun test_user_name_too_short() {
    let admin_address: address = @0xA;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));

    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<Config>(&scenario);

    // Test username too short
    let short_username = b"ab".to_string();
    social_layer_config::assert_user_name_is_valid(&config, &short_username);

    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
#[expected_failure(abort_code = social_layer_config::EUserNameTooLong)]
fun test_user_name_too_long() {
    let admin_address: address = @0xA;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));

    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<Config>(&scenario);

    // Test username too long
    let long_username = b"verylongusername123456".to_string();
    social_layer_config::assert_user_name_is_valid(&config, &long_username);

    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
#[expected_failure(abort_code = social_layer_config::EUserNameInvalidCharacter)]
fun test_user_name_invalid_characters() {
    let admin_address: address = @0xA;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));

    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<Config>(&scenario);

    // Test usernames with invalid characters
    let invalid_usernames = vector[
        b"user@name".to_string(), // @ symbol
        b"user_name".to_string(), // underscore
        b"user.name".to_string(), // period
        b"user name".to_string(), // space
        b"User".to_string(), // uppercase
        b"-username".to_string(), // starts with dash
        b"username-".to_string(), // ends with dash
        b"user--name".to_string(), // consecutive dashes
    ];

    let mut i = 0;
    while (i < invalid_usernames.length()) {
        social_layer_config::assert_user_name_is_valid(&config, &invalid_usernames[i]);
        i = i + 1;
    };

    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
#[expected_failure(abort_code = social_layer_config::EAddressIsNotConfigManager)]
fun test_unauthorized_config_manager_access() {
    let admin_address: address = @0xA;
    let unauthorized_address: address = @0xB;

    let mut scenario = test_scenario::begin(admin_address);
    suins_social_layer::app::test_init(ctx(&mut scenario));
    social_layer_config::test_create_config(ctx(&mut scenario));

    next_tx(&mut scenario, admin_address);
    let admin_cap = test_scenario::take_from_sender<AdminCap>(&scenario);
    let mut config = test_scenario::take_shared<Config>(&scenario);

    social_layer_config::assign_config_manager(
        &admin_cap,
        &mut config,
        admin_address,
        ctx(&mut scenario),
    );

    next_tx(&mut scenario, admin_address);
    let config_manager_cap = test_scenario::take_from_sender<ConfigManagerCap>(&scenario);

    // Try to modify config from unauthorized address
    next_tx(&mut scenario, unauthorized_address);
    social_layer_config::set_display_name_min_length(
        &config_manager_cap,
        &mut config,
        5,
        ctx(&mut scenario),
    );

    test_scenario::return_to_sender(&scenario, config_manager_cap);
    test_scenario::return_shared(config);
    test_scenario::return_to_sender(&scenario, admin_cap);
    test_scenario::end(scenario);
}

#[test]
fun test_config_manager_cap_validation() {
    let admin_address: address = @0xA;
    let new_config_manager: address = @0xB;

    let mut scenario = test_scenario::begin(admin_address);
    suins_social_layer::app::test_init(ctx(&mut scenario));
    social_layer_config::test_create_config(ctx(&mut scenario));

    next_tx(&mut scenario, admin_address);
    let admin_cap = test_scenario::take_from_sender<AdminCap>(&scenario);
    let mut config = test_scenario::take_shared<Config>(&scenario);

    // Assign new config manager
    social_layer_config::assign_config_manager(
        &admin_cap,
        &mut config,
        new_config_manager,
        ctx(&mut scenario),
    );
    test_scenario::return_to_sender(&scenario, admin_cap);

    // Verify new config manager can access config
    next_tx(&mut scenario, new_config_manager);
    let config_manager_cap = test_scenario::take_from_sender<ConfigManagerCap>(&scenario);

    // Test that new config manager can modify config
    social_layer_config::set_display_name_min_length(
        &config_manager_cap,
        &mut config,
        5,
        ctx(&mut scenario),
    );

    test_scenario::return_to_sender(&scenario, config_manager_cap);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_config_version_validation() {
    let admin_address: address = @0xA;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));

    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<Config>(&scenario);

    // Test that current version is valid
    social_layer_config::assert_interacting_with_most_up_to_date_package(&config);

    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}
