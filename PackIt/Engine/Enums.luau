--!strict
--!native

local this = {}

-- Sizes
export type ByteSize = "BYTE"
export type WordSize = "WORD"
export type NoneSize = "NONE"
export type DWordSize = "DWORD"
export type QWordSize = "QWORD"

local sizes = {}
local str_to_size: {[string]: number} = {}

str_to_size.NONE = 0
str_to_size.BYTE = 1
str_to_size.WORD = str_to_size.BYTE *2
str_to_size.DWORD = str_to_size.WORD *2
str_to_size.QWORD = str_to_size.DWORD *2

sizes[str_to_size.NONE] = "NONE"
sizes[str_to_size.BYTE] = "BYTE"
sizes[str_to_size.WORD] = "WORD"
sizes[str_to_size.DWORD] = "DWORD"
sizes[str_to_size.QWORD] = "QWORD"

-- Type checker skill issues
sizes.NONE = str_to_size.NONE
sizes.BYTE = str_to_size.BYTE
sizes.WORD = str_to_size.WORD
sizes.DWORD = str_to_size.DWORD
sizes.QWORD = str_to_size.QWORD
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
local float_limits = {
	DWORD = 3.402823466e+38,
	QWORD = 1.7976931348623e+308
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
		v[i] = sanitizers.BOOL(b) or b
	end
end

local function invalidEnum(v, opt: {[string]: any})
	if v == "Enum" then
		error(`Missing default value to generate template at enum {opt.Values}`)
	end
	
	error(`Value {v} is not a valid enum for {opt.Values}`)
end

sanitizers.IS_ENUM = function(v: EnumItem|string|number, t, opt: {[string]: any})
	sanitizers.HAS_SIZE(v, t, opt)
	local et = typeof(v)
	
	if et ~= "EnumItem" and et ~= "string" and et ~= "number" then
		error(`Value {v} is not an valid enum type`) end
	
	local name = v
	if et == "EnumItem" then
		name = (v :: EnumItem).Name
	end
	
	local max = 2^(str_to_size[opt.Size] *8) -1
	local t = typeof(opt.Values)
	
	if t == "Enum" then
		if et == "number" then
			if not (opt.Values :: any):FromValue(v) then
				invalidEnum(v, opt) end
		else
			if not (opt.Values :: any):FromName(name) then
				invalidEnum(v, opt) end
		end
		
		for _, v in pairs(opt.Values:GetEnumItems()) do
			if v.Value > max then
				error(`Enum {opt.Values} count size out of range for {opt.Size} ENUM`)	
			end
		end
		
	elseif t == "table" then	
		for i, v in pairs(opt.Values) do
			if i > max then
				error(`Enum {opt.Values} count size out of range for {opt.Size} ENUM`)	
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
	sanitizers.HAS_SIZE(v, t, opt)
	sanitizers.IS_NUMBER(v)
	sanitizers.IS_INT(v)
	sanitizers.IS_POSITIVE(v)
	sanitizers.IS_FINITE(v)
	
	if v > 2 ^(str_to_size[opt.Size] *8) -1 then 
		error(`Value {v} out of range for {opt.Size} {tag or "UINT"}`) end
end

sanitizers.HAS_INT_SIZE = function(v, t, opt: {[string]: any})
	sanitizers.HAS_SIZE(v, t, opt)
	sanitizers.IS_NUMBER(v)
	sanitizers.IS_INT(v)
	sanitizers.IS_FINITE(v)
	
	local limit: number = 2 ^((str_to_size[opt.Size] *8) - 1)
	if v < -limit or v > limit - 1 then 
		error(`Value {v} out of range for {opt.Size} INT`) end
end

sanitizers.HAS_NUMBER_SIZE = function(v, t, opt: {[string]: any})
	sanitizers.HAS_SIZE(v, t, opt)
	sanitizers.IS_NUMBER(v)
	
	if not math.isfinite(v) then return end
	
	if opt.Size == "DWORD" then
		local b = buffer.create(str_to_size[opt.Size])
		buffer.writef32(b, 0, v)
		
		if v ~= buffer.readf32(b, 0) then
			error(`Value {v} out of range for {opt.Size} FLOAT`)
		end
		
	elseif opt.Size ~= "QWORD" then
		error(`Size {opt.Size} is not supported for FLOAT`)
		
	elseif math.abs(v) > float_limits[opt.Size] then
		error(`Value {v} out of range for {opt.Size} FLOAT`)
	end
end

sanitizers.HAS_FLOAT_SIZE = function(v, t, opt: {[string]: any})
	sanitizers.IS_FINITE(v)
	sanitizers.HAS_NUMBER_SIZE(v, t, opt)
end

sanitizers.HAS_CHAR_SIZE = function(v: string, t, opt: {[string]: any})
	if not opt.Lenght then error("This type has no specified lenght") end
	sanitizers.IS_STRING(v)

	if string.len(v) > opt.Lenght then
		error(`String {v} is too long for {opt.Lenght} CHAR`) end
end

sanitizers.HAS_STRING_SIZE = function(v: string, t, opt: {[string]: any})
	sanitizers.HAS_SIZE(v, t, opt)
	sanitizers.IS_STRING(v)
	
	sanitizers.HAS_UINT_SIZE(string.len(v), t, opt, "VARCHAR")
end

sanitizers.HAS_BUFFER_SIZE = function(v: buffer, t, opt: {[string]: any})
	sanitizers.HAS_SIZE(v, t, opt)
	sanitizers.IS_BUFFER(v)
	
	sanitizers.HAS_UINT_SIZE(buffer.len(v), t, opt, "BUFFER")
end

sanitizers.HAS_UINT_VEC_SIZE = function(v: Vector3, t, opt: {[string]: any})
	sanitizers.HAS_UINT_SIZE(v.X, t, opt)
	sanitizers.HAS_UINT_SIZE(v.Y, t, opt)
	
	if not pcall(function() return v.Z end) then return end
	sanitizers.HAS_UINT_SIZE(v.Z, t, opt)
end

sanitizers.HAS_INT_VEC_SIZE = function(v: Vector3, t, opt: {[string]: any})
	sanitizers.HAS_INT_SIZE(v.X, t, opt)
	sanitizers.HAS_INT_SIZE(v.Y, t, opt)
	
	if not pcall(function() return v.Z end) then return end
	sanitizers.HAS_INT_SIZE(v.Z, t, opt)
end

sanitizers.HAS_NUMBER_VEC_SIZE = function(v: Vector3, t, opt: {[string]: any})
	sanitizers.HAS_NUMBER_SIZE(v.X, t, opt)
	sanitizers.HAS_NUMBER_SIZE(v.Y, t, opt)

	if not pcall(function() return v.Z end) then return end
	sanitizers.HAS_NUMBER_SIZE(v.Z, t, opt)
end

sanitizers.HAS_FLOAT_VEC_SIZE = function(v: Vector3, t, opt: {[string]: any})
	sanitizers.HAS_FLOAT_SIZE(v.X, t, opt)
	sanitizers.HAS_FLOAT_SIZE(v.Y, t, opt)
	
	if not pcall(function() return v.Z end) then return end
	sanitizers.HAS_FLOAT_SIZE(v.Z, t, opt)
end

this.Sanitizers = sanitizers

return this
