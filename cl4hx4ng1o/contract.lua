function __init__ ()
  return {}
end

function makeFlip ()
  local num_of_players = tonumber(call.payload.num_of_players)
  local fee = tonumber(call.payload.fee)
  local balance = call.msatoshi
  local id = util.cuid()

  local base = {
    num_of_players = num_of_players,
    fee = fee,
    balance = balance,
    players = {}
  }
  if balance/1000 >= fee then
    table.insert(base.players, account.id)
    util.print("added player to contract " .. id .. " with index #“ .. #base[players] .. “.")
    contract.state[id] = base
  end
end

function joinFlip ()
  local id = call.payload.id
  if #contract.state[id].players < contract.state[id].num_of_players then
    if call.msatoshi < contract.state[id].fee then
      error("must contribute at least " .. contract.state[id].fee .. " sats.")
    end
  end

  contract.state[id].balance = contract.state[id].balance + tonumber(call.msatoshi)
  table.insert(contract.state[id].players, account.id)
  _checkPlayers(id)
end

function _checkPlayers (id)
  if #contract.state[id].players == contract.state[id].num_of_players then
    _runFlip(id)
  end
end

function _runFlip (id)
  local rand = math.random(1, #contract.state[id].players)
  local winner = contract.state[id].players[rand]
  contract.send(winner, contract.state[id].balance)
end