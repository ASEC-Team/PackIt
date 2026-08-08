--!strict
--!native

local a = require("@self/Auto")
local e = require("../Enums")
local t = require("./Type")
local this = {}

local function new(size: number, count: number): (t.Parser, number)
	return { size = size *count } :: t.Parser, count
end

local function mapList(list: {any}): {[string]: any}
	local map = {}
	for i, v in list do map[v] = i end
	return map
end

local function dictCopy(dict: {[string]: any})
	local copy = {}
	for k, v in pairs(dict) do
		copy[k] = v
	end
	return copy
end

local function round(value: number, options: t.ParserOptions?, unround: boolean?)
	local round = options and options.options and options.options.Round
	if round then
		if type(value) ~= "number" then error("Value to round must be a number") end
		if round == 0 or not math.isfinite(round) then
			error("Round at decimal must be different than 0")
		end

		value = unround and value *round or math.round(value /round)
	end

	return value
end

local function newlCFrame(ax: number, ay: number, az: number, angle: number, x: number, y: number, z: number)
	return CFrame.fromAxisAngle(
		Vector3.new(ax, ay, az), angle 

	) +Vector3.new(x, y, z)
end

local function conformAutoValue(value: any, options: t.ParserOptions, read: boolean?): any
	if not options.options or not options.options.Round then
		return value end

	local t = typeof(value)
	if t == "number" then
		return round(value, options, read)

	elseif t == "Vector2" then
		return Vector2.new(
			round(value.X, options, read),
			round(value.Y, options, read))

	elseif t == "Vector3" then
		return Vector3.new(
			round(value.X, options, read),
			round(value.Y, options, read),
			round(value.Z, options, read))
	end
	
	-- CFrame not required atm
	return value
end

function this.numbers(parsers: {[number]: t.Parser})
	for _, v in pairs(parsers) do
		local w, r = v.write, v.read
		
		function v.raw(v, opt)
			return round(v, opt)
		end
		
		function v.write(b, o, v, opt, ...)
			return w(b, o, round(v, opt), opt, ...)
		end
		
		function v.read(b, o, opt, ...)
			return round(r(b, o, opt, ...), opt, true)
		end
	end
	
	return parsers
end

function this.list(write: t.Write, read: t.Read, size: number, listLen: number, constructor: (...any) -> any)
	local wrapper, count = new(size, listLen)
	
	function wrapper.raw(values: {any}, options: t.ParserOptions)
		local list = {}
		for i = 0, count -1 do
			table.insert(list, round(values[i +1], options))
		end
		
		return constructor(table.unpack(list))
	end

	function wrapper.write(b: buffer, offset: number, values: {any}, options: t.ParserOptions?)
		for i = 0, count -1 do
			write(b, offset +i *size, round(
				values[i +1], options), options)
		end

		return nil
	end
	
	function wrapper.read(b: buffer, offset: number, options: t.ParserOptions?)
		local list = {}
		for i = 0, count -1 do
			local res = read(b, offset +i *size, options)
			local val = round(res, options, true)
			table.insert(list, val)
		end

		return constructor(table.unpack(list))
	end

	return wrapper
end

