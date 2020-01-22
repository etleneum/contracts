function __init__ ()
  return {
    open={_=0},
    closed={_=0}
  }
end

function create ()
  if not account.id then
    error("must be authorized!")
  end

  if call.msatoshi < 1000 then
    error("must have a bounty!")
  end

  local voters = {account.id}
  for _, v in ipairs(call.payload.voters or {}) do
    if not _inarray(voters, v) then
      voters[#voters + 1] = v
    end
  end

  local task = {
    head=call.payload.head,
    desc=call.payload.desc,
    needed=tonumber(call.payload.needed) or 1,
    voters=voters,
    bounty={
      [account.id]=call.msatoshi
    },
    created_at=os.time(),
  }

  if #task.voters < task.needed then
    task.needed = #task.voters
  end

  contract.state.open[util.cuid()] = task
end

-- anyone can contribute to any existing task so there's more chance
-- someone will try to complete it
function fund ()
  local funder = account.id or 'anon'

  if call.msatoshi < 1000 then
    error("must have a bounty!")
  end

  local task = contract.state.open[call.payload.taskid]
  local current = task.bounty[funder] or 0
  task.bounty[funder] = current + call.msatoshi
  contract.state.open[call.payload.taskid] = task
end

-- anyone can call this function to add completion attempt
-- it will be judged later by the voters (or ignored)
-- any completion attempt can be replaced by its owner
function complete ()
  if not account.id then
    error("must be authorized!")
  end

  local task = contract.state.open[call.payload.taskid]
  task.completions = task.completions or {}
  task.completions[account.id] = {
    time=os.time(),
    content=call.payload.content
  }
  contract.state.open[call.payload.taskid] = task
end

-- any voter can call this. if the specified number of votes
-- is reached the prize is awarded and the task is closed
function award ()
  if not account.id then
    error("must be authorized!")
  end

  local task = contract.state.open[call.payload.taskid]
  if not _inarray(task.voters, account.id) then
    error("you're not registered as a voter for this task!")
  end

  local completion = task.completions[call.payload.completer]
  completion.votes = completion.votes or {}
  completion.votes[account.id] = true
  task.completions[call.payload.completer] = completion

  if _tablelength(completion.votes) >= task.needed then
    -- award task
    local amount = 0
    for _, amt in pairs(task.bounty) do
      amount = amount + amt
    end
    contract.send(call.payload.completer, amount)
    contract.state.open[call.payload.taskid] = nil
    task.awarded_at = os.time()
    contract.state.closed[call.payload.taskid] = task
  else
    -- just save vote
    contract.state.open[call.payload.taskid] = task
  end
end

-- this works like award_task, but instead of awarding it deletes the task
-- money is returned to contributors (except anonymous, these lose their money)
function delete ()
  if not account.id then
    error("must be authorized!")
  end

  local task = contract.state.open[call.payload.taskid]
  if not _inarray(task.voters, account.id) then
    error("you're not registered as a voter for this task!")
  end

  task.deletions = task.deletions or {}
  task.deletions[account.id] = true

  if _tablelength(task.deletions) >= task.needed then
    -- delete task and return money to funders
    for funder, amount in pairs(task.bounty) do
      if funder ~= 'anon' then -- anon contributors get nothing
        contract.send(funder, amount)
      end
    end
    contract.state.open[call.payload.taskid] = nil
  else
    -- just save vote
    contract.state.open[call.payload.taskid] = task
  end
end

function _tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function _inarray(arr, v)
  for _, iv in ipairs(arr) do
    if iv == v then
      return true
    end
  end
  return false
end