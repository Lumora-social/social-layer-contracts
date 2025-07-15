module suins_social_layer::profile;

use std::string::String;
use sui::clock::{Self, Clock};
use sui::display;
use sui::dynamic_field as df;
use sui::event;
use sui::package;
use suins::domain::new;
use suins::registry::has_record;
use suins::suins::SuiNS;
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

public struct Profile has key, store {
    id: UID,
    owner: address,
    display_name: String,
    display_image_blob_id: Option<String>,
    background_image_blob_id: Option<String>,
    walrus_site_id: Option<String>,
    url: Option<String>,
    bio: Option<String>,
    is_archived: bool,
    created_at: u64,
    updated_at: u64,
}

// OTW for display.
public struct PROFILE has drop {}

fun init(otw: PROFILE, ctx: &mut TxContext) {
    let publisher = package::claim(otw, ctx);
    let mut display = display::new<Profile>(&publisher, ctx);

    // TODO: change to the actual walrus app url
    // display.add(
    //     b"link".to_string(),
    //     b"https://mock.walrus.app/0x{walrus_site_id}".to_string(),
    // );

    display.add(
        b"image_url".to_string(),
        b"https://aggregator.walrus-testnet.walrus.space/v1/blobs/{display_image_blob_id}".to_string(),
    );
    display.update_version();

    transfer::public_transfer(publisher, ctx.sender());
    transfer::public_transfer(display, ctx.sender());
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
    display_image_blob_id: Option<String>,
    background_image_blob_id: Option<String>,
    walrus_site_id: Option<String>,
    url: Option<String>,
    bio: Option<String>,
}

public struct UpdateProfileEvent has copy, drop {
    profile_id: ID,
    owner: address,
    display_name: String,
    timestamp: u64,
    display_image_blob_id: Option<String>,
    background_image_blob_id: Option<String>,
    walrus_site_id: Option<String>,
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

public fun display_image_blob_id(self: &Profile): Option<String> {
    assert!(!self.is_archived, EArchivedProfile);
    self.display_image_blob_id
}

public fun background_image_blob_id(self: &Profile): Option<String> {
    assert!(!self.is_archived, EArchivedProfile);
    self.background_image_blob_id
}

public fun walrus_site_id(self: &Profile): Option<String> {
    assert!(!self.is_archived, EArchivedProfile);
    self.walrus_site_id
}

public fun is_archived(self: &Profile): bool {
    self.is_archived
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

fun emit_update_profile_event(profile: &Profile, clock: &Clock) {
    event::emit(UpdateProfileEvent {
        profile_id: object::id(profile),
        owner: profile.owner,
        display_name: profile.display_name,
        timestamp: clock::timestamp_ms(clock),
        display_image_blob_id: profile.display_image_blob_id,
        background_image_blob_id: profile.background_image_blob_id,
        walrus_site_id: profile.walrus_site_id,
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

    social_layer_registry::remove_entry_display_name_registry(registry, profile.display_name);
    profile.display_name = display_name;
    profile.updated_at = clock::timestamp_ms(clock);
    social_layer_registry::add_entry_display_name_registry(registry, display_name);
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

public(package) fun set_display_image_blob_id(
    profile: &mut Profile,
    display_image_blob_id: String,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

    profile.display_image_blob_id = option::some(display_image_blob_id);
    profile.updated_at = clock::timestamp_ms(clock);

    emit_update_profile_event(profile, clock);
}

public(package) fun remove_display_image_blob_id(
    profile: &mut Profile,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

    profile.display_image_blob_id = option::none();
    profile.updated_at = clock::timestamp_ms(clock);

    emit_update_profile_event(profile, clock);
}

public(package) fun set_background_image_blob_id(
    profile: &mut Profile,
    background_image_blob_id: String,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

    profile.background_image_blob_id = option::some(background_image_blob_id);
    profile.updated_at = clock::timestamp_ms(clock);

    emit_update_profile_event(profile, clock);
}

public(package) fun remove_background_image_blob_id(
    profile: &mut Profile,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

    profile.background_image_blob_id = option::none();
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

public(package) fun set_walrus_site_id(
    profile: &mut Profile,
    walrus_site_id: String,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

    profile.walrus_site_id = option::some(walrus_site_id);
    profile.updated_at = clock::timestamp_ms(clock);

    emit_update_profile_event(profile, clock);
}

public(package) fun remove_walrus_site_id(
    profile: &mut Profile,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

    profile.walrus_site_id = option::none();
    profile.updated_at = clock::timestamp_ms(clock);

    emit_update_profile_event(profile, clock);
}

public(package) fun archive_profile(
    profile: &mut Profile,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
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
        is_archived: _,
        created_at: _,
        updated_at: _,
        display_image_blob_id: _,
        background_image_blob_id: _,
        walrus_site_id: _,
        owner,
    } = profile;

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
    display_image_blob_id: Option<String>,
    background_image_blob_id: Option<String>,
    walrus_site_id: Option<String>,
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
        display_image_blob_id,
        background_image_blob_id,
        walrus_site_id,
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
    display_image_blob_id: Option<String>,
    background_image_blob_id: Option<String>,
    walrus_site_id: Option<String>,
    suins_registration: &SuinsRegistration,
    config: &Config,
    registry: &mut Registry,
    clock: &Clock,
    ctx: &mut TxContext,
): Profile {
    assert_display_name_matches_with_suins(display_name, suins_registration);
    create_profile_helper(
        display_name,
        url,
        bio,
        display_image_blob_id,
        background_image_blob_id,
        walrus_site_id,
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
    display_image_blob_id: Option<String>,
    background_image_blob_id: Option<String>,
    walrus_site_id: Option<String>,
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

    let profile = Profile {
        id: object::new(ctx),
        display_name,
        url,
        bio,
        is_archived: false,
        created_at: clock::timestamp_ms(clock),
        updated_at: clock::timestamp_ms(clock),
        display_image_blob_id,
        background_image_blob_id,
        walrus_site_id,
        owner: tx_context::sender(ctx),
    };
    social_layer_registry::add_entries(registry, display_name, profile.owner);

    event::emit(CreateProfileEvent {
        profile_id: object::id(&profile),
        display_name: profile.display_name,
        timestamp: clock::timestamp_ms(clock),
        display_image_blob_id,
        background_image_blob_id,
        walrus_site_id,
        bio,
        url,
        owner: tx_context::sender(ctx),
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
