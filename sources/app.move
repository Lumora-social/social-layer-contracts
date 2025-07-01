module suins_social_layer::app;

public struct AdminCap has key, store {
    id: UID,
}

fun init(tx_context: &mut TxContext) {
    let admin_cap = AdminCap { id: object::new(tx_context) };
    transfer::transfer<AdminCap>(admin_cap, tx_context::sender(tx_context));
}

#[test_only]
public fun test_init(tx_context: &mut TxContext) {
    let admin_cap = AdminCap { id: object::new(tx_context) };
    transfer::transfer<AdminCap>(admin_cap, tx_context::sender(tx_context));
}
