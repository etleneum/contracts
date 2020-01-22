A lottery with progressive jackpots that only expires when someone wins.

To get a chance to win, you must buy a ticket _and choose a number for your ticket_. You can choose numbers **from 0 to {{math.floor(16^3)}}**. You can buy any number of tickets you want.

Drawings are limited to one every _144 blocks_ (1 day). Anyone can initiate a draw.

The winner number will be given by the last 3 characters of the hash of the block number just after the last ticket was bought, reversed and translated to decimal. **Provably fair!**

If no one wins, the prize is accumulated to the next drawing round, and you don't lose your tickets!

The last drawing was at Bitcoin _block {{0}}_.
The current pot is **{{math.floor(funds/1000)}} sat**.
The current ticket price is _{{state.ticket_price_sats}} sat_.