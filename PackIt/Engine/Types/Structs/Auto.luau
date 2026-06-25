--!strict

local e = require("../../Enums")
local t = require("../Type")
local en: {[string]: any}

local this, parsers = {}, {}

local types, itypes = {
	-- "id" (float),
	-- "enum" (unknown enum),
	
	"bool",
	"bits",
	"color3",
	"brickcolor",
	
	"char", "varchar",
	
	"cframe:32", "cframe:64",
	"lcframe:32", "lcframe:64",
	
	"float:32", "float:64",
	"number:32", "number:64",
	"int:8", "int:16", "int:32",
	"uint:8", "uint:16", "uint:32",
	
	"buffer:8", "buffer:16", "buffer:32",
	
	"floatVec2:32", "floatVec2:64",
	"numberVec2:32", "numberVec2:64",
	"intVec2:8", "intVec2:16", "intVec2:32",
	"uintVec2:8", "uintVec2:16", "uintVec2:32",
	
	"floatVec3:32", "floatVec3:64",
	"numberVec3:32", "numberVec3:64",
	"intVec3:8", "intVec3:16", "intVec3:32",
	"uintVec3:8", "uintVec3:16", "uintVec3:32"
}, {}

local uint, int = {
	{ min = 0, max = 2^8 -1, size = 8 },
	{ min = 0, max = 2^16 -1, size = 16 },
	{ min = 0, max = 2^32 -1, size = 32 }
}, {
	{ min = -2^7, max = 2^7 -1, size = 8 },
	{ min = -2^15, max = 2^15 -1, size = 16 },
	{ min = -2^31, max = 2^31 -1, size = 32 }
}

for i, t in ipairs(types) do itypes[t] = i end
local function parseValues(t: string, parser: (any) -> (string, number), ...: any)
	local type, size = "", -1
	for _, v in ipairs({...}) do
		local t, s = parser(v)
		
		if size <= s then -- From basic to complex data types
			type, size = t, s
		end
	end
	
	return type ..t, size
end

local function minLenght(len: number): number?
	for _, i in ipairs(uint) do
		if i.min <= len and i.max >= len then
			return i.size
		end
	end
	
	return nil
end

local function float(v: number)
	local t = "float"
	if math.isnan(v) or math.isinf(v) then
		t = "number"
	end
	
	local b = buffer.create(4)
	buffer.writef32(b, 0, v)

	local f32_val = buffer.readf32(b, 0)
	return t, math.abs(v -f32_val) < math
		.abs(v) *1e-7 and 32 or 64
end

function parsers.BrickColor() return "brickcolor" end
function parsers.boolean() return "bool" end
function parsers.Color3() return "color3" end

function parsers.number(v: number)
	if v %1 == 0 then
		if v < 0 then
			for _, i in ipairs(int) do
				if i.min <= v and i.max >= v then
					return `int`, i.size end
			end
		end

		for _, i in ipairs(uint) do
			if i.min <= v and i.max >= v then
				return `uint`, i.size end
		end
	end

	return float(v)
end

function parsers.string(v: string): string?
	local l = string.len(v)
	-- Cannot map other sizes of char
	if l == 1 then return "char" end
	if minLenght(l) then return "varchar" end
	return nil
end

function parsers.buffer(v: buffer)
	local l = buffer.len(v)
	return "buffer", minLenght(l)
end

function parsers.table(v: {}): any?
	local c = #v
	
	if c < 1 or c > 8 then return end
	for _, v in ipairs(uint) do
		if type(v) ~= "boolean" then return end
	end
	
	return "bits"
end

function parsers.CFrame(v: CFrame)
	local _, size = parseValues("", float, v:GetComponents())
	
	local axis, angle = v:ToAxisAngle()
	local pos = v.Position

	local testCF = CFrame.fromAxisAngle(axis, angle) +v.Position
	local accuracy = v.LookVector:Dot(testCF.LookVector)
	
	if accuracy > 0.99999 then return "lcframe", size end
	return "cframe", size
end

function parsers.Vector2(v: Vector2)
	return parseValues("Vec2", parsers.number, v.X, v.Y)
end

function parsers.Vector3(v: Vector3)
	return parseValues("Vec3", parsers.number, v.X, v.Y, v.Z)
end

local function getType(t)
	en = en or require("../../../Engine") :: any
	return en.getType(t)
end

local function getValue(t): any?
	if t == "char" then return 1 end
	if t == "enum" then return {} end
	return
end

local function getId(type: string, size: number?)
	local id
	
	if size then id = itypes[`{type}:{size}`]
	else id = itypes[type] end
	
	if not id then error(`Auto does not map this id: {type}:{size or ""}`) end
	return id
end

-- Easier enum type
function this.getId(value: any, options: t.ParserOptions): (t.Entry, number)
	local t = typeof(value)
	local parser = parsers[t]
	
	if not parser then
		error(`Auto does not currently support this type {t}`) end
	
	local type, size = parser(value)
	if not type then
		error(`This value of type: {t} cannot be automatically parsed`) end
	
	options.size = size and size :: number /8
	options.value = getValue(type)
	
	return getType(type), getId(type, size)
end

function this.fromId(id: number, options: t.ParserOptions): t.Entry
	local t = types[id] :: string?
	if not t then error(`Auto doesnt support type id: {id}`) end
	
	--local type, size = string.match(t, "^(%D+)(%d*)$")
	local split = string.split(t, ":")
	local type, size = split[1], split[2]
	size = tonumber(size)
	
	options.size = size and size /8
	options.value = getValue(type)
	return getType(type)
end

return this
