--!strict
--!native

local w = require("@self/Structs")
local t = require("@self/Type")
local e = require("./Enums")

local this: {[string]: Entry} = {}
local z = e.Sanitizers
local s = e.Sizes

export type Sanitizers = t.Sanitizers
export type EntryType = t.EntryType
export type Entry = t.Entry
	
export type LenghtOptions = t.LenghtOptions
export type EntryOptions = t.EntryOptions
export type EnumOptions = t.EnumOptions
export type FloatSizes = t.FloatSizes
export type IntSizes = t.IntSizes
export type ByteSize = t.ByteSize
export type NoneSize = t.NoneSize
export type Sizes = t.Sizes

export type UnifiedEntryOptions = t.UnifiedEntryOptions & {
	SerOptions: SerOptions?
}

export type SchematizedDict = {{
	type: SchematizedDict|SchematizedList|EntryType,
	options: UnifiedEntryOptions?,
	size: Sizes?,
	key: string
}}

export type SchematizedList = {
	type: SchematizedList|SchematizedDict|EntryType,
	options: UnifiedEntryOptions?
}

export type Mode = e.Mode
export type Compression = {
	Type: Enum.CompressionAlgorithm,
	Level: number?
}
	
export type Serialization = {
	Compress: Compression?,
	Mode: Mode?
}

export type _SerOptions = _Versioning & Serialization
export type SerOptions = { -- Type checker skill issues
	Compress: Compression?,
	Variant: number?,
	Engine: number?,
	Mode: Mode?
}

export type Versioning = {
	Variant: number?,
	Engine: number?
}

export type _Versioning = {
	Variant: number,
	Engine: number
}

export type Schematized = SchematizedList|SchematizedDict
export type DictData = {[string]: any}
export type ListData = {any}
export type Data = DictData|ListData

-- Auto
this.auto = t.new("auto", s.NONE, {
	[s.NONE] = w.auto() -- Variable type and size
}, "Auto")

-- Boolean
this.bool = t.new("bool", s.BYTE, {
	[s.BYTE] = w.boolean()
	
}, false, { z.BOOL })

-- Char
this.char = t.new("char", s.BYTE, {
	[s.BYTE] = w.char()
	
}, " ", { z.HAS_CHAR_SIZE })

-- Schema
this.schema = t.new("schema", s.NONE, {
	[s.NONE] = w.schema()

}, {}, { z.IS_SCHEMA })

-- Buffer
this.buffer = t.new("buffer", s.BYTE, {
	[s.BYTE] = w.buffer(buffer.writeu8, buffer.readu8, s.BYTE),
	[s.WORD] = w.buffer(buffer.writeu16, buffer.readu16, s.WORD),
	[s.DWORD] = w.buffer(buffer.writeu32, buffer.readu32, s.DWORD)
	
}, buffer.create(0), { z.HAS_BUFFER_SIZE })

-- String
this.varchar = t.new("varchar", s.BYTE, {
	[s.BYTE] = w.string(buffer.writeu8, buffer.readu8, s.BYTE),
	[s.WORD] = w.string(buffer.writeu16, buffer.readu16, s.WORD),
	[s.DWORD] = w.string(buffer.writeu32, buffer.readu32, s.DWORD)
}, "", { z.HAS_STRING_SIZE })

-- Color3
this.color3 = t.new("color3", s.BYTE, {
	[s.BYTE] = w.object(function(b, offset, value: number)
		buffer.writeu8(b, offset, value *255)
		
	end, buffer.readu8, s.BYTE, {"R", "G", "B"}, Color3.fromRGB)
}, Color3.fromRGB(), { z.IS_COLOR3 })

-- BrickColor
this.brickcolor = t.new("brickcolor", s.WORD, {
	[s.WORD] = w.object(buffer.writeu16, buffer
		.readu16, s.WORD, {"Number"}, BrickColor.new)
	
}, BrickColor.new(1), { z.IS_BRICKCOLOR })

-- Bits
this.bits = t.new("bits", s.BYTE, {
	[s.BYTE] = w.bits(buffer.writeu8, buffer.readu8, s.BYTE),
	[s.WORD] = w.bits(buffer.writeu16, buffer.readu16, s.WORD),
	[s.DWORD] = w.bits(buffer.writeu32, buffer.readu32, s.DWORD)
	
}, table.create(8, false), { z.IS_BITS })

-- Enums
this.enum = t.new("enum", s.BYTE, {
	[s.BYTE] = w.enum(buffer.writeu8, buffer.readu8, s.BYTE),
	[s.WORD] = w.enum(buffer.writeu16, buffer.readu16, s.WORD),
	[s.DWORD] = w.enum(buffer.writeu32, buffer.readu32, s.DWORD)
}, "Enum", { z.IS_ENUM })

-- Numeric
this.id = t.new("id", s.QWORD, {
	[s.QWORD] = { write = buffer.writef64, read = buffer.readf64 }
}, 0, { z.IS_NUMBER, z.IS_POSITIVE, z.HAS_FLOAT_SIZE })

this.int = t.new("int", s.BYTE, w.numbers({
	[s.BYTE] = { write = buffer.writei8, read = buffer.readi8 },
	[s.WORD] = { write = buffer.writei16, read = buffer.readi16 },
	[s.DWORD] = { write = buffer.writei32, read = buffer.readi32 }
}), 0, { z.HAS_INT_SIZE })

