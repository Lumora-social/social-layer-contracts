# Profile Actions Module

This module contains entry functions for managing social profiles on the SuiNS Social Layer. It provides a comprehensive set of operations for creating, updating, and managing user profiles.

## Overview

The `profile_actions` module serves as the public interface for profile management operations. All functions are marked as `public entry` functions, making them callable from transactions.

## Functions

### Profile Creation

- `create_profile` - Creates a new profile with basic information
- `create_profile_with_suins` - Creates a new profile with SuiNS registration

### Profile Updates

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

### Wallet Management

- `add_wallet_address` - Adds a wallet address to a profile
- `update_wallet_address` - Updates an existing wallet address on a profile
- `remove_wallet_address` - Removes a wallet address from a profile

### Profile Lifecycle

- `archive_profile` - Archives a profile (marks as inactive)
- `unarchive_profile` - Unarchives a profile (marks as active)
- `delete_profile` - Permanently deletes a profile

### Dynamic Fields

- `add_df_to_profile` - Adds a dynamic field to a profile
- `remove_df_from_profile` - Removes a dynamic field from a profile
- `add_df_to_profile_no_event` - Adds a dynamic field to a profile without emitting events
- `remove_df_from_profile_no_event` - Removes a dynamic field from a profile without emitting events
