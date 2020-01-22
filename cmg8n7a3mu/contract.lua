function __init__ ()
  return {_=0}
end

function ask ()
  local question = call.payload.question
  local question_id = string.sub(util.sha256(question), 0, 5)
  _ask(question, question_id, call.payload.answerer_keybase)
end

function add_funds ()
  _ask(nil, call.payload.question_id, call.payload.answerer_keybase)
end

function _ask (question, question_id, answerer)
  if call.msatoshi < 100000 then
    error("you must offer at least 100 sat for an answer")
  end

  local asker = account.id or 'anonymous'
  local questions = contract.state[answerer] or {}
  local question = questions[question_id] or {
    question=question,
    answer=nil,
    funds={},
    asked=os.time(),
    answered=nil,
  }

  if question.answer ~= nil then
    error("question was already answered!")
  end

  question.funds[asker] = (question.funds[asker] or 0) + call.msatoshi
  questions[question_id] = question
  contract.state[answerer] = questions
end

function remove_funds ()
  if not account.id then
    error("you must make this call authorized")
  end

  local question_id = call.payload.question_id
  local question = contract.state[call.payload.answerer_keybase][question_id]

  if question.answer ~= nil then
    error("question was already answered!")
  end

  local myfunds = question.funds[account.id]
  if not myfunds then
    error("you don't have any funds in this question")
  end

  contract.send(account.id, myfunds)
  question.funds[account.id] = nil

  -- cleanup
  if next(question.funds) == nil then
    contract.state[call.payload.answerer_keybase][question_id] = nil
  end
  if next(contract.state[call.payload.answerer_keybase]) == nil then
    contract.state[call.payload.answerer_keybase] = nil
  end
end

function answer ()
  if not account.id then
    error("you must make this call authorized")
  end

  if type(call.payload.answer) ~= 'string' or call.payload.answer:len() == 0 then
    error("answer must be a string")
  end

  local kbname
  for kb, ea in pairs(etleneum.get_contract('cog4wt7q8n3').identities) do
    if ea == account.id then
      kbname = kb
      break
    end
  end

  if not kbname then
    error("no keybase link for " .. account.id ..  ". go to kad.etleneum.com first.")
  end

  local question = contract.state[kbname][call.payload.question_id]
  if question.answer ~= nil then
    error("question was already answered!")
  end

  question.answer = call.payload.answer
  question.answered = os.time()
  local payment = 0
  for _, funds in pairs(question.funds) do
    payment = payment + funds
  end
  contract.send(account.id, payment)
end