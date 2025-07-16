module suins_social_layer::profile_actions;

use std::string::String;
use sui::clock::Clock;
use suins::suins::SuiNS;
use suins::suins_registration::SuinsRegistration;
use suins_social_layer::blocklist::{Self, BlockList};
use suins_social_layer::following::{Self, Following};
use suins_social_layer::profile::{Self, Profile};
use suins_social_layer::social_layer_config::Config;
use suins_social_layer::social_layer_registry::Registry;

/// Creates a new profile with basic information
#[allow(lint(self_transfer))]
public entry fun create_profile(
    display_name: String,
    url: Option<String>,
    bio: Option<String>,
    display_image_url: Option<String>,
    background_image_url: Option<String>,
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
        config,
        suins,
        registry,
        clock,
        ctx,
    );

    transfer::public_transfer(profile, tx_context::sender(ctx));
}

/// Creates a new profile with SuiNS the same as the display name
public entry fun create_profile_with_suins(
    display_name: String,
    url: Option<String>,
    bio: Option<String>,
    display_image_url: Option<String>,
    background_image_url: Option<String>,
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
        suins_registration,
        config,
        registry,
        clock,
        ctx,
    );

    transfer::public_transfer(profile, tx_context::sender(ctx));
}

/// Updates the display name of an existing profile
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

/// Updates the display name with SuiNS same as the display name
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

/// Sets the bio text for a profile
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

/// Removes the bio text from a profile
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

/// Sets the display image URL for a profile
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

/// Removes the display image URL from a profile
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

/// Sets the background image URL for a profile
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

/// Removes the background image URL from a profile
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

/// Sets the URL for a profile
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

/// Removes the URL from a profile
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

/// Adds a wallet address to a profile
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

/// Updates an existing wallet address on a profile
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

/// Removes a wallet address from a profile
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

/// Archives a profile (marks as inactive)
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

/// Unarchives a profile (marks as active)
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

/// Permanently deletes a profile
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

/// Adds a dynamic field to a profile
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

/// Removes a dynamic field from a profile
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

/// Adds a dynamic field to a profile without emitting events
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

/// Removes a dynamic field from a profile without emitting events
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

public entry fun add_following(
    profile: &Profile,
    following: &mut Following,
    blocklist: &BlockList,
    following_address: address,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    following::follow_user(
        following,
        profile,
        following_address,
        blocklist,
        clock,
        ctx,
    )
}

public entry fun remove_following(
    profile: &Profile,
    following: &mut Following,
    following_address: address,
    clock: &Clock,
) {
    following::unfollow_user(
        following,
        profile,
        following_address,
        clock,
    )
}

public entry fun block_user(
    blocklist: &mut BlockList,
    profile: &Profile,
    block_user_address: address,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    blocklist::block_user(
        blocklist,
        profile,
        block_user_address,
        clock,
        ctx,
    );
}

public entry fun unblock_user(
    blocklist: &mut BlockList,
    profile: &Profile,
    block_user_address: address,
    clock: &Clock,
) {
    blocklist::unblock_user(
        blocklist,
        profile,
        block_user_address,
        clock,
    );
}
