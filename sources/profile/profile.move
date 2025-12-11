module suins_social_layer::profile;

use std::string::String;
use sui::clock::{Self, Clock};
use sui::dynamic_field as df;
use sui::event;
use sui::table::{Self, Table};
use sui::vec_map::VecMap;
use suins::domain::new;
use suins::registry::has_record;
use suins::suins::SuiNS;
use suins::suins_registration;
use suins::suins_registration::SuinsRegistration;
use suins_social_layer::social_layer_config::{Self as config, Config};
use suins_social_layer::social_layer_registry::{Self, Registry};

#[error]
const EArchivedProfile: u64 = 0;
const ESenderNotOwner: u64 = 1;
const EProfileAlreadyExists: u64 = 2;
const EDisplayNameNotMatching: u64 = 3;
const EDisplayNameTaken: u64 = 4;
const EDisplayNameAlreadyTaken: u64 = 5;
const ESuinsRegistrationExpired: u64 = 6;
const EWalletKeyDoesNotExist: u64 = 7;
const EDisplayNameChangeCooldown: u64 = 8;

// Display name change cooldown: 10 minutes (600,000 milliseconds)
// This prevents shared object contention issues with the Registry
const DISPLAY_NAME_CHANGE_COOLDOWN_MS: u64 = 600000;

public struct Profile has key, store {
    id: UID,
    owner: address,
    display_name: String,
    display_image_url: Option<String>,
    background_image_url: Option<String>,
    url: Option<String>,
    bio: Option<String>,
    social_accounts: VecMap<String, String>,
    wallet_addresses: VecMap<String, vector<String>>,
    following: Table<address, bool>,
    block_list: Table<address, bool>,
    is_archived: bool,
    created_at: u64,
    updated_at: u64,
    last_display_name_change_at: u64,
}

public struct PROFILE has drop {}

fun init(otw: PROFILE, ctx: &mut TxContext) {
    let publisher = sui::package::claim(otw, ctx);
    transfer::public_transfer(publisher, ctx.sender());
}

// === Events ===
public struct DeleteProfileEvent has copy, drop {
    owner: address,
    display_name: String,
    timestamp: u64,
}

public struct UnarchiveProfileEvent has copy, drop {
    profile_id: ID,
    owner: address,
    display_name: String,
    timestamp: u64,
}

public struct ArchiveProfileEvent has copy, drop {
    profile_id: ID,
    owner: address,
    display_name: String,
    timestamp: u64,
}

public struct CreateProfileEvent has copy, drop {
    profile_id: ID,
    owner: address,
    display_name: String,
    timestamp: u64,
    display_image_url: Option<String>,
    background_image_url: Option<String>,
    wallet_addresses: VecMap<String, vector<String>>,
    social_accounts: VecMap<String, String>,
    url: Option<String>,
    bio: Option<String>,
}

public struct UpdateProfileEvent has copy, drop {
    profile_id: ID,
    owner: address,
    display_name: String,
    timestamp: u64,
    display_image_url: Option<String>,
    background_image_url: Option<String>,
    wallet_addresses: VecMap<String, vector<String>>,
    social_accounts: VecMap<String, String>,
    url: Option<String>,
    bio: Option<String>,
}

public struct AddDfToProfileEvent<K: copy + drop + store, V: copy + drop> has copy, drop {
    profile_id: ID,
    owner: address,
    df_key: K,
    df_value: V,
    timestamp: u64,
}

public struct RemoveDfFromProfileEvent<K: copy + drop + store, V: store> has copy, drop {
    profile_id: ID,
    owner: address,
    df_key: K,
    df_value: V,
    timestamp: u64,
}

public struct FollowUserEvent has copy, drop {
    owner: address,
    followed_address: address,
    timestamp: u64,
}

public struct UnfollowUserEvent has copy, drop {
    owner: address,
    unfollowed_address: address,
    timestamp: u64,
}

public struct BlockUserEvent has copy, drop {
    timestamp: u64,
    owner: address,
    blocked_address: address,
}

public struct UnblockUserEvent has copy, drop {
    owner: address,
    unblocked_address: address,
    timestamp: u64,
}

// === Getters ===
public fun display_name(self: &Profile): String {
    assert!(!self.is_archived, EArchivedProfile);
    self.display_name
}

public fun url(self: &Profile): Option<String> {
    assert!(!self.is_archived, EArchivedProfile);
    self.url
}

public fun bio(self: &Profile): Option<String> {
    assert!(!self.is_archived, EArchivedProfile);
    self.bio
}

