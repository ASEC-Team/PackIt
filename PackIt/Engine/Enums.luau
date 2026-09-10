--!strict
--!native

local this = {}

-- Sizes
export type ByteSize = "BYTE"
export type WordSize = "WORD"
export type NoneSize = "NONE"
export type DWordSize = "DWORD"
export type QWordSize = "QWORD"
export type TriByteSize = "TRIBYTE"

local sizes = {}
local str_to_size: {[string]: number} = {}

str_to_size.NONE = 0
str_to_size.BYTE = 1
str_to_size.WORD = str_to_size.BYTE *2
str_to_size.DWORD = str_to_size.WORD *2
str_to_size.QWORD = str_to_size.DWORD *2
str_to_size.TRIBYTE = str_to_size.BYTE *3

sizes[str_to_size.NONE] = "NONE"
sizes[str_to_size.BYTE] = "BYTE"
sizes[str_to_size.WORD] = "WORD"
sizes[str_to_size.DWORD] = "DWORD"
sizes[str_to_size.QWORD] = "QWORD"
sizes[str_to_size.TRIBYTE] = "TRIBYTE"

-- Type checker skill issues
sizes.NONE = str_to_size.NONE
sizes.BYTE = str_to_size.BYTE
sizes.WORD = str_to_size.WORD
sizes.DWORD = str_to_size.DWORD
sizes.QWORD = str_to_size.QWORD
sizes.TRIBYTE = str_to_size.TRIBYTE
this.Sizes = sizes

-- Mode
export type Mode = "Flat" | "Nested"
local mode = { "Flat", "Nested" }
local str_to_mode: {[string]: number} = {}

str_to_mode.Flat = 1
str_to_mode.Nested = 2

mode.Flat = str_to_mode.Flat
mode.Nested = str_to_mode.Nested
this.Mode = mode

-- Sanitizers
local sanitizers = {}
local DWORD_BUFFER = buffer.create(sizes.DWORD)

local function uint_limit(size: number)
	return 2 ^(size *8) -1
end

local function int_limit(size: number)
	local limit: number = 2 ^((size *8) - 1)
	return { min = -limit, max = limit -1 }
end

local UINT_LIMITS = {
	NONE = uint_limit(sizes.NONE),
	BYTE = uint_limit(sizes.BYTE),
	WORD = uint_limit(sizes.WORD),
	DWORD = uint_limit(sizes.DWORD),
	QWORD = uint_limit(sizes.QWORD),
	TRIBYTE = uint_limit(sizes.TRIBYTE)
}

local INT_LIMITS = {
	NONE = int_limit(sizes.NONE),
	BYTE = int_limit(sizes.BYTE),
	WORD = int_limit(sizes.WORD),
	DWORD = int_limit(sizes.DWORD),
	QWORD = int_limit(sizes.QWORD),
	TRIBYTE = int_limit(sizes.TRIBYTE)
}

sanitizers.BOOL = function(v)
	if type(v) == "number" then
		return v > 0
	end
	
	return not not v
end

sanitizers.IS_INT = function(v: number)
	if v %1 == 0 then return end
	error(`Value {v} is not an integer`)
end

sanitizers.IS_SCHEMA = function(v)
	if type(v) ~= "table" or (not v._variants and not v._base) then
		error(`Value {v} is not a schema`) end
end

sanitizers.IS_NUMBER = function(v)
	if type(v) ~= "number" then error(`Value {v} is not a number`) end
end

sanitizers.IS_FINITE = function(v)
	if not math.isfinite(v) then error(`Value {v} is not finite`) end
end

sanitizers.IS_STRING = function(v)
	if type(v) ~= "string" then error(`Value {v} is not a string`) end
end

sanitizers.IS_POSITIVE = function(v)
	if v < 0 then error(`Value {v} is not positive`) end
end

sanitizers.IS_BUFFER = function(v)
	if type(v) ~= "buffer" then error(`Value {v} is not a buffer`) end
end

sanitizers.IS_CFRAME = function(v)
	if typeof(v) ~= "CFrame" then error(`Value {v} is not a CFrame`) end
end

sanitizers.IS_COLOR3 = function(v)
	if typeof(v) ~= "Color3" then error(`Value {v} is not a Color3`) end
end

