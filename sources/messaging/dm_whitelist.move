module suins_social_layer::dm_whitelist;

use sui::clock::{Self, Clock};
use sui::event;

const ENoAccess: u64 = 1;
const EWrongVersion: u64 = 2;

const VERSION: u64 = 1;

// === Events ===
public struct CreateDMWhitelistEvent has copy, drop {
    conversation_id: ID,
    sender: address,
    receiver: address,
    timestamp: u64,
}

// public struct DeleteDMWhitelistEvent has copy, drop {
//     conversation_id: ID,
//     sender: address,
//     receiver: address,
//     timestamp: u64,
// }

public struct DM_Whitelist has key {
    id: UID,
    version: u64,
    sender: address,
    receiver: address,
}

// === Event Emitters ===
fun emit_create_dm_whitelist_event(wl: &DM_Whitelist, timestamp: u64) {
    event::emit(CreateDMWhitelistEvent {
        conversation_id: object::uid_to_inner(&wl.id),
        sender: wl.sender,
        receiver: wl.receiver,
        timestamp: timestamp,
    });
}

public fun create_dm_whitelist(ctx: &mut TxContext, receiver: address): DM_Whitelist {
    let wl = DM_Whitelist {
        id: object::new(ctx),
        version: VERSION,
        sender: ctx.sender(),
        receiver: receiver,
    };
    wl
}

public fun share_dm_whitelist(wl: DM_Whitelist) {
    transfer::share_object(wl);
}

public fun sender(wl: &DM_Whitelist): address {
    wl.sender
}

public fun receiver(wl: &DM_Whitelist): address {
    wl.receiver
}

public fun create_dm_whitelist_entry(receiver: address, clock: &Clock, ctx: &mut TxContext) {
    let wl = create_dm_whitelist(ctx, receiver);
    emit_create_dm_whitelist_event(&wl, clock::timestamp_ms(clock));
    share_dm_whitelist(wl);
}

fun check_policy(caller: address, id: vector<u8>, wl: &DM_Whitelist): bool {
    assert!(wl.version == VERSION, EWrongVersion);

    // Check if the id has the right prefix
    let prefix = wl.id.to_bytes();
    let mut i = 0;
    if (prefix.length() > id.length()) {
        return false
    };
    while (i < prefix.length()) {
        if (prefix[i] != id[i]) {
            return false
        };
        i = i + 1;
    };

    // Check if user is the receiver or sender
    wl.receiver == caller || wl.sender == caller
}

entry fun seal_approve(id: vector<u8>, wl: &DM_Whitelist, ctx: &TxContext) {
    assert!(check_policy(ctx.sender(), id, wl), ENoAccess);
}

#[test_only]
public fun destroy_for_testing(wl: DM_Whitelist) {
    let DM_Whitelist { id, version: _, sender: _, receiver: _ } = wl;
    object::delete(id);
}
