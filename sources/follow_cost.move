module suins_social_layer::follow_cost;

use std::string::String;
use sui::table::{Self, Table};
use sui::types;

const ETypeNotOneTimeWitness: u64 = 1;

public struct FollowingCost has key {
    id: UID,
    registry: Table<String, u64>,
}

public struct Cost has key {
    id: UID,
    cost: u64,
}

public struct FOLLOW_COST has drop {}

fun init(otw: FOLLOW_COST, ctx: &mut TxContext) {
    assert!(types::is_one_time_witness<FOLLOW_COST>(&otw), ETypeNotOneTimeWitness);
    let cost = FollowingCost {
        id: object::new(ctx),
        registry: sui::table::new(ctx),
    };
    transfer::share_object(cost);
}

public fun get_cost(self: &FollowingCost, user_name: String): u64 {
    if (!table::contains(&self.registry, user_name)) {
        return 0
    };
    return 10
}
