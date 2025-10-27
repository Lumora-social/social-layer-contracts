module suins_social_layer::post;

use std::string::String;
use sui::clock::{Self, Clock};
use sui::event;
use suins_social_layer::social_layer_config::{Self as config, Config};

#[error]
const ESenderNotOwner: u64 = 0;
const EPostDeleted: u64 = 1;
const EContentTooLong: u64 = 2;
const ETooManyAttachments: u64 = 3;

// Constants for validation
const MAX_CONTENT_LENGTH: u64 = 5000;
const MAX_ATTACHMENTS: u64 = 10;

/// Post object - owned by creator, no contention
/// All interactions (likes, reposts, replies) are separate owned objects
public struct Post has key, store {
    id: UID,
    owner: address,
    content: String,
    attachment_ids: vector<String>,
    is_deleted: bool,
    created_at: u64,
    updated_at: u64,
}

/// Like object - owned by liker, references post
/// Enables parallel likes without contention
public struct Like has key, store {
    id: UID,
    post_id: ID,
    post_owner: address,
    liker: address,
    created_at: u64,
}

/// Repost object - owned by reposter, references original post
/// Enables parallel reposts without contention
public struct Repost has key, store {
    id: UID,
    original_post_id: ID,
    original_owner: address,
    reposter: address,
    created_at: u64,
}

public struct POST has drop {}

fun init(otw: POST, ctx: &mut TxContext) {
    let publisher = sui::package::claim(otw, ctx);
    let mut display = sui::display::new<Post>(&publisher, ctx);

    display.add(
        b"content".to_string(),
        b"{content}".to_string(),
    );
    display.update_version();

    transfer::public_transfer(publisher, ctx.sender());
    transfer::public_transfer(display, ctx.sender());
}

// === Events ===
public struct CreatePostEvent has copy, drop {
    post_id: ID,
    owner: address,
    content: String,
    attachment_ids: vector<String>,
    timestamp: u64,
}

public struct DeletePostEvent has copy, drop {
    post_id: ID,
    owner: address,
    timestamp: u64,
}

public struct UpdatePostEvent has copy, drop {
    post_id: ID,
    owner: address,
    content: String,
    attachment_ids: vector<String>,
    timestamp: u64,
}

public struct LikePostEvent has copy, drop {
    post_id: ID,
    liker: address,
    post_owner: address,
    timestamp: u64,
}

public struct UnlikePostEvent has copy, drop {
    post_id: ID,
    unliker: address,
    post_owner: address,
    timestamp: u64,
}

public struct RepostEvent has copy, drop {
    original_post_id: ID,
    reposter: address,
    original_owner: address,
    timestamp: u64,
}

public struct ReplyEvent has copy, drop {
    reply_post_id: ID,
    original_post_id: ID,
    replier: address,
    original_owner: address,
    timestamp: u64,
}

// === Post Getters ===
public fun owner(self: &Post): address {
    assert!(!self.is_deleted, EPostDeleted);
    self.owner
}

public fun content(self: &Post): String {
    assert!(!self.is_deleted, EPostDeleted);
    self.content
}

public fun attachment_ids(self: &Post): vector<String> {
    assert!(!self.is_deleted, EPostDeleted);
    self.attachment_ids
}

public fun created_at(self: &Post): u64 {
    assert!(!self.is_deleted, EPostDeleted);
    self.created_at
}

public fun updated_at(self: &Post): u64 {
    assert!(!self.is_deleted, EPostDeleted);
    self.updated_at
}

public fun is_deleted(self: &Post): bool {
    self.is_deleted
}

public fun uid(self: &Post): &UID {
    &self.id
}

// === Like Getters ===
public fun like_post_id(self: &Like): ID {
    self.post_id
}

public fun like_post_owner(self: &Like): address {
    self.post_owner
}

public fun liker(self: &Like): address {
    self.liker
}

public fun like_created_at(self: &Like): u64 {
    self.created_at
}

// === Repost Getters ===
public fun repost_original_post_id(self: &Repost): ID {
    self.original_post_id
}

public fun repost_original_owner(self: &Repost): address {
    self.original_owner
}

public fun reposter(self: &Repost): address {
    self.reposter
}

public fun repost_created_at(self: &Repost): u64 {
    self.created_at
}

fun emit_update_post_event(post: &Post, clock: &Clock) {
    event::emit(UpdatePostEvent {
        post_id: object::id(post),
        owner: post.owner,
        content: post.content,
        attachment_ids: post.attachment_ids,
        timestamp: clock::timestamp_ms(clock),
    });
}

