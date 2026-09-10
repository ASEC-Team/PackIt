--!strict
--!native

local e = require("./Engine")
local this = {}

-- Options
export type Serialization = e.Serialization
export type _Versioning = e._Versioning
export type Versioning = e.Versioning
export type _SerOptions = e._SerOptions
export type SerOptions = e.SerOptions

-- Dict
export type DictData = e.DictData
export type DictEntry = {
	type: Variant|e.EntryType,
	options: UnifiedEntryOptions?,
	key: string
}

export type SchematizedDict = e.SchematizedDict
export type UnifiedEntryOptions = e.UnifiedEntryOptions & {
	Schema: Variant|Schema?
}

export type DictLogical = {
	keys: {[string|number]: DictEntry},
	entries: {DictEntry}
}

type DictSchemaProto = { 
	_cache: {[number]: SchematizedDict},
	_variants: {DictVariant},
	_indexed: boolean?
}

type DictVariantProto = {
	_logical: DictLogical,
	_base: DictSchema,
	_lastKey: number?
}

type DictMethods = {
	Deserialize: (self: DictVariant, data: buffer, skipSanitize: boolean?) -> (DictData, number),
	Load: (self: DictVariant, data: buffer|DictData, options: SerOptions?) -> DictData,
	Template: (self: DictVariant, options: Versioning?, lists: boolean?) -> DictData,
	Serialize: (self: DictVariant, data: DictData, options: SerOptions?) -> buffer,
	Bytes: (self: DictVariant, data: DictData, options: SerOptions?) -> number,
	Logic: (self: DictVariant, options: Versioning?) -> SchematizedDict,
	Variant: (self: DictVariant, version: number?) -> DictVariant,
	Build: (self: DictVariant) -> DictVariant,

	schema: (self: DictVariant, key: string, schema: Variant|Schema, options: e.SerOptions?) -> DictVariant,
	tuple: (self: DictVariant, key: string, func: (tuple: TupleVariant) -> ()) -> DictVariant,
	dict: (self: DictVariant, key: string, func: (dict: DictVariant) -> ()) -> DictVariant,
	list: (self: DictVariant, key: string, func: (list: ListVariant) -> ()) -> DictVariant,

	brickcolor: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,
	varchar: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,
	color3: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,
	buffer: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,
	char: (self: DictVariant, key: string, options: e.LenghtOptions) -> DictVariant,
	bool: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,
	bits: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,
	auto: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,
	enum: (self: DictVariant, key: string, options: e.EnumOptions) -> DictVariant,
	id: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,

	number: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,
	float: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,
	uint: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,
	int: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,

	numberVec3: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,
	floatVec3: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,
	uintVec3: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,
	intVec3: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,

	numberVec2: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,
	floatVec2: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,
	uintVec2: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,
	intVec2: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,

	lcframe: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant,
	cframe: (self: DictVariant, key: string, options: e.EntryOptions?) -> DictVariant
}

local dict_mt = { __index = {} :: DictMethods }

export type DictSchema = typeof(setmetatable({} :: DictSchemaProto, dict_mt))
export type DictVariant = typeof(setmetatable({} :: DictVariantProto, dict_mt))

