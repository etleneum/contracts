function __init__ ()
  return {
    identities={_=0},
    challenge='etleneumidentitylink'
  }
end

function link ()
  local username = call.payload.keybase_name
  local bundle = call.payload.bundle
  local signedmessage = keybase.extract_message(bundle)
  local challenge = contract.state.challenge

  if signedmessage ~= challenge and signedmessage ~= challenge .. '\n' then
    error('signed the wrong message, must sign "' .. contract.state.challenge .. '"')
  end

  if not keybase.verify(username, bundle) then
    error('signature does not match!')
  end

  contract.state.identities[username] = account.id
  contract.state.challenge = util.sha256(username .. ':' .. challenge)
end

function unlink ()
  -- with call.payload.keybase_name and call.payload.bundle
  link() -- will link to nil, as there's no logged account
end