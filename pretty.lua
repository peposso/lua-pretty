local _G = _G  -- noqa
local table, string, debug = table, string, debug
local type, pcall, pairs = type, pcall, pairs
local tostring = tostring
local print = print

local _M = {}
local config = {
  typeorder = {
    number=1, string=2, boolean=3, ['nil']=4,
  },
  stringmax = 127,
  tablemax = 512,
  depth = 1,
}
_M.config = config

local global_classes_ = nil

local function istype_(v, ...)
  local types = {...}
  local typename = type(v)
  for i = 1, #types do
    if typename == types[i] then return true end
  end
  return false
end

local function pget(func)
  local ok, val = pcall(func)
  if ok then return val end
  return nil
end

local function gclasses_()
  local classes = {}
  for k, v in pairs(_G) do
    if type(v) == 'table' then
      classes[v] = k
    end
  end
  return classes
end

local function metaname_(val)
  if global_classes_ == nil then
    global_classes_ = {}
    for k, v in pairs(_G) do
      if type(v) == 'table' then
        global_classes_[v] = k
      end
    end
  end
  local mt = pget(function() return debug.getmetatable(val) end)
  if not mt then return nil end
  local mtname = pget(function() return mt.__name end)
  return mtname or global_classes_[mt]
end

local function sortedkeys(t)
  local keys = {}
  for k in pairs(t) do
    table.insert(keys, k)
  end
  local typeorder = config.typeorder
  table.sort(keys, function(a, b)
    local ok, lt = pcall(function() return a < b end)
    if ok and type(lt) == 'boolean' then return lt end
    local ta, tb = type(a), type(b)
    if ta == tb then
      -- ex) ud-ud, tbl-tbl, bool-bool, co-co,
      return tostring(a) < tostring(b)
    end
    local oa, ob = typeorder[ta] or 256, typeorder[tb] or 256
    if oa ~= ob then
      return oa < ob
    end
    return ta < tb
  end)
  return keys
end

-- to human readable string
local function _pretty(t, opt)
  opt = opt or {}
  opt.depth = opt.depth or config.depth
  opt.classes = opt.classes or gclasses_()
  if t == nil then
    return 'nil'
  elseif type(t) == 'string' then
    local s = string.format('%q', t):gsub('\n', 'n')
    if config.stringmax and #s > config.stringmax then
      s = s:sub(1, config.stringmax - 4)..'..."'
    end
    return s
  elseif type(t) == 'userdata' then
    local s = tostring(t)
    local ptr = s:match('^userdata: (0x.-)$')
    if not ptr then return s end
    local mtname = metaname_(t, opt.classes)
    return string.format('%s{userdata:*%s}', mtname or '', ptr)
  elseif type(t) == 'function' then
    local s = tostring(t)
    local ptr = s:match('^function: (0x.-)$')
    if not ptr then return s end
    local info = debug.getinfo(t)
    if info.what == 'C' then
      return '<cfunction>'
    end
    local source = info.source
    if source then
      source = source:match('^@(.-)$') or source
      source = source:match('/lua/(.-)$') or source
      source = '@'..source
    end
    local ftype = 'function'
    if info.namewhat ~= '' then
      ftype = info.namewhat..' function'
    end
    if info.name ~= nil and info.name ~= '' then
      return string.format('<%s %s %s:%s>',
                           ftype,
                           info.name,
                           source,
                           info.linedefined)
    end
    return string.format('<%s %s:%s>',
                         ftype,
                         source,
                         info.linedefined)
  elseif type(t) ~= 'table' then
    return tostring(t)
  end
  -- else table
  local bracket = opt.bracket or config.bracket or '{}'
  local mtname = metaname_(t, opt.classes)
  local s = tostring(t)
  local ptr = s:match('^table: (0x.-)$')
  if not ptr then return s end
  if opt.depth <= 0 then
    return string.format('%s%s*%s%s',
                         mtname or '',
                         bracket:sub(1, 1),
                         ptr,
                         bracket:sub(2, 2))
  end

  local keys = sortedkeys(t)
  local index = 1
  local size = 0
  local items = {}
  local optnext = {depth=opt.depth-1}
  for i = 1, #keys do
    local key = keys[i]
    local val = t[key]
    local item;
    if type(key) == 'number' and key == index then
      index = index + 1
      item = _pretty(val, optnext)
    elseif type(key) == 'string' and key:match('^[a-zA-Z_][0-9a-zA-Z_]*$') then
      item = string.format('%s=%s', key, _pretty(val, optnext))
    else
      item = string.format('[%s]=%s',
                           _pretty(key, optnext),
                           _pretty(val, optnext))
    end
    size = size + #item + 1
    items[#items+1] = item
    if config.tablemax and size > config.tablemax - 2 then
      items[#items] = '...'
      break
    end
  end
  return string.format('%s%s%s%s',
                       mtname or '',
                       bracket:sub(1, 1),
                       table.concat(items, ','),
                       bracket:sub(2, 2))
end

local function pretty(...)
  local n = select('#', ...)
  if n == 1 then
    return _pretty(...)
  end
  return _pretty({...}, {depth=config.depth, bracket='()'})
end


-- exports
_M.sortedkeys = sortedkeys
_M.pretty = pretty

function _M.print(...)
  print(pretty(...))
end

function _M.printf(f, ...)
  local n = select('#', ...)
  local args = {}
  for i = 1, n do
    local a = select(i, ...)
    if istype_(a, 'number', 'string', 'boolean')  then
      args[i] = a
    else
      args[i] = pretty(a)
    end
  end
  print(string.format(f, unpack(args)))
end

_M.p = _M.print

setmetatable(_M, {
  __call=function(_, ...) return pretty(...) end,
})

return _M