// === Validation ===
fun assert_content_valid(content: &String) {
    let length = std::string::length(content);
    assert!(length > 0 && length <= MAX_CONTENT_LENGTH, EContentTooLong);
}

fun assert_attachments_valid(attachments: &vector<String>) {
    assert!(vector::length(attachments) <= MAX_ATTACHMENTS, ETooManyAttachments);
}

// === Post Core Functions ===
public(package) fun create_post(
    content: String,
    attachment_ids: vector<String>,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
): Post {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert_content_valid(&content);
    assert_attachments_valid(&attachment_ids);

    let post = Post {
        id: object::new(ctx),
        owner: tx_context::sender(ctx),
        content,
        attachment_ids,
        is_deleted: false,
        created_at: clock::timestamp_ms(clock),
        updated_at: clock::timestamp_ms(clock),
    };

    event::emit(CreatePostEvent {
        post_id: object::id(&post),
        owner: post.owner,
        content: post.content,
        attachment_ids: post.attachment_ids,
        timestamp: clock::timestamp_ms(clock),
    });

    post
}

public(package) fun update_post(
    post: &mut Post,
    content: String,
    attachment_ids: vector<String>,
    config: &Config,
    clock: &Clock,
    ctx: &TxContext,
) {
    config::assert_interacting_with_most_up_to_date_package(config);
    assert!(tx_context::sender(ctx) == post.owner, ESenderNotOwner);
    assert!(!post.is_deleted, EPostDeleted);
    assert_content_valid(&content);
    assert_attachments_valid(&attachment_ids);

    post.content = content;
    post.attachment_ids = attachment_ids;
    post.updated_at = clock::timestamp_ms(clock);

    emit_update_post_event(post, clock);
}

public(package) fun delete_post(
    post: Post,
    clock: &Clock,
    ctx: &TxContext,
) {
    assert!(tx_context::sender(ctx) == post.owner, ESenderNotOwner);

    let Post {
        id,
        owner,
        content: _,
        attachment_ids: _,
        is_deleted: _,
        created_at: _,
        updated_at: _,
    } = post;

    event::emit(DeletePostEvent {
        post_id: object::id_from_address(id.to_address()),
        owner,
        timestamp: clock::timestamp_ms(clock),
    });

    id.delete();
}

// === Like Functions ===
/// Creates a new Like object owned by the liker
/// No contention - each like is an independent owned object
public(package) fun create_like(
    post_id: ID,
    post_owner: address,
    clock: &Clock,
    ctx: &mut TxContext,
): Like {
    let liker = tx_context::sender(ctx);
    let timestamp = clock::timestamp_ms(clock);

    let like = Like {
        id: object::new(ctx),
        post_id,
        post_owner,
        liker,
        created_at: timestamp,
    };

    event::emit(LikePostEvent {
        post_id,
        liker,
        post_owner,
        timestamp,
    });

    like
}

/// Deletes a Like object
/// User provides their own Like object to delete
public(package) fun delete_like(
    like: Like,
    clock: &Clock,
    ctx: &TxContext,
) {
    assert!(tx_context::sender(ctx) == like.liker, ESenderNotOwner);

    let Like {
        id,
        post_id,
        post_owner,
        liker,
        created_at: _,
    } = like;

    event::emit(UnlikePostEvent {
        post_id,
        unliker: liker,
        post_owner,
        timestamp: clock::timestamp_ms(clock),
    });

    id.delete();
}

// === Repost Functions ===
/// Creates a new Repost object owned by the reposter
/// No contention - each repost is an independent owned object
public(package) fun create_repost(
    original_post_id: ID,
    original_owner: address,
    clock: &Clock,
    ctx: &mut TxContext,
): Repost {
    let reposter = tx_context::sender(ctx);
    let timestamp = clock::timestamp_ms(clock);

    let repost = Repost {
        id: object::new(ctx),
        original_post_id,
        original_owner,
        reposter,
        created_at: timestamp,
    };

    event::emit(RepostEvent {
        original_post_id,
        reposter,
        original_owner,
        timestamp,
    });

    repost
}

// === Reply Functions ===
/// Emits a reply event
/// Replies are tracked as events only, no count updates on original post
public(package) fun emit_reply_event(
    reply_post_id: ID,
    original_post_id: ID,
    original_owner: address,
    clock: &Clock,
    ctx: &TxContext,
) {
    event::emit(ReplyEvent {
        reply_post_id,
        original_post_id,
        replier: tx_context::sender(ctx),
        original_owner,
        timestamp: clock::timestamp_ms(clock),
    });
}
