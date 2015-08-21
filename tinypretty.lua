local sformat = string.format
local tostring, pairs, print = tostring, pairs, print

local function pretty(t, cycle)
  if type(t) == 'string' then return sformat('%q', t) end
  if type(t) ~= 'table' then return tostring(t) end
  cycle = cycle or {}
  if cycle[t] then return '{*cycle}' end
  cycle[t] = true
  local ls = {}
  for k, v in pairs(t) do
    ls[#ls+1] = sformat('%s=%s', k, pretty(v, cycle))
  end
  return '{'..table.concat(ls, ',')..'}'
end

local function print_(...)
  local arg = select('#', ...) == 1 and ... or {...}
  print(pretty(arg))
end

return {pretty=pretty, print=print_, p=print_,}
