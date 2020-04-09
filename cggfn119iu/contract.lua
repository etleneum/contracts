function __init__ ()
  return {
    ranking = {},
    owner = 'asg38t7q8se'
  }
end

function sponsor_ad ()
  local msatoshi_per_hour = call.payload.sats_per_day * 1000 / 24
  local hours = call.msatoshi / msatoshi_per_hour
  local seconds = hours * 60 * 60

  local ad = {
    rate = call.payload.sats_per_day,
    msatoshi = call.msatoshi,
    seconds = seconds,
    placed = os.time(),
    link = tostring(call.payload.link)
  }

  if call.payload.image_url then
    ad.image_url = tostring(call.payload.image_url)
  elseif call.payload.text then
    ad.text = tostring(call.payload.text)
  else
    error('ad must have image or text')
  end

  -- place this ad in the ranking
  contract.state.ranking[#contract.state.ranking + 1] = ad

  -- pay the contract owner
  contract.send(contract.state.owner, call.msatoshi)

  bump()
end

function remove ()
  if account.id ~= contract.state.owner then
    error('only the owner can call this')
  end

  table.remove(contract.state.ranking, call.payload.index)
end

function bump ()
  -- remove expired ads
  for i = #contract.state.ranking, 1, -1 do
    local ad = contract.state.ranking[i]
    if ad.placed + ad.seconds <= os.time() then
      table.remove(contract.state.ranking, i)
    end
  end

  -- sort ranking
  local function ratesorter (a, b)
    if a.rate == b.rate then
      return a.placed < b.placed
    else
      return a.rate > b.rate
    end
  end
  table.sort(contract.state.ranking, ratesorter)
end