type TupleIndex = { Index: number? }
type TupleMethods = {
	Deserialize: (self: TupleVariant, data: buffer, skipSanitize: boolean?) -> (ListData, number),
	Load: (self: TupleVariant, data: buffer|ListData, options: SerOptions?) -> ListData,
	Template: (self: TupleVariant, options: Versioning?, lists: boolean?) -> ListData,
	Serialize: (self: TupleVariant, data: ListData, options: SerOptions?) -> buffer,
	Bytes: (self: TupleVariant, data: ListData, options: SerOptions?) -> number,
	Logic: (self: TupleVariant, options: Versioning?) -> SchematizedDict,
	Variant: (self: TupleVariant, version: number?) -> TupleVariant,
	Build: (self: TupleVariant) -> TupleVariant,

	schema: (self: TupleVariant, schema: Variant|Schema, options: e.SerOptions?) -> TupleVariant,
	tuple: (self: TupleVariant, func: (tuple: TupleVariant) -> ()) -> TupleVariant,
	dict: (self: TupleVariant, func: (dict: DictVariant) -> ()) -> TupleVariant,
	list: (self: TupleVariant, func: (list: ListVariant) -> ()) -> TupleVariant,

	brickcolor: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,
	varchar: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,
	color3: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,
	buffer: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,
	char: (self: TupleVariant, options: (e.LenghtOptions & TupleIndex)) -> TupleVariant,
	bool: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,
	bits: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,
	auto: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,
	enum: (self: TupleVariant, options: (e.EnumOptions & TupleIndex)) -> TupleVariant,
	id: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,

	number: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,
	float: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,
	uint: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,
	int: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,

	numberVec3: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,
	floatVec3: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,
	uintVec3: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,
	intVec3: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,

	numberVec2: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,
	floatVec2: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,
	uintVec2: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,
	intVec2: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,

	lcframe: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant,
	cframe: (self: TupleVariant, options: (e.EntryOptions & TupleIndex)?) -> TupleVariant
}

local tuple_mt = { __index = {} :: TupleMethods }

export type TupleSchema = typeof(setmetatable({} :: DictSchemaProto, tuple_mt))
export type TupleVariant = typeof(setmetatable({} :: DictVariantProto, tuple_mt))


-- List
export type ListData = e.ListData
export type ListLogical = {
	type: Variant|e.EntryType?,
	options: UnifiedEntryOptions?
}

export type SchematizedList = e.SchematizedList

type ListSchemaProto = { 
	_cache: {[number]: SchematizedList},
	_variants: {ListVariant}
}

type ListVariantProto = {
	_logical: ListLogical,
	_base: ListSchema
}

type ListMethods = {
	Deserialize: (self: ListVariant, data: buffer, skipSanitize: boolean?) -> (ListData, number),
	Load: (self: ListVariant, data: buffer|ListData, options: SerOptions?) -> ListData,
	Template: (self: ListVariant, options: Versioning?, lists: boolean) -> ListData,
	Serialize: (self: ListVariant, data: ListData, options: SerOptions?) -> buffer,
	Bytes: (self: ListVariant, data: ListData, options: SerOptions?) -> number,
	Logic: (self: ListVariant, options: Versioning?) -> SchematizedList,
	Variant: (self: ListVariant, version: number?) -> ListVariant,
	Build: (self: ListVariant) -> ListVariant,

	schema: (self: ListVariant, schema: Variant|Schema, options: e.SerOptions?) -> (),
	tuple: (self: ListVariant, func: (tuple: TupleVariant) -> ()) -> ListVariant,
	dict: (self: ListVariant, func: (dict: DictVariant) -> ()) -> (),
	list: (self: ListVariant, func: (list: ListVariant) -> ()) -> (),

	brickcolor: (self: ListVariant, options: e.EntryOptions?) -> (),
	varchar: (self: ListVariant, options: e.EntryOptions?) -> (),
	color3: (self: ListVariant, options: e.EntryOptions?) -> (),
	buffer: (self: ListVariant, options: e.EntryOptions?) -> (),
	char: (self: ListVariant, options: e.LenghtOptions) -> (),
	bool: (self: ListVariant, options: e.EntryOptions?) -> (),
	bits: (self: ListVariant, options: e.EntryOptions?) -> (),
	auto: (self: ListVariant, options: e.EntryOptions?) -> (),
	enum: (self: ListVariant, options: e.EnumOptions) -> (),
	id: (self: ListVariant, options: e.EntryOptions?) -> (),

	number: (self: ListVariant, options: e.EntryOptions?) -> (),
	float: (self: ListVariant, options: e.EntryOptions?) -> (),
	uint: (self: ListVariant, options: e.EntryOptions?) -> (),
	int: (self: ListVariant, options: e.EntryOptions?) -> (),

	numberVec3: (self: ListVariant, options: e.EntryOptions?) -> (),
	floatVec3: (self: ListVariant, options: e.EntryOptions?) -> (),
	uintVec3: (self: ListVariant, options: e.EntryOptions?) -> (),
	intVec3: (self: ListVariant, options: e.EntryOptions?) -> (),

	numberVec2: (self: ListVariant, options: e.EntryOptions?) -> (),
	floatVec2: (self: ListVariant, options: e.EntryOptions?) -> (),
	uintVec2: (self: ListVariant, options: e.EntryOptions?) -> (),
	intVec2: (self: ListVariant, options: e.EntryOptions?) -> (),

	lcframe: (self: ListVariant, options: e.EntryOptions?) -> (),
	cframe: (self: ListVariant, options: e.EntryOptions?) -> ()
}

