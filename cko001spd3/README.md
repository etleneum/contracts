A marketplace for ads.

It goes like this:

* Alice has a website, she calls `place_banner` in this contract specifying the website address _https://alice.com/_ and a price per hour and it gets assigned the id _cxyz963_.
* Then she uses server-side code or installs a JavaScript widget at _https://alice.com/_ that shows the current active ad for _cxyz963_.
* Bob wants to advertise his business _Bob's Mushrooms_, he is casually browsing _https://alice.com/_, sees the banner there, empty, saying "advertise here" and linking to this contract and the banner id.
* He decides Alice is trustworthy enough to actually display the ad he is going to pay for instead of just faking the display and getting the money anyway.
* He calls `queue_ad` with the address of mushroom picture as `image_url` and _https://bobsmushrooms.com/_ as the `link`.

Helper website with less intimidating interface: https://banners.etleneum.com/