public fun display_image_url(self: &Profile): Option<String> {
    assert!(!self.is_archived, EArchivedProfile);
    self.display_image_url
}

public fun background_image_url(self: &Profile): Option<String> {
    assert!(!self.is_archived, EArchivedProfile);
    self.background_image_url
}

public fun wallet_addresses(self: &Profile): VecMap<String, vector<String>> {
    assert!(!self.is_archived, EArchivedProfile);
    self.wallet_addresses
}

public fun social_accounts(self: &Profile): VecMap<String, String> {
    assert!(!self.is_archived, EArchivedProfile);
    self.social_accounts
}

public(package) fun get_social_account_username(self: &Profile, platform: &String): Option<String> {
    if (sui::vec_map::contains(&self.social_accounts, platform)) {
        option::some(*sui::vec_map::get(&self.social_accounts, platform))
    } else {
        option::none()
    }
}

public fun owner(self: &Profile): address {
    assert!(!self.is_archived, EArchivedProfile);
    self.owner
}

public fun is_archived(self: &Profile): bool {
    self.is_archived
}

public fun created_at(self: &Profile): u64 {
    assert!(!self.is_archived, EArchivedProfile);
    self.created_at
}

public fun updated_at(self: &Profile): u64 {
    assert!(!self.is_archived, EArchivedProfile);
    self.updated_at
}

public fun uid(self: &Profile): &UID {
    &self.id
}

public fun uid_mut(self: &mut Profile): &mut UID {
    &mut self.id
}

public fun get_df<K: copy + drop + store, V: store + copy + drop>(
    profile: &Profile,
    df_key: K,
): &V {
    df::borrow(&profile.id, df_key)
}

fun assert_display_name_not_taken(display_name: String, suins: &SuiNS) {
    let mut display_name_with_sui = display_name;
    std::string::append(
        &mut display_name_with_sui,
        b".sui".to_string(),
    );
    let domain = new(display_name_with_sui);
    assert!(!has_record(suins.registry(), domain), EDisplayNameTaken);
}

fun assert_display_name_matches_with_suins(
    display_name: String,
    suins_registration: &SuinsRegistration,
) {
    let expected_name = suins_registration.domain().label(1);
    assert!(expected_name == display_name, EDisplayNameNotMatching);
}

// === Setters ===
public(package) fun set_display_name(
    profile: &mut Profile,
    display_name: String,
    suins: &SuiNS,
    registry: &mut Registry,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    assert_display_name_not_taken(display_name, suins);
    set_display_name_helper(profile, display_name, registry, config, clock, ctx);
}

public(package) fun set_display_name_with_suins(
    profile: &mut Profile,
    display_name: String,
    suins_registration: &SuinsRegistration,
    registry: &mut Registry,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    assert!(
        !suins_registration::has_expired(suins_registration, clock),
        ESuinsRegistrationExpired
    );
    assert_display_name_matches_with_suins(display_name, suins_registration);
    set_display_name_helper(profile, display_name, registry, config, clock, ctx);
}

public(package) fun set_display_name_helper(
    profile: &mut Profile,
    display_name: String,
    registry: &mut Registry,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);
    config::assert_display_name_is_valid(config, &display_name);
    assert!(
        !social_layer_registry::get_entry_display_name_registry(registry, display_name),
        EDisplayNameAlreadyTaken,
    );

    // Check cooldown period to prevent shared object contention
    let current_time = clock::timestamp_ms(clock);
    let time_since_last_change = current_time - profile.last_display_name_change_at;
    assert!(time_since_last_change >= DISPLAY_NAME_CHANGE_COOLDOWN_MS, EDisplayNameChangeCooldown);

    social_layer_registry::remove_entry_display_name_registry(registry, profile.display_name);
    social_layer_registry::add_entry_display_name_registry(registry, display_name);
    profile.display_name = display_name;
    profile.updated_at = current_time;
    profile.last_display_name_change_at = current_time;
    emit_update_profile_event(profile, clock);
}

public(package) fun set_bio(
    profile: &mut Profile,
    bio: String,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);
    config::assert_bio_length_is_valid(config, &bio);

    profile.bio = option::some(bio);
    profile.updated_at = clock::timestamp_ms(clock);

    emit_update_profile_event(profile, clock);
}

public(package) fun remove_bio(
    profile: &mut Profile,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

    profile.bio = option::none();
    profile.updated_at = clock::timestamp_ms(clock);

    emit_update_profile_event(profile, clock);
}

public(package) fun set_display_image_url(
    profile: &mut Profile,
    display_image_url: String,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

    profile.display_image_url = option::some(display_image_url);
    profile.updated_at = clock::timestamp_ms(clock);

    emit_update_profile_event(profile, clock);
}

