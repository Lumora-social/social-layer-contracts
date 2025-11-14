module suins_social_layer::oracle_utils_tests;

use suins_social_layer::oracle_utils;

#[test]
fun test_validate_oracle_public_key() {
    // Test valid public key (32 bytes)
    let mut valid_key = vector::empty<u8>();
    let mut i = 0;
    while (i < 32) {
        vector::push_back(&mut valid_key, i);
        i = i + 1;
    };

    // Should not panic
    oracle_utils::validate_oracle_public_key(&valid_key);
}
