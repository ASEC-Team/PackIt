--!strict
--!native

local this = {}

function this.writeu24(buf: buffer, offset: number, value: number)
	buffer.writeu8(buf, offset, bit32.band(value, 0xFF))
	buffer.writeu8(buf, offset + 1, bit32.extract(value, 8, 8))
	buffer.writeu8(buf, offset + 2, bit32.rshift(value, 16))
end

function this.readu24(buf: buffer, offset: number): number
	local b1 = buffer.readu8(buf, offset)
	local b2 = buffer.readu8(buf, offset + 1)
	local b3 = buffer.readu8(buf, offset + 2)

	return bit32.bor(
		b1,
		bit32.lshift(b2, 8),
		bit32.lshift(b3, 16)
	)
end

function this.writei24(buf: buffer, offset: number, value: number)
	local uvalue = bit32.band(value, 0xFFFFFF)

	buffer.writeu8(buf, offset, bit32.band(uvalue, 0xFF))
	buffer.writeu8(buf, offset + 1, bit32.extract(uvalue, 8, 8))
	buffer.writeu8(buf, offset + 2, bit32.rshift(uvalue, 16))
end

function this.readi24(buf: buffer, offset: number): number
	local b1 = buffer.readu8(buf, offset)
	local b2 = buffer.readu8(buf, offset + 1)
	local b3 = buffer.readu8(buf, offset + 2)

	local uvalue = bit32.bor(
		b1,
		bit32.lshift(b2, 8),
		bit32.lshift(b3, 16)
	)

	if bit32.btest(uvalue, 0x800000) then
		return uvalue - 0x1000000
	end

	return uvalue
end

return this
