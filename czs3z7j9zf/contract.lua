function __init__ ()
  return {hue=0}
end

function sethue ()
  if call.msatoshi < 10000 then
    error('pay at least 10 sat!')
  end

  if type(call.payload.hue) ~= 'number' then
    error('hue is not a number!')
  end

  if call.payload.hue < 0 or call.payload.hue > 360 then
    error('hue is out of the 0~360 range!')
  end

  contract.state.hue = call.payload.hue
  contract.send('ay81i7dw7', call.msatoshi)
end