this.uint = t.new("uint", s.BYTE, w.numbers({
	[s.BYTE] = { write = buffer.writeu8, read = buffer.readu8 },
	[s.WORD] = { write = buffer.writeu16, read = buffer.readu16 },
	[s.DWORD] = { write = buffer.writeu32, read = buffer.readu32 }
}), 0, { z.HAS_UINT_SIZE })

this.float = t.new("float", s.DWORD, w.numbers({
	[s.DWORD] = { write = buffer.writef32, read = buffer.readf32 },
	[s.QWORD] = { write = buffer.writef64, read = buffer.readf64 }
}), 0, { z.HAS_FLOAT_SIZE })

this.number = t.new("number", s.DWORD, w.numbers({
	[s.DWORD] = { write = buffer.writef32, read = buffer.readf32 },
	[s.QWORD] = { write = buffer.writef64, read = buffer.readf64 }
}), 0, { z.HAS_NUMBER_SIZE })

-- Vec3
local vec3 = {"X", "Y", "Z"}
local vec3d = Vector3.zero
local vec3c = Vector3.new

this.intVec3 = t.new("intVec3", s.BYTE, {
	[s.BYTE] = w.object(buffer.writei8, buffer.readi8, s.BYTE, vec3, vec3c),
	[s.WORD] = w.object(buffer.writei16, buffer.readi16, s.WORD, vec3, vec3c),
	[s.DWORD] = w.object(buffer.writei32, buffer.readi32, s.DWORD, vec3, vec3c)
}, vec3d, { z.HAS_INT_VEC_SIZE })

this.uintVec3 = t.new("uintVec3", s.BYTE, {
	[s.BYTE] = w.object(buffer.writeu8, buffer.readu8, s.BYTE, vec3, vec3c),
	[s.WORD] = w.object(buffer.writeu16, buffer.readu16, s.WORD, vec3, vec3c),
	[s.DWORD] = w.object(buffer.writeu32, buffer.readu32, s.DWORD, vec3, vec3c)
}, vec3d, { z.HAS_UINT_VEC_SIZE })

this.floatVec3 = t.new("floatVec3", s.DWORD, {
	[s.DWORD] = w.object(buffer.writef32, buffer.readf32, s.DWORD, vec3, vec3c),
	[s.QWORD] = w.object(buffer.writef64, buffer.readf64, s.QWORD, vec3, vec3c)
}, vec3d, { z.HAS_FLOAT_VEC_SIZE })

this.numberVec3 = t.new("numberVec3", s.DWORD, {
	[s.DWORD] = w.object(buffer.writef32, buffer.readf32, s.DWORD, vec3, vec3c),
	[s.QWORD] = w.object(buffer.writef64, buffer.readf64, s.QWORD, vec3, vec3c)
}, vec3d, { z.HAS_NUMBER_VEC_SIZE })

-- Vec2
local vec2 = {"X", "Y"}
local vec2d = Vector2.zero
local vec2c = Vector2.new

this.intVec2 = t.new("intVec2", s.BYTE, {
	[s.BYTE] = w.object(buffer.writei8, buffer.readi8, s.BYTE, vec2, vec2c),
	[s.WORD] = w.object(buffer.writei16, buffer.readi16, s.WORD, vec2, vec2c),
	[s.DWORD] = w.object(buffer.writei32, buffer.readi32, s.DWORD, vec2, vec2c)
}, vec2d, { z.HAS_INT_VEC_SIZE })

this.uintVec2 = t.new("uintVec2", s.BYTE, {
	[s.BYTE] = w.object(buffer.writeu8, buffer.readu8, s.BYTE, vec2, vec2c),
	[s.WORD] = w.object(buffer.writeu16, buffer.readu16, s.WORD, vec2, vec2c),
	[s.DWORD] = w.object(buffer.writeu32, buffer.readu32, s.DWORD, vec2, vec2c)
}, vec2d, { z.HAS_UINT_VEC_SIZE })

this.floatVec2 = t.new("floatVec2", s.DWORD, {
	[s.DWORD] = w.object(buffer.writef32, buffer.readf32, s.DWORD, vec2, vec2c),
	[s.QWORD] = w.object(buffer.writef64, buffer.readf64, s.QWORD, vec2, vec2c)
}, vec2d, { z.HAS_FLOAT_VEC_SIZE })

this.numberVec2 = t.new("numberVec2", s.DWORD, {
	[s.DWORD] = w.object(buffer.writef32, buffer.readf32, s.DWORD, vec2, vec2c),
	[s.QWORD] = w.object(buffer.writef64, buffer.readf64, s.QWORD, vec2, vec2c)
}, vec2d, { z.HAS_NUMBER_VEC_SIZE })

-- CFrame
local cfd = CFrame.new()
this.cframe = t.new("cframe", s.DWORD, {
	[s.DWORD] = w.cframe(buffer.writef32, buffer.readf32, s.DWORD),
	[s.QWORD] = w.cframe(buffer.writef64, buffer.readf64, s.QWORD)
}, cfd, { z.IS_CFRAME })

this.lcframe = t.new("lcframe", s.DWORD, {
	[s.DWORD] = w.lossyCFrame(buffer.writef32, buffer.readf32, s.DWORD),
	[s.QWORD] = w.lossyCFrame(buffer.writef64, buffer.readf64, s.QWORD),
}, cfd, { z.IS_CFRAME })

return this