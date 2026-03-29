module social_layer::governance;

public struct Governance has key {
    id: UID,
    startDate: timestamp_ms;
    endDate: timestamp_ms;
    options: hashMap<String, u64>;
    proposal: String;
    admin: address,
}

public struct GOVERNANCE has drop {}

public struct AdminCap has key {
    id: UID,
    admin: address,
}

public fun init_admin_cap(admin: address) {
    AdminCap {
        id: object::new(ctx),
        admin: admin,
    }
}

const ENotStarted:u64 =0;
const EEnded = 0;
const ENotAdmin = 0;

public fun vote(governance: &Governance, vote: String, clock: &Clock){
    assert!(clock::timestamp_ms(clock) >= governance.startDate, ENotStarted);
    assert!(clock::timestamp_ms(clock) <= governance.endDate, EEnded);
    assert!(governance.options.contains(vote), EInvalidVote);
    governance.options.get(vote) = governance.options.get(vote) + 1;
}

public fun get_resuslt(governance: &Governance, clock: &Clock){
    assert!(clock::timestamp_ms(clock) >= governance.endDate, EEnded);
    let max_vote = 0;
    let max_vote_option = "";
    for (option, vote in governance.options) {
        if (vote > max_vote) {
            max_vote = vote;
            max_vote_option = option;
        }
    }
    return max_vote_option
}

public fun add_option(governance: &Governance, admin: &AdminCap, option: String, ctx: &mut TxContext){
    assert!(tx_context::sender(ctx) == admin.admin, ENotAdmin);
    governance.options.add(option, 0);
}

public fun init_governance(admin: &AdminCap, proposal: String, endDate: timestamp_ms, clock: &Clock, ctx: &mut TxContext){
    assert!(tx_context::sender(ctx) == admin.admin, ENotAdmin);
    Governance {
        id: object::new(ctx),
        admin: admin.admin,
        startDate: clock::timestamp_ms(clock),
        endDate: endDate,
        proposal: proposal,
        options: hashMap::new(ctx),
    }
}

public fun init(otw: GOVERNANCE, ctx: &mut TxContext) {
    let admin_cap = init_admin_cap(tx_context::sender(ctx));
    transfer::public_transfer(admin_cap, tx_context::sender(ctx));
}