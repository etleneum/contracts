function __init__ ()
  return {}
end

function create ()
  if not account.id then
    error('must be authenticated!')
  end

  local ryear, rmonth, rday = call.payload.resolve_at:match('(%d+)-(%d+)-(%d+)')
  if not ryear or not rmonth or not rday then
    error('resolve_at "' .. call.payload.resolve_at .. '" is invalid')
  end

  if call.payload.yes ~= account.id and call.payload.no ~= account.id then
    error('bet creator must be either on the "yes" or on the "no" side')
  end

  resolvable = os.time({year=ryear, month=rmonth, day=rday})
  cancellable = resolvable + 60*60*24 * 15

  if not call.payload.yes or not call.payload.no then
    error('bet must be defined with someone betting "yes" and someone betting "no"')
  end

  local bet = {
    terms = call.payload.terms,
    resolvable = resolvable,
    cancellable = cancellable,
    msatoshi = call.msatoshi, -- each person pays this
    yes = call.payload.yes,
    no = call.payload.no,
    resolver = call.payload.resolver, -- can be null, will fallback to both parties
    creator = account.id,
    pending = true
  }

  local betid = _calc_betid({bet.yes, bet.no}, bet.msatoshi)
  if contract.state[betid] then
    error('a bet with these participants and value already exists')
  end
  contract.state[betid] = bet

  util.print(betid .. " created by " .. account.id)
end

function accept ()
  if not account.id then
    error('must be authenticated!')
  end

  local betid = _calc_betid({account.id, call.payload.with}, call.msatoshi)
  local bet = contract.state[betid]
  if not bet then
    error('a bet with these parameters does not exist!')
  end

  if not bet.pending then
    error('this bet is already running!')
  end

  bet.pending = nil

  util.print(betid .. " accepted by " .. account.id)
end

function resolve ()
  if not account.id then
    error('must be authenticated!')
  end

  local betid = call.payload.id
  if not betid then
    betid = _calc_betid({account.id, call.payload.with}, 1000 * call.payload.sats)
  end
  local bet = contract.state[betid]
  if not bet then
    error('a bet with these parameters does not exist!')
  end

  if bet.pending then
    error('this bet is pending!')
  end

  if call.payload.result ~= 'yes' and call.payload.result ~= 'no' then
    error('result must be "yes" or "no", not "' .. call.payload.result .. '"')
  end

  bet.votes = bet.votes or {}
  bet.votes[account.id] = call.payload.result

  bump()
end

function cancel ()
  if not account.id then
    error('must be authenticated!')
  end

  local betid = call.payload.id
  if not betid then
    betid = _calc_betid({account.id, call.payload.with}, 1000 * call.payload.sats)
  end
  local bet = contract.state[betid]
  if not bet then
    error('a bet with these parameters does not exist!')
  end

  if not bet.pending then
    error('bet is not pending!')
  end

  util.print(betid .. " canceled by " .. account.id .. ", returning money to " .. bet.creator)
  contract.state[betid] = nil
  contract.send(bet.creator, bet.msatoshi)
end

function bump ()
  now = os.time()
  for id, bet in pairs(contract.state) do
    if not bet.pending and bet.resolvable < now then
      -- resolve bet
      local result = nil
      if bet.votes then
        if bet.resolver and bet.votes[bet.resolver] then
          result = bet.votes[bet.resolver]
        end
        if bet.votes[bet.yes] and bet.votes[bet.yes] == bet.votes[bet.no] then
          result = bet.votes[bet.yes]
        end
      end

      if result then
        local winner = bet[result]
        util.print(id .. " resolved as '" .. result .. "' -- " .. winner .. " won")
        contract.send(winner, bet.msatoshi * 2)
        contract.state[id] = nil
      end
    end

    if not bet.pending and bet.cancellable < now then
      -- cancel bet
      util.print(id .. " expired without resolution")
      contract.send(bet.yes, bet.msatoshi)
      contract.send(bet.no, bet.msatoshi)
      contract.state[id] = nil
    end

    if bet.pending and bet.resolvable < now then
      -- expired, cancel automatically
      util.print(id .. " expired while pending")
      contract.send(bet.creator, bet.msatoshi)
      contract.state[id] = nil
    end
  end
end

function _calc_betid (peers, msatoshi)
  table.sort(peers)
  local hash = util.sha256(peers[1] .. ':' .. peers[2] .. ':' .. msatoshi)
  return hash:sub(0, 7)
end