--!strict
--!native

--[[
		# PackIt
		Define schemas, serialize,
		sanitize and compress data.
		
		by richiitalia
		~ Riky47#3355
]]

local Schema = require("@self/Schema")
local Dict = require("@self/Schema/Dict")
local List = require("@self/Schema/List")

local this, schemas = {}, {}
local configs = {}

export type Dict = Schema.DictVariant
export type List = Schema.ListVariant

local function new(tag: string?, s: Schema.Variant): Schema.Variant
	if not tag then return s end
	assert(not schemas[tag], `Schema already exists for tag {tag}`)
	schemas[tag] = s
	return s
end

local function aliases(s: Schema.Variant, ...: string?)
	for i=1, select("#", 1) do
		new(select(i, ...), s)
	end
	
	return s
end

function this.dict(tag: string?, ...: string): Schema.DictVariant
	return aliases(Dict.new(), tag, ...) :: Schema.DictVariant
end

function this.list(tag: string?, ...: string): Schema.ListVariant
	return aliases(List.new(), tag, ...) :: Schema.ListVariant
end

function this.tuple(tag: string?, ...: string): Schema.TupleVariant
	return aliases(Dict.new(true), tag, ...) :: Schema.TupleVariant
end

function this.get(tag: string): Schema.Variant
	local s = schemas[tag]
	assert(s, `Schema does not exists for tag {tag}`)
	return s
end

_G.ASEC = _G.ASEC or {}
_G.ASEC.PackIt = this
return this
