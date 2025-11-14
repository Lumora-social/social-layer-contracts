module suins_social_layer::social_layer_constants;

use std::string::String;

const SOLANA: vector<u8> = b"SOL";
const ETHEREUM: vector<u8> = b"ETH";
const BITCOIN: vector<u8> = b"BTC";

public fun display_name_min_length(): u64 { 3 }

public fun display_name_max_length(): u64 { 63 }

public fun bio_min_length(): u64 { 0 }

public fun bio_max_length(): u64 { 200 }

public fun allowed_wallet_keys(): vector<String> {
    let mut v = vector::empty();
    v.push_back(SOLANA.to_string());
    v.push_back(ETHEREUM.to_string());
    v.push_back(BITCOIN.to_string());
    v
}