public(package) fun remove_display_image_url(
    profile: &mut Profile,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

    profile.display_image_url = option::none();
    profile.updated_at = clock::timestamp_ms(clock);

    emit_update_profile_event(profile, clock);
}

public(package) fun set_background_image_url(
    profile: &mut Profile,
    background_image_url: String,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

    profile.background_image_url = option::some(background_image_url);
    profile.updated_at = clock::timestamp_ms(clock);

    emit_update_profile_event(profile, clock);
}

public(package) fun remove_background_image_url(
    profile: &mut Profile,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

    profile.background_image_url = option::none();
    profile.updated_at = clock::timestamp_ms(clock);

    emit_update_profile_event(profile, clock);
}

public(package) fun set_url(
    profile: &mut Profile,
    url: String,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

    profile.url = option::some(url);
    profile.updated_at = clock::timestamp_ms(clock);

    emit_update_profile_event(profile, clock);
}

public(package) fun remove_url(
    profile: &mut Profile,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

    profile.url = option::none();
    profile.updated_at = clock::timestamp_ms(clock);

    emit_update_profile_event(profile, clock);
}

public(package) fun add_wallet_address(
    profile: &mut Profile,
    network: String,
    address: String,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);
    config::assert_wallet_key_is_allowed(config, &network);

    if (sui::vec_map::contains(&profile.wallet_addresses, &network)) {
        // Network exists, check if address already linked
        let addresses = sui::vec_map::get_mut(&mut profile.wallet_addresses, &network);
        if (!std::vector::contains(addresses, &address)) {
            std::vector::push_back(addresses, address);
        }
    } else {
        // New network, create vector with this address
        let mut addresses = std::vector::empty<String>();
        std::vector::push_back(&mut addresses, address);
        sui::vec_map::insert(&mut profile.wallet_addresses, network, addresses);
    };

    profile.updated_at = clock::timestamp_ms(clock);

    emit_update_profile_event(profile, clock);
}

public(package) fun remove_wallet_address(
    profile: &mut Profile,
    network: String,
    address: String,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

    config::assert_wallet_key_is_allowed(config, &network);
    assert!(sui::vec_map::contains(&profile.wallet_addresses, &network), EWalletKeyDoesNotExist);

    let addresses = sui::vec_map::get_mut(&mut profile.wallet_addresses, &network);
    let (found, index) = std::vector::index_of(addresses, &address);
    assert!(found, EWalletKeyDoesNotExist);

    std::vector::remove(addresses, index);

    // If no addresses left for this network, remove the network entry
    if (std::vector::is_empty(addresses)) {
        sui::vec_map::remove(&mut profile.wallet_addresses, &network);
    };

    profile.updated_at = clock::timestamp_ms(clock);

    emit_update_profile_event(profile, clock);
}

#[allow(unused_mut_parameter)]
public(package) fun archive_profile(
    profile: &mut Profile,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

    profile.is_archived = true;
    profile.updated_at = clock::timestamp_ms(clock);

    event::emit(ArchiveProfileEvent {
        profile_id: object::id(profile),
        owner: profile.owner,
        display_name: profile.display_name,
        timestamp: clock::timestamp_ms(clock),
    });
}

public(package) fun unarchive_profile(
    profile: &mut Profile,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

    profile.is_archived = false;
    profile.updated_at = clock::timestamp_ms(clock);

    event::emit(UnarchiveProfileEvent {
        profile_id: object::id(profile),
        owner: profile.owner,
        display_name: profile.display_name,
        timestamp: clock::timestamp_ms(clock),
    });
}

public(package) fun delete_profile(
    profile: Profile,
    registry: &mut Registry,
    clock: &Clock,
    ctx: &TxContext,
) {
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);
    social_layer_registry::remove_entries(registry, profile.display_name, profile.owner);

    let Profile {
        id,
        display_name,
        url: _,
        bio: _,
        social_accounts: _,
        is_archived: _,
        created_at: _,
        updated_at: _,
        display_image_url: _,
        background_image_url: _,
        wallet_addresses: _,
        following,
        block_list,
        owner,
        last_display_name_change_at: _,
    } = profile;

    table::drop(following);
    table::drop(block_list);

    event::emit(DeleteProfileEvent {
        owner,
        display_name,
        timestamp: clock::timestamp_ms(clock),
    });

    id.delete();
}

