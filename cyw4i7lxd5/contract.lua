function __init__ ()
  return {number=0}
end

function up ()
  local amount = call.payload.amount or 1
  contract.state.number = contract.state.number + amount
end

function down ()
  local amount = call.payload.amount or 1
  contract.state.number = contract.state.number - amount
end