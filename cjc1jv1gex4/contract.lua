local shareprice = 1000 * 100 -- 100 sat

function __init__ ()
  return {}
end

function createmarket ()
  local liquidity = tonumber(call.payload.liquidity) or 7

  local resolvers = call.payload.resolvers or {account.id}
  if #resolvers == 0 then
    error("no resolver!")
  end
  for _, rsv in ipairs(resolvers) do
    if rsv:sub(0, 1) ~= "a" and rsv:sub(0, 1) ~= "c" then
      error("invalid resolver!")
    end
  end

  local terms = call.payload.terms

  local market = {
    liquidity = liquidity,
    terms = terms,
    balance = _balance(liquidity, 0, 0),
    shares = {
      yes = {},
      no = {}
    },
    resolvers = resolvers,
    votes = {},
    created = os.time(),
    lastexchange = nil,
    nexchanges = 0,
  }

  local sacrificial = call.msatoshi
  if sacrificial ~= market.balance then
    error("sacrificial deposit must be " .. market.balance .. " msat.")
  end

  contract.state[util.cuid()] = market
end

function increaseliquidity ()
  local id = call.payload.id
  local market = contract.state[id]
  if not market then
    error('market not found!')
  end

  local newliquidity = call.payload.liquidity
  if newliquidity <= market.liquidity then
    error("can't decrease liquidity!")
  end

  local newbalance = _balance(
    newliquidity,
    _countshares(market.shares['yes']),
    _countshares(market.shares['no'])
  )

  local balancediff = newbalance - market.balance
  if balancediff ~= call.msatoshi then
      error("must include " .. balancediff .. "msat for this call.")
  end

  market.balance = newbalance
  market.liquidity = newliquidity
end

function exchange ()
  if not account.id then
    error('must be authenticated!')
  end

  local id = call.payload.id
  local market = contract.state[id]
  if not market then
    error('market not found!')
  end

  local side = call.payload.side
  if side ~= 'yes' and side ~= 'no' then
    error('side must be yes or no.')
  end

  -- shares can be negative, means selling
  local nshares = tonumber(call.payload.nshares)

  -- get shares for this user
  market.shares[side][account.id] = market.shares[side][account.id] or 0
  market.shares[side][account.id] = market.shares[side][account.id] + nshares

  if market.shares[side][account.id] < 0 then
    error("can't sell more shares than you currently own!")
  end

  local newbalance = _balance(
    market.liquidity,
    _countshares(market.shares['yes']),
    _countshares(market.shares['no'])
  )
  local balancediff = newbalance - market.balance
  if balancediff > 0 then
    -- buying stuff, require payment.
    if call.msatoshi ~= balancediff then
      error("must include " .. balancediff .. "msat for this call.")
    end
  else
    -- selling stuff. send payment to this account.
    contract.send(account.id, -balancediff)
  end

  -- cleanup user account if share count is zero
  if market.shares[side][account.id] == 0 then
    market.shares[side][account.id] = nil
  end

  market.balance = newbalance
  market.lastexchange = os.time()
  market.nexchanges = market.nexchanges + 1
end

function resolve ()
  if not account.id then
    error('must be authenticated!')
  end

  local id = call.payload.id
  local market = contract.state[id]
  if not market then
    error('market not found!')
  end

  local vote = call.payload.vote
  if vote ~= 'yes' and vote ~= 'no' then
    error("vote must be either yes or no.")
  end

  for _, rsv in ipairs(market.resolvers) do
    if account.id == rsv then
      market.votes[account.id] = vote
      _checkresolution(id, market)
      break
    end
  end
end

function _balance (liquidity, yes_shares, no_shares)
  local vshares = liquidity * math.log(
    math.exp(yes_shares / liquidity) + math.exp(no_shares / liquidity)
  )
  return math.ceil(vshares * shareprice)
end

function _countshares (shares)
  local nshares = 0
  for _, n in pairs(shares) do
    nshares = nshares + n
  end
  return nshares
end

function _checkresolution (id, market)
  local nresolvers = #market.resolvers
  local votesneeded = math.ceil(nresolvers / 2)
  if votesneeded * 2 == nresolvers then
    votesneeded = votesneeded + 1
  end

  local votes = {yes = 0, no = 0}
  for _, side in pairs(market.votes) do
    votes[side] = votes[side] + 1
  end

  if votes.yes >= votesneeded then
    _grantwin(id, market, 'yes', votes.yes)
  elseif votes.no >= votesneeded then
    _grantwin(id, market, 'no', votes.no)
  else
    util.print("market not resolved yet, needs more votes")
  end
end

function _grantwin (id, market, side, nvoters)
  util.print("market resolved: " .. side)

  local remainder = market.balance

  -- paying shareholders
  for acct, n in pairs(market.shares[side]) do
    local msatoshi = n * shareprice
    contract.send(acct, msatoshi)
    remainder = remainder - msatoshi
  end

  -- paying resolvers
  local each = math.floor(remainder / nvoters)
  for rsv, v in pairs(market.votes) do
    if v == side then
      contract.send(rsv, each)
    end
  end

  -- deleting market
  contract.state[id] = nil
end