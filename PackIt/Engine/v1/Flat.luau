--!strict
--!native

local VERSION = script.Parent.Name
local s = require("../Types/Type")
local t = require("../Types")
local e = require("../Enums")

local alloc, ser, deser = {}, {}, {}
local this, methods = {}, {}

local listHeader = s.new("ListHeader", e.Sizes.WORD, {
	[e.Sizes.WORD] = { write = buffer.writeu16, read = buffer.readu16 }
})

type Proto = {
	_logic: t.Schematized,
	_data: t.Data|buffer
}

-- Helpers
local function copyDict(dict: {[any]: any})
	local new = {}
	for k, v in pairs(dict or {}) do
		new[k] = v
	end
	
	return new
end

local function parserOptions(options: t.UnifiedEntryOptions?)
	options = options or {} :: t.UnifiedEntryOptions
	local ser = copyDict(options.SerOptions :: any)
	ser.Mode = "Flat"
	
	local schema = (options :: any).Schema and {
		schema = (options :: any).Schema,
		options = ser
	}
	
	return {
		tag = VERSION,
		size = e.Sizes[options.Size :: any],
		options = options :: t.UnifiedEntryOptions,
		value = options.Values or options.Lenght or schema
	}
end

local function isListSchema(logi: t.Schematized)
	local l = (logi :: t.SchematizedList)
	return not not l.type
end

-- Alloc
function alloc.object(logic: t.Schematized, data: t.Data): number
	return if isListSchema(logic) then
		alloc.list(logic :: t.SchematizedList, data :: t.ListData)
	else
		alloc.dict(logic :: t.SchematizedDict, data :: t.DictData)
end

function alloc.list(logic: t.SchematizedList, data: t.ListData): number
	local size = listHeader:Bytes()
	if #data <= 0 then return size end
	
	if type(logic.type) ~= "string" then
		for _, entry in data do
			size += alloc.object(logic.type :: t.Schematized, entry)
		end
		
		return size
	end
	
	local opts = parserOptions(logic.options)
	for _, entry in data do
		size += t[logic.type]:Bytes(entry, opts :: any)
	end

	return size
end

function alloc.dict(logic: t.SchematizedDict, data: t.DictData): number
	local size = 0
	
	for i, entry in logic do
		if type(entry.type) ~= "string" then
			size += alloc.object(entry.type :: t.Schematized, data[entry.key])
			continue
		end
		
		size += t[entry.type]:Bytes(data[entry.key],
			parserOptions(entry.options) :: any)
	end
	
	return size
end

-- Serialize
function ser.object(logic: t.Schematized, data: t.Data, b: buffer, offset: number): number
	return if isListSchema(logic) then
		ser.list(logic :: t.SchematizedList, data :: t.ListData, b, offset)
	else
		ser.dict(logic :: t.SchematizedDict, data :: t.DictData, b, offset)
end

function ser.list(logic: t.SchematizedList, data: t.ListData, b: buffer, offset: number): number
	local count = #data
	
	offset = listHeader:Write(b, offset, count)
	if count <= 0 then return offset end
	
	if type(logic.type) ~= "string" then
		for _, entry in data do
			offset = ser.object(logic.type :: t.Schematized, entry, b, offset)
		end
		
		return offset
	end
	
	local opts = parserOptions(logic.options)
	for _, entry in data do
		offset = t[logic.type]:Write(b, offset, entry, opts :: any)
	end
	
	return offset
end

function ser.dict(logic: t.SchematizedDict, data: t.DictData, b: buffer, offset: number): number
	for i, entry in logic do
		if type(entry.type) ~= "string" then
			offset = ser.object(entry.type :: t.Schematized, data[entry.key], b, offset)
			continue
		end
		
		offset = t[entry.type]:Write(b, offset, data[entry
			.key], parserOptions(entry.options) :: any)
	end
	
	return offset
end

-- Deserialization
function deser.object(logic: t.Schematized, b: buffer, offset: number): (t.Data, number)
	if isListSchema(logic) then
		return deser.list(logic :: t.SchematizedList, b, offset)
	end
	return deser.dict(logic :: t.SchematizedDict, b, offset)
end

function deser.list(logic: t.SchematizedList, b: buffer, offset: number): (t.ListData, number)
	local count, offset = listHeader:Read(b, offset)
	local data = {} :: t.ListData
	
	if count <= 0 then return data, offset end
	if type(logic.type) ~= "string" then
		for i = 1, count do
			local entry, off = deser.object(logic.type :: t.Schematized, b, offset)
			table.insert(data, entry)
			offset = off
		end
		
		return data, offset
	end
	
	local opts = parserOptions(logic.options)
	for i = 1, count do
		local entry, off = t[logic.type]:Read(b, offset, opts :: any)
		table.insert(data, entry)
		offset = off
	end
	
	return data, offset
end

function deser.dict(logic: t.SchematizedDict, b: buffer, offset: number): (t.DictData, number)
	local data = {} :: t.DictData
	
	for i, entry in logic do
		if type(entry.type) ~= "string" then
			data[entry.key], offset = deser.object(entry.type :: t.Schematized, b, offset)
			continue
		end
		
		local opts = parserOptions(entry.options)
		data[entry.key], offset = t[entry.type]:Read(b, offset, opts :: any)
	end
	
	return data, offset
end

-- Methods
function methods:Bytes(addBytes: number?)
	return alloc.object(self._logic, self._data :: t.Data) +(addBytes or 0)
end

function methods:Alloc(addBytes: number?): buffer
	return buffer.create((self :: Serializer):Bytes(addBytes))
end

function methods:Serialize(b: buffer?, offset: number?): (buffer, number)
	local b = b or (self :: Serializer):Alloc()
	offset = ser.object(self._logic, self
		._data :: t.Data, b, offset or 0)
	
	return b, offset
end

function methods:Deserialize(offset: number?): (t.Data, number)
	return deser.object(self._logic, self
		._data :: buffer, offset or 0)
end

local metatable = { __index = methods }
export type Serializer = typeof(setmetatable({} :: Proto, metatable))

function this.new(logic: t.Schematized, data: t.Data|buffer): Serializer
	return setmetatable({
		_logic = logic,
		_data = data

	} :: Proto, metatable)
end

return this