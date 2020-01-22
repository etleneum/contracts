Instead of someone saying: "I will do X and I need your money", this contract allows people to commit money beforehand to projects they want to see done. It's not hiring anyone to do it, just throwing money at the first person who does it because they wanted to.

While calling `create`, the creator may specify a set of **voters** that will determine if the task was fulfilled or not. The creator is always a voter. If no **voters** are specified the creator will decide alone. The **number of votes needed** for a resolution to be reached must be specified, otherwise it will be 1 (meaning any of the voters can decide alone).

Anyone can call `fund` on any task. That adds money to the task. If a task is perceived to be for the common good then many people will fund it and increase the incentive for someone to try to complete it. To `fund` it's not necessary to be authenticated, one can fund anonymously, but if the voters decide to `delete` the task anonymous funds will be lost.

Anyone can call `complete` and specify a free-text field describing what he did or something like that and linking to relevant resources.

The voters mechanism above is applied to `award` and `delete`. when a task is awarded the bounty prize goes to the awardee and the task becomes closed forever. When a task is deleted money is returned to funders.

For all reputation concerns (like asserting the identity of voters or completers), accounts are expected to be linked at [Keybase Account Directory ](https://etleneum.com/#/contract/cog4wt7q8n3) or https://kad.etleneum.com/, but this is not mandatory.