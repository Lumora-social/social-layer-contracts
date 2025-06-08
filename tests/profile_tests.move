module suins_social_layer::profile_tests;

use sui::test_scenario::{Self, next_tx, ctx};
use sui::test_utils::assert_eq;
use suins_social_layer::social_layer_config;
use sui::clock;
use suins_social_layer::profile::Profile;

#[test]
fun test_create_profile() {
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
    {
        suins_social_layer::profile_actions::create_profile_without_suins(
            display_name,
            url,
            bio,
            image_url,
            &config,
            &clock,
            test_scenario::ctx(&mut scenario),
        );
    };

    next_tx(&mut scenario, user_address);
    let profile = test_scenario::take_from_sender<Profile>(&scenario);
    assert_eq(profile.user_name(), user_address.to_string());

    clock.destroy_for_testing();
    test_scenario::return_to_sender(&scenario, profile);

    next_tx(&mut scenario, admin_address);
    test_scenario::return_shared(config);

    test_scenario::end(scenario);
}
