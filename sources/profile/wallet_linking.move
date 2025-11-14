/// Module for securely linking external wallets to profiles using backend attestation
///
/// Security Model:
/// 1. User signs message with their external wallet (ETH/BTC/SOL/SUI)
/// 2. Backend verifies the wallet signature off-chain
/// 3. Backend creates attestation: profile_id || chain || wallet_address || timestamp
/// 4. Backend signs attestation with oracle private key (Ed25519)
/// 5. User submits attestation to blockchain
/// 6. Smart contract verifies backend's signature
/// 7. Wallet is linked to profile if valid
module suins_social_layer::wallet_linking;

use std::string::String;
use sui::bcs;
use sui::clock::{Self, Clock};
use sui::event;
use suins_social_layer::oracle_utils::{Self, OracleConfig};
use suins_social_layer::profile::{Self, Profile};
use suins_social_layer::social_layer_config::{Self as config, Config};

// === Errors ===
#[error]
const ETimestampExpired: u64 = 1;
const ESenderNotOwner: u64 = 2;

// Attestation validity window: 10 minutes (600,000 milliseconds)
const ATTESTATION_VALIDITY_MS: u64 = 600000;

// === Events ===

/// Event emitted when a wallet is successfully linked
public struct WalletLinkedEvent has copy, drop {
    profile_id: ID,
    profile_owner: address,
    chain: String,
    wallet_address: String,
    timestamp: u64,
}

// === Public Functions ===

/// Link a wallet to a profile using backend attestation
/// Supports ETH, BTC, SOL, and SUI chains
/// The chain parameter must be one of the allowed wallet keys
public(package) fun link_chain_wallet(
    profile: &mut Profile,
    chain: String,
    wallet_address: String,
    signature: vector<u8>,
    timestamp: u64,
    oracle_config: &OracleConfig,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    // Validate that chain is one of the allowed values
    config::assert_wallet_key_is_allowed(config, &chain);

    link_wallet_internal(
        profile,
        chain,
        wallet_address,
        signature,
        timestamp,
        oracle_config,
        config,
        clock,
        ctx,
    );
}

// === Helper Functions ===

/// Internal function that handles wallet linking logic
/// Called by all chain-specific public functions
fun link_wallet_internal(
    profile: &mut Profile,
    chain: String,
    wallet_address: String,
    signature: vector<u8>,
    timestamp: u64,
    oracle_config: &OracleConfig,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    // 1. Verify sender is profile owner
    assert!(tx_context::sender(ctx) == profile::owner(profile), ESenderNotOwner);

    // 2. Verify config is up to date
    config::assert_interacting_with_most_up_to_date_package(config);

    // 3. Verify oracle public key is set
    let oracle_public_key = oracle_utils::get_oracle_public_key(oracle_config);
    oracle_utils::validate_oracle_public_key(&oracle_public_key);

    // 4. Verify timestamp hasn't expired
    let current_time = clock::timestamp_ms(clock);
    assert!(
        current_time >= timestamp && current_time - timestamp <= ATTESTATION_VALIDITY_MS,
        ETimestampExpired,
    );

    // 5. Construct the message that should have been signed by backend
    let message = construct_wallet_link_attestation_message(
        object::id(profile),
        &chain,
        &wallet_address,
        timestamp,
    );

    // 6. Verify the backend signature
    oracle_utils::verify_oracle_signature(&message, &oracle_public_key, &signature);

    // 7. Add wallet to profile (uses existing profile::add_wallet_address function)
    profile::add_wallet_address(profile, chain, wallet_address, config, clock, ctx);

    // 8. Emit event
    event::emit(WalletLinkedEvent {
        profile_id: object::id(profile),
        profile_owner: profile::owner(profile),
        chain,
        wallet_address,
        timestamp: current_time,
    });
}

/// Constructs the wallet link attestation message
/// Format: profile_id || chain || "||" || wallet_address || "||" || timestamp
/// This MUST match the backend message construction exactly
fun construct_wallet_link_attestation_message(
    profile_id: ID,
    chain: &String,
    wallet_address: &String,
    timestamp: u64,
): vector<u8> {
    let mut message = vector::empty<u8>();

    // Add profile ID (32 bytes)
    let profile_id_bytes = object::id_to_bytes(&profile_id);
    vector::append(&mut message, profile_id_bytes);

    // Add chain name (UTF-8 bytes)
    let chain_bytes = chain.as_bytes();
    vector::append(&mut message, *chain_bytes);

    // Add separator
    vector::append(&mut message, b"||");

    // Add wallet address (UTF-8 bytes)
    let wallet_bytes = wallet_address.as_bytes();
    vector::append(&mut message, *wallet_bytes);

    // Add separator
    vector::append(&mut message, b"||");

    // Add timestamp (8 bytes, little-endian via BCS)
    let timestamp_bytes = bcs::to_bytes(&timestamp);
    vector::append(&mut message, timestamp_bytes);

    message
}
