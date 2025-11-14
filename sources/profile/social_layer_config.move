module suins_social_layer::social_layer_config;

use std::string::String;
use sui::types;
use suins_social_layer::app::AdminCap;
use suins_social_layer::social_layer_constants;

const ENotLatestVersion: u64 = 0;
const ETypeNotOneTimeWitness: u64 = 1;
const EDisplayNameTooLong: u64 = 2;
const EDisplayNameTooShort: u64 = 3;
const EBioTooLong: u64 = 4;
const EBioTooShort: u64 = 5;
const EAddressIsNotConfigManager: u64 = 6;
const EDisplayNameInvalidCharacter: u64 = 7;
const EWalletKeyNotAllowed: u64 = 8;
const EWalletKeyAlreadyExists: u64 = 9;
const ESocialPlatformNotAllowed: u64 = 10;
const ESocialPlatformAlreadyExists: u64 = 11;
const EInvalidMigrationVersion: u64 = 12;
const EConfigAlreadyAtTargetVersion: u64 = 13;

const PACKAGE_VERSION: u64 = 1;

public struct SOCIAL_LAYER_CONFIG has drop {}

public struct Config has key {
    id: UID,
    version: u64,
    display_name_min_length: u64,
    display_name_max_length: u64,
    bio_min_length: u64,
    bio_max_length: u64,
    allowed_wallet_keys: vector<String>,
    allowed_social_platforms: vector<String>,
    config_manager: address,
}

public struct ConfigManagerCap has key, store {
    id: UID,
    config_manager: address,
}

public fun assert_interacting_with_most_up_to_date_package(config: &Config) {
    assert!(config.version == PACKAGE_VERSION, ENotLatestVersion);
}

public fun assert_address_is_config_manager(
    config_manager_cap: &ConfigManagerCap,
    config: &Config,
    ctx: &mut TxContext,
) {
    assert!(
        config_manager_cap.config_manager == tx_context::sender(ctx),
        EAddressIsNotConfigManager,
    );
    assert!(config.config_manager == tx_context::sender(ctx), EAddressIsNotConfigManager);
}

public fun create_config(otw: &SOCIAL_LAYER_CONFIG, ctx: &mut TxContext) {
    assert!(types::is_one_time_witness<SOCIAL_LAYER_CONFIG>(otw), ETypeNotOneTimeWitness);

    let config = Config {
        id: object::new(ctx),
        version: 1,
        display_name_min_length: social_layer_constants::display_name_min_length(),
        display_name_max_length: social_layer_constants::display_name_max_length(),
        bio_min_length: social_layer_constants::bio_min_length(),
        bio_max_length: social_layer_constants::bio_max_length(),
        allowed_wallet_keys: social_layer_constants::allowed_wallet_keys(),
        allowed_social_platforms: social_layer_constants::allowed_social_platforms(),
        config_manager: tx_context::sender(ctx),
    };

    transfer::share_object(config);
}

fun init(otw: SOCIAL_LAYER_CONFIG, ctx: &mut TxContext) {
    create_config(&otw, ctx);
}

public fun assign_config_manager(
    _admin_cap: &AdminCap,
    config: &mut Config,
    config_manager_address: address,
    ctx: &mut TxContext,
) {
    assert_interacting_with_most_up_to_date_package(config);

    config.config_manager = config_manager_address;

    let config_manager_cap = ConfigManagerCap {
        id: object::new(ctx),
        config_manager: config_manager_address,
    };

    transfer::transfer(config_manager_cap, config_manager_address);
}

public fun set_display_name_min_length(
    config_manager_cap: &ConfigManagerCap,
    config: &mut Config,
    display_name_min_length: u64,
    ctx: &mut TxContext,
) {
    assert_address_is_config_manager(config_manager_cap, config, ctx);

    config.display_name_min_length = display_name_min_length;
}

public fun set_display_name_max_length(
    config_manager_cap: &ConfigManagerCap,
    config: &mut Config,
    display_name_max_length: u64,
    ctx: &mut TxContext,
) {
    assert_address_is_config_manager(config_manager_cap, config, ctx);

    config.display_name_max_length = display_name_max_length;
}

public fun set_bio_min_length(
    config_manager_cap: &ConfigManagerCap,
    config: &mut Config,
    bio_min_length: u64,
    ctx: &mut TxContext,
) {
    assert_address_is_config_manager(config_manager_cap, config, ctx);

    config.bio_min_length = bio_min_length;
}

public fun set_bio_max_length(
    config_manager_cap: &ConfigManagerCap,
    config: &mut Config,
    bio_max_length: u64,
    ctx: &mut TxContext,
) {
    assert_address_is_config_manager(config_manager_cap, config, ctx);

    config.bio_max_length = bio_max_length;
}

public fun assert_display_name_length_is_valid(config: &Config, display_name: &String) {
    assert!(display_name.length() >= config.display_name_min_length, EDisplayNameTooShort);
    assert!(display_name.length() <= config.display_name_max_length, EDisplayNameTooLong);
}

public fun assert_bio_length_is_valid(config: &Config, bio: &String) {
    assert!(bio.length() >= config.bio_min_length, EBioTooShort);
    assert!(bio.length() <= config.bio_max_length, EBioTooLong);
}

public fun assert_display_name_is_valid(config: &Config, display_name: &String) {
    assert_display_name_length_is_valid(config, display_name);
    let display_name_bytes = display_name.as_bytes();
    let mut index = 0;
    let len = display_name.length();
    while (index < len) {
        let character = display_name_bytes[index];
        let is_valid_character =
            (0x61 <= character && character <= 0x7A)                   // a-z
                || (0x30 <= character && character <= 0x39)                // 0-9
                || (character == 0x2D && index != 0 && index != len - 1); // '-' not at beginning or end
        assert!(is_valid_character, EDisplayNameInvalidCharacter);
        index = index + 1;
    };
}

