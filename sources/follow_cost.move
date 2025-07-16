module suins_social_layer::follow_cost;

use sui::table::{Self, Table};
use sui::types;
use suins_social_layer::profile::Profile;

const ETypeNotOneTimeWitness: u64 = 1;

public struct FollowingCost has key {
    id: UID,
    registry: Table<address, Cost>,
}

public struct Cost has key, store {
    id: UID,
    cost: u64,
}

public struct FOLLOW_COST has drop {}

fun init(otw: FOLLOW_COST, ctx: &mut TxContext) {
    assert!(types::is_one_time_witness<FOLLOW_COST>(&otw), ETypeNotOneTimeWitness);
    let cost = FollowingCost {
        id: object::new(ctx),
        registry: table::new(ctx),
    };
    transfer::share_object(cost);
}

public fun cost(self: &Cost): u64 {
    return self.cost
}

public fun has_cost(self: &FollowingCost, profile: &Profile): bool {
    return table::contains(&self.registry, profile.owner())
}

public fun get_cost(self: &FollowingCost, profile: &Profile): &Cost {
    return table::borrow(&self.registry, profile.owner())
}

public fun set_cost(self: &mut FollowingCost, profile: &Profile, cost: Cost) {
    table::add(&mut self.registry, profile.owner(), cost);
}

public fun remove_cost(self: &mut FollowingCost, profile: &Profile): Cost {
    table::remove(&mut self.registry, profile.owner())
}
