function __init__ ()
  return {}
end

function add ()
  local aliases = contract.state[account.id] or {}
  table.insert(aliases, call.payload.alias)
  contract.state[account.id] = aliases
end

function _get_key_for_value( t, value )
  for k,v in pairs(t) do
    if v==value then return k end
  end
  return nil
end

function delete ()
  local aliases = contract.state[account.id] or {}
  local key = _get_key_for_value(aliases, call.payload.alias)
  if key ~= nil then table.remove(aliases, key) end
  contract.state[account.id] = aliases
end