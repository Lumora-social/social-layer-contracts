/// Shared utilities for oracle signature verification
/// Used by profile_badges and social_verification modules
module suins_social_layer::oracle_utils;

use sui::ed25519;

// === Errors ===
#[error]
const EInvalidSignature: u64 = 0;
const EInvalidMessageFormat: u64 = 1;

// === Public Functions ===

/// Verifies backend oracle Ed25519 signature
/// Validates public key (32 bytes) and signature (64 bytes) lengths
/// Then verifies the signature matches the message
public fun verify_oracle_signature(
    message: &vector<u8>,
    public_key: &vector<u8>,
    signature: &vector<u8>,
) {
    assert!(vector::length(public_key) == 32, EInvalidMessageFormat);
    assert!(vector::length(signature) == 64, EInvalidMessageFormat);
    let is_valid = ed25519::ed25519_verify(signature, public_key, message);
    assert!(is_valid, EInvalidSignature);
}

/// Validates that oracle public key is properly set (32 bytes)
public fun validate_oracle_public_key(public_key: &vector<u8>) {
    assert!(vector::length(public_key) == 32, EInvalidMessageFormat);
}
