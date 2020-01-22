function __init__ ()
  return {}
end

function fund ()
  -- does nothing
end

function bet ()
  if not account.id then
    error("call must be done by a logged account")
  end

  local prize = 0
  local funds = contract.get_funds()
  local bettable = funds / 4
  local bet = call.msatoshi
  if bet > bettable then
    contract.send(account.id, bet - bettable)
    bet = bettable
  end
  
  prize = bet * 2

  math.randomseed(os.time())
  if math.random() < 0.5 then
    util.print('you won!')
    contract.send(account.id, prize)
  else
    util.print('you lost!')
  end
end