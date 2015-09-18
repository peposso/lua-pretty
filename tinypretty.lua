local print = print
return function(...)
  local arg = select('#', ...) > 1 and {...} or ...
  local cycle = {}
  local tinsert = table.insert
  local function pretty(t)
    if type(t) ~= 'table' then return tostring(t) end
    if cycle[t] then return '{*cycle}' end
    cycle[t] = true
    local ls = {}
    if t[1] ~= nil then
      for i = 1, #t do tinsert(ls, pretty(t[i])) end
      for k, v in pairs(t) do
        if type(k) ~= 'number' or math.floor(k) ~= k or k <= 0 or #t < k then
          tinsert(ls, ('%s=%s'):format(k, pretty(v)))
        end
      end
    else
      for k, v in pairs(t) do
        tinsert(ls, ('%s=%s'):format(k, pretty(v)))
      end
    end
    cycle[t] = nil
    return '{'..table.concat(ls, ',')..'}'
  end
  local s = pretty(arg)
  print(s)
  return s
end
