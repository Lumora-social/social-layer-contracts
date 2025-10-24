module suins_social_layer::post;

use std::string::String;
use sui::clock::{Self, Clock};
use sui::event;
use sui::table::{Self, Table};
use suins_social_layer::social_layer_config::{Self as config, Config};

#[error]
const ESenderNotOwner: u64 = 0;
const EPostDeleted: u64 = 1;
const EContentTooLong: u64 = 2;
const ETooManyAttachments: u64 = 3;

// Constants for validation
const MAX_CONTENT_LENGTH: u64 = 5000;
const MAX_ATTACHMENTS: u64 = 10;

public struct Post has key, store {
    id: UID,
    owner: address,
    content: String,
    attachment_ids: vector<String>,
    likes: Table<address, bool>,
    likes_count: u64,
    repost_count: u64,
    reply_count: u64,
    is_deleted: bool,
    created_at: u64,
    updated_at: u64,
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

// === Getters ===
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

public fun likes_count(self: &Post): u64 {
    assert!(!self.is_deleted, EPostDeleted);
    self.likes_count
}

public fun repost_count(self: &Post): u64 {
    assert!(!self.is_deleted, EPostDeleted);
    self.repost_count
}

public fun reply_count(self: &Post): u64 {
    assert!(!self.is_deleted, EPostDeleted);
    self.reply_count
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

public fun has_liked(self: &Post, address: address): bool {
    assert!(!self.is_deleted, EPostDeleted);
    table::contains(&self.likes, address)
}

public fun uid(self: &Post): &UID {
    &self.id
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

// === Core Functions ===
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
        likes: sui::table::new(ctx),
        likes_count: 0,
        repost_count: 0,
        reply_count: 0,
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
        likes,
        likes_count: _,
        repost_count: _,
        reply_count: _,
        is_deleted: _,
        created_at: _,
        updated_at: _,
    } = post;

    table::drop(likes);

    event::emit(DeletePostEvent {
        post_id: object::id_from_address(id.to_address()),
        owner,
        timestamp: clock::timestamp_ms(clock),
    });

    id.delete();
}

public(package) fun like_post(
    post: &mut Post,
    clock: &Clock,
    ctx: &TxContext,
) {
    assert!(!post.is_deleted, EPostDeleted);
    let liker = tx_context::sender(ctx);

    if (!table::contains(&post.likes, liker)) {
        table::add(&mut post.likes, liker, true);
        post.likes_count = post.likes_count + 1;
        post.updated_at = clock::timestamp_ms(clock);

        event::emit(LikePostEvent {
            post_id: object::id(post),
            liker,
            post_owner: post.owner,
            timestamp: clock::timestamp_ms(clock),
        });
    };
}

public(package) fun unlike_post(
    post: &mut Post,
    clock: &Clock,
    ctx: &TxContext,
) {
    assert!(!post.is_deleted, EPostDeleted);
    let unliker = tx_context::sender(ctx);

    if (table::contains(&post.likes, unliker)) {
        table::remove(&mut post.likes, unliker);
        post.likes_count = post.likes_count - 1;
        post.updated_at = clock::timestamp_ms(clock);

        event::emit(UnlikePostEvent {
            post_id: object::id(post),
            unliker,
            post_owner: post.owner,
            timestamp: clock::timestamp_ms(clock),
        });
    };
}

public(package) fun increment_repost_count(
    post: &mut Post,
    clock: &Clock,
    ctx: &TxContext,
) {
    assert!(!post.is_deleted, EPostDeleted);
    post.repost_count = post.repost_count + 1;
    post.updated_at = clock::timestamp_ms(clock);

    event::emit(RepostEvent {
        original_post_id: object::id(post),
        reposter: tx_context::sender(ctx),
        original_owner: post.owner,
        timestamp: clock::timestamp_ms(clock),
    });
}

public(package) fun increment_reply_count(
    post: &mut Post,
    reply_post_id: ID,
    clock: &Clock,
    ctx: &TxContext,
) {
    assert!(!post.is_deleted, EPostDeleted);
    post.reply_count = post.reply_count + 1;
    post.updated_at = clock::timestamp_ms(clock);

    event::emit(ReplyEvent {
        reply_post_id,
        original_post_id: object::id(post),
        replier: tx_context::sender(ctx),
        original_owner: post.owner,
        timestamp: clock::timestamp_ms(clock),
    });
}
