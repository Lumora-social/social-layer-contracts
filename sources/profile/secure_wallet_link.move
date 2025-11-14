/// Module for securely linking Sui wallets to profiles using cryptographic signatures
///
/// Security Model:
/// 1. User signs a message with Wallet B (wallet to be linked)
/// 2. Message format: profile_id || wallet_B_address || timestamp
/// 3. Wallet A (profile owner) calls link_sui_wallet with the signature
/// 4. On-chain verification ensures Wallet B's owner authorized the link
/// 5. Timestamp expiration (5 minutes) and profile duplicate check prevent replay attacks
module suins_social_layer::secure_wallet_link;

use std::string::String;
use sui::bcs;
use sui::clock::{Self, Clock};
use sui::ecdsa_k1;
use sui::ed25519;
use sui::event;
use suins_social_layer::profile::{Self, Profile};
use suins_social_layer::social_layer_config::{Self as config, Config};

// === Errors ===
#[error]
const EInvalidSignature: u64 = 0;
const ETimestampExpired: u64 = 1;
const ESenderNotOwner: u64 = 2;
const EInvalidMessageFormat: u64 = 3;

// Signature validity window: 10 minutes
const SIGNATURE_VALIDITY_MS: u64 = 600000;

// === Events ===

public struct MultiChainWalletLinkedEvent has copy, drop {
    profile_id: ID,
    profile_owner: address,
    chain: String,
    wallet_address: String,
    timestamp: u64,
}

public struct MultiChainWalletUnlinkedEvent has copy, drop {
    profile_id: ID,
    profile_owner: address,
    chain: String,
    wallet_address: String,
    timestamp: u64,
}

// === Public Functions ===

/// Links an Ethereum/Bitcoin wallet using ECDSA secp256k1 signature
public fun link_evm_wallet(
    profile: &mut Profile,
    chain: String, // "ethereum", "bitcoin", etc.
    wallet_address: String,
    public_key: vector<u8>, // 33-byte compressed or 65-byte uncompressed secp256k1 public key
    signature: vector<u8>, // 65-byte ECDSA signature (r || s || v)
    timestamp: u64,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // 1. Verify sender is profile owner
    assert!(tx_context::sender(ctx) == profile::owner(profile), ESenderNotOwner);

    // 2. Verify config is up to date
    config::assert_interacting_with_most_up_to_date_package(config);

    // 3. Verify timestamp hasn't expired
    let current_time = clock::timestamp_ms(clock);
    assert!(
        current_time >= timestamp && current_time - timestamp <= SIGNATURE_VALIDITY_MS,
        ETimestampExpired,
    );

    // 4. Construct the message that should have been signed
    let message = construct_multichain_link_message(
        object::id(profile),
        chain,
        wallet_address,
        timestamp,
    );

    // 5. Verify the ECDSA secp256k1 signature
    verify_ecdsa_k1_signature(&message, &public_key, &signature);

    // 6. Add wallet to profile
    profile::add_wallet_address(profile, chain, wallet_address, config, clock, ctx);

    // 7. Emit event
    event::emit(MultiChainWalletLinkedEvent {
        profile_id: object::id(profile),
        profile_owner: profile::owner(profile),
        chain,
        wallet_address,
        timestamp: current_time,
    });
}

/// Links a Solana wallet using Ed25519 signature
public fun link_solana_wallet(
    profile: &mut Profile,
    wallet_address: String,
    public_key: vector<u8>, // 32-byte Ed25519 public key
    signature: vector<u8>, // 64-byte Ed25519 signature
    timestamp: u64,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // 1. Verify sender is profile owner
    assert!(tx_context::sender(ctx) == profile::owner(profile), ESenderNotOwner);

    // 2. Verify config is up to date
    config::assert_interacting_with_most_up_to_date_package(config);

    // 3. Verify timestamp hasn't expired
    let current_time = clock::timestamp_ms(clock);
    assert!(
        current_time >= timestamp && current_time - timestamp <= SIGNATURE_VALIDITY_MS,
        ETimestampExpired,
    );

    // 4. Construct the message that should have been signed
    let chain = b"solana".to_string();
    let message = construct_multichain_link_message(
        object::id(profile),
        chain,
        wallet_address,
        timestamp,
    );

    // 5. Verify the Ed25519 signature
    verify_ed25519_signature(&message, &public_key, &signature);

    // 6. Add wallet to profile
    profile::add_wallet_address(profile, chain, wallet_address, config, clock, ctx);

    // 7. Emit event
    event::emit(MultiChainWalletLinkedEvent {
        profile_id: object::id(profile),
        profile_owner: profile::owner(profile),
        chain,
        wallet_address,
        timestamp: current_time,
    });
}

