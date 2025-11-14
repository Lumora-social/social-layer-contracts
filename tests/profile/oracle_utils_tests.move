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

#[test]
#[expected_failure(abort_code = suins_social_layer::oracle_utils::EInvalidMessageFormat)]
fun test_validate_oracle_public_key_invalid_length() {
    // Test invalid public key (not 32 bytes)
    let invalid_key = vector::empty<u8>();
    oracle_utils::validate_oracle_public_key(&invalid_key);
}

#[test]
#[expected_failure(abort_code = suins_social_layer::oracle_utils::EInvalidMessageFormat)]
fun test_verify_oracle_signature_invalid_public_key() {
    // Create a test message (as vector<u8>)
    let mut message = vector::empty<u8>();
    vector::append(&mut message, b"test message");

    // Create invalid public key (not 32 bytes)
    let invalid_public_key = vector::empty<u8>();

    // Create a dummy signature (64 bytes)
    let mut invalid_signature = vector::empty<u8>();
    let mut i = 0;
    while (i < 64) {
        vector::push_back(&mut invalid_signature, i);
        i = i + 1;
    };

    // This should fail
    oracle_utils::verify_oracle_signature(&message, &invalid_public_key, &invalid_signature);
}

#[test]
#[expected_failure(abort_code = suins_social_layer::oracle_utils::EInvalidMessageFormat)]
fun test_verify_oracle_signature_invalid_signature_length() {
    // Create a test message (as vector<u8>)
    let mut message = vector::empty<u8>();
    vector::append(&mut message, b"test message");

    // Create valid public key (32 bytes)
    let mut public_key = vector::empty<u8>();
    let mut i = 0;
    while (i < 32) {
        vector::push_back(&mut public_key, i);
        i = i + 1;
    };

    // Create invalid signature (not 64 bytes)
    let invalid_signature = vector::empty<u8>();

    // This should fail
    oracle_utils::verify_oracle_signature(&message, &public_key, &invalid_signature);
}
