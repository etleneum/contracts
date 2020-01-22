This contract allows anyone to `ask` questions to any known person (identified by their [Keybase](https://keybase.io/) username) and actually get answers.

Askers attach **money compensations** to their questions, so the person to whom they're asking are incentivized to spend some minutes crafting an `answer`.

More than that: if some other person is also interested in the answer to that specific question they can `add_funds` to it to increase the incentives and the possibilities of attracting the attention of the person being asked.

If after some time it's feeling like an answer isn't coming any of the askers or funders can `remove_funds` from any given question. **Be sure to make authenticated calls when creating questions or adding funds**, otherwise you won't be able to remove the funds later.

Once the requested user posts an answer they will **get all the funds** and **the answer will be saved forever** in the contract.

_To answer a question it is necessary for the answerer to first have its Etleneum account linked to a Keybase account through the [Keybase Account Directory](https://etleneum.com/#/contract/cog4wt7q8n3) contract._

**Why wouldn't the answerer just post a random string as the answer and claim the funds?** That's perfectly possible to do, but by doing that they would be showing themselves as jerks to everybody and will likely not ever get a question again.

**Why is it possible to post questions while unauthenticated?** Although that causes the attached funds to not be able to be removed, I think it makes sense to allow for the possibility of anonymous questions to appear.