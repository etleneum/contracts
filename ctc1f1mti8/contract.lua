function __init__ ()
  return {}
end

function register ()
  local key = call.payload.key
  local name = call.payload.name
  local logo = call.payload.logo
  local url = call.payload.url
  local owner = account.id

  if not owner or owner == '' or
        type(key) ~= 'string' or key == '' or
        key:find(' ') or utf8.len(key) > 50 or
        type(name) ~= 'string' or name == '' or
        type(url) ~= 'string' or url:sub(0, 4) ~= 'http' or
        (type(logo) ~= 'string' and logo ~= nil) then
    error("missing owner or key or name or url!")
  end

  local base = {
    name = name,
    logo = logo,
    url = url,
    owner = owner,
    requests = {}
  }

  local domain = contract.state[key]
  if domain == nil then
    domain = base
  else
    if domain.owner == account.id then
      newdomain = base
      newdomain.requests = domain.requests
      domain = newdomain
    else
      error("key " .. key .. " already exists.")
    end
  end

  contract.state[key] = domain
end

function request ()
  -- creating a new request
  if call.msatoshi < 1000000 then
    error("must contribute at least 1000 sat.")
  end

  local key = call.payload.key

  local domain = contract.state[key]
  if not domain then
    error("key " .. key .. " doesn't not exist.")
  end

  local name = call.payload.name
  local description = call.payload.description

  if type(name) ~= 'string' or name == '' or utf8.len(name) > 50 then
    error('name must have between 1 and 50 characters')
  end

  if type(description) ~= 'string' then
    error('description must be a string')
  end

  table.insert(domain.requests, {
    name = name,
    description = description,
    msatoshi = call.msatoshi,
    status = "open",
    opened = os.time()
  })
  util.print("added request to " .. key .. " with index " .. #domain.requests .. ".")
end

function contribute ()
  -- contributing to an existing request
  if call.msatoshi < 100000 then
    error("must contribute at least 100 sat.")
  end

  local key = call.payload.key

  local domain = contract.state[key]
  if not domain then
    error("key " .. key .. " doesn't not exist.")
  end

  local idx = tonumber(call.payload.idx)

  if domain.requests[idx].status ~= "open" then
    error(key .. ":" .. idx .. " is not open.")
  end

  local weight = domain.requests[idx].msatoshi + call.msatoshi
  domain.requests[idx].msatoshi = weight
  domain.requests[idx].last_contribution = os.time()
  util.print(key .. ":" .. idx .. " has now a weight of " .. weight .. " msat.")
end

function setstatus ()
  local key = call.payload.key
  local domain = contract.state[key]
  if not domain then
    error("key " .. key .. " doesn't not exist.")
  end

  if domain.requests[idx].status ~= "open" then
    error(key .. ":" .. idx .. " is not open.")
  end

  if account.id ~= domain.owner then
    error("only the domain owner can do this")
  end

  local idx = tonumber(call.payload.idx)
  local status = call.payload.status
  if status ~= "finished" and status ~= "canceled" then
    error("status must be: finished or canceled.")
  end

  -- redeem money to owner
  local weight = domain.requests[idx].msatoshi
  if weight > 0 then
    contract.send(domain.owner, weight)
  end

  -- set status
  domain.requests[idx].status = status
  domain.requests[idx].closed = os.time()
end
