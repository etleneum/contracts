function __init__ ()
  return {identities={_=0}, nonces={_=0}}
end

function link ()
  username = call.payload.keybase_name
  bundle = call.payload.bundle
  nonce = keybase.extract_message(bundle)

  if string.len(nonce) > 80 then
    error('nonce too big.')
  end

  if contract.state.nonces[nonce] ~= nil then
    error('nonce already used!')
  end

  if not keybase.verify(username, bundle) then
    error('signature does not match!')
  end

  contract.state.identities[username] = account.id
  contract.state.nonces[nonce] = true
end

function unlink ()
  -- with call.payload.keybase_name and call.payload.bundle
  link() -- will link to nil, as there's no logged account
end