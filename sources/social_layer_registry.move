module suins_social_layer::social_layer_registry;

use std::string::String;
use sui::table::{Self, Table};
use sui::types;

const ERecordAlreadyExists: u64 = 1;
const ERecordDoesNotExist: u64 = 2;
const ETypeNotOneTimeWitness: u64 = 3;

public struct Registry has key, store {
    id: UID,
    display_name_registry: Table<String, bool>,
    address_registry: Table<address, bool>,
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
        display_name_registry: table::new(ctx),
        address_registry: table::new(ctx),
    }
}

public fun get_entry_display_name_registry(self: &Registry, display_name: String): bool {
    table::contains(&self.display_name_registry, display_name)
}

public fun get_entry_address_registry(self: &Registry, address: address): bool {
    table::contains(&self.address_registry, address)
}

public(package) fun add_entry_display_name_registry(self: &mut Registry, display_name: String) {
    assert!(!table::contains(&self.display_name_registry, display_name), ERecordAlreadyExists);
    table::add(&mut self.display_name_registry, display_name, true);
}

public(package) fun add_entry_address_registry(self: &mut Registry, address: address) {
    assert!(!table::contains(&self.address_registry, address), ERecordAlreadyExists);
    table::add(&mut self.address_registry, address, true);
}

public(package) fun remove_entry_display_name_registry(self: &mut Registry, display_name: String) {
    assert!(table::contains(&self.display_name_registry, display_name), ERecordDoesNotExist);
    table::remove(&mut self.display_name_registry, display_name);
}

public(package) fun remove_entry_address_registry(self: &mut Registry, address: address) {
    assert!(table::contains(&self.address_registry, address), ERecordDoesNotExist);
    table::remove(&mut self.address_registry, address);
}

public(package) fun add_entries(self: &mut Registry, display_name: String, address: address) {
    assert!(!table::contains(&self.display_name_registry, display_name), ERecordAlreadyExists);
    assert!(!table::contains(&self.address_registry, address), ERecordAlreadyExists);
    table::add(&mut self.display_name_registry, display_name, true);
    table::add(&mut self.address_registry, address, true);
}

public(package) fun remove_entries(self: &mut Registry, display_name: String, address: address) {
    assert!(table::contains(&self.display_name_registry, display_name), ERecordDoesNotExist);
    assert!(table::contains(&self.address_registry, address), ERecordDoesNotExist);
    table::remove(&mut self.display_name_registry, display_name);
    table::remove(&mut self.address_registry, address);
}

#[test_only]
public fun create_registry_for_testing(ctx: &mut TxContext) {
    let registry = Registry {
        id: object::new(ctx),
        display_name_registry: table::new(ctx),
        address_registry: table::new(ctx),
    };
    transfer::share_object(registry);
}
