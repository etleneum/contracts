function __init__ ()
    return {
        issued = 2100000000000,
        admin = 'ankzhb1ko9w',
        balance = { ankzhb1ko9w = 2100000000000}
    }
end
function _transfer_exec (from,to,amount)
    if not from or not amount or amount <=0 or not to then
        error('from nil')
    end

    contract.state.balance[from] = contract.state.balance[from] - amount
    contract.state.balance[to] = contract.state.balance[to] or 0
    contract.state.balance[to] = contract.state.balance[to] + amount
end

function transfer ()
    if not account.id then
        error('not authenticated')
    end
    local to = call.payload.to
    local amount = call.payload.amount
    _transfer_exec(account.id,to,amount)
end



function _calculate_price()
    return contract.state.issued / contract.state.balance[contract.state.admin]
end

function buy()
    local amount = call.msatoshi 
    _transfer_exec(contract.state.admin, account.id, amount * _calculate_price())
end

function sell()
    local amount = tonumber(call.payload.amount)
    _transfer_exec(account.id, contract.state.admin, amount)
    local tosend = amount / _calculate_price()
    contract.send(account.id, tosend * 0.99)
    contract.send(contract.state.admin, tosend * 0.01)
end
