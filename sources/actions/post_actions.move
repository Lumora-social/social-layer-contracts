module suins_social_layer::post_actions;

use std::string::String;
use sui::clock::Clock;
use suins_social_layer::post::{Self, Post};
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

/// Likes a post
public fun like_post(post: &mut Post, clock: &Clock, ctx: &mut TxContext) {
    post::like_post(
        post,
        clock,
        ctx,
    );
}

/// Unlikes a post
public fun unlike_post(post: &mut Post, clock: &Clock, ctx: &mut TxContext) {
    post::unlike_post(
        post,
        clock,
        ctx,
    );
}

/// Reposts a post (increments repost count on original)
public fun repost(original_post: &mut Post, clock: &Clock, ctx: &mut TxContext) {
    post::increment_repost_count(
        original_post,
        clock,
        ctx,
    );
}

/// Creates a reply to a post (increments reply count on original)
#[allow(lint(self_transfer))]
public fun create_reply(
    original_post: &mut Post,
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

    // Increment reply count on original post
    post::increment_reply_count(
        original_post,
        object::id(&reply_post),
        clock,
        ctx,
    );

    transfer::public_transfer(reply_post, tx_context::sender(ctx));
}
