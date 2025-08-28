module suins_social_layer::message;

use sui::clock::{Self, Clock};
use sui::event;
use suins_social_layer::dm_whitelist::{DM_Whitelist, sender, receiver};

// === Events ===
public struct CreateMessageEvent has copy, drop {
    message_id: ID,
    sender: address,
    receiver: address,
    encryptedData: vector<u8>,
    encryptedDataWithObject: ID,
    timestamp: u64,
}

public struct EditMessageEvent has copy, drop {
    message_id: ID,
    sender: address,
    receiver: address,
    encryptedData: vector<u8>,
    encryptedDataWithObject: ID,
    timestamp: u64,
}

public struct DeleteMessageEvent has copy, drop {
    message_id: ID,
    sender: address,
    receiver: address,
    encryptedData: vector<u8>,
    encryptedDataWithObject: ID,
    timestamp: u64,
}

public struct Message has key, store {
    id: UID,
    sender: address,
    receiver: address,
    encryptedData: vector<u8>,
    encryptedDataWithObject: ID,
    updated_at: u64,
    created_at: u64,
}

// === Event Emitters ===
fun emit_create_message_event(message: &Message, clock: &Clock) {
    event::emit(CreateMessageEvent {
        message_id: object::uid_to_inner(&message.id),
        sender: message.sender,
        receiver: message.receiver,
        encryptedData: message.encryptedData,
        encryptedDataWithObject: message.encryptedDataWithObject,
        timestamp: clock::timestamp_ms(clock),
    });
}

fun emit_edit_message_event(message: &Message, clock: &Clock) {
    event::emit(EditMessageEvent {
        message_id: object::uid_to_inner(&message.id),
        sender: message.sender,
        receiver: message.receiver,
        encryptedData: message.encryptedData,
        encryptedDataWithObject: message.encryptedDataWithObject,
        timestamp: clock::timestamp_ms(clock),
    });
}

fun emit_delete_message_event(message: &Message, clock: &Clock) {
    event::emit(DeleteMessageEvent {
        message_id: object::uid_to_inner(&message.id),
        sender: message.sender,
        receiver: message.receiver,
        encryptedData: message.encryptedData,
        encryptedDataWithObject: message.encryptedDataWithObject,
        timestamp: clock::timestamp_ms(clock),
    });
}

// public fun is_valid_message(sender: address, receiver: address, dm_whitelist: &DM_Whitelist): bool {
//     (sender == sender(dm_whitelist) && receiver == receiver(dm_whitelist)) ||
//     (sender == receiver(dm_whitelist) && receiver == sender(dm_whitelist))
// }

public entry fun create_message(
    sender: address,
    receiver: address,
    encryptedData: vector<u8>,
    encryptedDataWithObject: ID,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let message = Message {
        id: object::new(ctx),
        sender: sender,
        receiver: receiver,
        encryptedData: encryptedData,
        encryptedDataWithObject: encryptedDataWithObject,
        updated_at: clock::timestamp_ms(clock),
        created_at: clock::timestamp_ms(clock),
    };

    emit_create_message_event(&message, clock);
    transfer::public_transfer(message, ctx.sender());
}

public entry fun edit_message(message: &mut Message, encryptedData: vector<u8>, clock: &Clock) {
    message.encryptedData = encryptedData;
    message.updated_at = clock::timestamp_ms(clock);

    emit_edit_message_event(message, clock);
}

public entry fun delete_message(message: Message, clock: &Clock) {
    emit_delete_message_event(&message, clock);

    let Message {
        id,
        sender: _,
        receiver: _,
        encryptedData: _,
        encryptedDataWithObject: _,
        updated_at: _,
        created_at: _,
    } = message;

    id.delete();
}
