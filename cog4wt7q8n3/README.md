This exists so you can link your etleneum.com account (which is just a random id) with a [Keybase](https://keybase.io) account. Could be useful so people can be find your account and refer to your etleneum.com id in other contracts or calls and send you money knowing it's really you.

To `link` an identity, make an authenticated call providing your `keybase_name` and a `bundle` of message + signature as produced by https://keybase.io/sign. The message must be `{{state.challenge}}` and the bundle must be passed with the correct newlines. Example:

Helper site with less intimidating interface: https://kad.etleneum.com/

```
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA512

{{state.challenge}}
-----BEGIN PGP SIGNATURE-----
Version: Keybase OpenPGP v2.1.3
Comment: https://keybase.io/crypto

wsBcBAABCgAGBQJdrR2oAAoJEAJs7pbOl+xqQA0H/32xUyVE+GSxsJ5xN1IbbBsK
eZH7H2IqQ+VTWUcS1x2JprsfKWlZ9Eks3mWpSOG6Jb9TUX08t+JAMS56uZNU5zeX
wN5i3Cc6V9R7q0Nzk/b2Z7wsZfuyhoxF/ybCnYy4Mj5NnkIo+yt44+s3L3MA1aEg
nkcg9JeJHzdu/jwQ4Lc6StJ8d3OV+7igQo8Ax0aAFV7pS3tSg3upqd6M5JtmiuIq
4lkU4NkaGGMJTnpCcUajn+z9isUUyQR5B+sMI3w7Q6jNZ0FRe7NAVKxl3d6QfwA9
pDYxl6ZWEnVSWjqM6V2Rncu1zR4g83++z8bqWrK2FBm8EzTHUVDPChPwEzFHLrQ=
=LcDv
-----END PGP SIGNATURE-----
```

To `unlink` an identity, do the same, but _make the call unauthenticated_. The `unlink` method is just an alias.
