module suins_social_layer::social_layer_registry;

use std::string::String;
use sui::table::{Self, Table};
use sui::types;

const ERecordAlreadyExists: u64 = 1;
const ERecordDoesNotExist: u64 = 2;
const ETypeNotOneTimeWitness: u64 = 3;

public struct Registry has key, store {
    id: UID,
    registry: Table<String, address>,
}

public struct SOCIAL_LAYER_REGISTRY has drop {}

fun init(otw: SOCIAL_LAYER_REGISTRY, ctx: &mut TxContext) {
    let registry = create_registry(&otw, ctx);
    transfer::share_object(registry);
}

public fun create_registry(otw: &SOCIAL_LAYER_REGISTRY, ctx: &mut TxContext): Registry {
    assert!(types::is_one_time_witness<SOCIAL_LAYER_REGISTRY>(otw), ETypeNotOneTimeWitness);
    Registry {
        id: object::new(ctx),
        registry: table::new(ctx),
    }
}

public fun has_record(self: &Registry, user_name: String): bool {
    table::contains(&self.registry, user_name)
}

public fun get_record(self: &Registry, user_name: String): &address {
    table::borrow(&self.registry, user_name)
}

public(package) fun add_record(self: &mut Registry, user_name: String, address: address) {
    assert!(table::contains(&self.registry, user_name), ERecordAlreadyExists);
    table::add(&mut self.registry, user_name, address);
}

public(package) fun remove_record(self: &mut Registry, user_name: String) {
    assert!(table::contains(&self.registry, user_name), ERecordDoesNotExist);
    table::remove(&mut self.registry, user_name);
}
