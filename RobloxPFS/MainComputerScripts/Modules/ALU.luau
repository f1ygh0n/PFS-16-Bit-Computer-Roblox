local ALU = {}

---------------------------------------------------

function ALU.AND(a, b)
	return (a == 1 and b == 1) and 1 or 0
end

function ALU.OR(a, b)
	return (a == 1 or b == 1) and 1 or 0
end

function ALU.NOT(a)
	return a == 1 and 0 or 1
end

function ALU.NOR(a, b)
	return ALU.NOT(ALU.OR(a, b))
end

function ALU.NAND(a, b)
	return ALU.NOT(ALU.AND(a, b))
end

function ALU.XOR(a, b)
	return (a ~= b) and 1 or 0
end

function ALU.XNOR(a, b)
	return ALU.NOT(ALU.XOR(a, b))
end

----------------------------------------------------

function ALU.toBits(num)
	local bits = {}
	
	for i = 1, 16 do
		bits[i] = num % 2
		num = math.floor(num / 2)
	end
	
	return bits
end

function ALU.fromBits(bits)
	local num = 0
	
	for i = 1, 16 do
		num += bits[i] * (2 ^ (i - 1))
	end
	
	return num
end

---------------------------------------------------

function ALU.toSigned(value)
	
	if value >= 32768 then
		return value - 65536
	end
	
	return value
end

function ALU.toUnsigned(value)
	
	if value < 0 then
		return value + 65536
	end
	
	return value
end

----------------------------------------------------

function ALU.fullAdder(a, b, carryIn)
	local sum = ALU.XOR(ALU.XOR(a, b), carryIn)
	
	local carryOut = (ALU.AND(a, b) == 1) or (ALU.AND(a, carryIn) == 1) or (ALU.AND(b, carryIn) == 1)
	
	return sum, carryOut and 1 or 0
end

-------------------------------------------------------

function ALU.Add(a, b)
	
	local result = {}
	
	local carry = 0
	
	local aBits = ALU.toBits(a)
	local bBits = ALU.toBits(b)
	
	for i = 1, 16 do
		local xor1 = ALU.XOR(aBits[i], bBits[i])
		local sum = ALU.XOR(xor1, carry)
		local carry1 = ALU.AND(aBits[i], bBits[i])
		local carry2 = ALU.AND(xor1, carry)
		carry = ALU.OR(carry1, carry2)
		
		result[i] = sum
	end
	
	return {
		Result = ALU.fromBits(result),
		Carry = (carry == 1)
	}
end

function ALU.Sub(a, b)
	local inverted = ALU.BitNOT(b)
	
	local twosComplement = ALU.Add(inverted, 1)
	
	local result = ALU.Add(a, twosComplement.Result)
	
	return {
		Result = result.Result,
		Carry = result.Carry
	}
end

function ALU.Mul(a, b)
	
	local result = 0
	local carry = false
	
	for i = 1, b do
		local addResult = ALU.Add(result, a)
		
		result = addResult.Result
		
		if addResult.Carry then
			carry = true
		end
	end
	
	return {
		Result = result,
		Carry = carry
	}
end

function ALU.Div(a, b)

	a = ALU.toSigned(a)
	b = ALU.toSigned(b)

	if b == 0 then
		return {
			Result = 0,
			Carry = false
		}
	end

	local negative = false

	if a < 0 then
		a = -a
		negative = not negative
	end

	if b < 0 then
		b = -b
		negative = not negative
	end

	local count = 0

	while a >= b do
		local subResult = ALU.Sub(a, b)
		a = subResult.Result

		local incResult = ALU.Inc(count)
		count = incResult.Result
	end

	if negative then
		count = ALU.Sub(0, count).Result
	end

	return {
		Result = ALU.toUnsigned(count),
		Carry = false
	}
end

