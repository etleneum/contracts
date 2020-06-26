This contract just accumulates satoshis before sending them to [ChainMarket](https://etleneum.com/#/contract/c8w0c13v75).

You want this only to prevent someone from taking your offers while they're too small and then you end up creating small UTXOs which you may not want.

You can call `queue` multiple times here targeting the same address and when the pool size limit is reached all accumulated sats are combined in a single call to ChainMarket's `queuepay` method.

You define the pool size at the time you're calling `queue`. You can have different pools at the same time targeting the same address.

Fees are also accumulated. Each different `queue` call can have a different amount in fees.