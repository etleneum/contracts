function __init__ ()
  return {
    keybase={_=0},
    etleneum={_=0}
  }
end

function claim ()
  if not account.id then
    error("must be authenticated!")
  end

  local identities = etleneum.get_contract('cog4wt7q8n3').identities
  local keybase = nil
  for k, a in pairs(identities) do
    if a == account.id then
      keybase = k
      break
    end
  end

  if not keybase then
    error("no keybase identity found!")
  end

  if contract.state.keybase[keybase] ~= nil then
    error("already claimed with this keybase identity!")
  end

  if contract.state.etleneum[account.id] ~= nil then
    error("already claimed with this etleneum account!")
  end

  contract.state.keybase[keybase] = true
  contract.state.etleneum[account.id] = true
  contract.send(account.id, 1000000)
end

function fund ()
  -- just takes your sats
  if call.msatoshi < 1000000 then
    error("fund more than 1000 sat")
  end
end