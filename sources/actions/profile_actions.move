module suins_social_layer::profile_actions;

use std::string::String;
use sui::clock::Clock;
use suins::suins::SuiNS;
use suins::suins_registration::SuinsRegistration;
use suins_social_layer::profile::{Self, Profile};
use suins_social_layer::social_layer_config::Config;
use suins_social_layer::social_layer_registry::Registry;

#[allow(lint(self_transfer))]
public entry fun create_profile(
    display_name: String,
    url: Option<String>,
    bio: Option<String>,
    display_image_url: Option<String>,
    background_image_url: Option<String>,
    walrus_site_id: Option<String>,
    config: &Config,
    suins: &SuiNS,
    registry: &mut Registry,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let profile = profile::create_profile(
        display_name,
        url,
        bio,
        display_image_url,
        background_image_url,
        walrus_site_id,
        config,
        suins,
        registry,
        clock,
        ctx,
    );

    transfer::public_transfer(profile, tx_context::sender(ctx));
}

public entry fun create_profile_with_suins(
    display_name: String,
    url: Option<String>,
    bio: Option<String>,
    display_image_url: Option<String>,
    background_image_url: Option<String>,
    walrus_site_id: Option<String>,
    suins_registration: &SuinsRegistration,
    config: &Config,
    registry: &mut Registry,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let profile = profile::create_profile_with_suins(
        display_name,
        url,
        bio,
        display_image_url,
        background_image_url,
        walrus_site_id,
        suins_registration,
        config,
        registry,
        clock,
        ctx,
    );

    transfer::public_transfer(profile, tx_context::sender(ctx));
}

public entry fun set_display_name(
    profile: &mut Profile,
    display_name: String,
    suins: &SuiNS,
    registry: &mut Registry,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::set_display_name(
        profile,
        display_name,
        suins,
        registry,
        config,
        clock,
        ctx,
    );
}

public entry fun set_display_name_with_suins(
    profile: &mut Profile,
    display_name: String,
    suins_registration: &SuinsRegistration,
    registry: &mut Registry,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::set_display_name_with_suins(
        profile,
        display_name,
        suins_registration,
        registry,
        config,
        clock,
        ctx,
    );
}

public entry fun set_bio(
    profile: &mut Profile,
    bio: String,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::set_bio(
        profile,
        bio,
        config,
        clock,
        ctx,
    )
}

public entry fun remove_bio(
    profile: &mut Profile,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::remove_bio(
        profile,
        config,
        clock,
        ctx,
    )
}

public entry fun set_display_image_url(
    profile: &mut Profile,
    display_image_url: String,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::set_display_image_url(
        profile,
        display_image_url,
        config,
        clock,
        ctx,
    )
}

public entry fun remove_display_image_url(
    profile: &mut Profile,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::remove_display_image_url(
        profile,
        config,
        clock,
        ctx,
    )
}

public entry fun set_background_image_url(
    profile: &mut Profile,
    background_image_url: String,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::set_background_image_url(
        profile,
        background_image_url,
        config,
        clock,
        ctx,
    )
}

public entry fun remove_background_image_url(
    profile: &mut Profile,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::remove_background_image_url(
        profile,
        config,
        clock,
        ctx,
    )
}

public entry fun set_url(
    profile: &mut Profile,
    url: String,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::set_url(
        profile,
        url,
        config,
        clock,
        ctx,
    )
}

public entry fun remove_url(
    profile: &mut Profile,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::remove_url(
        profile,
        config,
        clock,
        ctx,
    )
}

public entry fun set_walrus_site_id(
    profile: &mut Profile,
    walrus_site_id: String,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::set_walrus_site_id(
        profile,
        walrus_site_id,
        config,
        clock,
        ctx,
    )
}

public entry fun remove_walrus_site_id(
    profile: &mut Profile,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::remove_walrus_site_id(
        profile,
        config,
        clock,
        ctx,
    )
}

public entry fun add_wallet_address(
    profile: &mut Profile,
    network: String,
    address: String,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::add_wallet_address(
        profile,
        network,
        address,
        config,
        clock,
        ctx,
    )
}

public entry fun update_wallet_address(
    profile: &mut Profile,
    network: String,
    address: String,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::update_wallet_address(
        profile,
        network,
        address,
        config,
        clock,
        ctx,
    )
}

public entry fun remove_wallet_address(
    profile: &mut Profile,
    network: String,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::remove_wallet_address(
        profile,
        network,
        config,
        clock,
        ctx,
    )
}

public entry fun archive_profile(
    profile: &mut Profile,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::archive_profile(
        profile,
        config,
        clock,
        ctx,
    )
}

public entry fun unarchive_profile(
    profile: &mut Profile,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::unarchive_profile(
        profile,
        config,
        clock,
        ctx,
    )
}

public entry fun delete_profile(
    profile: Profile,
    registry: &mut Registry,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::delete_profile(
        profile,
        registry,
        clock,
        ctx,
    )
}

public entry fun add_df_to_profile<K: copy + drop + store, V: store + copy + drop>(
    profile: &mut Profile,
    df_key: K,
    df_value: V,
    clock: &Clock,
) {
    profile::add_df_to_profile(
        profile,
        df_key,
        df_value,
        clock,
    )
}

public entry fun remove_df_from_profile<K: copy + drop + store, V: store + copy + drop>(
    profile: &mut Profile,
    df_key: K,
    clock: &Clock,
) {
    profile::remove_df_from_profile<K, V>(
        profile,
        df_key,
        clock,
    )
}

public entry fun add_df_to_profile_no_event<K: copy + drop + store, V: store + drop>(
    profile: &mut Profile,
    df_key: K,
    df_value: V,
    clock: &Clock,
) {
    profile::add_df_to_profile_no_event(
        profile,
        df_key,
        df_value,
        clock,
    )
}

public entry fun remove_df_from_profile_no_event<K: copy + drop + store, V: store + drop>(
    profile: &mut Profile,
    df_key: K,
    clock: &Clock,
) {
    profile::remove_df_from_profile_no_event<K, V>(
        profile,
        df_key,
        clock,
    );
}
