module suins_social_layer::social_layer_constants;

use std::string::{Self as string, String};

// Wallet key constants
const WALLET_KEY_SUI: vector<u8> = b"SUI";
const WALLET_KEY_SOL: vector<u8> = b"SOL";
const WALLET_KEY_ETH: vector<u8> = b"ETH";
const WALLET_KEY_BTC: vector<u8> = b"BTC";

// Social platform constants
const SOCIAL_PLATFORM_TWITTER: vector<u8> = b"twitter";
const SOCIAL_PLATFORM_DISCORD: vector<u8> = b"discord";
const SOCIAL_PLATFORM_TELEGRAM: vector<u8> = b"telegram";
const SOCIAL_PLATFORM_GOOGLE: vector<u8> = b"google";

// Length constants
const DISPLAY_NAME_MIN_LENGTH: u64 = 3;
const DISPLAY_NAME_MAX_LENGTH: u64 = 63;
const BIO_MIN_LENGTH: u64 = 0;
const BIO_MAX_LENGTH: u64 = 200;

// Public getters for wallet keys
public fun wallet_key_sui(): String { string::utf8(WALLET_KEY_SUI) }

public fun wallet_key_sol(): String { string::utf8(WALLET_KEY_SOL) }

public fun wallet_key_eth(): String { string::utf8(WALLET_KEY_ETH) }

public fun wallet_key_btc(): String { string::utf8(WALLET_KEY_BTC) }

// Public getters for social platforms
public fun social_platform_twitter(): String { string::utf8(SOCIAL_PLATFORM_TWITTER) }

public fun social_platform_discord(): String { string::utf8(SOCIAL_PLATFORM_DISCORD) }

public fun social_platform_telegram(): String { string::utf8(SOCIAL_PLATFORM_TELEGRAM) }

public fun social_platform_google(): String { string::utf8(SOCIAL_PLATFORM_GOOGLE) }

// Public getters for length constants
public fun display_name_min_length(): u64 { DISPLAY_NAME_MIN_LENGTH }

public fun display_name_max_length(): u64 { DISPLAY_NAME_MAX_LENGTH }

public fun bio_min_length(): u64 { BIO_MIN_LENGTH }

public fun bio_max_length(): u64 { BIO_MAX_LENGTH }

public fun allowed_wallet_keys(): vector<String> {
    let mut v = vector::empty();
    v.push_back(wallet_key_sui());
    v.push_back(wallet_key_sol());
    v.push_back(wallet_key_eth());
    v.push_back(wallet_key_btc());
    v
}

public fun allowed_social_platforms(): vector<String> {
    let mut v = vector::empty();
    v.push_back(social_platform_twitter());
    v.push_back(social_platform_discord());
    v.push_back(social_platform_telegram());
    v.push_back(social_platform_google());
    v
}
