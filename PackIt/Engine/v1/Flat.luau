--!strict
--!native

local VERSION = script.Parent.Name
local s = require("../Types/Type")
local t = require("../Types")
local e = require("../Enums")

local alloc, ser, deser = {}, {}, {}
local this, methods = {}, {}

local BUDDY_TABLE = table.freeze({})
local parserCache = setmetatable({}, { __mode = "k" })

local listHeader = s.new("ListHeader", e.Sizes.WORD, {
	[e.Sizes.WORD] = { write = buffer.writeu16, read = buffer.readu16 }
})

type Proto = {
	_logic: t.Schematized,
	_data: t.Data|buffer
}

type FieldPlan = {
	key: string,
	parser: t.Parser,
	options: any,
	write: t.Write,
	read: t.Read,
	length: t.Lenght?,
	size: number?
}

local flatPlans = setmetatable({}, { __mode = "k" })
local listPlans = setmetatable({}, { __mode = "k" })

local function parserOptions(options: t.UnifiedEntryOptions?)
	options = options or BUDDY_TABLE :: t.UnifiedEntryOptions
	local cached = parserCache[options]
	if cached then return cached end

	local value = options.Values or options.Lenght

	if (options :: any).Schema then
		local ser = options.SerOptions and
			table.clone(options.SerOptions :: any) or {}
		ser.Mode = "Flat"

		value = {
			schema = (options :: any).Schema,
			options = ser
		}
	end

	local parsed = {
		tag = VERSION,
		value = value,
		size = e.Sizes[options.Size :: any],
		options = options :: t.UnifiedEntryOptions
	}
	parserCache[options] = parsed
	return parsed
end

local function getFlatPlan(logic: t.SchematizedDict): {FieldPlan}?
	local cached = flatPlans[logic]
	if cached ~= nil then return cached or nil end

	local plan = table.create(#logic)
	for i = 1, #logic do
		local entry = logic[i]
		if type(entry.type) ~= "string" then
			flatPlans[logic] = false
			return nil
		end

		local options = parserOptions(entry.options)
		local parser = t[entry.type]:Parser(options)
		plan[i] = {
			key = entry.key,
			parser = parser,
			options = options,
			write = parser.write,
			read = parser.read,
			length = parser.lenght,
			size = parser.size
		}
	end

	flatPlans[logic] = plan
	return plan
end

local function getListPlan(logic: t.SchematizedList): FieldPlan?
	if type(logic.type) ~= "string" then return nil end

	local cached = listPlans[logic]
	if cached then return cached end

	local options = parserOptions(logic.options)
	local parser = t[logic.type]:Parser(options)
	local plan = {
		key = "",
		parser = parser,
		options = options,
		write = parser.write,
		read = parser.read,
		length = parser.lenght,
		size = parser.size
	}
	listPlans[logic] = plan
	return plan
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
		for i = 1, #data do
			local entry = data[i]
			size += alloc.object(logic.type :: t.Schematized, entry)
		end

		return size
	end

	local plan = getListPlan(logic) :: FieldPlan
	for i = 1, #data do
		local entry = data[i]
		size += plan.length and plan.length(entry, plan.options)
			or plan.size or 0
	end

	return size
end

function alloc.dict(logic: t.SchematizedDict, data: t.DictData): number
	local plan = getFlatPlan(logic)
	if plan then
		local size = 0
		for i = 1, #plan do
			local field = plan[i]
			local value = data[field.key]
			size += field.length and field.length(value, field.options) or field.size or 0
		end
		return size
	end

	local size = 0

	for i = 1, #logic do
		local entry = logic[i]
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
		for i = 1, count do
			local entry = data[i]
			offset = ser.object(logic.type :: t.Schematized, entry, b, offset)
		end

		return offset
	end

	local plan = getListPlan(logic) :: FieldPlan
	for i = 1, count do
		local entry = data[i]
		local nextOffset = plan.write(b, offset, entry, plan.options)
		offset = nextOffset or offset + (plan.length
			and plan.length(entry, plan.options) or plan.size or 0)
	end

	return offset
end

function ser.dict(logic: t.SchematizedDict, data: t.DictData, b: buffer, offset: number): number
	local plan = getFlatPlan(logic)
	if plan then
		for i = 1, #plan do
			local field = plan[i]
			local nextOffset = field.write(b, offset, data[field.key], field.options)
			offset = nextOffset or offset + (field.length and field.length(data[field.key], field.options) or field.size or 0)
		end
		return offset
	end

	for i = 1, #logic do
		local entry = logic[i]
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
	local data = table.create(count or 0) :: t.ListData

	if count <= 0 then return data, offset end
	if type(logic.type) ~= "string" then
		for i = 1, count do
			data[i], offset = deser.object(logic.type :: t.Schematized, b, offset)
		end

		return data, offset
	end

	local plan = getListPlan(logic) :: FieldPlan
	for i = 1, count do
		local value, nextOffset = plan.read(b, offset, plan.options)
		data[i] = value
		offset = nextOffset or offset + (plan.size or 0)
	end

	return data, offset
end

function deser.dict(logic: t.SchematizedDict, b: buffer, offset: number): (t.DictData, number)
	local plan = getFlatPlan(logic)
	if plan then
		local data = {} :: t.DictData
		for i = 1, #plan do
			local field = plan[i]
			local value, nextOffset = field.read(b, offset, field.options)
			data[field.key] = value
			offset = nextOffset or offset + (field.size or 0)
		end
		return data, offset
	end

	local data = {} :: t.DictData

	for i = 1, #logic do
		local entry = logic[i]
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