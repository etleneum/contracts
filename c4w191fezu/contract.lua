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

  local secret_hash = util.sha256(secret)

  local winner, is_draw, is_notfound = _gamewinner(gameid)
  is_draw = is_draw or (is_notfound and data.creation + 259200 < os.time())
  if not winner and not is_draw then
    error("this game doesn't have a result yet.")
  end

  if is_draw then
    if data.black and data.white then
      -- return half to this and exclude it, so the next call made by the other
      -- player will fall on the next clause
      if data.black == secret_hash then
        contract.send(account.id, math.floor(data.msatoshi / 2))
        data.black = nil
        data.msatoshi = math.floor(data.msatoshi / 2)
        return
      elseif data.white == secret_hash then
        contract.send(account.id, math.floor(data.msatoshi / 2))
        data.white = nil
        data.msatoshi = math.floor(data.msatoshi / 2)
        return
      end
    else
      -- return all to this player, either because the challenge was never accepted
      -- or because the other player has already cashed out their part
      if data.black == secret_hash then
        contract.send(account.id, data.msatoshi)
        contract.state[challenge] = nil
        return
      elseif data.white == secret_hash then
        contract.send(account.id, data.msatoshi)
        contract.state[challenge] = nil
        return
      end
    end
  elseif secret_hash == data[winner] then
    -- send all to this player since they are the winner
    contract.send(account.id, data.msatoshi)
    contract.state[challenge] = nil
    return
  end

  error("the given player secret was invalid.")
end

function _gamewinner (gameid)
  local resp, err = http.gettext('https://lichess.org/game/export/' .. gameid .. '?moves=false&clocks=false&evals=false&opening=false&literate=false&pgnInJson=false')
  if not resp or err ~= nil then
    if err == 'response status code: 404' then
      return nil, true, true
    end
    return nil, false, false
  end

  if resp:find('[Result "1-0"]', nil, true) then
    return 'white', false, false
  elseif resp:find('[Result "0-1"]', nil, true) then
    return 'black', false, false
  elseif resp:find('[Termination "Abandoned"]', nil, true) then
    return nil, true, false
  elseif resp:find('[Result "1/2-1/2"]', nil, true) then
    return nil, true, false
  else
    return nil, false, false
  end
end
