--!strict
--!native

local s = require("@self/Flat")
local t = require("./Types")

local this = {}
local modes = {
	Nested = require("@self/Nested"),
	Flat = require("@self/Flat")
}

function this.new(logic: t.Schematized, data: t.Data|buffer, options: t.Serialization): s.Serializer 
	if not modes[options.Mode] then error(`Mode {options.Mode} not supported by this engine`) end
	return modes[options.Mode].new(logic, data)
end

return this
