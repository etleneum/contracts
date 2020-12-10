function __init__ ()
   local admin = 'aiw1244jb41'
   local email = 'somes731@gmail.com'
   return {
      admin = admin,
      email = email,
      users={_=0},
      deals={_=0},
      log ={_=0}
   }
end

function _tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function _return_bond(buyer)
   local seller = contract.state.deals[buyer].seller
   local bond = contract.state.deals[buyer].bond
   local value = contract.state.deals[buyer].value
   contract.send(buyer, bond/2)
   contract.send(seller, bond/2)
   
   if contract.state.deals[buyer].stage == 2 then
    contract.state.users[buyer].completed = contract.state.users[buyer].completed + 1   
    contract.state.users[seller].completed = contract.state.users[seller].completed + 1
    contract.send(seller, value)
   end
   
   contract.state.deals[buyer].stage = 3
end

function _log_state(buyer)
   local closed_deal = contract.state.deals[buyer]
   if not contract.state.log[buyer] then
    contract.state.log[buyer] = {}
   end  
   local idx = _tablelength(contract.state.log[buyer]) + 1
   contract.state.log[buyer][idx] = {
      stage=closed_deal.stage,
      value=closed_deal.value,
      seller=closed_deal.seller
   }
end

function link ()
   if not account.id then
     error('you must be logged in')
   end
   if contract.state.deals[account.id] ~= nil then
    contract.state.deals[account.id].key = call.payload.key
   else
    contract.state.users[account.id] = {
      contact=call.payload.contact,
      key=call.payload.key,
      offers=0,
      completed=0,
      guilty=0,
      disputed=0
   }
   end
end

function unlink ()
   if not account.id then
      error('you must be logged in')
   end
   if contract.state.deals[account.id] ~= nil then
    contract.state.deals[account.id].contact = ""
    contract.state.deals[account.id].key = ""
   else
    error('no user to unlink')
   end
end

function bid()
   buyer = account.id
   if not buyer then
     error('you must be logged in')
   end
   
   local deal = contract.state.deals[buyer]
   if deal ~= nil then
    local state = contract.state.deals[buyer].stage
    if state ~= 3 and state ~= 0 then
      error("contract cant be updated")
    end
   end
   
   local pk = contract.state.users[buyer].key
   if pk == nil then
      error("register your public key first")
   end
   
   local type = call.payload.type
   local fiat = tonumber(call.payload.fiat)
   local currency = call.payload.currency
   local expiration = os.time() + (call.payload.expiration or 144)*600
   
   local msat = call.msatoshi
   
   if msat < 150000000 then
      error("contract starts from 149999 sats")
   end
   
   local value = msat/1.2
   local bond = msat - value
   
   contract.state.deals[buyer] = {
      stage=1,
      value=value,
      bond=bond,
      type=type,
      fiat=fiat,
      seller="",
      secret="",
      expiration=expiration
   }
   contract.state.users[buyer].offers = contract.state.users[buyer].offers + 1
end

function ask()
   seller = account.id
   if not seller then
     error('you must be logged in')
   end
   
   local deal = contract.state.deals[seller]
   if deal ~= nil then
    local state = contract.state.deals[seller].state
    if state ~= 0 then
      error("close contract first")
    end
   end
   
   local pk = contract.state.users[seller].key
   if pk == nil then
      error("register your public key first")
   end

   local type = call.payload.type
   local fiat = tonumber(call.payload.fiat)
   local sats = tonumber(call.payload.sats)
   local currency = call.payload.currency
   local msat = call.msatoshi
   
   if msat < 99000 then
      error("pay 100 sat to advertise position")
   end

   contract.state.deals[seller] = {
      stage=0,
      type=type,
      fiat=fiat,
      sats=sats,
      currency=currency,
      expiration=0
   }
   contract.send(contract.state.admin, msat)
end

function match_ask()
   buyer = account.id
   if not buyer then
     error('you must be logged in')
   end
   local pk = contract.state.users[buyer].key
   if pk == nil then
      error("register your public key first")
   end
   
   local seller = call.payload.seller
   local deal = contract.state.deals[seller]
   local expiration = os.time() + 144*600
   
   if deal == nil then
      error('there is no ask')
   end
      
   local msat = call.msatoshi
   
   if msat ~= 1200*deal.sats then
     error('provide bond and deposit i.e. double contract value')
   end
   
   local value = msat/1.2
   local bond = msat - value
   
   contract.state.deals[buyer] = {
      stage=1,
      value=value,
      bond=bond,
      type=deal.type,
      fiat=deal.fiat,
      currency=deal.currency,
      seller=seller,
      secret="",
      expiration=expiration
   }
   contract.state.users[buyer].offers = contract.state.users[buyer].offers + 1