sanitizers.IS_BRICKCOLOR = function(v)
	if typeof(v) ~= "BrickColor" then error(`Value {v} is not a BrickColor`) end
end

sanitizers.IS_BITS = function(v: {any})
	if typeof(v) ~= "table" then error(`Value {v} is not a number`) end
	for i, b in v do
		if type(b) == "number" then
			v[i] = if b > 0 then true else b
		else
			v[i] = not not b
		end
	end
end

local function invalidEnum(v, opt: {[string]: any})
	if v == "Enum" then
		error(`Missing default value to generate template at enum {opt.Values}`)
	end
	
	error(`Value {v} is not a valid enum for {opt.Values}`)
end

sanitizers.IS_ENUM = function(v: EnumItem|string|number, t, opt: {[string]: any})
	local size = opt.Size
	if not size then error("This type has no specified size") end
	if not str_to_size[size] then error("This type has an invalid size") end
	local et = typeof(v)
	
	if et ~= "EnumItem" and et ~= "string" and et ~= "number" then
		error(`Value {v} is not an valid enum type`) end
	
	local name = v
	if et == "EnumItem" then
		name = (v :: EnumItem).Name
	end
	
	local max = UINT_LIMITS[size]
	local t = typeof(opt.Values)
	
	if t == "Enum" then
		if et == "number" then
			if not (opt.Values :: any):FromValue(v) then
				invalidEnum(v, opt) end
		else
			if not (opt.Values :: any):FromName(name) then
				invalidEnum(v, opt) end
		end
		
		for _, v in opt.Values:GetEnumItems() do
			if v.Value > max then
				error(`Enum {opt.Values} count size out of range for {size} ENUM`)	
			end
		end
		
	elseif t == "table" then	
		for i, v in opt.Values do
			if i > max then
				error(`Enum {opt.Values} count size out of range for {size} ENUM`)	
			end
			
			if typeof(v) == "EnumItem" then
				if v.Name == name or v.Value == name then return end
			else
				if v == name then return end
			end
		end
		
		if et == "number" then
			if opt.Values[v] then return end
			invalidEnum(v, opt)
		end
		
		invalidEnum(v, opt)
	else
		error("This type has an invalid enum")
	end
end

sanitizers.HAS_SIZE = function(v, t, opt: {[string]: any})
	if not opt.Size then error("This type has no specified size") end
	if not str_to_size[opt.Size] then error("This type has an invalid size") end
end

sanitizers.HAS_UINT_SIZE = function(v, t, opt: {[string]: any}, tag)
	local size = opt.Size
	if not size then error("This type has no specified size") end
	if not str_to_size[size] then error("This type has an invalid size") end
	if type(v) ~= "number" then error(`Value {v} is not a number`) end
	if v % 1 ~= 0 then error(`Value {v} is not an integer`) end
	if v < 0 then error(`Value {v} is not positive`) end
	if not math.isfinite(v) then error(`Value {v} is not finite`) end

	if v > UINT_LIMITS[size] then 
		error(`Value {v} out of range for {opt.Size} {tag or "UINT"}`) end
end

sanitizers.HAS_INT_SIZE = function(v, t, opt: {[string]: any})
	local size = opt.Size
	if not size then error("This type has no specified size") end
	if not str_to_size[size] then error("This type has an invalid size") end
	if type(v) ~= "number" then error(`Value {v} is not a number`) end
	if v % 1 ~= 0 then error(`Value {v} is not an integer`) end
	if not math.isfinite(v) then error(`Value {v} is not finite`) end

	local limit = INT_LIMITS[size]
	if v < limit.min or v > limit.max then 
		error(`Value {v} out of range for {opt.Size} INT`) end
end

sanitizers.HAS_NUMBER_SIZE = function(v, t, opt: {[string]: any})
	local size = opt.Size
	if not size then error("This type has no specified size") end
	if not str_to_size[size] then error("This type has an invalid size") end
	if type(v) ~= "number" then error(`Value {v} is not a number`) end
	
	if not math.isfinite(v) then return end
	
	if size == "DWORD" then
		buffer.writef32(DWORD_BUFFER, 0, v)
		if v ~= buffer.readf32(DWORD_BUFFER, 0) then
			error(`Value {v} out of range for {size} FLOAT`)
		end
		
	elseif size ~= "QWORD" then
		error(`Size {size} is not supported for FLOAT`)
	end
