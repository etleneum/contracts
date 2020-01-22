This contract enables creation, redemption and cancellation of Hashed Timelocked Contracts.

`create` takes a `hash` (a 32-byte hex-encoded string for which you must know the preimage otherwise no one will be able to redeem the HTLC), and a `timelock` in seconds (defaults to 5 days). If you want to be able to cancel the HTLC after the timelock you must make this call authenticated.

`redeem` takes a `hash` to identify which HTLC you're redeeming and a `preimage` for which `sha256(preimage) == hash`. This call must be done authenticated so you can get the redeemed funds in your account.

`cancel` takes a `hash` to identify which HTLC you're cancelling.