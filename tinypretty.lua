local print = print
return function(...)
  local arg = select('#', ...) > 1 and {...} or ...
  local cycle = {}
  local function pretty(t)
    if type(t) == 'string' then return ('%q'):format(t) end
    if type(t) ~= 'table' then return tostring(t) end
    if cycle[t] then return '{*cycle}' end
    cycle[t] = true
    local ls, keys, index = {}, {}, 1
    for k in pairs(t) do keys[#keys+1] = k end
    table.sort(keys, function(a, b)
      local ok, ret = pcall(function() return a < b end)
      if ok then return ret end
      local ta, tb = type(a), type(b)
      if ta ~= tb then return ta < tb end
      return tostring(a) < tostring(b)
    end)
    for i = 1, #keys do
      local k = keys[i]
      if k == index then
        ls[#ls+1] = pretty(t[k])
        index = index + 1
      elseif type(k) == 'string' and k:match('^[%l%u_][%w_]*$') then
        ls[#ls+1] = ('%s=%s'):format(k, pretty(t[k]))
      else
        ls[#ls+1] = ('[%s]=%s'):format(pretty(k), pretty(t[k]))
      end
    end
    cycle[t] = nil
    return '{'..table.concat(ls, ',')..'}'
  end
  local s = pretty(arg)
  print(s)
  return s
end