function ALU.Mod(a, b)

	a = ALU.toSigned(a)
	b = ALU.toSigned(b)

	if b == 0 then
		return {
			Result = 0,
			Carry = false
		}
	end

	local negative = (a < 0)

	if a < 0 then
		a = -a
	end

	if b < 0 then
		b = -b
	end

	while a >= b do
		local subResult = ALU.Sub(a, b)
		a = subResult.Result
	end

	if negative then
		a = ALU.Sub(0, a).Result
	end

	return {
		Result = ALU.toUnsigned(a),
		Carry = false
	}
end

function ALU.Inc(a)
	return ALU.Add(a, 1)
end

function ALU.Dec(a)
	return ALU.Sub(a, 1)
end

----------------------------------------------------------

function ALU.Equal(a, b)
	return a == b and 1 or 0
end

function ALU.LessThan(a, b)
	return (a < b) and 1 or 0
end

---------------------------------------------------------

function ALU.BitAND(a, b)
	local aBits = ALU.toBits(a)
	local bBits = ALU.toBits(b)
	
	local result = {}
	
	for i = 1, 16 do
		result[i] = ALU.AND(aBits[i], bBits[i])
	end
	
	return ALU.fromBits(result)
end

function ALU.BitOR(a, b)
	local aBits = ALU.toBits(a)
	local bBits = ALU.toBits(b)

	local result = {}

	for i = 1, 16 do
		result[i] = ALU.OR(aBits[i], bBits[i])
	end

	return ALU.fromBits(result)
end

function ALU.BitXOR(a, b)
	local aBits = ALU.toBits(a)
	local bBits = ALU.toBits(b)

	local result = {}

	for i = 1, 16 do
		result[i] = ALU.XOR(aBits[i], bBits[i])
	end

	return ALU.fromBits(result)
end

function ALU.BitNOT(a)
	
	local bits = ALU.toBits(a)
	
	for i = 1, 16 do
		bits[i] = ALU.NOT(bits[i])
	end
	
	return ALU.fromBits(bits)
end

function ALU.BitNAND(a, b)
	
	local aBits = ALU.toBits(a)
	local bBits = ALU.toBits(b)
	local result = {}
	
	
	for i = 1, 16 do
		result[i] = ALU.NAND(aBits[i], bBits[i])
	end
	
	return ALU.fromBits(result)
end

function ALU.BitNOR(a, b)

	local aBits = ALU.toBits(a)
	local bBits = ALU.toBits(b)

	local result = {}

	for i = 1, 16 do
		result[i] = ALU.NOR(aBits[i], bBits[i])
	end

	return ALU.fromBits(result)
end


function ALU.BitXNOR(a, b)

	local aBits = ALU.toBits(a)
	local bBits = ALU.toBits(b)

	local result = {}

	for i = 1, 16 do
		result[i] = ALU.XNOR(aBits[i], bBits[i])
	end

	return ALU.fromBits(result)
end


------------------------------------------------

function ALU.SHL(a)
	
	local bits = ALU.toBits(a)
	
	for i = 16, 2, -1 do
		bits[i] = bits[i - 1]
	end
	
	bits[1] = 0
	
	return ALU.fromBits(bits)
end

function ALU.SHR(a)
	
	local bits = ALU.toBits(a)
	
	for i = 1, 15 do
		bits[i] = bits[i + 1]
	end
	
	bits[16] = 0
	
	return ALU.fromBits(bits)
end

-------------------------------------------------

function ALU.ROL(value)
	
	local bits = ALU.toBits(value)
	
	local last = bits[16]
	
	for i = 16, 2, -1 do
		bits[i] = bits[i - 1]
	end
	
	bits[1] = last
	
	return {
		Result = ALU.fromBits(bits),
		Carry = (last == 1)
	}
end

function ALU.ROR(value)
	
	local bits = ALU.toBits(value)
	
	local first = bits[1]
	
	for i = 1, 15 do
		bits[i] = bits[i + 1]
	end
	
	bits[16] = first
	
	return {
		Result = ALU.fromBits(bits),
		Carry = (first == 1)
	}
end

return ALU