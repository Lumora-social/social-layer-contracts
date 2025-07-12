module suins_social_layer::social_layer_blocklist;

use std::string::String;
use sui::table::{Self, Table};
use sui::types;
use suins_social_layer::profile::Profile;

const ETypeNotOneTimeWitness: u64 = 1;
const EUserNotBlocked: u64 = 2;

public struct BlockList has key {
    id: UID,
    registry: Table<String, Table<String, bool>>,
}

public struct SOCIAL_LAYER_BLOCKLIST has drop {}

fun init(otw: SOCIAL_LAYER_BLOCKLIST, ctx: &mut TxContext) {
    assert!(types::is_one_time_witness<SOCIAL_LAYER_BLOCKLIST>(&otw), ETypeNotOneTimeWitness);
    let block_list = BlockList {
        id: object::new(ctx),
        registry: sui::table::new(ctx),
    };
    transfer::share_object(block_list);
}

public(package) fun has_key(self: &BlockList, user_name: String): bool {
    return table::contains(&self.registry, user_name)
}

public(package) fun block_user(
    self: &mut BlockList,
    profile: &Profile,
    block_user_name: String,
    ctx: &mut TxContext,
) {
    if (!has_key(self, profile.user_name())) {
        table::add(&mut self.registry, profile.user_name(), sui::table::new(ctx));
    };
    let block_list = table::borrow_mut(&mut self.registry, profile.user_name());
    table::add(block_list, block_user_name, true);
}

public(package) fun unblock_user(self: &mut BlockList, profile: &Profile, block_user_name: String) {
    assert!(has_key(self, profile.user_name()), EUserNotBlocked);
    let block_list = table::borrow_mut(&mut self.registry, profile.user_name());
    assert!(table::contains(block_list, block_user_name), EUserNotBlocked);
    table::remove(block_list, block_user_name);
}

public(package) fun is_blocked(self: &BlockList, user_name: String, block_user_name: String): bool {
    if (!has_key(self, user_name)) {
        return false
    };
    let block_list = table::borrow(&self.registry, user_name);
    return table::contains(block_list, block_user_name)
}