public(package) fun create_profile(
    display_name: String,
    url: Option<String>,
    bio: Option<String>,
    display_image_url: Option<String>,
    background_image_url: Option<String>,
    config: &Config,
    suins: &SuiNS,
    registry: &mut Registry,
    clock: &Clock,
    ctx: &mut TxContext,
): Profile {
    assert_display_name_not_taken(display_name, suins);
    create_profile_helper(
        display_name,
        url,
        bio,
        display_image_url,
        background_image_url,
        config,
        registry,
        clock,
        ctx,
    )
}

public(package) fun create_profile_with_suins(
    display_name: String,
    url: Option<String>,
    bio: Option<String>,
    display_image_url: Option<String>,
    background_image_url: Option<String>,
    suins_registration: &SuinsRegistration,
    config: &Config,
    registry: &mut Registry,
    clock: &Clock,
    ctx: &mut TxContext,
): Profile {
    assert!(
        !suins_registration::has_expired(suins_registration, clock),
        ESuinsRegistrationExpired
    );
    assert_display_name_matches_with_suins(display_name, suins_registration);
    create_profile_helper(
        display_name,
        url,
        bio,
        display_image_url,
        background_image_url,
        config,
        registry,
        clock,
        ctx,
    )
}

public(package) fun create_profile_helper(
    display_name: String,
    url: Option<String>,
    bio: Option<String>,
    display_image_url: Option<String>,
    background_image_url: Option<String>,
    config: &Config,
    registry: &mut Registry,
    clock: &Clock,
    ctx: &mut TxContext,
): Profile {
    config::assert_interacting_with_most_up_to_date_package(config);
    config::assert_display_name_is_valid(config, &display_name);
    if (option::is_some(&bio)) {
        config::assert_bio_length_is_valid(config, option::borrow(&bio));
    };
    assert!(
        !social_layer_registry::get_entry_display_name_registry(registry, display_name),
        EDisplayNameAlreadyTaken,
    );
    assert!(
        !social_layer_registry::get_entry_address_registry(registry, tx_context::sender(ctx)),
        EProfileAlreadyExists,
    );

    let current_time = clock::timestamp_ms(clock);
    let profile = Profile {
        id: object::new(ctx),
        display_name,
        url,
        bio,
        is_archived: false,
        created_at: current_time,
        updated_at: current_time,
        social_accounts: sui::vec_map::empty<String, String>(),
        display_image_url,
        background_image_url,
        wallet_addresses: sui::vec_map::empty<String, vector<String>>(),
        owner: tx_context::sender(ctx),
        following: sui::table::new(ctx),
        block_list: sui::table::new(ctx),
        last_display_name_change_at: current_time,
    };
    social_layer_registry::add_entries(registry, display_name, profile.owner);

    event::emit(CreateProfileEvent {
        profile_id: object::id(&profile),
        owner: tx_context::sender(ctx),
        display_name: profile.display_name,
        timestamp: clock::timestamp_ms(clock),
        display_image_url,
        background_image_url,
        wallet_addresses: sui::vec_map::empty<String, vector<String>>(),
        social_accounts: profile.social_accounts,
        url,
        bio,
    });

    profile
}

public(package) fun add_df_to_profile<K: copy + drop + store, V: store + copy + drop>(
    profile: &mut Profile,
    df_key: K,
    df_value: V,
    clock: &Clock,
) {
    df::add(&mut profile.id, df_key, df_value);
    profile.updated_at = clock::timestamp_ms(clock);
    emit_add_df_to_profile_event(profile, df_key, df_value, clock);
}

public(package) fun remove_df_from_profile<K: copy + drop + store, V: store + copy + drop>(
    profile: &mut Profile,
    df_key: K,
    clock: &Clock,
) {
    let df_value: V = df::remove(&mut profile.id, df_key);
    profile.updated_at = clock::timestamp_ms(clock);
    emit_remove_df_from_profile_event(profile, df_key, df_value, clock);
}

public(package) fun add_df_to_profile_no_event<K: copy + drop + store, V: store + drop>(
    profile: &mut Profile,
    df_key: K,
    df_value: V,
    clock: &Clock,
) {
    df::add(&mut profile.id, df_key, df_value);
    profile.updated_at = clock::timestamp_ms(clock);
}

public(package) fun remove_df_from_profile_no_event<K: copy + drop + store, V: store + drop>(
    profile: &mut Profile,
    df_key: K,
    clock: &Clock,
): V {
    let df_value: V = df::remove(&mut profile.id, df_key);
    profile.updated_at = clock::timestamp_ms(clock);
    df_value
}

// === Follow/Block Functions ===

