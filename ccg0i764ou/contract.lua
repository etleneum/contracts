function __init__ ()
  return {
    contributors={{}}
  }
end

local contribution = 100000

function contribute ()
  if not account.id then
    error('you must be logged in')
  end

  if call.msatoshi ~= contribution then
    error('must deposit ' .. contribution .. ' msatoshi')
  end

  local currentlevel = #contract.state.contributors - 1
  local currentlevelcontributors = contract.state.contributors[currentlevel + 1]

  table.insert(currentlevelcontributors, account.id)

  local neededcontributors = 2^currentlevel
  if neededcontributors == #currentlevelcontributors then
    -- add a new level
    table.insert(contract.state.contributors, {})

    -- give money to all people on previous level
    local previouslevelcontributors = contract.state.contributors[#contract.state.contributors - 2]

    -- this will be nil if we're in the first two levels
    if previouslevelcontributors == nil then
      return
    end

    for _, account in ipairs(previouslevelcontributors) do
      contract.send(account, contribution * 2)
    end
  end
end