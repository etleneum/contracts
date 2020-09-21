function __init__ ()
  return {} -- {<address> = {<pool_min_size> = { amount = <msat>, fee = <msat> }}}
end

function queue ()
  local addr = call.payload.addr
  local fee_msat = tonumber(call.payload.fee_msat)
  local msat = call.msatoshi - fee_msat
  local min_msat = tostring(math.floor(tonumber(call.payload.min_msat)))

  if util.check_address(addr) ~= nil then
    error("address " .. addr .. " is invalid")
  end

  if fee_msat < 0 then
    error("fee_msat can't be negative")
  end

  if msat < 0 then
    error("msat to destination can't be negative")
  end

  contract.state[addr] = contract.state[addr] or {}
  local data = contract.state[addr][min_msat] or {amount = 0, fee = 0}
  data.amount = data.amount + msat
  data.fee = data.fee + fee_msat
  contract.state[addr][min_msat] = data

  dispatch()
end

function dispatch ()
  for addr, pools in pairs(contract.state) do
    for min_msat, data in pairs(pools) do
      if data.amount >= tonumber(min_msat) then
        local included_msat = data.amount + data.fee - 1000 -- save 1000 for the ext call cost
        etleneum.call_external('c8w0c13v75', 'queuepay', { addr = addr, fee_msat = data.fee }, included_msat, {as = nil})

        pools[min_msat] = nil
        break
      end
    end
  end


  -- cleanup
  for addr, pools in pairs(contract.state) do
    local npools = 0
    for i, _ in pairs(pools) do npools = npools + 1 end
    if npools == 0 then
      contract.state[addr] = nil
    end
  end
end