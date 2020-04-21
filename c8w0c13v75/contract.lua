function __init__ ()
  return {}
end

local STAKE_PER_OFFER = 100000

function queuepay ()
  bump()

  if call.msatoshi < 1000 then
    error("must include at least 1 sat")
  end

  local addr = call.payload.addr
  local fee_msat = tonumber(call.payload.fee_msat)
  local sat = math.floor((call.msatoshi - fee_msat) / 1000)

  if sat < 0 then
    error("sats to destination can't be negative")
  end

  -- if amount paid contains msatoshi not specified in fees, add these to the fees
  local extra_msat = call.msatoshi - (sat * 1000 + fee_msat)
  fee_msat = fee_msat + extra_msat

  local offer = contract.state[addr] or {
    block = 0,
    sat = 0,
    fee_msat = 0
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
  offer.block = _getblockchaintip()

  contract.state[addr] = offer
end

function reserve ()
  bump()

  if not account.id then
    error('must be authenticated!')
  end

  local stake_needed = 0

  for _, addr in ipairs(call.payload.addresses) do
    local offer = contract.state[addr]

    if offer.reserved then
      error('offer for ' .. addr .. ' is reserved until block ' .. offer.reserved.upto)
    end

    offer.reserved = {
      to = account.id,
      upto = _getblockchaintip() + 6 -- reserve for 6 blocks
    }

    stake_needed = stake_needed + STAKE_PER_OFFER
  end

  if call.msatoshi < stake_needed then
    error('to reserve offers you must stake 1000 sat for each offer reserved')
  end
end

function txsent ()
  bump()

  if not account.id then
    error('must be authenticated!')
  end

  local tx = http.getjson("https://blockstream.info/api/tx/" .. call.payload.txid)

  if not tx.status.confirmed then
    error('transaction must be confirmed')
  end

  local prize = 0

  for _, vout in ipairs(tx.vout) do
    local addr = vout.scriptpubkey_address
    local offer = contract.state[addr]

    if offer then
      -- check if this user isn't reporting an older transaction as if it was recent
      if offer.block >= tx.status.block_height then
        error('transaction is older than the offer')
      end

      -- check amounts match exactly
      if vout.value ~= offer.sat then
        error("output to " .. addr .. " (" .. vout.value .. ") is different than expected (" .. offer.sat .. ")")
      end

      -- check reservation status
      if offer.reserved and offer.reserved.to ~= account.id then
        error(addr .. " reserved to " .. offer.reserved.to .. ". you are " .. account.id)
      elseif offer.reserved and offer.reserved.to == account.id then
        -- reserved to this account
        prize = prize + STAKE_PER_OFFER -- return staked sats for reservation
      else
        -- offer wasn't reserved, just proceed (it can be paid even if not reserved)
      end

      -- add all amounts to the prize
      prize = prize + offer.sat * 1000 + offer.fee_msat

      -- delete offer
      contract.state[addr] = nil
    end
  end

  -- pay the transactor
  contract.send(account.id, prize)
end

function bump ()
  local tip = _getblockchaintip()

  for _, offer in pairs(contract.state) do
    if offer.reserved and offer.reserved.upto < tip then
      -- remove reservation
      offer.reserved = nil

      -- revert staked sats to the offer fee
      offer.fee_msat = offer.fee_msat + STAKE_PER_OFFER
    end
  end
end

function _getblockchaintip ()
  local tip = tonumber(http.gettext("https://blockstream.info/api/blocks/tip/height"))
  if not tip then
    error("couldn't get current block")
  end
  return tip
end