To create markets, increase a market's liquidity and buy or sell shares, please use the UI at https://predictions.etleneum.com/ or compatible (since it involves some calculation that must be done before calling). To resolve markets you can use the interface here.

This contract enables anyone to create a prediction market (with just "yes" or "no" possible results) that can be resolved at anytime by a set of predefined Etleneum accounts. The market creator chooses which accounts will resolve it and people can buy and sell shares of _yes_ or _no_. By default the market creator will be the sole resolver, but they can also make the `createmarket` call unauthenticated and specify a list of resolvers manually (beware: specifying an invalid resolver will probably cause the market to never resolve).

It comes with an automated market maker is based on the simplest version of [this algorithm](https://bitcoinhivemind.com/papers/LogMSR_Demo.xlsx). For it to work the market creator must make an initial deposit and after that the market will never be bankrupt. A _liquidity factor_ is also specified upon market creation, it specifies basically how much capital the creator wants to deposit initially to make the market less volatile. The liquidity factor can be increased after the market is operational by calling `increaseliquidity` and making a donation to the market's funds.

`exchange` can be called with either a positive or a negative number of shares. If negative, these shares will be sold and the money will be sent to the seller's account. If positive, the correct amount of satoshis will have to be included in the call.

---

If you're interested in a more complete version of this contract with much better trust assumptions and censorship-resistance that can scale to guide decisions and public opinion on matters of great public importance, take a look at https://bitcoinhivemind.com/.
