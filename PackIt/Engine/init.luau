--!strict
--!native

local EncodingService = game:GetService("EncodingService")

local w = require("@self/Types/Structs")
local s = require("@self/Types/Type")
local e = require("@self/Enums")
local t = require("@self/Types")

local f = table.freeze
local this, versions = {}, f({
	require("@self/v1")
})

export type UnifiedEntryOptions = t.UnifiedEntryOptions
export type LenghtOptions = t.LenghtOptions
export type Serialization = t.Serialization
export type EntryOptions = t.EntryOptions
export type EnumOptions = t.EnumOptions
export type Sanitizers = t.Sanitizers
export type EntryType = t.EntryType
export type Entry = t.Entry

export type DictData = t.DictData
export type ListData = t.ListData

export type FloatSizes = t.FloatSizes
export type IntSizes = t.IntSizes
export type ByteSize = t.ByteSize
export type Sizes = t.Sizes
export type Data = t.Data

export type SchematizedDict = t.SchematizedDict
export type SchematizedList = t.SchematizedList
export type Schematized = t.Schematized
export type _Versioning = t._Versioning
export type _SerOptions = t._SerOptions
export type SerOptions = t.SerOptions
export type Versioning = t.Versioning

export type Header = {
	Compress: number,
	Variant: number,
	Engine: number,
	Mode: number
}

local function dictCopy(dict: {[string]: any})
	local copy = {}
	for k, v in pairs(dict) do
		copy[k] = v
	end
	return copy
end

local function decompress(b: buffer, algoId: number)
	return EncodingService:DecompressBuffer(b, Enum.CompressionAlgorithm
		:FromValue(algoId) :: Enum.CompressionAlgorithm)
end

local function compress(b: buffer, opts: t.Compression?): (buffer, number)
	if not opts or not opts.Type then return b, 255 end
	local succ, c = pcall(EncodingService.CompressBuffer,
		EncodingService, b, opts.Type, opts.Level)

	if not succ then
		warn(`Compression failed: {c}, returning uncompressed buffer.`)
		return b, 255
	end return c, opts.Type.Value
end

local HeaderProps = { "Variant", "Engine", "Mode", "Compress" }
local HeaderCons = function(...)
	local args, h = {...}, {}
	for i, v in HeaderProps do
		h[v] = args[i]
	end
	
	return h
end

local header = s.new("PayloadHeader", e.Sizes.BYTE, {
	[e.Sizes.BYTE] = w.uintHeader(buffer.writeu8, buffer
		.readu8, e.Sizes.BYTE, HeaderProps, HeaderCons)
}, {
	Compress = 255,
	Variant = 1,
	Engine = 1,
	Mode = 1,
})

function this.bytes(logi: Schematized, data: Data, options: _SerOptions): number
	local ver = versions[options.Engine]
	if not ver then error(`Engine v{options.Engine} is not supported`) end

	local mode = e.Mode[options.Mode :: any]
	if typeof(mode) ~= "number" then error(`Mode {options.Mode} is not supported`) end
	
	return ver.new(logi, data, options):Bytes(header:Bytes())
end

function this.serialize(logi: Schematized, data: Data, options: _SerOptions): buffer
	local ver = versions[options.Engine]
	if not ver then error(`Engine v{options.Engine} is not supported`) end
	
	local mode = e.Mode[options.Mode :: any]
	if typeof(mode) ~= "number" then error(`Mode {options.Mode} is not supported`) end
	
	local comp = options.Compress
	options.Compress = nil
	
	local h = dictCopy(header:Default())
	for k, v in pairs(options :: any) do
		if h[k] then h[k] = v end
	end
	
	h.Mode = mode
	local ser = ver.new(logi, data, options)
	local size = header:Bytes()
	local b = ser:Alloc(size)
	
	local off = header:Write(b, 0, h)
	local res = ser:Serialize(b, off)
	
	res, h.Compress = compress(b, comp)
	if h.Compress >= 255 then return res end
	
	-- Little overhead, duplicated header (one is compressed).
	local b = buffer.create(buffer.len(res) +size)
	local off = header:Write(b, 0, h)
	buffer.copy(b, off, res)
	return b
end

function this.deserialize(logi: Schematized, b: buffer): Data
	local h, off = header:Read(b, 0)
	
	local ver = versions[h.Engine]
	if not ver then error(`Engine v{h.Engine} is not supported`) end
	
	local mode = e.Mode[h.Mode]
	if not mode then error(`Mode {h.Mode} is not supported`) end
	
	local comp = h.Compress
	if comp < 255 then
		local t = buffer.create(
			buffer.len(b) -off)
		
		buffer.copy(t, 0, b, off)
		b = decompress(t, comp)
	end
	
	h.Mode = mode
	return (ver.new(logi, b, h)
		:Deserialize(off))
end

function this.getHeader(b: buffer): Header
	return (header:Read(b, 0))
end

function this.getType(type: EntryType)
	if not t[type] then error(`{type} is not a valid entry type`) end
	return t[type]
end

this.versions = versions
this.types = t
return this