public fun assert_wallet_key_is_allowed(config: &Config, wallet_key: &String) {
    assert!(vector::contains(&config.allowed_wallet_keys, wallet_key), EWalletKeyNotAllowed);
}

public fun assert_social_platform_is_allowed(config: &Config, platform: &String) {
    assert!(
        vector::contains(&config.allowed_social_platforms, platform),
        ESocialPlatformNotAllowed,
    );
}

// Getters
public fun version(config: &Config): u64 { config.version }

public fun display_name_min_length(config: &Config): u64 { config.display_name_min_length }

public fun display_name_max_length(config: &Config): u64 { config.display_name_max_length }

public fun bio_min_length(config: &Config): u64 { config.bio_min_length }

public fun bio_max_length(config: &Config): u64 { config.bio_max_length }

public fun config_manager(config: &Config): address { config.config_manager }

public fun allowed_wallet_keys(config: &Config): &vector<String> { &config.allowed_wallet_keys }

public fun allowed_social_platforms(config: &Config): &vector<String> {
    &config.allowed_social_platforms
}

public fun set_allowed_wallet_keys(
    config_manager_cap: &ConfigManagerCap,
    config: &mut Config,
    allowed_wallet_keys: vector<String>,
    ctx: &mut TxContext,
) {
    assert_address_is_config_manager(config_manager_cap, config, ctx);
    config.allowed_wallet_keys = allowed_wallet_keys;
}

public fun add_allowed_wallet_key(
    config_manager_cap: &ConfigManagerCap,
    config: &mut Config,
    wallet_key: String,
    ctx: &mut TxContext,
) {
    assert_address_is_config_manager(config_manager_cap, config, ctx);
    assert!(!vector::contains(&config.allowed_wallet_keys, &wallet_key), EWalletKeyAlreadyExists);
    vector::push_back(&mut config.allowed_wallet_keys, wallet_key);
}

public fun remove_allowed_wallet_key(
    config_manager_cap: &ConfigManagerCap,
    config: &mut Config,
    wallet_key: String,
    ctx: &mut TxContext,
): bool {
    assert_address_is_config_manager(config_manager_cap, config, ctx);

    let wallet_keys = &mut config.allowed_wallet_keys;
    let len = vector::length(wallet_keys);
    let mut index = 0;

    while (index < len) {
        if (*vector::borrow(wallet_keys, index) == wallet_key) {
            vector::swap_remove(wallet_keys, index);
            return true
        };
        index = index + 1;
    };

    false
}

public fun set_allowed_social_platforms(
    config_manager_cap: &ConfigManagerCap,
    config: &mut Config,
    allowed_social_platforms: vector<String>,
    ctx: &mut TxContext,
) {
    assert_address_is_config_manager(config_manager_cap, config, ctx);
    config.allowed_social_platforms = allowed_social_platforms;
}

public fun add_allowed_social_platform(
    config_manager_cap: &ConfigManagerCap,
    config: &mut Config,
    platform: String,
    ctx: &mut TxContext,
) {
    assert_address_is_config_manager(config_manager_cap, config, ctx);
    assert!(
        !vector::contains(&config.allowed_social_platforms, &platform),
        ESocialPlatformAlreadyExists,
    );
    vector::push_back(&mut config.allowed_social_platforms, platform);
}

public fun remove_allowed_social_platform(
    config_manager_cap: &ConfigManagerCap,
    config: &mut Config,
    platform: String,
    ctx: &mut TxContext,
): bool {
    assert_address_is_config_manager(config_manager_cap, config, ctx);

    let platforms = &mut config.allowed_social_platforms;
    let len = vector::length(platforms);
    let mut index = 0;

    while (index < len) {
        if (*vector::borrow(platforms, index) == platform) {
            vector::swap_remove(platforms, index);
            return true
        };
        index = index + 1;
    };

    false
}

/// Migrates Config from one version to another
/// Must be called immediately after package upgrade to update the on-chain Config object
public fun migrate_config(
    config_manager_cap: &ConfigManagerCap,
    config: &mut Config,
    target_version: u64,
    ctx: &mut TxContext,
) {
    assert_address_is_config_manager(config_manager_cap, config, ctx);
    assert!(target_version > config.version, EConfigAlreadyAtTargetVersion);
    assert!(target_version <= PACKAGE_VERSION, EInvalidMigrationVersion);

    // Version-specific migration logic
    // Migrate from version 1 to version 2
    if (config.version == 1 && target_version == 2) {
        config.version = 2;
    } else {
        // For other version jumps, require step-by-step migration
        // This ensures all migration logic is executed in order
        assert!(false, EInvalidMigrationVersion);
    };
}

/// Updates Config version to match PACKAGE_VERSION
/// Convenience function that calls migrate_config with PACKAGE_VERSION
public fun update_config_to_latest_version(
    config_manager_cap: &ConfigManagerCap,
    config: &mut Config,
    ctx: &mut TxContext,
) {
    migrate_config(config_manager_cap, config, PACKAGE_VERSION, ctx);
}

#[test_only]
public fun test_create_config(ctx: &mut TxContext) {
    let config = Config {
        id: object::new(ctx),
        version: 1,
        display_name_min_length: social_layer_constants::display_name_min_length(),
        display_name_max_length: social_layer_constants::display_name_max_length(),
        bio_min_length: social_layer_constants::bio_min_length(),
        bio_max_length: social_layer_constants::bio_max_length(),
        allowed_wallet_keys: social_layer_constants::allowed_wallet_keys(),
        allowed_social_platforms: social_layer_constants::allowed_social_platforms(),
        config_manager: tx_context::sender(ctx),
    };
    transfer::share_object(config)
}
