function __init__ ()
  return {}
end

function set ()
  if not account.id then
    error('must be authenticated!')
  end

  if not call.payload.alias or not call.payload.id then
    error('missing alias or contract id')
  end

  ok = etleneum.get_contract(call.payload.id)
  if not ok then
    error('contract ' .. call.payload.id .. ' does not exist')
  end

  if not contract.state[account.id] then
    contract.state[account.id] = {}
  end

  contract.state[account.id][call.payload.alias] = call.payload.id
end

function unset ()
  if not account.id then
    error('must be authenticated!')
  end

  contract.state[account.id][call.payload.alias] = nil
end