public(package) fun follow_user(profile: &mut Profile, follow_address: address, clock: &Clock) {
    assert!(!profile.is_archived, EArchivedProfile);
    assert!(follow_address != profile.owner, ESenderNotOwner);

    if (!table::contains(&profile.following, follow_address)) {
        table::add(&mut profile.following, follow_address, true);
        profile.updated_at = clock::timestamp_ms(clock);

        event::emit(FollowUserEvent {
            owner: profile.owner,
            followed_address: follow_address,
            timestamp: clock::timestamp_ms(clock),
        });
    };
}

public(package) fun unfollow_user(profile: &mut Profile, unfollow_address: address, clock: &Clock) {
    assert!(!profile.is_archived, EArchivedProfile);

    if (table::contains(&profile.following, unfollow_address)) {
        table::remove(&mut profile.following, unfollow_address);
        profile.updated_at = clock::timestamp_ms(clock);

        event::emit(UnfollowUserEvent {
            owner: profile.owner,
            unfollowed_address: unfollow_address,
            timestamp: clock::timestamp_ms(clock),
        });
    };
}

public(package) fun block_user(profile: &mut Profile, block_address: address, clock: &Clock) {
    assert!(!profile.is_archived, EArchivedProfile);
    assert!(block_address != profile.owner, ESenderNotOwner);

    if (!table::contains(&profile.block_list, block_address)) {
        table::add(&mut profile.block_list, block_address, true);
        profile.updated_at = clock::timestamp_ms(clock);

        event::emit(BlockUserEvent {
            owner: profile.owner,
            blocked_address: block_address,
            timestamp: clock::timestamp_ms(clock),
        });
    };
}

public(package) fun unblock_user(profile: &mut Profile, unblock_address: address, clock: &Clock) {
    assert!(!profile.is_archived, EArchivedProfile);

    if (table::contains(&profile.block_list, unblock_address)) {
        table::remove(&mut profile.block_list, unblock_address);
        profile.updated_at = clock::timestamp_ms(clock);

        event::emit(UnblockUserEvent {
            owner: profile.owner,
            unblocked_address: unblock_address,
            timestamp: clock::timestamp_ms(clock),
        });
    };
}

public fun is_following(profile: &Profile, address: address): bool {
    assert!(!profile.is_archived, EArchivedProfile);
    table::contains(&profile.following, address)
}

public fun is_blocked(profile: &Profile, address: address): bool {
    assert!(!profile.is_archived, EArchivedProfile);
    table::contains(&profile.block_list, address)
}

#[allow(unused_mut_parameter)]
public(package) fun link_social_account(
    profile: &mut Profile,
    platform: String,
    username: String,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

    config::assert_social_platform_is_allowed(config, &platform);

    sui::vec_map::insert(&mut profile.social_accounts, platform, username);
    profile.updated_at = clock::timestamp_ms(clock);

    emit_update_profile_event(profile, clock);
}

#[allow(unused_mut_parameter)]
public(package) fun unlink_social_account(profile: &mut Profile, platform: &String, config: &Config, clock: &Clock, ctx: &mut TxContext) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

    config::assert_social_platform_is_allowed(config, platform);

    if (sui::vec_map::contains(&profile.social_accounts, platform)) {
        sui::vec_map::remove(&mut profile.social_accounts, platform);
        profile.updated_at = clock::timestamp_ms(clock);

        emit_update_profile_event(profile, clock);
    };
}

fun emit_update_profile_event(profile: &Profile, clock: &Clock) {
    event::emit(UpdateProfileEvent {
        profile_id: object::id(profile),
        owner: profile.owner,
        display_name: profile.display_name,
        timestamp: clock::timestamp_ms(clock),
        display_image_url: profile.display_image_url,
        background_image_url: profile.background_image_url,
        wallet_addresses: profile.wallet_addresses,
        social_accounts: profile.social_accounts,
        url: profile.url,
        bio: profile.bio,
    });
}

fun emit_add_df_to_profile_event<K: copy + drop + store, V: store + copy + drop>(
    profile: &Profile,
    df_key: K,
    df_value: V,
    clock: &Clock,
): V {
    event::emit(AddDfToProfileEvent {
        profile_id: object::id(profile),
        owner: profile.owner,
        timestamp: clock::timestamp_ms(clock),
        df_key,
        df_value,
    });
    df_value
}

fun emit_remove_df_from_profile_event<K: copy + drop + store, V: store + copy + drop>(
    profile: &Profile,
    df_key: K,
    df_value: V,
    clock: &Clock,
) {
    event::emit(RemoveDfFromProfileEvent {
        profile_id: object::id(profile),
        owner: profile.owner,
        timestamp: clock::timestamp_ms(clock),
        df_key,
        df_value,
    });
}