/// Unlinks a wallet from any chain
public fun unlink_wallet(
    profile: &mut Profile,
    chain: String,
    wallet_address: String,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    assert!(tx_context::sender(ctx) == profile::owner(profile), ESenderNotOwner);
    config::assert_interacting_with_most_up_to_date_package(config);

    profile::remove_wallet_address(profile, chain, wallet_address, config, clock, ctx);

    event::emit(MultiChainWalletUnlinkedEvent {
        profile_id: object::id(profile),
        profile_owner: profile::owner(profile),
        chain,
        wallet_address,
        timestamp: clock::timestamp_ms(clock),
    });
}

// === Helper Functions ===

/// Constructs the message to be signed
/// Format: profile_id || wallet_address || timestamp
fun construct_link_message(profile_id: ID, wallet_address: address, timestamp: u64): vector<u8> {
    let mut message = vector::empty<u8>();

    // Add profile ID
    let profile_id_bytes = object::id_to_bytes(&profile_id);
    vector::append(&mut message, profile_id_bytes);

    // Add wallet address
    let address_bytes = bcs::to_bytes(&wallet_address);
    vector::append(&mut message, address_bytes);

    // Add timestamp
    let timestamp_bytes = bcs::to_bytes(&timestamp);
    vector::append(&mut message, timestamp_bytes);

    message
}

/// Verifies an Ed25519 signature
fun verify_ed25519_signature(
    message: &vector<u8>,
    public_key: &vector<u8>,
    signature: &vector<u8>,
) {
    // Validate lengths
    assert!(vector::length(public_key) == 32, EInvalidMessageFormat);
    assert!(vector::length(signature) == 64, EInvalidMessageFormat);

    // Verify signature
    let is_valid = ed25519::ed25519_verify(
        signature,
        public_key,
        message,
    );

    assert!(is_valid, EInvalidSignature);
}

/// Constructs the message for multi-chain wallet linking
/// Format: profile_id || chain || wallet_address || timestamp
fun construct_multichain_link_message(
    profile_id: ID,
    chain: String,
    wallet_address: String,
    timestamp: u64,
): vector<u8> {
    let mut message = vector::empty<u8>();

    // Add profile ID
    let profile_id_bytes = object::id_to_bytes(&profile_id);
    vector::append(&mut message, profile_id_bytes);

    // Add chain
    let chain_bytes = bcs::to_bytes(&chain);
    vector::append(&mut message, chain_bytes);

    // Add wallet address
    let address_bytes = bcs::to_bytes(&wallet_address);
    vector::append(&mut message, address_bytes);

    // Add timestamp
    let timestamp_bytes = bcs::to_bytes(&timestamp);
    vector::append(&mut message, timestamp_bytes);

    message
}

/// Verifies an ECDSA secp256k1 signature (for Ethereum/Bitcoin wallets)
fun verify_ecdsa_k1_signature(
    message: &vector<u8>,
    public_key: &vector<u8>,
    signature: &vector<u8>,
) {
    // Validate signature length (65 bytes: r || s || v)
    assert!(vector::length(signature) == 65, EInvalidMessageFormat);

    // Hash the message with keccak256 for Ethereum compatibility
    let message_hash = sui::hash::keccak256(message);

    // Verify signature using secp256k1
    let is_valid = ecdsa_k1::secp256k1_verify(
        signature,
        public_key,
        &message_hash,
        1, // KECCAK256 hash function
    );

    assert!(is_valid, EInvalidSignature);
}
