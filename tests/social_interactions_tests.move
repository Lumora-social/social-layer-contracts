module suins_social_layer::social_interactions_tests;

use sui::clock;
use sui::test_scenario::{Self, next_tx, ctx};
use suins_social_layer::profile;
use suins_social_layer::profile_actions;
use suins_social_layer::social_layer_config;
use suins_social_layer::social_layer_registry;

#[test]
fun test_block_and_unblock_users() {
    let admin_address: address = @0xAD;
    let user_a_address: address = @0xA;
    let user_b_address: address = @0xB;

    let mut scenario = test_scenario::begin(admin_address);

    // Setup
    social_layer_config::test_create_config(ctx(&mut scenario));
    social_layer_registry::create_registry_for_testing(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Create profiles for both users
    next_tx(&mut scenario, user_a_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let mut profile_a = profile::create_profile_helper(
        b"user-a".to_string(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    next_tx(&mut scenario, user_b_address);
    let mut profile_b = profile::create_profile_helper(
        b"user-b".to_string(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    // Test 1: User A blocks User B
    next_tx(&mut scenario, user_a_address);
    profile_actions::block_user(
        &mut profile_a,
        user_b_address,
        &clock,
    );

    // Verify User B is blocked by User A
    assert!(profile::is_blocked(&profile_a, user_b_address));

    // Test 2: User A unblocks User B
    next_tx(&mut scenario, user_a_address);
    profile_actions::unblock_user(
        &mut profile_a,
        user_b_address,
        &clock,
    );

    // Verify User B is no longer blocked by User A
    assert!(!profile::is_blocked(&profile_a, user_b_address));

    // Test 3: User B blocks User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::block_user(
        &mut profile_b,
        user_a_address,
        &clock,
    );

    // Verify User A is blocked by User B
    assert!(profile::is_blocked(&profile_b, user_a_address));

    // Test 4: User B unblocks User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::unblock_user(
        &mut profile_b,
        user_a_address,
        &clock,
    );

    // Verify User A is no longer blocked by User B
    assert!(!profile::is_blocked(&profile_b, user_a_address));

    // Cleanup - need to unblock and unfollow before deleting profiles
    profile_actions::unblock_user(&mut profile_a, user_b_address, &clock);
    profile_actions::unfollow_user(&mut profile_a, user_b_address, &clock);
    profile_actions::unblock_user(&mut profile_b, user_a_address, &clock);
    profile_actions::unfollow_user(&mut profile_b, user_a_address, &clock);

    // Cleanup
    clock.destroy_for_testing();
    next_tx(&mut scenario, admin_address);

    // Delete profiles
    let clock_for_deletion = clock::create_for_testing(ctx(&mut scenario));
    next_tx(&mut scenario, user_a_address);
    profile_actions::delete_profile(
        profile_a,
        &mut registry,
        &clock_for_deletion,
        ctx(&mut scenario),
    );

    next_tx(&mut scenario, user_b_address);
    profile_actions::delete_profile(
        profile_b,
        &mut registry,
        &clock_for_deletion,
        ctx(&mut scenario),
    );

    clock_for_deletion.destroy_for_testing();
    test_scenario::return_shared(registry);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_follow_and_unfollow_users() {
    let admin_address: address = @0xAD;
    let user_a_address: address = @0xA;
    let user_b_address: address = @0xB;

    let mut scenario = test_scenario::begin(admin_address);

    // Setup
    social_layer_config::test_create_config(ctx(&mut scenario));
    social_layer_registry::create_registry_for_testing(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Create profiles for both users
    next_tx(&mut scenario, user_a_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let mut profile_a = profile::create_profile_helper(
        b"user-a".to_string(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    next_tx(&mut scenario, user_b_address);
    let mut profile_b = profile::create_profile_helper(
        b"user-b".to_string(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    // Test 1: User A follows User B
    next_tx(&mut scenario, user_a_address);
    profile_actions::follow_user(
        &mut profile_a,
        user_b_address,
        &clock,
    );

    // Verify User A is following User B
    assert!(profile::is_following(&profile_a, user_b_address));

    // Test 2: User A unfollows User B
    next_tx(&mut scenario, user_a_address);
    profile_actions::unfollow_user(
        &mut profile_a,
        user_b_address,
        &clock,
    );

    // Verify User A is no longer following User B
    assert!(!profile::is_following(&profile_a, user_b_address));

    // Test 3: User B follows User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::follow_user(
        &mut profile_b,
        user_a_address,
        &clock,
    );

    // Verify User B is following User A
    assert!(profile::is_following(&profile_b, user_a_address));

    // Test 4: User B unfollows User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::unfollow_user(
        &mut profile_b,
        user_a_address,
        &clock,
    );

    // Verify User B is no longer following User A
    assert!(!profile::is_following(&profile_b, user_a_address));

    // Cleanup
    clock.destroy_for_testing();
    next_tx(&mut scenario, admin_address);

    // Delete profiles
    let clock_for_deletion = clock::create_for_testing(ctx(&mut scenario));
    next_tx(&mut scenario, user_a_address);
    profile_actions::delete_profile(
        profile_a,
        &mut registry,
        &clock_for_deletion,
        ctx(&mut scenario),
    );

    next_tx(&mut scenario, user_b_address);
    profile_actions::delete_profile(
        profile_b,
        &mut registry,
        &clock_for_deletion,
        ctx(&mut scenario),
    );

    clock_for_deletion.destroy_for_testing();
    test_scenario::return_shared(registry);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_block_and_follow_interactions() {
    let admin_address: address = @0xAD;
    let user_a_address: address = @0xA;
    let user_b_address: address = @0xB;

    let mut scenario = test_scenario::begin(admin_address);

    // Setup
    social_layer_config::test_create_config(ctx(&mut scenario));
    social_layer_registry::create_registry_for_testing(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Create profiles for both users
    next_tx(&mut scenario, user_a_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let mut profile_a = profile::create_profile_helper(
        b"user-a".to_string(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    next_tx(&mut scenario, user_b_address);
    let mut profile_b = profile::create_profile_helper(
        b"user-b".to_string(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    // Test: User B blocks User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::block_user(
        &mut profile_b,
        user_a_address,
        &clock,
    );

    // Verify User A is blocked by User B
    assert!(profile::is_blocked(&profile_b, user_a_address));

    // User A can still follow User B even if B blocked A
    assert!(!profile::is_following(&profile_a, user_b_address));

    // Test: User B unblocks User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::unblock_user(
        &mut profile_b,
        user_a_address,
        &clock,
    );

    // Verify User A is no longer blocked by User B
    assert!(!profile::is_blocked(&profile_b, user_a_address));

    // Test: User A follows User B
    next_tx(&mut scenario, user_a_address);
    profile_actions::follow_user(
        &mut profile_a,
        user_b_address,
        &clock,
    );

    // Verify User A is following User B
    assert!(profile::is_following(&profile_a, user_b_address));

    // Cleanup - unfollow before deleting
    profile_actions::unfollow_user(&mut profile_a, user_b_address, &clock);

    // Cleanup
    clock.destroy_for_testing();
    next_tx(&mut scenario, admin_address);

    // Delete profiles
    let clock_for_deletion = clock::create_for_testing(ctx(&mut scenario));
    next_tx(&mut scenario, user_a_address);
    profile_actions::delete_profile(
        profile_a,
        &mut registry,
        &clock_for_deletion,
        ctx(&mut scenario),
    );

    next_tx(&mut scenario, user_b_address);
    profile_actions::delete_profile(
        profile_b,
        &mut registry,
        &clock_for_deletion,
        ctx(&mut scenario),
    );

    clock_for_deletion.destroy_for_testing();
    test_scenario::return_shared(registry);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_follow_blocked_user_succeeds() {
    let admin_address: address = @0xAD;
    let user_a_address: address = @0xA;
    let user_b_address: address = @0xB;

    let mut scenario = test_scenario::begin(admin_address);

    // Setup
    social_layer_config::test_create_config(ctx(&mut scenario));
    social_layer_registry::create_registry_for_testing(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Create profiles for both users
    next_tx(&mut scenario, user_a_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let mut profile_a = profile::create_profile_helper(
        b"user-a".to_string(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    next_tx(&mut scenario, user_b_address);
    let mut profile_b = profile::create_profile_helper(
        b"user-b".to_string(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    // User B blocks User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::block_user(
        &mut profile_b,
        user_a_address,
        &clock,
    );

    // User A can still follow User B (blocking doesn't prevent following)
    next_tx(&mut scenario, user_a_address);
    profile_actions::follow_user(
        &mut profile_a,
        user_b_address,
        &clock,
    );

    // Verify the follow succeeded
    assert!(profile::is_following(&profile_a, user_b_address));

    // Cleanup
    profile_actions::unfollow_user(&mut profile_a, user_b_address, &clock);
    profile_actions::unblock_user(&mut profile_b, user_a_address, &clock);

    clock.destroy_for_testing();
    next_tx(&mut scenario, admin_address);

    // Delete profiles
    let clock_for_deletion = clock::create_for_testing(ctx(&mut scenario));
    next_tx(&mut scenario, user_a_address);
    profile_actions::delete_profile(
        profile_a,
        &mut registry,
        &clock_for_deletion,
        ctx(&mut scenario),
    );

    next_tx(&mut scenario, user_b_address);
    profile_actions::delete_profile(
        profile_b,
        &mut registry,
        &clock_for_deletion,
        ctx(&mut scenario),
    );

    clock_for_deletion.destroy_for_testing();
    test_scenario::return_shared(registry);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}

#[test]
fun test_complex_social_interactions() {
    let admin_address: address = @0xAD;
    let user_a_address: address = @0xA;
    let user_b_address: address = @0xB;

    let mut scenario = test_scenario::begin(admin_address);

    // Setup
    social_layer_config::test_create_config(ctx(&mut scenario));
    social_layer_registry::create_registry_for_testing(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Create profiles for both users
    next_tx(&mut scenario, user_a_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let mut profile_a = profile::create_profile_helper(
        b"user-a".to_string(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    next_tx(&mut scenario, user_b_address);
    let mut profile_b = profile::create_profile_helper(
        b"user-b".to_string(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        option::none<std::string::String>(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    // Test complex interactions
    // 1. User A follows User B
    next_tx(&mut scenario, user_a_address);
    profile_actions::follow_user(
        &mut profile_a,
        user_b_address,
        &clock,
    );
    assert!(profile::is_following(&profile_a, user_b_address));

    // 2. User B follows User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::follow_user(
        &mut profile_b,
        user_a_address,
        &clock,
    );
    assert!(profile::is_following(&profile_b, user_a_address));

    // 3. User B blocks User A (but A can still follow B)
    next_tx(&mut scenario, user_b_address);
    profile_actions::block_user(
        &mut profile_b,
        user_a_address,
        &clock,
    );
    assert!(profile::is_blocked(&profile_b, user_a_address));

    // 4. User A unfollows User B
    next_tx(&mut scenario, user_a_address);
    profile_actions::unfollow_user(
        &mut profile_a,
        user_b_address,
        &clock,
    );
    assert!(!profile::is_following(&profile_a, user_b_address));

    // 5. User B unfollows User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::unfollow_user(
        &mut profile_b,
        user_a_address,
        &clock,
    );
    assert!(!profile::is_following(&profile_b, user_a_address));

    // 6. User B unblocks User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::unblock_user(
        &mut profile_b,
        user_a_address,
        &clock,
    );
    assert!(!profile::is_blocked(&profile_b, user_a_address));

    // 7. User A follows User B again
    next_tx(&mut scenario, user_a_address);
    profile_actions::follow_user(
        &mut profile_a,
        user_b_address,
        &clock,
    );
    assert!(profile::is_following(&profile_a, user_b_address));

    // Cleanup
    profile_actions::unfollow_user(&mut profile_a, user_b_address, &clock);

    clock.destroy_for_testing();
    next_tx(&mut scenario, admin_address);

    // Delete profiles
    let clock_for_deletion = clock::create_for_testing(ctx(&mut scenario));
    next_tx(&mut scenario, user_a_address);
    profile_actions::delete_profile(
        profile_a,
        &mut registry,
        &clock_for_deletion,
        ctx(&mut scenario),
    );

    next_tx(&mut scenario, user_b_address);
    profile_actions::delete_profile(
        profile_b,
        &mut registry,
        &clock_for_deletion,
        ctx(&mut scenario),
    );

    clock_for_deletion.destroy_for_testing();
    test_scenario::return_shared(registry);
    test_scenario::return_shared(config);
    test_scenario::end(scenario);
}
