function __init__ ()
  return {
    banners={_=0},
    current_ads={_=0},
    ad_queue={_=0}
  }
end

function place_banner ()
  if not account.id then
    error('must be authenticated!')
  end

  -- replacing an existing banner is fine, but ads currently in the queue
  -- won't have their duration affected.
  local id = util.cuid()
  if call.payload.id then
    id = call.payload.id

    if contract.state.banners[id].account ~= account.id then
      error('banner owned by a different account')
    end
  end

  local banner = {
    url = tostring(call.payload.url),
    account = account.id,
    msatoshi_per_hour = tonumber(call.payload.msatoshi_per_hour)
  }

  contract.state.banners[id] = banner
  bump()
end

function delete_banner ()
  banner_id = call.payload.id

  if account.id ~= contract.state.banners[banner_id].account then
    error('banner owned by a different account')
  end

  -- by doing this the banner owner will not get paid for current and next ads
  contract.state.banners[banner_id] = nil
  contract.state.current_ads[banner_id] = nil
  contract.state.ad_queue[banner_id] = nil

  bump()
end

function queue_ad ()
  local banner_id = call.payload.id
  local banner = contract.state.banners[banner_id]
  if not banner then
    error('found no banner')
  end

  local hours = call.msatoshi / banner.msatoshi_per_hour
  local seconds = hours * 60 * 60
  
  local ad = {
    msatoshi = call.msatoshi,
    seconds = seconds,
    link = tostring(call.payload.link)
  }
  
  if call.payload.image_url then
    ad.image_url = tostring(call.payload.image_url),
  elseif call.payload.text then
    ad.text = tostring(call.payload.text)
  else
    error('ad must have image or text')
  end

  -- place this ad in the queue
  local queue = contract.state.ad_queue[banner_id]
  if not queue then
    queue = {} -- create a queue for this banner if not exists
  end
  queue[#queue + 1] = ad
  contract.state.ad_queue[banner_id] = queue

  bump()
end

function bump ()
  contract.state.current_ads['_'] = nil
  contract.state.ad_queue['_'] = nil

  -- remove all current ads if their time has passed
  for id, current in pairs(contract.state.current_ads) do
    if current.end_time <= os.time() then
      contract.state.current_ads[id] = nil

      -- get the banner data and pay the receiver only now
      local banner = contract.state.banners[id]
      contract.send(banner.account, current.msatoshi)
    end
  end

  -- if there's no ad currently being shown, make the next in queue appear
  for id, queue in pairs(contract.state.ad_queue) do
    if #queue > 0 and contract.state.current_ads[id] == nil then
      local ad = queue[1] -- next in queue
      table.remove(queue, 1) -- remove it from queue
      ad.end_time = os.time() + ad.seconds
      contract.state.current_ads[id] = ad
    end
  end

  contract.state.current_ads['_'] = 0
  contract.state.ad_queue['_'] = 0
end
