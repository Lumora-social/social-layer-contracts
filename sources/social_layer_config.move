module suins_social_layer::social_layer_config {
    use sui::types;
    use std::string::{String};
    
    use suins_social_layer::app::{AdminCap};
    use suins_social_layer::social_layer_constants as constants;

    const ENotLatestVersion: u64 = 0;
    const ETypeNotOneTimeWitness: u64 = 1;
    const EDisplayNameTooLong: u64 = 2;
    const EDisplayNameTooShort: u64 = 3;
    const EBioTooLong: u64 = 4;
    const EBioTooShort: u64 = 5;
    const EAddressIsNotConfigManager: u64 = 6;

    public struct SOCIAL_LAYER_CONFIG has drop {}

    public struct Config has key {
        id: UID,
        version: u64,
        display_name_min_length: u64,
        display_name_max_length: u64,
        bio_min_length: u64,
        bio_max_length: u64,
        config_manager: address,
    }

    public struct ConfigManagerCap has key, store {
        id: UID,
        config_manager: address
    }

    public fun assert_interacting_with_most_up_to_date_package(config: &Config) {
        assert!(config.version == 1, ENotLatestVersion);
    }

    public fun assert_address_is_config_manager(config_manager_cap: &ConfigManagerCap, config: &Config, ctx: &mut TxContext) {
        assert!(config_manager_cap.config_manager == tx_context::sender(ctx), EAddressIsNotConfigManager);
        assert!(config.config_manager == tx_context::sender(ctx), EAddressIsNotConfigManager);
    }

    public(package) fun create_config(otw: &SOCIAL_LAYER_CONFIG, ctx: &mut TxContext) {
        assert!(types::is_one_time_witness<SOCIAL_LAYER_CONFIG>(otw), ETypeNotOneTimeWitness);


        let config = Config{
            id: object::new(ctx), 
            version: 1,
            display_name_min_length: constants::display_name_min_length(),
            display_name_max_length: constants::display_name_max_length(),
            bio_min_length: constants::bio_min_length(),
            bio_max_length: constants::bio_max_length(),
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
        
        let config_manager_cap = ConfigManagerCap{
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

    public fun assert_display_name_length_is_valid(
        config: &Config,
        display_name: &String,
    ) {
        assert!(display_name.length() >= config.display_name_min_length, EDisplayNameTooShort);
        assert!(display_name.length() <= config.display_name_max_length, EDisplayNameTooLong);
    }

    public fun assert_bio_length_is_valid(
        config: &Config,
        bio: &String,
    ) {
        assert!(bio.length() >= config.bio_min_length, EBioTooShort);
        assert!(bio.length() <= config.bio_max_length, EBioTooLong);
    }
}