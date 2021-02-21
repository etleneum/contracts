function __init__ ()
  return {}
end

local STAKE_PER_OFFER = 100000 -- in msat

local tip = tonumber(http.gettext("https://mempool.space/api/blocks/tip/height"))
if not tip then
  error("couldn't get current block")
end

function queuepay ()
  if call.msatoshi < 1000 then
    error("must include at least 1 sat")
  end

  local addr = call.payload.addr
  local fee_msat = tonumber(call.payload.fee_msat)
  local sat = math.floor((call.msatoshi - fee_msat) / 1000)

  if util.check_address(addr) ~= nil then
    error("address " .. addr .. " is invalid")
  end

  if sat < 0 then
    error("sats to destination can't be negative")
  end

  bump()

  -- if amount paid contains msatoshi not specified in fees, add these to the fees
  local extra_msat = call.msatoshi - (sat * 1000 + fee_msat)
  fee_msat = fee_msat + extra_msat

  local offer = contract.state[addr] or {
    block = 0,
    sat = 0,
    fee_msat = 0,
    stake = 0,
    waiting = nil,
    reserved = nil
  }

  if offer.reserved then
    -- this prevents random people to harm onchain transactors by changing the
    -- amounts while they may be waiting for a confirmation
    error("offer for " .. addr .. " is reserved")
  end

  offer.sat = offer.sat + sat
  offer.fee_msat = offer.fee_msat + fee_msat

  -- this prevents onchain transactors from
  -- altering amounts to suit an existing transaction that wasn't made by them
  offer.block = tip

  contract.state[addr] = offer
end

function reserve ()
  if not account.id then
    error('must be authenticated!')
  end

  bump()

  local stake_needed = 0

  for _, addr in ipairs(call.payload.addresses) do
    local offer = contract.state[addr]

    if offer.reserved then
      error('offer for ' .. addr .. ' is reserved until block ' .. offer.reserved.upto)
    end

    offer.reserved = {
      to = account.id,
      upto = tip + 3 -- reserve for 3 blocks
    }
    offer.stake = (offer.stake or 0) + STAKE_PER_OFFER

    stake_needed = stake_needed + STAKE_PER_OFFER
  end

  if call.msatoshi < stake_needed then
    error('to reserve offers you must stake 1000 sat for each offer reserved')
  end
end

function txsent ()
  if not account.id then
    error('must be authenticated!')
  end

  local tx = _gettx(call.payload.txid)

  local offersmatched = 0

  for _, vout in ipairs(tx.vout) do
    local addr = vout.scriptpubkey_address
    local offer = contract.state[addr]

    if offer then
      -- only transactions newer than the offers are valid
      if not tx.status.block_height or (offer.block < tx.status.block_height) then
        if vout.value ~= offer.sat then
          -- check amounts match exactly and this offer is not reserved
          util.print("output to " .. addr .. " (" .. vout.value .. ") is different than expected (" .. offer.sat .. ")")
        elseif offer.reserved and offer.reserved.to ~= account.id then
          -- check reservation by someone else
          util.print(addr .. " reserved to " .. offer.reserved.to .. ". you are " .. account.id)
        else
          -- make this offer wait for confirmation of this
          -- (will happen in the next bump if already confirmed)
          util.print(offer)
          offer.reserved = { to = account.id }
          offer.waiting = {
            txid = call.payload.txid,
            last_block_checked = tip - 1
          }
          offersmatched = offersmatched + 1
        end
      end
    end
  end

  if offersmatched == 0 then
    error("transaction didn't match any offer")
  end
  util.print("offers matched by the transaction: " .. offersmatched)

  bump()
end

function bump ()
  for addr, offer in pairs(contract.state) do
    if not offer.waiting and offer.reserved and offer.reserved.upto < tip then
      -- reservation period ended, not waiting for any tx to confirm
      -- remove reservation
      offer.reserved = nil -- offer.stake will remain
    elseif offer.waiting and offer.waiting.last_block_checked < tip then
      -- check if there are at least 2 confirmations
      local tx, err = _gettx(offer.waiting.txid)
      if err and err:match('status code: (%d+)') == '404' then
        -- tx is not in the mempool anymore
        util.print('tx ' .. offer.waiting.txid .. ' not in the mempool anymore')
        offer.waiting = nil
      elseif tx.status.confirmed and tip - tx.status.block_height >= 2 then
        -- ok
        -- pay the transactor and delete the offer
        util.print('tx ' .. offer.waiting.txid .. ' confirmed, resolving offer ' .. addr .. ' to ' .. offer.reserved.to)
        contract.send(offer.reserved.to, offer.stake + offer.sat * 1000 + offer.fee_msat)
        contract.state[addr] = nil
      else
        util.print('tx ' .. offer.waiting.txid .. ' does not have 2 confirmations yet, will keep waiting for it')
        offer.waiting.last_block_checked = tip
      end
    end
  end
end

local txcache = {}
function _gettx (txid)
  local cached = txcache[txid]
  if cached then
    return cached[1], cached[2]
  end

  local tx, err = http.getjson("https://mempool.space/api/tx/" .. txid)
  txcache[txid] = {tx, err}

  return _gettx(txid)
end
