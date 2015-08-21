local print = print
return function(...)
  local arg = select('#', ...) > 1 and {...} or ...
  local cycle = {}
  local function pretty(t)
    if type(t) ~= 'table' then return tostring(t) end
    if cycle[t] then return '{*cycle}' end
    cycle[t] = true
    local ls = {}; for k, v in pairs(t) do
      ls[#ls+1] = ('%s=%s'):format(k, v)
    end
    cycle[t] = nil
    return '{'..table.concat(ls, ',')..'}'
  end
  local s = pretty(arg)
  print(s)
  return s
end
