module suins_social_layer::profile {
    use sui::event;
    use sui::clock::{Self, Clock};

    use std::string::{String};
    use suins_social_layer::social_layer_config::Self as config;
    use suins_social_layer::social_layer_config::Config;
    use suins::suins_registration::SuinsRegistration;

    #[error]
    const EArchivedProfile: u64 = 0;
    const ESenderNotOwner: u64 = 1;
    const EUserNameInvalid: u64 = 2; //TODO: Unique error codes everywhere?

    //TODO: Convert to url instead of string here?
    public struct Profile has key, store {
        id: UID,
        owner: address, //TODO: Will cause issue if the owner changes? Multiple addrresses?
        display_name: String,
        user_name: String,
        image_url: Option<String>,
        url: Option<String>,
        bio: Option<String>,
        is_archived: bool,
        created_at: u64,
        updated_at: u64,
    }

    public struct DeleteProfileEvent has copy, drop {
        user_name: String,
        owner: address,
        display_name: String,
        timestamp: u64,
    }

    public struct UnarchiveProfileEvent has copy, drop {
        profile_id: ID,
        user_name: String,
        owner: address,
        display_name: String,
        timestamp: u64,
    }

    public struct ArchiveProfileEvent has copy, drop {
        profile_id: ID,
        user_name: String,
        owner: address,
        display_name: String,
        timestamp: u64,
    }

    public struct CreateProfileEvent has copy, drop {
        profile_id: ID,
        user_name: String,
        owner: address,
        display_name: String,
        timestamp: u64,
        image_url: Option<String>,
        url: Option<String>,
        bio: Option<String>,
    }

    public struct UpdateProfileEvent has copy, drop {
        profile_id: ID,
        user_name: String,
        owner: address,
        display_name: String,
        timestamp: u64,
        image_url: Option<String>,
        url: Option<String>,
        bio: Option<String>,
    }

    // === Getters ===
    public fun display_name(self: &Profile): String {
        assert!(!self.is_archived, EArchivedProfile);
        self.display_name
    }

    public fun user_name(self: &Profile): String {
        assert!(!self.is_archived, EArchivedProfile);
        self.user_name
    }

    public fun url(self: &Profile): Option<String> {
        assert!(!self.is_archived, EArchivedProfile);
        self.url
    }

    public fun bio(self: &Profile): Option<String> {
        assert!(!self.is_archived, EArchivedProfile);
        self.bio
    }

    public fun image_url(self: &Profile): Option<String> {
        assert!(!self.is_archived, EArchivedProfile);
        self.image_url
    }

    public fun is_archived(self: &Profile): bool {
        self.is_archived
    }

    fun emit_update_profile_event(
        profile: &Profile,
        clock: &Clock,
    ) {
        event::emit(UpdateProfileEvent {
            profile_id: object::id(profile),
            user_name: profile.user_name,
            owner: profile.owner,
            display_name: profile.display_name,
            timestamp: clock::timestamp_ms(clock),
            image_url: profile.image_url,
            url: profile.url,
            bio: profile.bio,
        });
    }

    // === Setters ===
    public(package) fun set_display_name(
        profile: &mut Profile, 
        display_name: String,
        config: &Config,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        config::assert_interacting_with_most_up_to_date_package(config);
        assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);
        config::assert_display_name_length_is_valid(config, &display_name);

        profile.display_name = display_name;
        profile.updated_at = clock::timestamp_ms(clock);

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

    public(package) fun set_image_url(
        profile: &mut Profile,
        image_url: String,
        config: &Config,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        config::assert_interacting_with_most_up_to_date_package(config);
        assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

        profile.image_url = option::some(image_url);
        profile.updated_at = clock::timestamp_ms(clock);

        emit_update_profile_event(profile, clock);
    }

    public(package) fun remove_image_url(
        profile: &mut Profile,
        config: &Config,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        config::assert_interacting_with_most_up_to_date_package(config);
        assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

        profile.image_url = option::none();
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

    public fun archive_profile(
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
            user_name: profile.user_name,
            owner: profile.owner,
            display_name: profile.display_name,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    public fun unarchive_profile(
        profile: &mut Profile,
        config: &Config,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        config::assert_interacting_with_most_up_to_date_package(config);
        assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

        profile.is_archived = false;
        profile.updated_at = clock::timestamp_ms(clock);

        event::emit(UnarchiveProfileEvent {
            profile_id: object::id(profile),
            user_name: profile.user_name,
            owner: profile.owner,
            display_name: profile.display_name,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    public fun delete_profile(
        profile: Profile,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        assert!(tx_context::sender(ctx) == profile.owner, ESenderNotOwner);

        let Profile {
            id,
            display_name,
            user_name,
            url: _,
            bio: _,
            is_archived: _,
            created_at: _,
            updated_at: _,
            image_url: _,
            owner,
        } = profile;

        event::emit(DeleteProfileEvent {
            user_name,
            owner,
            display_name,
            timestamp: clock::timestamp_ms(clock),
        });

        id.delete();
    }

    public(package) fun create_profile(
        user_name: String,
        display_name: String,
        url: Option<String>,
        bio: Option<String>,
        image_url: Option<String>,
        suins_registration: &SuinsRegistration,
        config: &Config,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Profile {
        config::assert_interacting_with_most_up_to_date_package(config);
        config::assert_display_name_length_is_valid(config, &display_name);

        if(option::is_some(&bio)) {
            config::assert_bio_length_is_valid(config, option::borrow(&bio));
        };

        assert!(suins_registration.domain_name() == user_name, EUserNameInvalid);
        let profile = Profile {
            id: object::new(ctx),
            display_name,
            user_name,
            url,
            bio,
            is_archived: false,
            created_at: clock::timestamp_ms(clock),
            updated_at: clock::timestamp_ms(clock),
            image_url,
            owner: tx_context::sender(ctx),
        };

        event::emit(CreateProfileEvent {
            profile_id: object::id(&profile),
            user_name: profile.user_name,
            display_name: profile.display_name,
            timestamp: clock::timestamp_ms(clock),
            image_url,
            bio,
            url,
            owner: tx_context::sender(ctx),
        });

        profile
    }
}