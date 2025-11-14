module suins_social_layer::profile_actions;

use std::string::String;
use sui::clock::Clock;
use suins::suins::SuiNS;
use suins::suins_registration::SuinsRegistration;
use suins_social_layer::profile::{Self, Profile};
use suins_social_layer::social_layer_config::Config;
use suins_social_layer::social_layer_registry::Registry;

/// Creates a new profile with basic information
#[allow(lint(self_transfer))]
public fun create_profile(
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
#[allow(lint(self_transfer))]
public fun create_profile_with_suins(
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
public fun set_display_name(
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
public fun set_display_name_with_suins(
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
public fun set_bio(
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
public fun remove_bio(profile: &mut Profile, config: &Config, clock: &Clock, ctx: &mut TxContext) {
    profile::remove_bio(
        profile,
        config,
        clock,
        ctx,
    )
}

/// Sets the display image URL for a profile
public fun set_display_image_url(
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
public fun remove_display_image_url(
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
public fun set_background_image_url(
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
public fun remove_background_image_url(
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
public fun set_url(
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
public fun remove_url(profile: &mut Profile, config: &Config, clock: &Clock, ctx: &mut TxContext) {
    profile::remove_url(
        profile,
        config,
        clock,
        ctx,
    )
}

/// Adds a wallet address to a profile
public fun add_wallet_address(
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

/// Removes a wallet address from a profile
public fun remove_wallet_address(
    profile: &mut Profile,
    network: String,
    address: String,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::remove_wallet_address(
        profile,
        network,
        address,
        config,
        clock,
        ctx,
    )
}

/// Archives a profile (marks as inactive)
public fun archive_profile(
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
public fun unarchive_profile(
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
public fun delete_profile(
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
public fun add_df_to_profile<K: copy + drop + store, V: store + copy + drop>(
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
public fun remove_df_from_profile<K: copy + drop + store, V: store + copy + drop>(
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
public fun add_df_to_profile_no_event<K: copy + drop + store, V: store + drop>(
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
public fun remove_df_from_profile_no_event<K: copy + drop + store, V: store + drop>(
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

/// Follows a user by address
public fun follow_user(profile: &mut Profile, follow_address: address, clock: &Clock) {
    profile::follow_user(
        profile,
        follow_address,
        clock,
    );
}

/// Unfollows a user by address
public fun unfollow_user(profile: &mut Profile, unfollow_address: address, clock: &Clock) {
    profile::unfollow_user(
        profile,
        unfollow_address,
        clock,
    );
}

/// Blocks a user by address
public fun block_user(profile: &mut Profile, block_address: address, clock: &Clock) {
    profile::block_user(
        profile,
        block_address,
        clock,
    );
}

/// Unblocks a user by address
public fun unblock_user(profile: &mut Profile, unblock_address: address, clock: &Clock) {
    profile::unblock_user(
        profile,
        unblock_address,
        clock,
    );
}
