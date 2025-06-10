module suins_social_layer::profile_tests;

use std::string::String;
use sui::clock;
use sui::test_scenario::{Self, next_tx, ctx};
use sui::test_utils::assert_eq;
use suins_social_layer::profile::Profile;
use suins_social_layer::social_layer_config;

//TODO: Add test to create profile with suins
#[test]
fun test_create_profile_no_suins() {
    let user_address: address = @0xA;
    let admin_address: address = @0xB;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));

    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    next_tx(&mut scenario, user_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let display_name = b"display_name".to_string();
    let url = option::some(b"url".to_string());
    let bio = option::some(b"My bio which is not too short".to_string());
    let image_url = option::some(b"image_url".to_string());
    let mut user_address_with_hex_prefix = b"0x".to_string();
    std::string::append(&mut user_address_with_hex_prefix, user_address.to_string());
    suins_social_layer::profile_actions::create_profile_without_suins(
        user_address_with_hex_prefix,
        display_name,
        url,
        bio,
        image_url,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );

    next_tx(&mut scenario, user_address);
    let profile = test_scenario::take_from_sender<Profile>(&scenario);
    assert_eq(profile.user_name(), user_address_with_hex_prefix);
    assert_eq(profile.display_name(), display_name);
    assert_eq(profile.url(), url);
    assert_eq(profile.bio(), bio);
    assert_eq(profile.image_url(), image_url);

    clock.destroy_for_testing();
    test_scenario::return_to_sender(&scenario, profile);

    next_tx(&mut scenario, admin_address);
    test_scenario::return_shared(config);

    test_scenario::end(scenario);
}

