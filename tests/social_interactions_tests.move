module suins_social_layer::social_interactions_tests;

use sui::clock;
use sui::test_scenario::{Self, next_tx, ctx};
use suins_social_layer::blocklist::{Self, BlockList};
use suins_social_layer::following::{Self, Following};
use suins_social_layer::profile;
use suins_social_layer::profile_actions;
use suins_social_layer::social_layer_config;
use suins_social_layer::social_layer_registry;

#[test]
fun test_blocklist_operations() {
    let user_a_address: address = @0xA;
    let user_b_address: address = @0xB;
    let admin_address: address = @0xC;

    let mut scenario = test_scenario::begin(admin_address);

    // Initialize dependencies
    social_layer_config::test_create_config(ctx(&mut scenario));
    social_layer_registry::create_registry_for_testing(ctx(&mut scenario));
    blocklist::test_create_blocklist(ctx(&mut scenario));
    following::test_create_following(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);
    let mut blocklist = test_scenario::take_shared<BlockList>(&scenario);

    next_tx(&mut scenario, admin_address);
    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Create profiles for both users
    next_tx(&mut scenario, user_a_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let profile_a = profile::create_profile_helper(
        b"user-a".to_string(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    next_tx(&mut scenario, user_b_address);
    let profile_b = profile::create_profile_helper(
        b"user-b".to_string(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    // Test 1: User A blocks User B
    next_tx(&mut scenario, user_a_address);
    profile_actions::block_user(
        &mut blocklist,
        &profile_a,
        user_b_address,
        &clock,
        ctx(&mut scenario),
    );

    // Verify User B is blocked by User A
    assert!(blocklist::is_blocked(&blocklist, user_a_address, user_b_address));

    // Test 2: User A unblocks User B
    next_tx(&mut scenario, user_a_address);
    profile_actions::unblock_user(
        &mut blocklist,
        &profile_a,
        user_b_address,
        &clock,
    );

    // Verify User B is no longer blocked by User A
    assert!(!blocklist::is_blocked(&blocklist, user_a_address, user_b_address));

    // Test 3: User B blocks User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::block_user(
        &mut blocklist,
        &profile_b,
        user_a_address,
        &clock,
        ctx(&mut scenario),
    );

    // Verify User A is blocked by User B
    assert!(blocklist::is_blocked(&blocklist, user_b_address, user_a_address));

    // Test 4: User B unblocks User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::unblock_user(
        &mut blocklist,
        &profile_b,
        user_a_address,
        &clock,
    );

    // Verify User A is no longer blocked by User B
    assert!(!blocklist::is_blocked(&blocklist, user_b_address, user_a_address));

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

    test_scenario::return_shared(config);
    test_scenario::return_shared(registry);
    test_scenario::return_shared(blocklist);
    test_scenario::end(scenario);
}

#[test]
fun test_following_operations() {
    let user_a_address: address = @0xA;
    let user_b_address: address = @0xB;
    let admin_address: address = @0xC;

    let mut scenario = test_scenario::begin(admin_address);

    // Initialize dependencies
    social_layer_config::test_create_config(ctx(&mut scenario));
    social_layer_registry::create_registry_for_testing(ctx(&mut scenario));
    blocklist::test_create_blocklist(ctx(&mut scenario));
    following::test_create_following(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);
    let mut following = test_scenario::take_shared<Following>(&scenario);
    let mut blocklist = test_scenario::take_shared<BlockList>(&scenario);

    next_tx(&mut scenario, admin_address);
    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Create profiles for both users
    next_tx(&mut scenario, user_a_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let profile_a = profile::create_profile_helper(
        b"user-a".to_string(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    next_tx(&mut scenario, user_b_address);
    let profile_b = profile::create_profile_helper(
        b"user-b".to_string(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    // Test 1: User A follows User B
    next_tx(&mut scenario, user_a_address);
    profile_actions::add_following(
        &profile_a,
        &mut following,
        &blocklist,
        user_b_address,
        &clock,
        ctx(&mut scenario),
    );

    // Verify User A is following User B
    assert!(following::is_following(&following, user_a_address, user_b_address));

    // Test 2: User A unfollows User B
    next_tx(&mut scenario, user_a_address);
    profile_actions::remove_following(
        &profile_a,
        &mut following,
        user_b_address,
        &clock,
    );

    // Verify User A is no longer following User B
    assert!(!following::is_following(&following, user_a_address, user_b_address));

    // Test 3: User B follows User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::add_following(
        &profile_b,
        &mut following,
        &blocklist,
        user_a_address,
        &clock,
        ctx(&mut scenario),
    );

    // Verify User B is following User A
    assert!(following::is_following(&following, user_b_address, user_a_address));

    // Test 4: User B unfollows User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::remove_following(
        &profile_b,
        &mut following,
        user_a_address,
        &clock,
    );

    // Verify User B is no longer following User A
    assert!(!following::is_following(&following, user_b_address, user_a_address));

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

    test_scenario::return_shared(config);
    test_scenario::return_shared(registry);
    test_scenario::return_shared(blocklist);
    test_scenario::return_shared(following);
    test_scenario::end(scenario);
}

#[test]
fun test_blocklist_following_interaction() {
    let user_a_address: address = @0xA;
    let user_b_address: address = @0xB;
    let admin_address: address = @0xC;

    let mut scenario = test_scenario::begin(admin_address);

    // Initialize dependencies
    social_layer_config::test_create_config(ctx(&mut scenario));
    social_layer_registry::create_registry_for_testing(ctx(&mut scenario));
    blocklist::test_create_blocklist(ctx(&mut scenario));
    following::test_create_following(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);
    let mut blocklist = test_scenario::take_shared<BlockList>(&scenario);
    let mut following = test_scenario::take_shared<Following>(&scenario);

    next_tx(&mut scenario, admin_address);
    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Create profiles for both users
    next_tx(&mut scenario, user_a_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let profile_a = profile::create_profile_helper(
        b"user-a".to_string(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    next_tx(&mut scenario, user_b_address);
    let profile_b = profile::create_profile_helper(
        b"user-b".to_string(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    // Test 1: User B blocks User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::block_user(
        &mut blocklist,
        &profile_b,
        user_a_address,
        &clock,
        ctx(&mut scenario),
    );

    // Verify User A is blocked by User B
    assert!(blocklist::is_blocked(&blocklist, user_b_address, user_a_address));

    // Verify User A is not following User B
    assert!(!following::is_following(&following, user_a_address, user_b_address));

    // Test 2: User B unblocks User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::unblock_user(
        &mut blocklist,
        &profile_b,
        user_a_address,
        &clock,
    );

    // Verify User A is no longer blocked by User B
    assert!(!blocklist::is_blocked(&blocklist, user_b_address, user_a_address));

    // Test 3: User A can now follow User B
    next_tx(&mut scenario, user_a_address);
    profile_actions::add_following(
        &profile_a,
        &mut following,
        &blocklist,
        user_b_address,
        &clock,
        ctx(&mut scenario),
    );

    // Verify User A is now following User B
    assert!(following::is_following(&following, user_a_address, user_b_address));

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

    test_scenario::return_shared(config);
    test_scenario::return_shared(registry);
    test_scenario::return_shared(blocklist);
    test_scenario::return_shared(following);
    test_scenario::end(scenario);
}

#[test]
#[expected_failure(abort_code = following::EUserBlocked)]
fun test_follow_blocked_user_fails() {
    let user_a_address: address = @0xA;
    let user_b_address: address = @0xB;
    let admin_address: address = @0xC;

    let mut scenario = test_scenario::begin(admin_address);

    // Initialize dependencies
    social_layer_config::test_create_config(ctx(&mut scenario));
    social_layer_registry::create_registry_for_testing(ctx(&mut scenario));
    blocklist::test_create_blocklist(ctx(&mut scenario));
    following::test_create_following(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);
    let mut blocklist = test_scenario::take_shared<BlockList>(&scenario);
    let mut following = test_scenario::take_shared<Following>(&scenario);

    next_tx(&mut scenario, admin_address);
    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Create profiles for both users
    next_tx(&mut scenario, user_a_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let profile_a = profile::create_profile_helper(
        b"user-a".to_string(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    next_tx(&mut scenario, user_b_address);
    let profile_b = profile::create_profile_helper(
        b"user-b".to_string(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    // User B blocks User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::block_user(
        &mut blocklist,
        &profile_b,
        user_a_address,
        &clock,
        ctx(&mut scenario),
    );

    // User A tries to follow User B (should fail with EUserBlocked)
    next_tx(&mut scenario, user_a_address);
    profile_actions::add_following(
        &profile_a,
        &mut following,
        &blocklist,
        user_b_address,
        &clock,
        ctx(&mut scenario),
    );

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

    test_scenario::return_shared(config);
    test_scenario::return_shared(registry);
    test_scenario::return_shared(blocklist);
    test_scenario::return_shared(following);
    test_scenario::end(scenario);
}

#[test]
fun test_comprehensive_social_interactions() {
    let user_a_address: address = @0xA;
    let user_b_address: address = @0xB;
    let admin_address: address = @0xC;

    let mut scenario = test_scenario::begin(admin_address);

    // Initialize dependencies
    social_layer_config::test_create_config(ctx(&mut scenario));
    social_layer_registry::create_registry_for_testing(ctx(&mut scenario));
    blocklist::test_create_blocklist(ctx(&mut scenario));
    following::test_create_following(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);
    let mut blocklist = test_scenario::take_shared<BlockList>(&scenario);
    let mut following = test_scenario::take_shared<Following>(&scenario);

    next_tx(&mut scenario, admin_address);
    let mut registry = test_scenario::take_shared<social_layer_registry::Registry>(&scenario);
    let config = test_scenario::take_shared<social_layer_config::Config>(&scenario);

    // Create profiles for both users
    next_tx(&mut scenario, user_a_address);
    let clock = clock::create_for_testing(ctx(&mut scenario));
    let profile_a = profile::create_profile_helper(
        b"user-a".to_string(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    next_tx(&mut scenario, user_b_address);
    let profile_b = profile::create_profile_helper(
        b"user-b".to_string(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        &config,
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    // Phase 1: Normal following
    // User A follows User B
    next_tx(&mut scenario, user_a_address);
    profile_actions::add_following(
        &profile_a,
        &mut following,
        &blocklist,
        user_b_address,
        &clock,
        ctx(&mut scenario),
    );
    assert!(following::is_following(&following, user_a_address, user_b_address));

    // User B follows User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::add_following(
        &profile_b,
        &mut following,
        &blocklist,
        user_a_address,
        &clock,
        ctx(&mut scenario),
    );
    assert!(following::is_following(&following, user_b_address, user_a_address));

    // Phase 2: Blocking
    // User B blocks User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::block_user(
        &mut blocklist,
        &profile_b,
        user_a_address,
        &clock,
        ctx(&mut scenario),
    );
    assert!(blocklist::is_blocked(&blocklist, user_b_address, user_a_address));

    // Phase 3: Unfollowing after blocking
    // User A unfollows User B
    next_tx(&mut scenario, user_a_address);
    profile_actions::remove_following(
        &profile_a,
        &mut following,
        user_b_address,
        &clock,
    );
    assert!(!following::is_following(&following, user_a_address, user_b_address));

    // User B unfollows User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::remove_following(
        &profile_b,
        &mut following,
        user_a_address,
        &clock,
    );
    assert!(!following::is_following(&following, user_b_address, user_a_address));

    // Phase 4: Unblocking
    // User B unblocks User A
    next_tx(&mut scenario, user_b_address);
    profile_actions::unblock_user(
        &mut blocklist,
        &profile_b,
        user_a_address,
        &clock,
    );
    assert!(!blocklist::is_blocked(&blocklist, user_b_address, user_a_address));

    // Phase 5: Following again after unblocking
    // User A can follow User B again
    next_tx(&mut scenario, user_a_address);
    profile_actions::add_following(
        &profile_a,
        &mut following,
        &blocklist,
        user_b_address,
        &clock,
        ctx(&mut scenario),
    );
    assert!(following::is_following(&following, user_a_address, user_b_address));

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

    test_scenario::return_shared(config);
    test_scenario::return_shared(registry);
    test_scenario::return_shared(blocklist);
    test_scenario::return_shared(following);
    test_scenario::end(scenario);
}
