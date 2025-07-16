module suins_social_layer::blocklist;

use sui::clock::{Self, Clock};
use sui::event;
use sui::table::{Self, Table};
use sui::types;
use suins_social_layer::profile::Profile;

const ETypeNotOneTimeWitness: u64 = 1;
const EUserNotBlocked: u64 = 2;
const EUserAlreadyBlocked: u64 = 3;

public struct BlockList has key {
    id: UID,
    registry: Table<address, Table<address, bool>>,
}

public struct BLOCKLIST has drop {}

// === Events ===
public struct BlockUserEvent has copy, drop {
    blocker_address: address,
    blocked_address: address,
    timestamp: u64,
}

public struct UnblockUserEvent has copy, drop {
    unblocker_address: address,
    unblocked_address: address,
    timestamp: u64,
}

fun init(otw: BLOCKLIST, ctx: &mut TxContext) {
    assert!(types::is_one_time_witness<BLOCKLIST>(&otw), ETypeNotOneTimeWitness);
    let block_list = BlockList {
        id: object::new(ctx),
        registry: sui::table::new(ctx),
    };
    transfer::share_object(block_list);
}

public(package) fun has_key(self: &BlockList, user_address: address): bool {
    return table::contains(&self.registry, user_address)
}

public(package) fun block_user(
    self: &mut BlockList,
    profile: &Profile,
    block_user_address: address,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    if (!has_key(self, profile.owner())) {
        table::add(&mut self.registry, profile.owner(), sui::table::new(ctx));
    };
    let block_list = table::borrow_mut(&mut self.registry, profile.owner());
    assert!(!table::contains(block_list, block_user_address), EUserAlreadyBlocked);
    table::add(block_list, block_user_address, true);

    // Emit block event
    event::emit(BlockUserEvent {
        blocker_address: profile.owner(),
        blocked_address: block_user_address,
        timestamp: clock::timestamp_ms(clock),
    });
}

public(package) fun unblock_user(
    self: &mut BlockList,
    profile: &Profile,
    block_user_address: address,
    clock: &Clock,
) {
    assert!(has_key(self, profile.owner()), EUserNotBlocked);
    let block_list = table::borrow_mut(&mut self.registry, profile.owner());
    assert!(table::contains(block_list, block_user_address), EUserNotBlocked);
    table::remove(block_list, block_user_address);

    // Emit unblock event
    event::emit(UnblockUserEvent {
        unblocker_address: profile.owner(),
        unblocked_address: block_user_address,
        timestamp: clock::timestamp_ms(clock),
    });
}

public fun is_blocked(self: &BlockList, user_address: address, block_user_address: address): bool {
    if (!has_key(self, user_address)) {
        return false
    };
    let block_list = table::borrow(&self.registry, user_address);
    return table::contains(block_list, block_user_address)
}

#[test_only]
public fun test_create_blocklist(ctx: &mut TxContext) {
    let block_list = BlockList {
        id: object::new(ctx),
        registry: sui::table::new(ctx),
    };
    transfer::share_object(block_list);
}
