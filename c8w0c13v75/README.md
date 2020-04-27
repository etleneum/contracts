For a nicer interface to this contract see https://chainmarket.etleneum.com/

This contract allows Lightning users to send payments to addresses on the blockchain and for people with onchain coins to turn them into Lightning satoshis.

It goes like this:

  1. Alice has Lightning satoshis and wants to send them to address 3mno... onchain. Alice calls `queuepay` method with `{addr, fee_msat}` and the amount of satoshis she wants to send to 3mno... + the amount of msatoshis specified. That will create a pending offer.
  2. Now Bob appears. Bob wants to send satoshis to the address bc1ymq... onchain. Bob calls `queuepay`. Now there are two pending offers.
  3. Charlie has coins onchain and wants to get some satoshis on Lightning. He notices that he can send a batched transaction to 3mno... and bc1ymq... with the specified amounts in the pending offers, pay the fees and still pocket some extra sats from the sum of `fee_msat` of both offers.
  4. Before doing anything, Charlie calls `reserve`. That will ensure he has the right to fulfill these two offers without anyone messing up with them before him. When calling `reserve` Charlie includes _200 sat_ just to keep him honest. If he doesn't fulfill the offers in the expected time (6 blocks) these sats will be added to the `fee_msat` of the two offers.
  5. Then Charlie publishes the batched transaction to the blockchain and calls `txsent` with the transaction id. Once the transaction is confirmed he is awarded with the sats.

**Other details**

- Anytime a `queuepay` is called with an address for which there is already an offer, the new satoshis and fees will just be added to that offer (unless the offer is reserved, in that case the call will fail). You can use that to increase the fees if no one is taking your payment, for example.
- Onchain transactions must have outputs with **exact** values, otherwise they won't be recognized.
