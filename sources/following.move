module suins_social_layer::following;

use sui::clock::{Self, Clock};
use sui::event;
use sui::table::{Self, Table};
use sui::types;
use suins_social_layer::blocklist::{Self, BlockList};
use suins_social_layer::profile::Profile;

const ETypeNotOneTimeWitness: u64 = 1;
const EUserNotFollowing: u64 = 2;
const EUserBlocked: u64 = 3;
const EUserAlreadyFollowing: u64 = 4;

public struct Following has key {
    id: UID,
    registry: Table<address, Table<address, bool>>,
}

public struct FOLLOWING has drop {}

// === Events ===
public struct FollowUserEvent has copy, drop {
    follower_address: address,
    followed_address: address,
    timestamp: u64,
}

public struct UnfollowUserEvent has copy, drop {
    unfollower_address: address,
    unfollowed_address: address,
    timestamp: u64,
}

fun init(otw: FOLLOWING, ctx: &mut TxContext) {
    assert!(types::is_one_time_witness<FOLLOWING>(&otw), ETypeNotOneTimeWitness);
    let following = Following {
        id: object::new(ctx),
        registry: sui::table::new(ctx),
    };
    transfer::share_object(following);
}

public(package) fun has_key(self: &Following, user_address: address): bool {
    return table::contains(&self.registry, user_address)
}

public(package) fun follow_user(
    self: &mut Following,
    profile: &Profile,
    follow_user_address: address,
    blocklist: &BlockList,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // Check if the follower is blocked by the person they're trying to follow
    assert!(!blocklist::is_blocked(blocklist, follow_user_address, profile.owner()), EUserBlocked);

    if (!has_key(self, profile.owner())) {
        table::add(&mut self.registry, profile.owner(), sui::table::new(ctx));
    };
    let following_list = table::borrow_mut(&mut self.registry, profile.owner());
    assert!(!table::contains(following_list, follow_user_address), EUserAlreadyFollowing);
    table::add(following_list, follow_user_address, true);

    // Emit follow event
    event::emit(FollowUserEvent {
        follower_address: profile.owner(),
        followed_address: follow_user_address,
        timestamp: clock::timestamp_ms(clock),
    });
}

public(package) fun unfollow_user(
    self: &mut Following,
    profile: &Profile,
    follow_user_address: address,
    clock: &Clock,
) {
    assert!(has_key(self, profile.owner()), EUserNotFollowing);
    let following_list = table::borrow_mut(&mut self.registry, profile.owner());
    assert!(table::contains(following_list, follow_user_address), EUserNotFollowing);
    table::remove(following_list, follow_user_address);

    // Emit unfollow event
    event::emit(UnfollowUserEvent {
        unfollower_address: profile.owner(),
        unfollowed_address: follow_user_address,
        timestamp: clock::timestamp_ms(clock),
    });
}

public fun is_following(
    self: &Following,
    user_address: address,
    follow_user_address: address,
): bool {
    if (!has_key(self, user_address)) {
        return false
    };
    let following_list = table::borrow(&self.registry, user_address);
    return table::contains(following_list, follow_user_address)
}

#[test_only]
public fun test_create_following(ctx: &mut TxContext) {
    let following = Following {
        id: object::new(ctx),
        registry: sui::table::new(ctx),
    };
    transfer::share_object(following);
}
