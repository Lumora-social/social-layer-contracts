module suins_social_layer::profile_actions;

use std::string::String;
use sui::clock::Clock;
use suins::suins_registration::SuinsRegistration;
use suins_social_layer::profile::{Self, Profile};
use suins_social_layer::social_layer_config::Config;

#[allow(lint(self_transfer))]
public entry fun create_profile(
    user_name: String,
    display_name: String,
    url: Option<String>,
    bio: Option<String>,
    image_url: Option<String>,
    suins_registration: &SuinsRegistration,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let profile = profile::create_profile(
        user_name,
        display_name,
        url,
        bio,
        image_url,
        suins_registration,
        config,
        clock,
        ctx,
    );

    transfer::public_transfer(profile, tx_context::sender(ctx));
}

#[allow(lint(self_transfer))]
// Creates a profile without requiring a SuinsRegistration NFT
public entry fun create_profile_without_suins(
    user_name: String,
    display_name: String,
    url: Option<String>,
    bio: Option<String>,
    image_url: Option<String>,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let profile = profile::create_profile_without_suins(
        user_name,
        display_name,
        url,
        bio,
        image_url,
        config,
        clock,
        ctx,
    );

    transfer::public_transfer(profile, tx_context::sender(ctx));
}

public entry fun set_display_name(
    profile: &mut Profile,
    display_name: String,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::set_display_name(
        profile,
        display_name,
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

public entry fun set_image_url(
    profile: &mut Profile,
    image_url: String,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::set_image_url(
        profile,
        image_url,
        config,
        clock,
        ctx,
    )
}

public entry fun remove_image_url(
    profile: &mut Profile,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    profile::remove_image_url(
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

public entry fun delete_profile(profile: Profile, clock: &Clock, ctx: &mut TxContext) {
    profile::delete_profile(
        profile,
        clock,
        ctx,
    )
}
