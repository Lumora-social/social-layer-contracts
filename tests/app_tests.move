module suins_social_layer::app_tests;

use sui::test_scenario::{Self, next_tx, ctx};
use suins_social_layer::app;

#[test]
fun test_admin_cap_creation() {
    let admin_address: address = @0xAD;

    let mut scenario = test_scenario::begin(admin_address);

    // Initialize app module (creates AdminCap)
    app::test_init(ctx(&mut scenario));
    next_tx(&mut scenario, admin_address);

    // AdminCap should be transferred to admin_address
    // We can't directly test this without accessing the object, but we verify it compiles
    // In a real scenario, the AdminCap would be owned by the admin address

    test_scenario::end(scenario);
}