end

sanitizers.HAS_FLOAT_SIZE = function(v, t, opt: {[string]: any})
	local size = opt.Size
	if not size then error("This type has no specified size") end
	if not str_to_size[size] then error("This type has an invalid size") end
	if type(v) ~= "number" then error(`Value {v} is not a number`) end
	if not math.isfinite(v) then error(`Value {v} is not finite`) end

	if size == "DWORD" then
		buffer.writef32(DWORD_BUFFER, 0, v)
		if v ~= buffer.readf32(DWORD_BUFFER, 0) then
			error(`Value {v} out of range for {size} FLOAT`)
		end
	elseif size ~= "QWORD" then
		error(`Size {size} is not supported for FLOAT`)
	end
end

sanitizers.HAS_CHAR_SIZE = function(v: string, t, opt: {[string]: any})
	if not opt.Lenght then error("This type has no specified lenght") end
	if type(v) ~= "string" then error(`Value {v} is not a string`) end

	if string.len(v) > opt.Lenght then
		error(`String {v} is too long for {opt.Lenght} CHAR`) end
end

sanitizers.HAS_STRING_SIZE = function(v: string, t, opt: {[string]: any})
	local size = opt.Size
	if not size then error("This type has no specified size") end
	if not str_to_size[size] then error("This type has an invalid size") end
	if type(v) ~= "string" then error(`Value {v} is not a string`) end

	local length = string.len(v)
	if length > UINT_LIMITS[size] then
		error(`Value {length} out of range for {size} VARCHAR`)
	end
end

sanitizers.HAS_BUFFER_SIZE = function(v: buffer, t, opt: {[string]: any})
	local size = opt.Size
	if not size then error("This type has no specified size") end
	if not str_to_size[size] then error("This type has an invalid size") end
	if type(v) ~= "buffer" then error(`Value {v} is not a buffer`) end

	local length = buffer.len(v)
	if length > UINT_LIMITS[size] then
		error(`Value {length} out of range for {size} BUFFER`)
	end
end

sanitizers.HAS_UINT_VEC_SIZE = function(v: Vector2|Vector3, t, opt: {[string]: any})
	local size = opt.Size
	if not size then error("This type has no specified size") end
	if not str_to_size[size] then error("This type has an invalid size") end
	local max = UINT_LIMITS[size]
	local x, y = v.X, v.Y
	if type(x) ~= "number" then error(`Value {x} is not a number`) end
	if x % 1 ~= 0 then error(`Value {x} is not an integer`) end
	if x < 0 then error(`Value {x} is not positive`) end
	if not math.isfinite(x) then error(`Value {x} is not finite`) end
	if x > max then error(`Value {x} out of range for {size} UINT`) end
	if type(y) ~= "number" then error(`Value {y} is not a number`) end
	if y % 1 ~= 0 then error(`Value {y} is not an integer`) end
	if y < 0 then error(`Value {y} is not positive`) end
	if not math.isfinite(y) then error(`Value {y} is not finite`) end
	if y > max then error(`Value {y} out of range for {size} UINT`) end
	if typeof(v) == "Vector3" then
		local z = v.Z
		if type(z) ~= "number" then error(`Value {z} is not a number`) end
		if z % 1 ~= 0 then error(`Value {z} is not an integer`) end
		if z < 0 then error(`Value {z} is not positive`) end
		if not math.isfinite(z) then error(`Value {z} is not finite`) end
		if z > max then error(`Value {z} out of range for {size} UINT`) end
	end
end