#[test]
fun test_set_display_name() {
    let user_address: address = @0xA;
    let admin_address: address = @0xB;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Create profile
    next_tx(&mut scenario, user_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let display_name = b"old_name".to_string();
    let url = option::none<String>();
    let bio = option::none<String>();
    let image_url = option::none<String>();
    let mut user_address_with_hex_prefix = b"0x".to_string();
    std::string::append(&mut user_address_with_hex_prefix, user_address.to_string());
    suins_social_layer::profile_actions::create_profile_without_suins(
        user_address_with_hex_prefix,
        display_name,
        url,
        bio,
        image_url,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );

    // Set new display name
    next_tx(&mut scenario, user_address);
    let mut profile = test_scenario::take_from_sender<Profile>(&scenario);
    let new_display_name = b"new_name".to_string();
    suins_social_layer::profile_actions::set_display_name(
        &mut profile,
        new_display_name,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.display_name(), new_display_name);

    clock.destroy_for_testing();
    test_scenario::return_to_sender(&scenario, profile);
    next_tx(&mut scenario, admin_address);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_set_and_remove_bio() {
    let user_address: address = @0xA;
    let admin_address: address = @0xB;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    next_tx(&mut scenario, user_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let display_name = b"name".to_string();
    let url = option::none<String>();
    let bio = option::none<String>();
    let image_url = option::none<String>();
    let mut user_address_with_hex_prefix = b"0x".to_string();
    std::string::append(&mut user_address_with_hex_prefix, user_address.to_string());
    suins_social_layer::profile_actions::create_profile_without_suins(
        user_address_with_hex_prefix,
        display_name,
        url,
        bio,
        image_url,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );

    // Set bio
    next_tx(&mut scenario, user_address);
    let mut profile = test_scenario::take_from_sender<Profile>(&scenario);
    let new_bio = b"my new bio".to_string();
    suins_social_layer::profile_actions::set_bio(
        &mut profile,
        new_bio,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.bio(), option::some(b"my new bio".to_string()));

    // Remove bio
    suins_social_layer::profile_actions::remove_bio(
        &mut profile,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.bio(), option::none<String>());

    clock.destroy_for_testing();
    test_scenario::return_to_sender(&scenario, profile);
    next_tx(&mut scenario, admin_address);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_set_and_remove_image_url() {
    let user_address: address = @0xA;
    let admin_address: address = @0xB;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    next_tx(&mut scenario, user_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let display_name = b"name".to_string();
    let url = option::none<String>();
    let bio = option::none<String>();
    let image_url = option::none<String>();
    let mut user_address_with_hex_prefix = b"0x".to_string();
    std::string::append(&mut user_address_with_hex_prefix, user_address.to_string());
    suins_social_layer::profile_actions::create_profile_without_suins(
        user_address_with_hex_prefix,
        display_name,
        url,
        bio,
        image_url,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );

    // Set image_url
    next_tx(&mut scenario, user_address);
    let mut profile = test_scenario::take_from_sender<Profile>(&scenario);
    let new_image_url = b"img_url".to_string();
    suins_social_layer::profile_actions::set_image_url(
        &mut profile,
        new_image_url,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.image_url(), option::some(b"img_url".to_string()));

    // Remove image_url
    suins_social_layer::profile_actions::remove_image_url(
        &mut profile,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.image_url(), option::none<String>());

    clock.destroy_for_testing();
    test_scenario::return_to_sender(&scenario, profile);
    next_tx(&mut scenario, admin_address);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_set_and_remove_url() {
    let user_address: address = @0xA;
    let admin_address: address = @0xB;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    next_tx(&mut scenario, user_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let display_name = b"name".to_string();
    let url = option::none<String>();
    let bio = option::none<String>();
    let image_url = option::none<String>();
    let mut user_address_with_hex_prefix = b"0x".to_string();
    std::string::append(&mut user_address_with_hex_prefix, user_address.to_string());
    suins_social_layer::profile_actions::create_profile_without_suins(
        user_address_with_hex_prefix,
        display_name,
        url,
        bio,
        image_url,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );

    // Set url
    next_tx(&mut scenario, user_address);
    let mut profile = test_scenario::take_from_sender<Profile>(&scenario);
    let new_url = b"new_url".to_string();
    suins_social_layer::profile_actions::set_url(
        &mut profile,
        new_url,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.url(), option::some(b"new_url".to_string()));

    // Remove url
    suins_social_layer::profile_actions::remove_url(
        &mut profile,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert_eq(profile.url(), option::none<String>());

    clock.destroy_for_testing();
    test_scenario::return_to_sender(&scenario, profile);
    next_tx(&mut scenario, admin_address);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_archive_and_unarchive_profile() {
    let user_address: address = @0xA;
    let admin_address: address = @0xB;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    next_tx(&mut scenario, user_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let display_name = b"name".to_string();
    let url = option::none<String>();
    let bio = option::none<String>();
    let image_url = option::none<String>();
    let mut user_address_with_hex_prefix = b"0x".to_string();
    std::string::append(&mut user_address_with_hex_prefix, user_address.to_string());
    suins_social_layer::profile_actions::create_profile_without_suins(
        user_address_with_hex_prefix,
        display_name,
        url,
        bio,
        image_url,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );

    // Archive profile
    next_tx(&mut scenario, user_address);
    let mut profile = test_scenario::take_from_sender<Profile>(&scenario);
    suins_social_layer::profile_actions::archive_profile(
        &mut profile,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert!(profile.is_archived());

    // Unarchive profile
    suins_social_layer::profile_actions::unarchive_profile(
        &mut profile,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );
    assert!(!profile.is_archived());

    clock.destroy_for_testing();
    test_scenario::return_to_sender(&scenario, profile);
    next_tx(&mut scenario, admin_address);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_delete_profile() {
    let user_address: address = @0xA;
    let admin_address: address = @0xB;

    let mut scenario = test_scenario::begin(admin_address);
    social_layer_config::test_create_config(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    next_tx(&mut scenario, user_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let display_name = b"name".to_string();
    let url = option::none<String>();
    let bio = option::none<String>();
    let image_url = option::none<String>();
    let mut user_address_with_hex_prefix = b"0x".to_string();
    std::string::append(&mut user_address_with_hex_prefix, user_address.to_string());
    suins_social_layer::profile_actions::create_profile_without_suins(
        user_address_with_hex_prefix,
        display_name,
        url,
        bio,
        image_url,
        &config,
        &clock,
        test_scenario::ctx(&mut scenario),
    );

    // Delete profile
    next_tx(&mut scenario, user_address);
    let profile = test_scenario::take_from_sender<Profile>(&scenario);
    suins_social_layer::profile_actions::delete_profile(
        profile,
        &clock,
        test_scenario::ctx(&mut scenario),
    );

    clock.destroy_for_testing();
    next_tx(&mut scenario, admin_address);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}
