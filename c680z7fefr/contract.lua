function __init__ ()
  return {
    ticket_price_sats=100,
    last_drawing=0,
    last_ticket=0,
    last_number_drawn=0,
    tickets={_=0}
  }
end

function buy_ticket ()
  if not account.id then
    error("must be authenticated!")
  end

  local number = tonumber(call.payload.number)
  local max = 16^3
  if type(number) ~= 'number' or number > max or number < 0 then
    error('number must be a number between 0 and ' .. max)
  end

  if call.msatoshi ~= (contract.state.ticket_price_sats * 1000) then
    error("must pay the ticket price exactly!")
  end

  if contract.state.tickets[tostring(number)] ~= nil then
    error('ticket already bought by ' .. account.id)
  end

  local current_block, err = http.gettext('https://blockstream.info/api/blocks/tip/height')
  if err ~= nil then
    error("couldn't fetch current block: " .. err)
  end

  contract.state.tickets[number] = account.id
  contract.state.last_ticket = tonumber(current_block)
  util.print('ticket ' .. number .. ' bought for ' .. account.id .. '!')
end

function draw ()
  local current_block, err = http.gettext('https://blockstream.info/api/blocks/tip/height')
  if err ~= nil then
    error("couldn't fetch current block: " .. err)
  end
  local wait = contract.state.last_drawing + 144

  if wait > tonumber(current_block) then
    error("can't draw yet, we're in block " .. current_block .. ", wait for " .. wait)
  end

  local drawing_block = math.floor(contract.state.last_ticket + 1)
  local hash, err = http.gettext('https://blockstream.info/api/block-height/' .. drawing_block)
  if err ~= nil then
    util.print("wait until block " .. drawing_block .. " is available!")
    error("couldn't fetch drawing block: " .. err)
  end

  local drawn = tonumber('0x' .. hash:reverse():sub(0, 3))

  util.print('the number drawn was ' .. drawn)
  contract.state.last_number_drawn = drawn
  contract.state.last_drawing = drawing_block
  contract.state.ticket_price_sats = math.floor(drawing_block / 6000)

  local winner = contract.state.tickets[tostring(drawn)]
  if winner == nil then
    util.print('no one won.')
  else
    util.print(winner .. ' won!')
    contract.send(winner, contract.get_funds())
    contract.state.tickets = {_=0}
  end
end