function this.object(write: t.Write, read: t.Read, size: number, properties: {string}, constructor: (...any) -> any)
	local wrapper, count = new(size, #properties)
	
	function wrapper.raw(value: any, options: t.ParserOptions?)
		local list = {}
		for i = 0, count -1 do
			table.insert(list, round(
				value[properties[i +1]], options))
		end
		
		return constructor(table.unpack(list))
	end

	function wrapper.write(b: buffer, offset: number, value: {[string]: any}, options: t.ParserOptions?)
		for i = 0, count -1 do
			write(b, offset +i *size, round(
				value[properties[i +1]], options))
		end
		
		return nil
	end

	function wrapper.read(b: buffer, offset: number, options: t.ParserOptions?)
		local list = {}
		for i = 0, count -1 do
			local res = read(b, offset +i *size)
			local val = round(res, options, true)
			table.insert(list, val)
		end

		return constructor(table.unpack(list))
	end

	return wrapper
end

function this.string(write: t.Write, read: t.Read, size: number)
	local wrapper = {} :: t.Parser

	function wrapper.lenght(value: string)
		return size +string.len(value)
	end

	function wrapper.write(b: buffer, offset: number, value: string, options: t.ParserOptions?)
		local l = string.len(value)
		write(b, offset, l)
		offset = offset +size

		buffer.writestring(b, offset, value)
		return offset +l
	end

	function wrapper.read(b: buffer, offset: number): string
		local l = read(b, offset)
		return buffer.readstring(b, offset +size, l), offset +size +l
	end

	return wrapper
end

function this.char()
	local wrapper = {} :: t.Parser
	
	function wrapper.lenght(value: string, options: t.ParserOptions)
		return options.value
	end
	
	function wrapper.write(b: buffer, offset: number, value: string, options: t.ParserOptions)
		if string.len(value) > options.value then
			error(`String exceedes max charsize of {options.value}`)
		end
				
		buffer.fill(b, offset, 0, options.value)
		buffer.writestring(b, offset, value)
		
		return offset +options.value
	end
	
	function wrapper.read(b: buffer, offset: number, options: t.ParserOptions)
		local result = buffer.readstring(b, offset, options.value :: number)
		local nullPos = string.find(result, "\0")
		
		if nullPos then
			result = string.sub(result, 1, nullPos - 1)
		end
		return result, offset +options.value
	end
	
	return wrapper
end

function this.buffer(write: t.Write, read: t.Read, size: number)
	local wrapper = {} :: t.Parser
	wrapper.lenght = function(value: buffer)
		return buffer.len(value) +size
	end

	function wrapper.write(b: buffer, offset: number, value: buffer)
		local l = buffer.len(value)
		write(b, offset, l)
		
		offset += size
		buffer.copy(b, offset, value)
		return offset +l
	end

	function wrapper.read(b: buffer, offset: number)
		local l = read(b, offset)
		offset += size
		
		local new = buffer.create(l)
		buffer.copy(new, 0, b, offset, l)
		
		return new, offset +l
	end

	return wrapper
end

function this.schema()
	local size = e.Sizes.DWORD
	local wrapper = this.buffer(
		buffer.writeu32, buffer.readu32, size) :: t.Parser
	
	local write = wrapper.write
	local read = wrapper.read
	
	function wrapper.lenght(value: any, options: t.ParserOptions)
		local opt: any = options.options
		if opt and opt.SerOptions and (opt.SerOptions :: any).Compress then
			error("Schema compression in sub-schema, highly unreliable.")
		end
		
		local s = options.value
		local ser = s.schema:Serialize(value, s.options)
		return buffer.len(ser) +size
	end

	function wrapper.write(b: buffer, offset: number, value: any, options: t.ParserOptions)
		local s = options.value
		local ser = s.schema:Serialize(value, s.options)
		return write(b, offset, ser, options)
	end

	function wrapper.read(b: buffer, offset: number, options: t.ParserOptions)
		local val, off = read(b, offset, options)
		local s = options.value
		
		-- They may not want to load that to the latest
		local val = s.schema:Load(val, options)
		return val, off
	end

	return wrapper
end

function this.boolean()
	local wrapper = {} :: t.Parser
	
	function wrapper.write(b: buffer, offset: number, value: boolean)
		buffer.writeu8(b, offset, if value then 1 else 0)
		return offset +e.Sizes.BYTE
	end
	
	function wrapper.read(b: buffer, offset: number)
		return buffer.readu8(b, offset) == 1, offset +e.Sizes.BYTE
	end
	
	return wrapper
end

function this.bits(write: t.Write, read: t.Read, size: number)
	local wrapper = new(size, 1)
	local bits = size *8
	
	function wrapper.write(b: buffer, offset: number, value: {number|boolean})
		local packed = 0
		for i, v in value do
			if i > bits then error(`Index {i} is out of range for {bits} bits`) end
			if not v or v == 0 then continue end
			
			packed = bit32.replace(packed, 1, i -1, 1)
		end
		
		return write(b, offset, packed)
	end
	
	function wrapper.read(b: buffer, offset: number): {boolean}
		local packed = read(b, offset)
		local result = {}

		for i = 1, bits do
			table.insert(result, bit32
				.extract(packed, i -1, 1) == 1)
		end
		
		return result
	end
	
	return wrapper
end

function this.enum(write: t.Write, read: t.Read, size: number)
	local wrapper = new(size, 1)
	--local map = typeof(enums) == "table" and mapList(enums)

	function wrapper.write(b: buffer, offset: number, value: EnumItem|string|number, options: t.ParserOptions)
		local v: number
		local et = typeof(value)
		
		if et == "EnumItem" then
			v = (value :: EnumItem).Value
			
		elseif typeof(options.value) == "table" then
			for i, enum in options.value do
				local name = typeof(enum) == "EnumItem"
					and enum.Name or enum
				
				if typeof(enum) == "EnumItem" then
					if enum.Name == value or enum.Value == value then
						v = i break
					end
				else	
					if name == value then
						v = i break
					end
				end
			end
			
			if not v and et == "number" and options.value[value] then
				v = value :: number
			end
			
			if not v then
				error(`{value} is not a valid enum value for custom enums`)
			end
		else
			local en = (options.value :: any):FromName(value)
			if not en then error(`{value} is not a valid enum value for {options.value}`) end
			v = en.Value
		end
		
		return write(b, offset, v)
	end

	function wrapper.read(b: buffer, offset: number, options: t.ParserOptions): {boolean}
		local value: number = read(b, offset)
		
		local enum
		if typeof(options.value) == "table" then
			enum = (options.value :: {string|EnumItem})[value]
			if not enum then
				for _, e in options.value do
					if typeof(e) == "EnumItem" and e.Value == value then
						enum = e
					end
				end
			end
		else
			enum = (options.value :: any):FromValue(value)
		end

		if not enum then error(`{value} is not a valid enum value for {options.value}`) end
		return enum
	end

	return wrapper
end

function this.uintHeader(write: t.Write, read: t.Read, size: number, properties: {string}, constructor: (...any) -> any)
	local wrapper = this.object(write, read, size, properties, constructor)
	local count = wrapper.size :: number
	wrapper.size = count +size
	
	local oldW = wrapper.write
	function wrapper.write(b: buffer, offset: number, values: any)
		write(b, offset, count)
		oldW(b, offset +size, values)
	end
	
	function wrapper.read(b: buffer, offset: number)
		local count = read(b, offset)
		local list = {}
		
		for i = 1, count do
			local res = read(b, offset +i *size)
			table.insert(list, res)
		end

		return constructor(table.unpack(list)), count +size
	end
	
	return wrapper
end

function this.auto()
	local wrapper = {} :: t.Parser
	
	function wrapper.type(value: any, options: t.ParserOptions)
		local v = conformAutoValue(value, options)
		local type = a.getId(v, options)
		return type
	end
	
	function wrapper.lenght(value: any, options: t.ParserOptions)
		local options = dictCopy(options :: any)
		local v = conformAutoValue(value, options)
		
		local type, id = a.getId(v, options)
		return type:Bytes(v, options) +1
	end
	
	function wrapper.write(b: buffer, offset: number, value: any, options: t.ParserOptions)
		local options = dictCopy(options :: any)
		local v = conformAutoValue(value, options)
		
		local type, id = a.getId(v, options)
		buffer.writeu8(b, offset, id)
		return type:Write(b, offset +1, v, options)
	end
	
	function wrapper.read(b: buffer, offset: number, options: t.ParserOptions)
		local options = dictCopy(options :: any)
		local id = buffer.readu8(b, offset)
		
		local type = a.fromId(id, options)
		local v = type:Read(b, offset +1, options)
		return conformAutoValue(v, options, true)
	end
	
	return wrapper
end

function this.cframe(write: t.Write, read: t.Read, size: number)
	local len = #{CFrame.new():GetComponents()} :: {any}
	local wrapper = this.list(write, read, size, len, CFrame.new)

	local write = wrapper.write
	function wrapper.write(b: buffer, offset: number, value: {[string]: any}, options: t.ParserOptions?)
		return write(b, offset, {value:GetComponents()}, options)
	end

	return wrapper
end

function this.lossyCFrame(write: t.Write, read: t.Read, size: number)
	local wrapper = this.list(write, read, size, 7, newlCFrame)
	local write = wrapper.write
	
	function wrapper.write(b: buffer, offset: number, value: {[string]: any}, options: t.ParserOptions?)
		local axis, angle = value:ToAxisAngle()
		
		return write(b, offset, {
			axis.X, axis.Y, axis.Z, angle,
			value.X, value.Y, value.Z
		}, options)
	end
	
	return wrapper
end

return this
