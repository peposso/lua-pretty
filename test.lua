local _G = _G  -- noqa
local pretty = require "pretty"
local pp, ppf = pretty.p, pretty.pf  -- noqa
local tp = require "tinypretty"

ppf("pretty.lua test.")

ppf("_G=%s", _G)

local Hoge = {}
Hoge.__index = Hoge

function Hoge.new(cls)
  local self = setmetatable({}, cls)
  self.prop1 = 1
  self.prop2 = {2, {3}}
  return self
end
_G.Hoge = Hoge


assert(pretty.pretty({'test'}) == pretty({'test'}))

assert(pretty('\n') == '"\\n"')
assert(pretty({1, 2, 3}) == '{1,2,3}')
assert(pretty({"hello", "world"}) == '{"hello","world"}')
assert(pretty({c=true, b=2, a=1}) == '{a=1,b=2,c=true}')
assert(pretty({[3]=3, [1]=1, ['a']='a', ['2']='2', [true]=true}) ==
       '{1,[3]=3,["2"]="2",a="a",[true]=true}')

local function test1() end
assert(pretty(test1):match('<function @test.lua:%d->'))

pretty.config.depth = 3
local hoge = Hoge:new()

assert(pretty(hoge) == 'Hoge{prop1=1,prop2={2,{3}}}')

Hoge.__name = 'Piyo'
assert(pretty(hoge) == 'Piyo{prop1=1,prop2={2,{3}}}')
Hoge.__name = nil

tp.p({1, 2, 3, 4, 5, hello='world', [500]='test'})
tp.p(5, 4, 6)
