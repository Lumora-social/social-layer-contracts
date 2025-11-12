module suins_social_layer::social_layer_constants;

use std::string::String;

const SOL: vector<u8> = b"SOL";
const ETH: vector<u8> = b"ETH";
const BTC: vector<u8> = b"BTC";
const SUI: vector<u8> = b"SUI";

public fun display_name_min_length(): u64 { 3 }

public fun display_name_max_length(): u64 { 63 }

public fun bio_min_length(): u64 { 4 }

public fun bio_max_length(): u64 { 200 }

public fun allowed_wallet_keys(): vector<String> {
    let mut v = vector::empty();
    v.push_back(SOL.to_string());
    v.push_back(ETH.to_string());
    v.push_back(BTC.to_string());
    v.push_back(SUI.to_string());
    v
}