local list_mt = { __index = {} :: ListMethods }

export type ListSchema = typeof(setmetatable({} :: ListSchemaProto, list_mt))
export type ListVariant = typeof(setmetatable({} :: ListVariantProto, list_mt))

-- Utils
export type Schematized = e.Schematized
export type Variant = DictVariant|ListVariant
export type Schema = DictSchema|ListSchema

type Map = {[any]: {
	_data: DictEntry,
	_idx: number
}|Map}

local BUDDY_TABLE = table.freeze({})
local sanitizePlans = setmetatable({}, { __mode = "k" })
local serializationCaches = setmetatable({}, { __mode = "k" })

local function getError(msg: any)
	if type(msg) ~= "string" then
		return tostring(msg)
	end

	return (string.gsub(msg, "^.-:%d+:?%s*", ""))
end

local function isListVariant(self: Variant): boolean
	return not (self :: DictVariant)._logical.entries
end

local function isDictVariant(t: Variant): boolean
	return not isListVariant(t)
end

local function isListSchema(logi: any): boolean
	return type(logi) == "table" and logi.type ~= nil
end

local function isDictSchema(logi: any): boolean
	return type(logi) == "table" and not isListSchema(logi)
end

local function isListData(data: any): boolean
	if type(data) ~= "table" then return false end
	local l = #data

	if l == 0 then
		return next(data) == nil
	end

	local key = next(data, l)
	return key == nil
end

local function isDictData(data: any): boolean
	if type(data) ~= "table" then return false end
	--for k, v in ipairs(data) do return false end -- Allows numbers as keys
	return true
end

local function processEntryType(t: Variant|e.EntryType, map: Map, key: string?, existingSchema: any?): SchematizedDict|SchematizedList|e.EntryType
	if type(t) ~= "string" then
		local subMap = map
		if key then
			map[key] = map[key] or { _sub = {} }
			subMap = (map[key] :: any)._sub
		end

		local schema = (type(existingSchema) == "table" and existingSchema) or {}
		if isListVariant(t :: Variant) then
			return this.schematizeList(schema, subMap, t :: ListVariant)
		end

		return this.schematizeDict(schema, subMap, t :: DictVariant)
	end

	return t
end

local function mergeLatest(old: {[string]: any}?, new: {[string]: any}?)
	if not old then return new or BUDDY_TABLE end
	if not new then return old end

	local merged = table.clone(old)
	for k, v in new do merged[k] = v end
	return merged
end

function this.getBase(self: Schema|Variant): Schema
	return (self :: Variant)._base or self :: Schema
end

function this.getVariant(self: Schema|Variant, variant: number): Variant
	local v = this.getBase(self :: Variant)._variants[variant]
	if not v then error(`Variant v{variant} does not exist`) end
	return v
end

function this.versioning(self: Schema|Variant, options: Versioning?): _Versioning
	local options = options or BUDDY_TABLE :: Versioning
	local base = this.getBase(self)

	return {
		Variant = options.Variant or #base._variants,
		Engine = options.Engine or #e.versions
	}
end

