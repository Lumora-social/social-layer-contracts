module suins_social_layer::social_layer_config;

use std::string::String;
use sui::types;
use suins_social_layer::app::AdminCap;
use suins_social_layer::social_layer_constants as constants;

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

public struct SOCIAL_LAYER_CONFIG has drop {}

public struct Config has key {
    id: UID,
    version: u64,
    display_name_min_length: u64,
    display_name_max_length: u64,
    bio_min_length: u64,
    bio_max_length: u64,
    allowed_wallet_keys: vector<String>,
    config_manager: address,
}

public struct ConfigManagerCap has key, store {
    id: UID,
    config_manager: address,
}

public fun assert_interacting_with_most_up_to_date_package(config: &Config) {
    assert!(config.version == 1, ENotLatestVersion);
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

public(package) fun create_config(otw: &SOCIAL_LAYER_CONFIG, ctx: &mut TxContext) {
    assert!(types::is_one_time_witness<SOCIAL_LAYER_CONFIG>(otw), ETypeNotOneTimeWitness);

    let config = Config {
        id: object::new(ctx),
        version: 1,
        display_name_min_length: constants::display_name_min_length(),
        display_name_max_length: constants::display_name_max_length(),
        bio_min_length: constants::bio_min_length(),
        bio_max_length: constants::bio_max_length(),
        allowed_wallet_keys: constants::allowed_wallet_keys(),
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
    assert!(display_name.length() >= config.display_name_min_length, EDisplayNameTooShort);
    assert!(display_name.length() <= config.display_name_max_length, EDisplayNameTooLong);
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

// Getters
public fun version(config: &Config): u64 { config.version }

public fun display_name_min_length(config: &Config): u64 { config.display_name_min_length }

public fun display_name_max_length(config: &Config): u64 { config.display_name_max_length }

public fun bio_min_length(config: &Config): u64 { config.bio_min_length }

public fun bio_max_length(config: &Config): u64 { config.bio_max_length }

public fun config_manager(config: &Config): address { config.config_manager }

public fun allowed_wallet_keys(config: &Config): &vector<String> { &config.allowed_wallet_keys }

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

#[test_only]
public fun test_create_config(ctx: &mut TxContext) {
    let config = Config {
        id: object::new(ctx),
        version: 1,
        display_name_min_length: constants::display_name_min_length(),
        display_name_max_length: constants::display_name_max_length(),
        bio_min_length: constants::bio_min_length(),
        bio_max_length: constants::bio_max_length(),
        allowed_wallet_keys: constants::allowed_wallet_keys(),
        config_manager: tx_context::sender(ctx),
    };
    transfer::share_object(config)
}
