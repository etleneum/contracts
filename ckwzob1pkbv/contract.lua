function _round(num,dec)
    return tonumber(string.format("%." .. dec .. "f", num))
end
function _calculate_price()
    contract.state.price=_round(contract.state.issued/contract.state.balance[contract.state.admin],4) or contract.state.issued
end
function __init__ ()
    local issued=2100000000000
    local admin = 'ankzhb1ko9w'
    return {
        issued = issued,
        admin = admin,
        price = 1,
        balance = { 
            [admin] = issued
        }
    }
end

function _transfer_exec (from,to,amount)
    if not from or not amount or amount <0 or not to then
        error('nil')
    end
    local rounded_amount=_round(amount,0)
    if contract.state.balance[from] < rounded_amount then
        error("not enought balance")
    end
    contract.state.balance[from] = contract.state.balance[from] - rounded_amount
    contract.state.balance[to] = contract.state.balance[to] or 0
    contract.state.balance[to] = contract.state.balance[to] + rounded_amount
    _calculate_price()
end

function buy()
    if not account.id then
        error('not authenticated')
    end
    local amount = call.msatoshi 
    _transfer_exec(contract.state.admin, account.id, amount / contract.state.price)
end

function sell()
    if not account.id then
        error('not authenticated')
    end             
    local amount = tonumber(call.payload.magda_amount)
    _transfer_exec(account.id, contract.state.admin, amount)
    local tosend = amount * contract.state.price
    contract.send(account.id, tosend * 0.99)
    contract.send(contract.state.admin, tosend * 0.01)
end

function transfer ()
    if not account.id then
        error('not authenticated')
    end
    local to = call.payload.to
    local amount = tonumber(call.payload.magda_amount)
    _transfer_exec(account.id,to,amount)
end
