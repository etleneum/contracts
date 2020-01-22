A simple game: you ask difficult questions and place a prize on them.
If someone knows the answer they take the money.

## To ask a question: `create`

Before posting a question you must compute the SHA256 of the answer. That can be done in your terminal with `echo -n "answer goes here" | sha256sum` or using services like https://passwordsgenerator.net/sha256-hash-generator/ (note that lower and uppercase are different and that answer will only match if it's written perfectly like you did, no deviations of any character allowed).

You can provide an array of alternatives as the "hint" or even just some text with additional info there.

You don't have to be authenticated for this call. 

---

## To answer a question: `answer`

You have to be [authenticated](#/account) for this call (otherwise to where would the money go?).

Just send the answer. You don't even have to specify the question you're answering, because if the SHA256 hash of your answer matches any question you'll get the prize for that question.