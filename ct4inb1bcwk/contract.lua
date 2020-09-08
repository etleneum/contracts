min = 0
max = 65535

function __init__ ()
  return {}
end

function fund ()
  -- does nothing
end

function bet ()
  if not account.id then
    error("call must be done by a logged account")
  end

  math.randomseed(os.time())

  local bet = call.msatoshi
  local roll = math.random(min, max)
  local guess = tonumber(call.payload.guess)
  local multiplier = 1 / ( (max - guess) / max )
  local prize = bet * multiplier
  local funds = contract.get_funds()

  if ( funds < prize ) then
    error('not enough funds')
  else
    if ( guess > roll ) then
      util.print('multiplier: ' .. multiplier)
      util.print('roll: ' .. roll)
      util.print('guess: ' .. guess)
      util.print('you lost')
    end
    if ( guess <= roll ) then
      util.print('multiplier: ' .. multiplier)
      util.print('roll: ' .. roll)
      util.print('guess: ' .. guess)
      util.print('you won!!')
      util.print(prize)
      contract.send(account.id, prize)
    end

  end

end