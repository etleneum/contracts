A contract for friendly bets. One person proposes a bet by calling `create` with the terms of the bet (for example, `terms="it will rain tomorrow"`) and the sides (for example, `yes=[my_account]` and `no=[friend_account]`). The number of satoshis included is the value of the bet. A parameter `resolve_at` in the format `yyyy-mm-dd` must also be provided. The bet can't be resolved until that date. Finally, an optional parameter `resolver` may be provided as a user account. If it is, then that account may resolve the bet on behalf of the two peers.

The other party can then call `accept` with the exact same amount and a parameter `with=[creator_account]` to accept the bet (the bet id is generated from the two sides plus the amount).

To resolve the bet, both peers must call `resolve` with the same `result=[either 'yes' or 'no']`. Otherwise the bet will remain unresolved. If a "resolver" was specified that can also call `resolve` and that will settle the bet.

Any party can `cancel` the bet as long as it is still pending. Otherwise it will be automatically canceled 15 days after the date in which it should have been resolved. It will also be automatically canceled if it's pending at the date it should be resolved. When it is canceled people who put money in it get their money back.