end

function accept()
   seller = account.id
   if not seller then
     error('you must be logged in')
   end
   local pk = contract.state.users[seller].key
   if pk == nil then
      error("register your public key first")
   end
   local buyer = call.payload.buyer
   local deal = contract.state.deals[buyer]

   if deal == nil then
      error('there is no bid')
   end
   
   if deal.stage ~= 1 then
      error('bad stage to proceed')
   end
   
   if deal.seller ~= "" and deal.seller ~= seller  then
      error('you cant accept this deal')
   end

   if deal.expiration < os.time() then
      error('contract expired')
   end

   local msat = call.msatoshi
   if msat ~= deal.bond then
     error('provide the same bond value')
   end

   local encsec = call.payload.ecrypted
   if encsec == nil then
     error('ecrypted secret is empty')
   end 
  
   contract.state.deals[buyer].seller = seller
   contract.state.deals[buyer].secret = encsec
   contract.state.deals[buyer].bond = 2*contract.state.deals[buyer].bond
   contract.state.deals[buyer].stage = 2
   
   contract.state.users[seller].offers = contract.state.users[seller].offers + 1
end

function confirm()
   local buyer = account.id
   if not buyer then
     error('you must be logged in')
   end

   local deal = contract.state.deals[buyer]

   if deal == nil then
      error('there is no bid')
   end
   
   if deal.stage ~= 2 then
      error('contract is locked or you are not buyer')
   end
   _return_bond(buyer)
   _log_state(buyer)
end

function dispute_buy()
   local buyer = account.id
   if not buyer then
     error('you must be logged in')
   end

   local deal = contract.state.deals[buyer]
   if deal == nil then
      error('there is no bid')
   end
   
   if deal.stage ~= 2 then
      error('you cant dispute this contract')
   end
   
   contract.state.deals[buyer].stage = -1
   contract.state.users[buyer].disputed = contract.state.users[buyer].disputed + 1 
end

function retract_buy()
   local buyer = account.id
   if not buyer then
     error('you must be logged in')
   end

   local deal = contract.state.deals[buyer]

   if deal == nil then
      error('there is no contract')
   end   
   if deal.stage ~= 1 then
      error('you cant retract this contract')
   end
   contract.send(buyer, deal.bond)
   contract.send(buyer, deal.value)
   contract.state.deals[buyer] = {
      stage=0,
      value=0,
      bond=0,
      type='none',
      fiat='none',
      currency='none',
      seller='none',
      secret='',
      expiration=0
   }
end

function retract_sell()
   local seller = account.id
   if not seller then
     error('you must be logged in')
   end

   local buyer = call.payload.buyer
   local deal = contract.state.deals[buyer]

   if deal == nil then
      error('there is no contract')
   end   
   if deal.seller ~= seller or deal.stage < -1 then
      error('you cant retract this contract')
   end
   
   contract.state.deals[buyer].stage = -2
   _log_state(buyer)
   _return_bond(buyer)
   local value = contract.state.deals[buyer].value
   contract.send(seller, value)
end

function dispute_sell()
   local seller = account.id
   if not seller then
     error('you must be logged in')
   end

   local buyer = call.payload.buyer
   local deal = contract.state.deals[buyer]
   if deal == nil then
      error('there is no contract')
   end
   
   if deal.seller ~= seller or deal.stage < -1 then
      error('you cant retract this contract')
   end
   
   contract.state.deals[buyer].stage = -3
   contract.state.users[seller].disputed = contract.state.users[seller].disputed + 1 
end

function refund()
   local admin = account.id
   if not admin or admin ~=contract.state.admin then
     error('you must be logged in and you must be admin to use this function')
   end

   local buyer = call.payload.buyer
   local guilty = call.payload.guilty
   local deal = contract.state.deals[buyer]

   if deal == nil or buyer == nil then
      error('there is no buyer or contract')
   end   
   
   if deal.stage > -1 then
      error('cant be resolved')
   end
   
   local value = contract.state.deals[buyer].value
   local bond = contract.state.deals[buyer].bond
   local seller = contract.state.deals[buyer].seller
   if seller == guilty then
     contract.send(admin, bond/2)
     contract.send(buyer, bond/2)
     contract.send(buyer, value)
     contract.state.users[seller].guilty = contract.state.users[seller].guilty + 1 
   end
   if buyer == guilty then
     contract.send(admin, bond/2)
     contract.send(seller, bond/2)
     contract.send(seller, value)
     contract.state.users[buyer].guilty = contract.state.users[buyer].guilty + 1 
   end
   _log_state(buyer)   
   contract.state.deals[buyer].stage = 3
end