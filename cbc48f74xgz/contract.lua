function __init__ ()
  return {_=0}
end

function create ()
  if call.msatoshi < 1000 then
    error('trivia questions must pay at least 1 satoshi')
  end

  if contract.state[call.payload.answer_hash:lower()] ~= nil then
    error('that is already the answer to an existing question')
  end

  contract.state[call.payload.answer_hash:lower()] = {
    question=call.payload.question,
    prize=call.msatoshi,
    hint=call.payload.hint -- optional
  }
end

function answer ()
  if not account.id then
    error("must be authenticated!")
  end

  local answer_hash = util.sha256(call.payload.answer)
  local question = contract.state[answer_hash:lower()]
  if question == nil then
    error("wrong answer!")
  end

  util.print("correct answer!")
  contract.send(account.id, question.prize)
  contract.state[answer_hash:lower()] = nil
end