sanitizers.HAS_INT_VEC_SIZE = function(v: Vector2|Vector3, t, opt: {[string]: any})
	local size = opt.Size
	if not size then error("This type has no specified size") end
	if not str_to_size[size] then error("This type has an invalid size") end
	local limit = INT_LIMITS[size]
	local x, y = v.X, v.Y
	if type(x) ~= "number" then error(`Value {x} is not a number`) end
	if x % 1 ~= 0 then error(`Value {x} is not an integer`) end
	if not math.isfinite(x) then error(`Value {x} is not finite`) end
	if x < limit.min or x > limit.max then error(`Value {x} out of range for {size} INT`) end
	if type(y) ~= "number" then error(`Value {y} is not a number`) end
	if y % 1 ~= 0 then error(`Value {y} is not an integer`) end
	if not math.isfinite(y) then error(`Value {y} is not finite`) end
	if y < limit.min or y > limit.max then error(`Value {y} out of range for {size} INT`) end
	if typeof(v) == "Vector3" then
		local z = v.Z
		if type(z) ~= "number" then error(`Value {z} is not a number`) end
		if z % 1 ~= 0 then error(`Value {z} is not an integer`) end
		if not math.isfinite(z) then error(`Value {z} is not finite`) end
		if z < limit.min or z > limit.max then error(`Value {z} out of range for {size} INT`) end
	end
end

sanitizers.HAS_NUMBER_VEC_SIZE = function(v: Vector2|Vector3, t, opt: {[string]: any})
	local size = opt.Size
	if not size then error("This type has no specified size") end
	if not str_to_size[size] then error("This type has an invalid size") end
	local x, y = v.X, v.Y
	if type(x) ~= "number" then error(`Value {x} is not a number`) end
	if math.isfinite(x) and size == "DWORD" then
		buffer.writef32(DWORD_BUFFER, 0, x)
		if x ~= buffer.readf32(DWORD_BUFFER, 0) then error(`Value {x} out of range for {size} FLOAT`) end
	elseif size ~= "QWORD" and math.isfinite(x) then
		error(`Size {size} is not supported for FLOAT`)
	end
	if type(y) ~= "number" then error(`Value {y} is not a number`) end
	if math.isfinite(y) and size == "DWORD" then
		buffer.writef32(DWORD_BUFFER, 0, y)
		if y ~= buffer.readf32(DWORD_BUFFER, 0) then error(`Value {y} out of range for {size} FLOAT`) end
	elseif size ~= "QWORD" and math.isfinite(y) then
		error(`Size {size} is not supported for FLOAT`)
	end
	if typeof(v) == "Vector3" then
		local z = v.Z
		if type(z) ~= "number" then error(`Value {z} is not a number`) end
		if math.isfinite(z) and size == "DWORD" then
			buffer.writef32(DWORD_BUFFER, 0, z)
			if z ~= buffer.readf32(DWORD_BUFFER, 0) then error(`Value {z} out of range for {size} FLOAT`) end
		elseif size ~= "QWORD" and math.isfinite(z) then
			error(`Size {size} is not supported for FLOAT`)
		end
	end
end

sanitizers.HAS_FLOAT_VEC_SIZE = function(v: Vector2|Vector3, t, opt: {[string]: any})
	local size = opt.Size
	if not size then error("This type has no specified size") end
	if not str_to_size[size] then error("This type has an invalid size") end
	local x, y = v.X, v.Y
	if type(x) ~= "number" then error(`Value {x} is not a number`) end
	if not math.isfinite(x) then error(`Value {x} is not finite`) end
	if size == "DWORD" then
		buffer.writef32(DWORD_BUFFER, 0, x)
		if x ~= buffer.readf32(DWORD_BUFFER, 0) then error(`Value {x} out of range for {size} FLOAT`) end
	elseif size ~= "QWORD" then error(`Size {size} is not supported for FLOAT`) end
	if type(y) ~= "number" then error(`Value {y} is not a number`) end
	if not math.isfinite(y) then error(`Value {y} is not finite`) end
	if size == "DWORD" then
		buffer.writef32(DWORD_BUFFER, 0, y)
		if y ~= buffer.readf32(DWORD_BUFFER, 0) then error(`Value {y} out of range for {size} FLOAT`) end
	elseif size ~= "QWORD" then error(`Size {size} is not supported for FLOAT`) end
	if typeof(v) == "Vector3" then
		local z = v.Z
		if type(z) ~= "number" then error(`Value {z} is not a number`) end
		if not math.isfinite(z) then error(`Value {z} is not finite`) end
		if size == "DWORD" then
			buffer.writef32(DWORD_BUFFER, 0, z)
			if z ~= buffer.readf32(DWORD_BUFFER, 0) then error(`Value {z} out of range for {size} FLOAT`) end
		elseif size ~= "QWORD" then error(`Size {size} is not supported for FLOAT`) end
	end
end

this.Sanitizers = sanitizers

return this
