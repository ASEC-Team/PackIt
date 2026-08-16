--!strict
--!native

local list = require("./List")
local e = require("../Engine")
local u = require("./")

local this, methods = {}, {}
local f = table.freeze

local function pushField(self: u.DictVariant, key: string|number?, value: u.Variant|e.EntryType, options: u.UnifiedEntryOptions?)
	local l = self._logical
	
	if not key then
		key = (options and options.Index) or
			(self._lastKey and self._lastKey +1)
			or #l.entries +1
		
		if type(key) ~= "number" then error(`Key must be a number, got {key}`) end
		self._lastKey = key
	end
	
	if l.keys[key :: any] then error(`{key} field already exists in dictionary`) end
	local entry = {
		options = options,
		type = value,
		key = key
	} :: u.DictEntry
	
	l.keys[key :: any] = entry
	table.insert(l.entries, entry)
	
	return self
end

local function builLogicalSchema(self: u.DictVariant, variant: number): u.SchematizedDict
	local base = u.getBase(self) :: u.DictSchema
	
	if base._cache[variant] then return base._cache[variant] end
	local logical, map = {}, {}
	
	for i=1, variant, 1 do
		u.schematizeDict(logical, map, u.getVariant(self, i) :: u.DictVariant)
	end
	
	if (u.getBase(self) :: u.DictSchema)._indexed then
		for i, v: any in ipairs(logical) do
			if i ~= v.key then
				return error(`Index {i} is missing in tuple`)
			end
		end
	end
	
	base._cache[variant] = logical
	return logical
end

-- Load all the types methods
for _, v in pairs(e.types) do
	methods[v.name] = function(self: u.DictVariant, arg: any?, options: e.UnifiedEntryOptions?): u.DictVariant
		if (u.getBase(self) :: u.DictSchema)._indexed then
			return pushField(self, nil, v.name, arg)
		end
		
		return pushField(self, arg, v.name :: e.EntryType, options :: any)
	end
end

-- Creates a dictionary subs-schema at the given key
function methods:tuple(key: string, func: (tuple: u.TupleVariant) -> ()): u.DictVariant
	local s = this.new(true)
	func(s :: u.TupleVariant)

	return pushField(self, key, s)
end

function methods:dict(key: string, func: (dict: u.DictVariant) -> ()): u.DictVariant
	local s = this.new()
	func(s :: u.DictVariant)

	return pushField(self, key, s)
end

-- Creates a list subs-schema at the given key
function methods:list(key: string, func: (list: u.ListVariant) -> ()): u.DictVariant
	local s = list.new()
	func(s)
	
	return pushField(self, key, s)
end

-- Adds an existing schema to the current one
function methods:schema(key: string, schema: u.Variant|u.Schema, options: u.SerOptions?): u.DictVariant
	return pushField(self, key, "schema", {
		SerOptions = options,
		Schema = schema
		
	} :: u.UnifiedEntryOptions)
end

-- Parses the data to the schema or variant
-- - No matter if serialized or not
-- - No matter input versionings
function methods:Load(data: buffer|u.DictData, options: u.SerOptions?): u.DictData
	local ser = u.serialization(self, options)
	local old = ser.Variant
	local logi

	if type(data) == "buffer" then
		old = e.getHeader(data).Variant
		logi = builLogicalSchema(self, old)
		data = e.deserialize(logi, data) :: u.DictData
	end
	
	logi = builLogicalSchema(self, ser.Variant)
	local diff = old ~= ser.Variant
	
	if diff or not ser.SkipSanitize then
		return u.sanitizeDict(logi :: u.SchematizedDict, data :: u.DictData, diff)
	end
	
	return data :: u.DictData
end

-- Serializes the data to the versionings:
-- - Schema variant (highest by default)
-- - Engine (highest by default)
function methods:Serialize(data: u.DictData, options: u.SerOptions?): buffer
	local ser = u.serialization(self, options)
	
	local logi = builLogicalSchema(self, ser.Variant)
	data = ser.SkipSanitize and data
		or u.sanitizeDict(logi, data)
	
	return e.serialize(logi, data, ser)
end

-- Deserializes the data
function methods:Deserialize(data: buffer, skipSanitize: boolean?): (u.DictData, number)
	local var = e.getHeader(data).Variant
	local logi = builLogicalSchema(self, var)
	
	local des = e.deserialize(logi, data) :: u.DictData
	return skipSanitize and des or
		u.sanitizeDict(logi :: u.SchematizedDict, des :: u.DictData), var
end

-- Returns the logical schema for the variant
function methods:Logic(options: u.Versioning): u.SchematizedDict
	local options = u.versioning(self, options)
	return builLogicalSchema(self, options.Variant)
end

-- Returns the number of bytes it takes to serialize the data
function methods:Bytes(data: u.DictData, options: u.SerOptions?): number
	local ser = u.serialization(self, options)

	local logi = builLogicalSchema(self, ser.Variant)
	data = ser.SkipSanitize and data
		or u.sanitizeDict(logi, data)

	return e.bytes(logi, data, ser)
end

-- Returns a data template of the variant
function methods:Template(options: u.Versioning, lists: boolean?): u.DictData
	local options = u.versioning(self, options)
	local logi = builLogicalSchema(self, options.Variant)
	return u.sanitizeDict(logi, {}, true, lists)
end

-- Pre-generates the schema for each variant
function methods:Build(): u.DictVariant
	local base = u.getBase(self)
	table.clear(base._cache)
	
	for i=1, #base._variants, 1 do
		builLogicalSchema(self, i)
	end
	
	return self
end

-- Makes another version of the schema
-- - Allows to migrate from older versions
-- - Version is sequential by default
function methods:Variant(version: number?): u.DictVariant
	return u.variant(self :: u.DictVariant, this, version) :: u.DictVariant
end

local metatable = { __index = methods }

function this.new(indexed: boolean?): u.DictVariant|u.TupleVariant
	local s = setmetatable({
		_indexed = not not indexed,
		_variants = {},
		_cache = {}

	}, metatable)
	
	return u.variant(s :: u.DictSchema, this, 1)
end

function this.variant(base: u.DictSchema): u.DictVariant
	return setmetatable({
		_base = base,
		_logical = {
			entries = {},
			keys = {}
		}
		
	} :: any, metatable)
end

return this
