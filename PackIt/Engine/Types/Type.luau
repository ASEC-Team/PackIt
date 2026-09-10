--!strict
--!native

local f = table.freeze :: (table: Entry) -> Entry
local e = require("../Enums")
local s = e.Sanitizers

local this, methods = {}, {}
local parserCache = setmetatable({}, { __mode = "k" })
local sanitizeOptionCache = setmetatable({}, { __mode = "k" })

export type Sanitizers = {((value: any, type: string) -> any?)|Sanitizers}
export type EntryType = string -- Supposed to be "type1"|"type2"|...

export type IntSizes = e.ByteSize|e.WordSize|e.TriByteSize|e.DWordSize
export type FloatSizes = e.DWordSize|e.QWordSize
export type Sizes = IntSizes|e.QWordSize
export type ByteSize = e.ByteSize
export type NoneSize = e.NoneSize

-- Had to repeat stuff cuz it messes up the front-end api typecheck
export type LenghtOptions = {
	Sanitizers: Sanitizers?,
	Default: any?,

	Lenght: number
}

export type EntryOptions = {
	Sanitizers: Sanitizers?,
	Round: number?,
	Default: any?,
	Size: Sizes?
}

export type EnumOptions = {
	Sanitizers: Sanitizers?,
	Default: any?,
	Size: Sizes?,

	Values: Enum|{string}
}

export type UnifiedEntryOptions = {
	Values: Enum|{string|EnumItem}?,
	Lenght: number?,
	Index: number?

} & EntryOptions

export type Lenght = (value: any, options: ParserOptions?) -> number
export type Write = (buffer: buffer, offset: number, value: any, options: ParserOptions?) -> any|number?
export type Read = (buffer: buffer, offset: number, options: any|ParserOptions?) -> (any, number?)
export type ParserOptions = {
	options: UnifiedEntryOptions?,
	size: number?,
	tag: string?,
	value: any?
}

export type Parser = {
	type: ((value: any?, options: EntryOptions?) -> string)?,
	raw: ((value: any, options: ParserOptions?) -> string)?,
	lenght: Lenght?,
	size: number?,
	write: Write,
	read: Read
}

type Parsers = {[number]: Parser}
type Proto = {
	_san: {(any, string, opts: EntryOptions?) -> any?}?,
	_variants: {[string]: Entry},
	name: EntryType,
	_this: Parsers,
	_def: number,
	_val: any?
}

local function getSizes(self: Entry)
	local sizes = {}
	for key, _ in self._this do
		table.insert(sizes, key)
	end
	return sizes
end

local function getParser(self: Entry, size: number?): Parser
	local s = self._this[size or self._def]
	
	if not s then
		error(`Invalid size {size} for type {self.name}, accepts: {
			table.concat(getSizes(self), ", ")}`)
	end

	return s
end

local function getVariant(self: Entry, tag: string?): Entry
	return tag and self._variants[tag] or self
	--[[ if not tag then return self end
	local v = self._variants[tag]
	assert(v, `Unknown variant {tag} of type {self.name}`)
	return v ]]
end

local function useOptions(self: Entry, options: ParserOptions?): Parser
	local size = options and options.size
	local tag = options and options.tag
	if not options then
		return getParser(getVariant(self, tag), size)
	end

	local cache = parserCache[self]
	if not cache then
		cache = setmetatable({}, { __mode = "k" })
		parserCache[self] = cache
	end

	local parser = cache[options]
	if parser then return parser end

	parser = getParser(getVariant(self, tag), size)
	cache[options] = parser
	return parser
end

function methods:Variant(tag: string, defParser: number, parsers: Parsers)
	self._variants[tag] = this.new(self.name, defParser, parsers)
end

function methods:Parser(options: ParserOptions?): Parser
	return useOptions(self, options)
end

function methods:Write(b: buffer, offset: number, value: any, options: ParserOptions?): number
	local parser = useOptions(self, options)
	local off = parser.write(b, offset, value, options)
	return off or offset + (parser.lenght
		and parser.lenght(value, options)
		or parser.size or 0) --(self :: Entry):Bytes(value, options) :: number
end

function methods:Read(b: buffer, offset: number, options: ParserOptions?): (any, number)
	local parser = useOptions(self, options)
	local res, off = parser.read(b, offset, options)
	return res, off or offset +(parser.size or 0)
end

function methods:Bytes(value: any?, options: ParserOptions?): number
	local parser = useOptions(self, options)
	return parser.lenght and parser.lenght(value, options)
		or parser.size or 0
end

function methods.Sanitize(self: Entry, val: any, options: EntryOptions): any
	if not self._san then return val end

	local optionsCache = sanitizeOptionCache[self]
	if not optionsCache then
		optionsCache = setmetatable({}, { __mode = "k" })
		sanitizeOptionCache[self] = optionsCache
	end

	local cached = optionsCache[options]
	local opt
	if cached then
		opt = cached
	else
		opt = table.clone(options :: any)
		opt.Size = opt.Size or e.Sizes[self._def :: any]
		optionsCache[options] = opt
	end

	local parser = getParser(self)
	local typeName = self.name
	if typeName == "auto" then
		typeName = (parser :: any).type(val, opt)
	end

	local raw = parser.raw and parser.raw(val, {
		options = options :: any
	}) or val
	
	for _, sanit in self._san do
		val = sanit(raw, typeName, opt) or val
	end
	return val
end

function methods:Default(): any
	return self._val or "?"
end

function methods:Type(val: any?, options: EntryOptions?)
	local t = self
	if t.name == "auto" then -- ONLY AUTO HAS THIS
		local parser = useOptions(self)
		t = (parser :: any).type(val, options)
	end
	
	return t.name
end

function methods:RawValue(val: any, options: ParserOptions)
	local parser = useOptions(self)
	return parser.raw and parser.raw(val, options) or val
end

local metatable = { __index = methods }
export type Entry = typeof(setmetatable({} :: Proto, metatable))

function this.new(name: string, defParser: number, parsers: Parsers, defaultValue: any?, sanitizers: {(any, string, EntryOptions?) -> any?}?): Entry
	for size, v in parsers do
		v.size = v.size or size
	end

	return f(setmetatable({
		_val = defaultValue,
		_san = sanitizers,
		_def = defParser,
		_this = parsers,
		_variants = {},
		name = name

	} :: Proto, metatable))
end

return this

--[[function this.new(name: string, fields: {Entry}): Entry
	local t = { name = name, size = 0 }
	for _, property in fields do
		t.size += property.size
	end
	
	function t.write(b: buffer, offset: number, ...: any)
		for _, field in fields do
			field.write(b, offset, ...)
			offset += field.size
		end
	end

	function t.read(b: buffer, offset: number): ...any
		local values = {}
		
		for _, field in fields do
			table.insert(values,
				field.read(b, offset))
			
			offset += field.size
		end
		
		return table.unpack(values)
	end
	
	return table.freeze(t) :: Entry
end]]