function this.serialization(self: Schema|Variant, options: SerOptions?): _SerOptions
	local options = options or BUDDY_TABLE :: SerOptions
	local base = this.getBase(self)
	local cache = serializationCaches[base]
	if not cache then
		cache = setmetatable({}, { __mode = "k" })
		serializationCaches[base] = cache
	end

	local variant = options.Variant or #base._variants
	local engine = options.Engine or #e.versions
	local mode = options.Mode or "Flat" :: "Flat"
	local skipSanitize = not not options.SkipSanitize
	local preallocate = options.Preallocate
	local cached = cache[options]
	if cached and cached.Variant == variant
		and cached.Engine == engine
		and cached.Mode == mode
		and cached.SkipSanitize == skipSanitize
		and cached.Preallocate == preallocate then
		cached.Value.Compress = options.Compress
		return cached.Value
	end

	local serialization = {
		SkipSanitize = skipSanitize,
		Preallocate = preallocate,
		Mode = mode,
		Compress = options.Compress,
		Variant = variant,
		Engine = engine
	}
	cache[options] = {
		Value = serialization,
		SkipSanitize = skipSanitize,
		Preallocate = preallocate,
		Mode = mode,
		Variant = variant,
		Engine = engine
	}
	return serialization
end

function this.variant(self: Schema|Variant, that: any, version: number?): Variant
	local base = this.getBase(self)
	local c = #base._variants

	local version = version or (c +1)
	if c > version then error(`Variant v{version} already exists`) end

	local v: Variant = that.variant(base)
	table.insert(base._variants :: {Variant}, v)
	return v
end

function this.schematizeList(logical: SchematizedList, map: Map, variant: ListVariant): SchematizedList
	local logic = variant._logical

	if type(logical) == "table" then
		logical.options = if type(logical.options) == "table" 
			then mergeLatest(logical.options :: any, logic.options :: any) 
			else logic.options
	end

	local t = logic.type
	if not t then error("List type not specified") end
	logical.type = processEntryType(t, map, nil, logical.type)

	return logical
end

function this.schematizeDict(logical: SchematizedDict, map: Map, variant: DictVariant): SchematizedDict
	for _, e in variant._logical.entries do
		if string.sub(e.key, 1, 1) == "_" then error("Keys cannot start with '_'") end

		local record: any = map[e.key]
		local v = processEntryType(e.type, map, e.key, record
			and record._data :: DictEntry and record._data.type)

		record = map[e.key]
		local r: any = record and record._data or BUDDY_TABLE

		local data = {
			options = mergeLatest(r.options, e.options :: any),
			key = e.key,
			type = v
		} :: DictEntry

		if record and record._idx and logical[record._idx :: any] then
			logical[record._idx :: any] = data :: any
			record._data = data :: any
		else
			table.insert(logical :: any, data)
			if record then
				record._idx = #logical
				record._data = data :: any
			else
				map[e.key] = {
					_idx = #logical,
					_data = data,
					_sub = {}
				}
			end
		end
	end

	return logical
end

local function applySanitizers(sanitizers: e.Sanitizers?, value: any, t: e.Entry, o: e.EntryOptions)
	if not sanitizers then return value end
	local typeName = t.name

	for _, sanit in sanitizers do
		local ty = typeName
		if typeName == "auto" then
			ty = (t :: any):Type(value, o)
		end
		local new = sanit(value, ty)
		value = if new ~= nil then
			new else value
	end

	return value
end

local function flattenSanitizers(sanitizers: e.Sanitizers?): {any}?
	if not sanitizers then return nil end

	local flattened = {}
	local function append(values: e.Sanitizers)
		for _, sanit in values do
			if type(sanit) == "table" then
				append(sanit)
			else
				table.insert(flattened, sanit)
			end
		end
	end

	append(sanitizers)
	return flattened
end

