A contract too complex to be called manually.
Must be used from the interface at https://lichess.etleneum.com/.

Basically you create an [open-ended game](https://lichess.org/api#operation/challengeOpen) on lichess.org, call `openchallenge`, then share an URL with a friend whom you want to challenge. They call `acceptchallenge`. You go to play on lichess.org and after the game is over the winner calls `extract` to redeem the satoshis that were bet previously.

You don't have to be authenticated on etleneum.com to create or accept the challenge, only at the `extract` phase. Hopefully this makes it possible for people to play first without having to deal with bureaucracy and only later (if they win) do anything about it.