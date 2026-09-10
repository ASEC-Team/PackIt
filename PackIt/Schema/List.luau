--!strict
--!native

local e = require("../Engine")
local u = require("./")

local BUDDY_TABLE = table.freeze({})

local this, methods = {}, {}

local function setList(self: u.ListVariant, value: u.Variant|e.EntryType, options: u.UnifiedEntryOptions?)
	assert(not self._logical.type, `List type already set`)
	
	self._logical = {
		options = options,
		type = value
	}
end

local function builLogicalSchema(self: u.ListVariant, variant: number): u.SchematizedList
	local base = u.getBase(self) :: u.ListSchema
	
	if base._cache[variant] then return base._cache[variant] end
	local logical: u.SchematizedList = { type = nil } :: any
	local map = {}

	for i = 1, variant, 1 do
		local var = u.getVariant(self, i) :: u.ListVariant
		logical = u.schematizeList(logical, map, var)
	end

	base._cache[variant] = logical
	return logical
end

-- Load all the types methods
for _, v in pairs(e.types) do
	methods[v.name] = function(self: u.ListVariant, options: e.UnifiedEntryOptions?)
		setList(self, v.name :: e.EntryType, options :: any)
	end
end

-- Creates a dictionary subs-schema at the given key
function methods:dict(func: (dict: u.DictVariant) -> ())
	local dict = require("./Dict") :: any -- Cyclic require
	local s = dict.new()
	func(s)

	setList(self, s)
end

-- Creates a list subs-schema at the given key
function methods:list(func: (list: u.ListVariant) -> ())
	local s = this.new()
	func(s)

	setList(self, s)
end

-- Adds an existing schema to the current one
function methods:schema(schema: u.Variant|u.Schema, options: u.SerOptions?)
	setList(self, "schema", {
		SerOptions = options,
		Schema = schema

	} :: u.UnifiedEntryOptions)
end

-- Parses the data to the schema or variant
-- - No matter if serialized or not
-- - No matter input versionings
function methods:Load(data: buffer|string|u.ListData, options: u.SerOptions?)
	local ser = u.serialization(self, options)
	local old = ser.Variant
	local logi

	if type(data) == "buffer" then
		local head = e.getHeader(data)
		old = head.Variant
		
		logi = builLogicalSchema(self, old)
		data = e.deserialize(logi, data) :: u.ListData
	end

	logi = builLogicalSchema(self, ser.Variant)
	local diff = old ~= ser.Variant

	if diff or not ser.SkipSanitize then
		return u.sanitizeList(logi :: u.SchematizedList, data :: u.ListData, diff)
	end
	
	return data :: u.ListData
end

-- Serializes the data to the versionings:
-- - Schema variant (highest by default)
-- - Engine (highest by default)
function methods:Serialize(data: u.ListData, options: u.SerOptions?): buffer
	local ser = u.serialization(self, options)

	local logi = builLogicalSchema(self, ser.Variant)
	data = ser.SkipSanitize and data
		or u.sanitizeList(logi, data)

	return e.serialize(logi, data, ser)
end

-- Deserializes the data
function methods:Deserialize(data: buffer, skipSanitize: boolean?): (u.ListData, number)
	local var = e.getHeader(data).Variant
	local logi = builLogicalSchema(self, var)
	
	local des = e.deserialize(logi, data) :: u.ListData
	return skipSanitize and des or
		u.sanitizeList(logi :: u.SchematizedList, des :: u.ListData), var
end

-- Returns the logical schema for the variant
function methods:Logic(options: u.Versioning): u.SchematizedList
	local options = u.versioning(self, options)
	return builLogicalSchema(self, options.Variant)
end

-- Returns the number of bytes it takes to serialize the data
function methods:Bytes(data: u.ListData, options: u.SerOptions?): number
	local ser = u.serialization(self, options)

	local logi = builLogicalSchema(self, ser.Variant)
	data = ser.SkipSanitize and data
		or u.sanitizeList(logi, data)

	return e.bytes(logi, data, ser)
end

-- Returns a data template of the variant
function methods:Template(options: u.Versioning, lists: boolean?): u.ListData
	local options = u.versioning(self, options)
	local logi = builLogicalSchema(self, options.Variant)
	return u.sanitizeList(logi, BUDDY_TABLE, true, lists)
end

-- Pre-generates the schema for each variant
function methods:Build(): u.ListVariant
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
function methods:Variant(version: number?): u.ListVariant
	return u.variant(self :: u.ListVariant, this, version) :: u.ListVariant
end

local metatable = { __index = methods }

function this.new(): u.ListVariant
	local s = setmetatable({
		_variants = {},
		_cache = {}

	}, metatable)

	return u.variant(s :: u.ListSchema, this, 1) :: u.ListVariant
end

function this.variant(base: u.ListSchema): u.ListVariant
	return setmetatable({
		_logical = {} :: any,
		_base = base

	}, metatable)
end

return this
