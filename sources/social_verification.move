/// Module for social verification using backend oracle signatures
module suins_social_layer::social_verification;

// === Errors ===
#[error]
const EInvalidPublicKey: u64 = 0;

// === Structs ===

/// Oracle configuration that stores the public key for verifying attestations
public struct OracleConfig has key {
    id: UID,
    public_key: vector<u8>,
}

// === Public Functions ===

/// Get the oracle public key from the config
public fun get_oracle_public_key(config: &OracleConfig): vector<u8> {
    config.public_key
}

/// Create a new oracle configuration (admin function)
/// This should be called once during deployment to set up the oracle
public fun create_oracle_config(
    public_key: vector<u8>,
    ctx: &mut TxContext,
) {
    // Validate public key length (Ed25519 public keys are 32 bytes)
    assert!(vector::length(&public_key) == 32, EInvalidPublicKey);

    let config = OracleConfig {
        id: object::new(ctx),
        public_key,
    };

    transfer::share_object(config);
}
