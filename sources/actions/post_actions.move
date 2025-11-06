module suins_social_layer::post_actions;

use std::string::String;
use sui::clock::Clock;
use suins_social_layer::post::{Self, Post, Like, Repost};
use suins_social_layer::social_layer_config::Config;

/// Creates a new post with content and optional attachments
#[allow(lint(self_transfer))]
public fun create_post(
    content: String,
    attachment_ids: vector<String>,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let post = post::create_post(
        content,
        attachment_ids,
        config,
        clock,
        ctx,
    );

    transfer::public_transfer(post, tx_context::sender(ctx));
}

/// Updates an existing post's content and attachments
public fun update_post(
    post: &mut Post,
    content: String,
    attachment_ids: vector<String>,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    post::update_post(
        post,
        content,
        attachment_ids,
        config,
        clock,
        ctx,
    );
}

/// Permanently deletes a post
public fun delete_post(post: Post, clock: &Clock, ctx: &mut TxContext) {
    post::delete_post(
        post,
        clock,
        ctx,
    );
}

/// Likes a post by creating a Like object owned by the liker
/// No contention - creates independent owned object
#[allow(lint(self_transfer))]
public fun like_post(post_id: ID, post_owner: address, clock: &Clock, ctx: &mut TxContext) {
    let like = post::create_like(
        post_id,
        post_owner,
        clock,
        ctx,
    );

    transfer::public_transfer(like, tx_context::sender(ctx));
}

/// Unlikes a post by deleting the user's Like object
/// User must provide their own Like object
public fun unlike_post(like: Like, clock: &Clock, ctx: &mut TxContext) {
    post::delete_like(
        like,
        clock,
        ctx,
    );
}

/// Reposts a post by creating a Repost object owned by the reposter
/// No contention - creates independent owned object
#[allow(lint(self_transfer))]
public fun repost(
    original_post_id: ID,
    original_owner: address,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let repost = post::create_repost(
        original_post_id,
        original_owner,
        clock,
        ctx,
    );

    transfer::public_transfer(repost, tx_context::sender(ctx));
}

/// Creates a reply to a post
/// Event-only tracking - no count updates on original post
#[allow(lint(self_transfer))]
public fun create_reply(
    original_post_id: ID,
    original_owner: address,
    content: String,
    attachment_ids: vector<String>,
    config: &Config,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // Create the reply post
    let reply_post = post::create_post(
        content,
        attachment_ids,
        config,
        clock,
        ctx,
    );

    // Emit reply event for indexer to track
    post::emit_reply_event(
        object::id(&reply_post),
        original_post_id,
        original_owner,
        clock,
        ctx,
    );

    transfer::public_transfer(reply_post, tx_context::sender(ctx));
}