local function getDictSanitizePlan(logi: SchematizedDict): {any}
	local plan = sanitizePlans[logi]
	if plan then return plan end

	plan = table.create(#logi)
	for i = 1, #logi do
		local entry = logi[i]
		local typeName = entry.type
		local item = {
			key = entry.key,
			type = typeName,
			options = entry.options or BUDDY_TABLE,
			sanitizers = flattenSanitizers((entry.options :: any)
				and (entry.options :: any).Sanitizers)
		}
		if type(typeName) == "string" then
			item.entry = e.getType(typeName)
		end
		plan[i] = item
	end

	sanitizePlans[logi] = plan
	return plan
end

local function getListSanitizePlan(logi: SchematizedList): any
	local plan = sanitizePlans[logi]
	if plan then return plan end

	local typeName = logi.type
	plan = {
		type = typeName,
		options = logi.options or BUDDY_TABLE,
		sanitizers = flattenSanitizers((logi.options :: any)
			and (logi.options :: any).Sanitizers)
	}
	if type(typeName) == "string" then
		plan.entry = e.getType(typeName)
	else
		plan.action = isListSchema(typeName) and this.sanitizeList or this.sanitizeDict
	end

	sanitizePlans[logi] = plan
	return plan
end

function this.sanitizeList(logi: SchematizedList, data: ListData, template: boolean?, lists: boolean?): ListData
	if not isListData(data) then error(`Data is not a list: {data}`) end

	local plan = getListSanitizePlan(logi)
	local action = plan.action
	local typeName = plan.type

	local o = plan.options :: any
	if template and lists and #data < 1 then
		table.insert(data, action and BUDDY_TABLE or (o.Default or e
			.getType(logi.type :: string):Default()))
	end

	local sanit = table.create(#data)
	for i, v in data do
		if action then
			sanit[i] = (action :: any)(logi.type, v, template)
			continue
		end

		if typeName == "schema" then
			sanit[i] = if template then
				(o.Schema :: any):Template(o.SerOptions, lists)
				else (o.Schema :: any):Load(v or BUDDY_TABLE, o.SerOptions)

			continue
		end

		local t = plan.entry
		if not template then
			v = applySanitizers(plan.sanitizers, v, t, o)
			v = t:Sanitize(v, o)
		else
			local succ, err = pcall(function()
				v = applySanitizers(plan.sanitizers, v, t, o)
				v = t:Sanitize(v, o)
			end)

			if not succ then -- Force default value
				v = o.Default or t:Default()

				succ, err = pcall(function()
					v = applySanitizers(plan.sanitizers, v, t, o)
					v = t:Sanitize(v, o)
				end)
			end

			if not succ then error(`Failed to sanitize data for index {i}: {getError(err)}`) end
		end
		sanit[i] = v
	end

	return sanit
end

function this.sanitizeDict(logi: SchematizedDict, data: DictData, template: boolean?, lists: boolean?): DictData
	if not isDictData(data) then error(`Data is not a dictionary: {data}`) end
	local sanit = {}

	local plan = getDictSanitizePlan(logi)
	for i = 1, #plan do
		local field = plan[i]
		local value = data[field.key]
		local t = field.type

		if type(t) ~= "string" then
			local struct
			if lists then
				struct = value or {}
			else
				struct = value or BUDDY_TABLE
			end

			sanit[field.key] = if isListSchema(t) then
				this.sanitizeList(t :: SchematizedList, struct, template, lists)
				else this.sanitizeDict(t :: SchematizedDict, struct, template, lists)

			continue
		end

		local o = field.options :: UnifiedEntryOptions
		value = if value ~= nil then
			value else o.Default

		if t == "schema" then
			sanit[field.key] = if template then
				(o.Schema :: any):Template(o.SerOptions, lists)
				else (o.Schema :: any):Load(value or BUDDY_TABLE, o.SerOptions)

			continue
		end

		local entryType = field.entry
		if template then
			value = if value ~= nil then
				value else entryType:Default()
		end

		if value == nil then error(`Missing value for key: {field.key}`) end
		if not template then
			value = applySanitizers(field.sanitizers, value, entryType, o)
			value = entryType:Sanitize(value, o)
		else
			local succ, err = pcall(function()
				value = applySanitizers(field.sanitizers, value, entryType, o)
				value = entryType:Sanitize(value, o)
			end)

			if not succ then -- Force default value
				value = o.Default or entryType:Default()
				succ, err = pcall(function()
					value = applySanitizers(field.sanitizers, value, entryType, o)
				end)
			end

			if not succ then error(`Failed to sanitize data for key {field.key}: {getError(err)}`) end
		end
		sanit[field.key] = value
	end

	return sanit
end

return this
