function __init__ ()
  return {_dummy=0}
end

function create ()
  local hash = string.lower(call.payload.hash)
  local expiration = os.time() + (call.payload.timelock or 86400 * 5)

  if call.msatoshi == 0 then
    error('you have to include some sats!')
  end

  if string.len(call.payload.hash) ~= 64 then
    error('invalid hash: must be 32-byte hex-encoded')
  end

  if contract.state[hash] ~= nil then
    util.print('HTLC already exists, adding ' .. call.msatoshi .. ' to it')
    return
  end

  util.print('creating new HTLC with ' .. call.msatoshi .. ' msat')
  contract.state[hash] = {
    value=call.msatoshi,
    creator=account.id,
    expiration=account.id and expiration or nil
  }
end

function redeem ()
  if not account.id then
    error("call must be done by a logged account")
  end

  local hash = string.lower(call.payload.hash)
  local htlc = contract.state[hash]
  if htlc == nil then
    error("this htlc doesn't exist")
  end

  local hashed = util.sha256(call.payload.preimage)
  if hashed ~= hash then
    error("preimage doesn't match the stored hash, wanted " .. hash .. ", got " .. hashed)
  end

  util.print(htlc.value .. ' claimed to account ' .. account.id)
  contract.send(account.id, htlc.value)
  contract.state[hash] = nil
end

function cancel ()
  local hash = string.lower(call.payload.hash)
  local htlc = contract.state[hash]

  if htlc == nil then
    error("this htlc doesn't exist")
  end

  if htlc.creator == nil then
    error("htlc doesn't have an owner, can't cancel")
  end

  if htlc.expiration > os.time() then
    error("htlc still timelocked")
  end

  contract.send(htlc.creator, htlc.value)
  contract.state[hash] = nil
end