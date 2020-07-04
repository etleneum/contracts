function __init__ ()
  return {}
end

function openchallenge ()
  local challenge = call.payload.challenge
  local gameid_hash = call.payload.gameid_hash
  local color = call.payload.color
  local secret_hash = call.payload.secret_hash

  if call.msatoshi < 10000 then
    error("must bet at least 10 sats!")
  end

  if contract.state[challenge] ~= nil then
    error("challenge " .. challenge .. " already exists!")
  end

  contract.state[challenge] = {
    creation = os.time(),
    gameid_hash = gameid_hash,
    msatoshi = call.msatoshi,
    [color] = secret_hash
  }
end

function acceptchallenge ()
  local gameid = call.payload.gameid
  local challenge = call.payload.challenge
  local secret_hash = call.payload.secret_hash

  local data = contract.state[challenge]
  if not data then
    error("challenge not found!")
  end

  if util.sha256(gameid) ~= data.gameid_hash then
    error("invalid gameid for this challenge!")
  end

  if call.msatoshi < data.msatoshi then
    error("must contribute at least " .. data.msatoshi .. "msats to this bet.")
  end

  local color = 'black'
  if data.black ~= nil then
    color = 'white'

    if data.white ~= nil then
      error("this game already has 2 players.")
    end
  end

  data[color] = secret_hash
  data.msatoshi = data.msatoshi + call.msatoshi
end

-- after a game ends the player who won must come here and call this
-- so the sats go from the game to his etleneum account
function extract ()
  local challenge = call.payload.challenge
  local gameid = call.payload.gameid
  local secret = call.payload.secret

  if not account.id then
    error("must be authenticated!")
  end

  local data = contract.state[challenge]
  if not data then
    error("challenge not found!")
  end

  if util.sha256(gameid) ~= data.gameid_hash then
    error("invalid gameid for this challenge!")
  end

  local winner = _gamewinner(gameid)
  if not winner then
    error("this game doesn't have a winner yet.")
  end

  if util.sha256(secret) ~= data[winner] then
    error("the winner was " .. winner .. ", your secret was invalid for that player.")
  end

  contract.send(account.id, data.msatoshi)
  contract.state[challenge] = nil

  util.print("satoshis sent to " .. account.id)
end

-- this is for when a game is abandoned.
-- any of the two players can extract all the sats after 6 months.
function cancel ()
  local challenge = call.payload.challenge
  local gameid = call.payload.gameid
  local secret = call.payload.secret

  if not account.id then
    error("must be authenticated!")
  end

  local data = contract.state[challenge]
  if not data then
    error("challenge not found!")
  end

  if data.creation + 15552000 > os.time() then
    error("too soon to cancel this challenge, must wait 6 months since the creation.")
  end

  if util.sha256(gameid) ~= data.gameid_hash then
    error("invalid gameid for this challenge!")
  end

  local secret_hash = util.sha256(secret)
  if secret_hash ~= data.black and secret_hash ~= data.white then
    error("you were not a player in this game.")
  end

  contract.send(account.id, data.msatoshi)
  contract.state[challenge] = nil
  util.print("satoshis sent to " .. account.id)
end

function _gamewinner (gameid)
  local resp, err = http.gettext('https://lichess.org/game/export/' .. gameid .. '?moves=false&clocks=false&evals=false&opening=false&literate=false&pgnInJson=false')
  if not resp or err ~= nil then
    return nil
  end

  if resp:find('[Result "1-0"]', nil, true) then
    return 'white'
  elseif resp:find('[Result "0-1"]', nil, true) then
    return 'black'
  else
    return nil
  end
end
