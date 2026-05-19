local CPU = {
	Registers = {
		A = 0,
		B = 0,
		C = 0,
		D = 0
	},
	
	Memory = {},
	
	Stack = 0,
	SP = 0,
	
	PC = 1,
	
	Flags = {
		Zero = false,
		Carry = false,
		Negative = false,
		Overflow = false
	},
	
	Mode = "unsigned",
	running = false
}

function CPU.Reset()
	for _, reg in pairs(CPU.Registers) do
		reg = 0
	end
	
	CPU.Memory = {}
	
	CPU.Stack = {}
	CPU.SP = 0
	
	for i = 0, 2047 do
		CPU.Memory[i] = 0
	end
	
	CPU.PC = 1
	
	CPU.Flags.Zero = false
	CPU.Flags.Carry = false
end

return CPU
