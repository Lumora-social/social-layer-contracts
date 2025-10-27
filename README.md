# SuiNS Social Layer Contracts

This repository contains Move smart contracts for the SuiNS Social Layer, providing a decentralized social networking infrastructure on Sui blockchain.

## Overview

The SuiNS Social Layer consists of several interconnected modules:

- **Profile Management** - User profiles with customizable metadata
- **Post System** - Twitter-like posting with parallelism-optimized interactions
- **Social Verification** - Oracle-based verification of external social accounts
- **Profile Badges** - Achievement badges based on on-chain activity

## Architecture Highlights

### Parallelism-First Design

All modules are designed to maximize transaction parallelism on Sui:

- **Owned Objects** - Posts, Likes, and Reposts are owned by individual users
- **Event-Driven Indexing** - Counts and aggregations tracked off-chain via events
- **No Shared Object Contention** - Zero bottlenecks for concurrent user actions

This architecture enables thousands of users to interact simultaneously without waiting for each other's transactions.

## Modules

### Profile Actions Module

Entry functions for managing social profiles on the SuiNS Social Layer.

#### Profile Creation

- `create_profile` - Creates a new profile with basic information
- `create_profile_with_suins` - Creates a new profile with SuiNS registration

#### Profile Updates

- `set_display_name` - Updates the display name of an existing profile
- `set_display_name_with_suins` - Updates the display name with SuiNS registration
- `set_bio` - Sets the bio text for a profile
- `remove_bio` - Removes the bio text from a profile
- `set_display_image_url` - Sets the display image URL for a profile
- `remove_display_image_url` - Removes the display image URL from a profile
- `set_background_image_url` - Sets the background image URL for a profile
- `remove_background_image_url` - Removes the background image URL from a profile
- `set_url` - Sets the URL for a profile
- `remove_url` - Removes the URL from a profile

#### Wallet Management

- `add_wallet_address` - Adds a wallet address to a profile
- `update_wallet_address` - Updates an existing wallet address on a profile
- `remove_wallet_address` - Removes a wallet address from a profile

#### Profile Lifecycle

- `archive_profile` - Archives a profile (marks as inactive)
- `unarchive_profile` - Unarchives a profile (marks as active)
- `delete_profile` - Permanently deletes a profile

#### Dynamic Fields

- `add_df_to_profile` - Adds a dynamic field to a profile
- `remove_df_from_profile` - Removes a dynamic field from a profile
- `add_df_to_profile_no_event` - Adds a dynamic field to a profile without emitting events
- `remove_df_from_profile_no_event` - Removes a dynamic field from a profile without emitting events

### Post Actions Module

Entry functions for creating and interacting with posts in a Twitter-like social feed.

**Design Philosophy:** This module is optimized for Sui's parallel execution model. All interactions create owned objects rather than modifying shared state, eliminating contention bottlenecks.

#### Post Management

- `create_post(content, attachment_ids, config, clock)` - Creates a new post owned by the sender
  - **Returns:** Post object transferred to sender
  - **Parallelism:** ✅ Fully parallel, no contention

- `update_post(post, content, attachment_ids, config, clock)` - Updates an existing post
  - **Requires:** User must own the post object
  - **Parallelism:** ✅ Fully parallel, operates on owned object

- `delete_post(post, clock)` - Permanently deletes a post
  - **Requires:** User must own the post object
  - **Parallelism:** ✅ Fully parallel, operates on owned object

#### Post Interactions

All interaction functions create independent owned objects, enabling unlimited parallelism:

- `like_post(post_id, post_owner, clock)` - Likes a post
  - **Creates:** Like object owned by liker
  - **Parameters:** Post ID and owner address (no object reference needed)
  - **Parallelism:** ✅ Perfect - thousands of users can like simultaneously
  - **Event:** Emits `LikePostEvent` for indexer to track count

- `unlike_post(like, clock)` - Unlikes a post
  - **Deletes:** User's Like object
  - **Requires:** User must own the Like object
  - **Parallelism:** ✅ Fully parallel, operates on owned object
  - **Event:** Emits `UnlikePostEvent` for indexer to decrement count

- `repost(original_post_id, original_owner, clock)` - Reposts a post
  - **Creates:** Repost object owned by reposter
  - **Parameters:** Original post ID and owner address
  - **Parallelism:** ✅ Perfect - thousands of users can repost simultaneously
  - **Event:** Emits `RepostEvent` for indexer to track count

- `create_reply(original_post_id, original_owner, content, attachment_ids, config, clock)` - Replies to a post
  - **Creates:** Reply post owned by sender
  - **Parameters:** Original post ID and owner address
  - **Parallelism:** ✅ Perfect - no updates to original post
  - **Event:** Emits `ReplyEvent` for indexer to track count

#### Data Model

**Post Object** (owned by creator):
```move
struct Post {
    id: UID,
    owner: address,
    content: String,
    attachment_ids: vector<String>,
    is_deleted: bool,
    created_at: u64,
    updated_at: u64,
}
```

**Like Object** (owned by liker):
```move
struct Like {
    id: UID,
    post_id: ID,           // Reference to liked post
    post_owner: address,    // Original post owner
    liker: address,         // Who created this like
    created_at: u64,
}
```

**Repost Object** (owned by reposter):
```move
struct Repost {
    id: UID,
    original_post_id: ID,      // Reference to reposted post
    original_owner: address,    // Original post owner
    reposter: address,          // Who created this repost
    created_at: u64,
}
```

#### Why This Design?

Traditional social media designs on blockchain often use shared objects with counters (likes_count, repost_count). This creates severe contention:

❌ **Bad Design (Contention):**
```move
// DON'T DO THIS - causes bottleneck
struct Post {
    likes: Table<address, bool>,  // Shared state
    likes_count: u64,              // Requires exclusive access
}
```
Problem: When 1000 users try to like the same post, they must wait in sequence.

✅ **Good Design (Parallelism):**
```move
// DO THIS - enables parallelism
struct Like {
    post_id: ID,  // Just a reference, no exclusive access needed
}
```
Solution: Each user creates their own Like object. All 1000 transactions execute in parallel.

The indexer aggregates events to provide counts for the frontend, giving users a Twitter-like experience while maintaining blockchain scalability.
