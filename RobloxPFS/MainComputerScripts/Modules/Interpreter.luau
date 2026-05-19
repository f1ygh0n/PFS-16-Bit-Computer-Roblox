local CPU = require(script.Parent.CPU_State)
local ALU = require(script.Parent.ALU)

local outputEvent = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("Computer"):WaitForChild("Output")
local updateEvent = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("Computer"):WaitForChild("CpuUpdate")

local SEG7_DISPLAY_ADDR = 1792

local function ResolveValue(value)
	
	if type(value) == "string" then
		
		if CPU.Registers[value] == nil then
			outputEvent:FireAllClients("Error: Invalid Register " .. tostring(value), CPU.PC)
			return nil
		end
		
		return CPU.Registers[value]
	end
	
	return tonumber(value)
end

local function ResolveAddress(arg)

	if type(arg) == "string" and arg:sub(1,1) == "[" then

		local inside = arg:sub(2, -2) 

		local reg1, reg2 = inside:match("(%w+)%s*%+%s*(%w+)")

		if reg1 and reg2 then

			if CPU.Registers[reg1] == nil or CPU.Registers[reg2] == nil then
				outputEvent:FireAllClients("Error: Invalid Register in " .. inside, CPU.PC)
				return nil
			end

			return CPU.Registers[reg1] + CPU.Registers[reg2]
		end

		local reg, offset = inside:match("(%w+)%s*%+%s*(%d+)")

		if reg then
			if CPU.Registers[reg] == nil then
				outputEvent:FireAllClients("Error: Invalid Register " .. reg, CPU.PC)
				return nil
			end

			return CPU.Registers[reg] + tonumber(offset)
		end

		if CPU.Registers[inside] ~= nil then
			return CPU.Registers[inside]
		end

		outputEvent:FireAllClients("Error: Invalid address " .. tostring(arg), CPU.PC)
		return nil
	end

	return ResolveValue(arg)
end

local function IsValidRegister(reg)
	return CPU.Registers[reg] ~= nil
end

local function AssertRegister(reg)
	
	if CPU.Registers[reg] == nil then
		outputEvent:FireAllClients("Error: Invalid Register " .. tostring(reg), CPU.PC)
		
		return false
	end
	
	return true
end

local function UpdateFlags(value)
	
	value = value % 65536
	
	CPU.Flags.Zero = (value == 0)
	
	CPU.Flags.Negative = (value >= 32768)
	
	CPU.Flags.Overflow = false
end

updateEvent:FireAllClients({
	Registers = CPU.Registers,
	Flags = CPU.Flags,
	PC = CPU.PC,
	Memory = CPU.Memory
})

local Interpreter = {}

function Interpreter.Run(program, labels)
	CPU.Reset()
	
	updateEvent:FireAllClients({
		Registers = CPU.Registers,
		Flags = CPU.Flags,
		PC = CPU.PC,
		Memory = CPU.Memory
	})
	
	outputEvent:FireAllClients(nil, nil, true)
	
	CPU.running = true
	
	local instructionCount = 0
	
	while CPU.running do
		instructionCount += 1
		
		if instructionCount > 100000 then
			outputEvent:FireAllClients("Warning: Program exceeded instructions limit", CPU.PC)
			break
		end
		
		local instr = program[CPU.PC]
		
		if not instr then
			CPU.running = false
			break
		end
		
		local cmd = instr.cmd
		local args = instr.args
		
		if cmd == "LOAD" then
			
			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			local value = ResolveValue(args[2])
			
			if value == nil then
				break
			end
			
			CPU.Registers[reg] = value % 65536
			
		elseif cmd == "ADD" then
			
			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			local value = ResolveValue(args[2])
			
			local aluResult = ALU.Add(CPU.Registers[reg], value)
			
			CPU.Registers[reg] = aluResult.Result
			CPU.Flags.Carry = aluResult.Carry
			
			UpdateFlags(aluResult.Result)
			
		elseif cmd == "SUB" then
			
			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			local value = ResolveValue(args[2])
			
			local aluResult = ALU.Sub(CPU.Registers[reg], value)

			CPU.Registers[reg] = aluResult.Result
			CPU.Flags.Carry = aluResult.Carry

			UpdateFlags(aluResult.Result)
			
		elseif cmd == "PRINT" then
			
			local value = ResolveValue(args[1])
	
			if CPU.Mode == "signed" then
				if value >= 32768 then
					value = value - 65536
				end
			end
			
			outputEvent:FireAllClients(value, CPU.PC)
			
		elseif cmd == "JMP" then
			
			local label = args[1]
			
			local target = labels[label]
			
			if not target then
				outputEvent:FireAllClients("Error: Unknown label " .. tostring(label), CPU.PC)
				CPU.running = false
				break
			end
			
			CPU.PC = target
			continue
			
		elseif cmd == "HLT" then
			
			CPU.running = false
			break
			
		elseif cmd == "JZ" then
			
			local label = args[1]
			
			if CPU.Flags.Zero then
				if not labels[label] then
					outputEvent:FireAllClients("Error: Unknown label " .. tostring(label), CPU.PC)
					break
				end
				
				CPU.PC = labels[label]
				continue
			end
			
		elseif cmd == "JNZ" then
			
			local label = args[1]
			
			if not CPU.Flags.Zero then
				
				if not labels[label] then
					outputEvent:FireAllClients("Error: Unknown label " .. tostring(label), CPU.PC)
					break
				end
				
				CPU.PC = labels[label]
				continue
				
			end
			
		elseif cmd == "MOV" then
			
			local dest = args[1]
			
			if not AssertRegister(dest) then
				break
			end
			
			local source = args[2]
			
			if not AssertRegister(source) then
				break
			end
			
			CPU.Registers[dest] = CPU.Registers[source]
			
		elseif cmd == "CMP" then
			
			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			local value = ResolveValue(args[2])
			
			local result = ALU.Sub(CPU.Registers[reg], value)
			
			UpdateFlags(result.Result)
			
		elseif cmd == "AND" then
			
			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			local value = ResolveValue(args[2])
			
			CPU.Registers[reg] = ALU.BitAND(CPU.Registers[reg], value)
		
		elseif cmd == "OR" then

			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			local value = ResolveValue(args[2])

			CPU.Registers[reg] = ALU.BitOR(CPU.Registers[reg], value)

		elseif cmd == "XOR" then

			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			local value = ResolveValue(args[2])

			CPU.Registers[reg] = ALU.BitXOR(CPU.Registers[reg], value)
			
		elseif cmd == "NOT" then
			
			local reg = args[1]
			if not AssertRegister(reg) then
				break
			end
			
			CPU.Registers[reg] = ALU.BitNOT(CPU.Registers[reg])
			
		elseif cmd == "NAND" then
			
			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			local value = ResolveValue(args[2])
			
			CPU.Registers[reg] = ALU.BitNAND(CPU.Registers[reg], value)
			
		elseif cmd == "NOR" then

			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			local value = ResolveValue(args[2])

			CPU.Registers[reg] = ALU.BitNOR(CPU.Registers[reg], value)
			
		elseif cmd == "XNOR" then

			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			local value = ResolveValue(args[2])

			CPU.Registers[reg] = ALU.BitXNOR(CPU.Registers[reg], value)
		
		elseif cmd == "SHL" then

			local reg = args[1]
			if not AssertRegister(reg) then
				break
			end

			CPU.Registers[reg] = ALU.SHL(CPU.Registers[reg])

		elseif cmd == "SHR" then

			local reg = args[1]
			if not AssertRegister(reg) then
				break
			end

			CPU.Registers[reg] = ALU.SHR(CPU.Registers[reg])
			
		elseif cmd == "STORE" then
			
			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			local address = ResolveAddress(args[2])

			if not address then
				break
			end
			
			if address == SEG7_DISPLAY_ADDR then
				game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("Computer"):WaitForChild("DisplayUpdate"):Fire(CPU.Registers[reg])
			end
			
			if CPU.Memory[address] == nil then
				outputEvent:FireAllClients("Error: Invalid memory address " .. address, CPU.PC)
				break
			end
			
			CPU.Memory[address] = CPU.Registers[reg]
			
		elseif cmd == "LOADM" then
			
			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			local address = ResolveAddress(args[2])
			
			if not address then
				break
			end
			
			if CPU.Memory[address] == nil then
				outputEvent:FireAllClients("Error: Invalid memory address " .. address, CPU.PC)
				break
			end
			
			CPU.Registers[reg] = CPU.Memory[address]
			
		elseif cmd == "PUSH" then
			
			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			CPU.SP += 1
			
			CPU.Stack[CPU.SP] = CPU.Registers[reg]
			
		elseif cmd == "POP" then
			
			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			if CPU.SP <= 0 then
				outputEvent:FireAllClients("Warning: Stack underflow", CPU.PC)
				break
			end
			
			CPU.Registers[reg] = CPU.Stack[CPU.SP]
			
			CPU.Stack[CPU.SP] = nil
			
			CPU.SP -= 1
			
		elseif cmd == "CALL" then
			
			local label = args[1]
			
			local target = labels[label]
			
			if not target then
				outputEvent:FireAllClients("Error: Unknown label " .. tostring(label), CPU.PC)
				break
			end
			
			CPU.SP += 1
			
			CPU.Stack[CPU.SP] = CPU.PC + 1
			
			CPU.PC = target
			
			continue
			
		elseif cmd == "RET" then
			
			if CPU.SP <= 0 then
				outputEvent:FireAllClients("Warning: Stack underflow", CPU.PC)
				break
			end
			
			local returnAdress = CPU.Stack[CPU.SP]
			
			CPU.Stack[CPU.SP] = nil
			
			CPU.SP -= 1
			
			CPU.PC = returnAdress
			
			continue
			
		elseif cmd == "MUL" then
			
			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
		
			local value = ResolveValue(args[2])
			
			local aluResult = ALU.Mul(CPU.Registers[reg], value)

			CPU.Registers[reg] = aluResult.Result
			CPU.Flags.Carry = aluResult.Carry

			UpdateFlags(aluResult.Result)
			
		elseif cmd == "DIV" then
			
			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			local value = ResolveValue(args[2])
			
			local aluResult = ALU.Div(CPU.Registers[reg], value)

			CPU.Registers[reg] = aluResult.Result
			CPU.Flags.Carry = aluResult.Carry

			UpdateFlags(aluResult.Result)
			
		elseif cmd == "MOD" then
			
			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			local value = ResolveValue(args[2])
			
			local aluResult = ALU.Mod(CPU.Registers[reg], value)

			CPU.Registers[reg] = aluResult.Result
			CPU.Flags.Carry = aluResult.Carry

			UpdateFlags(aluResult.Result)
			
		elseif cmd == "INC" then
			
			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			local aluResult = ALU.Inc(CPU.Registers[reg])

			CPU.Registers[reg] = aluResult.Result
			CPU.Flags.Carry = aluResult.Carry

			UpdateFlags(aluResult.Result)
			
		elseif cmd == "DEC" then
			
			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			local aluResult = ALU.Dec(CPU.Registers[reg])

			CPU.Registers[reg] = aluResult.Result
			CPU.Flags.Carry = aluResult.Carry

			UpdateFlags(aluResult.Result)
			
		elseif cmd == "NOP" then
			-- do nothing lol
		elseif cmd == "JE" then
			
			local label = args[1]
			
			if CPU.Flags.Zero then
				
				if not labels[label] then
					outputEvent:FireAllClients("Error: Unknown label " .. tostring(label), CPU.PC)
					break
				end
				
				CPU.PC = labels[label]
				continue
			end
			
		elseif cmd == "JNE" then
			
			local label = args[1]
			
			if not CPU.Flags.Zero then
				
				if not labels[label] then
					outputEvent:FireAllClients("Error: Unknown label " .. tostring(label), CPU.PC)
					break
				end
				
				CPU.PC = labels[label]
				continue
			end
			
		elseif cmd == "JL" then
			
			local label = args[1]

			if CPU.Flags.Negative then

				if not labels[label] then
					outputEvent:FireAllClients("Error: Unknown label " .. tostring(label), CPU.PC)
					break
				end

				CPU.PC = labels[label]
				continue
			end
			
		elseif cmd == "JG" then
			
			local label = args[1]

			if not CPU.Flags.Zero and not CPU.Flags.Negative then

				if not labels[label] then
					outputEvent:FireAllClients("Error: Unknown label " .. tostring(label), CPU.PC)
					break
				end

				CPU.PC = labels[label]
				continue
			end
			
		elseif cmd == "PEEK" then
			
			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			if CPU.SP <= 0 then
				outputEvent:FireAllClients("Warning: Stack underflow", CPU.PC)
				break
			end
			
			CPU.Registers[reg] = CPU.Stack[CPU.SP]
			
		elseif cmd == "SWAP" then
			
			local reg1 = args[1]
			local reg2 = args[2]
			
			if not AssertRegister(reg1) or not AssertRegister(reg2) then
				break
			end
			
			local temp = CPU.Registers[reg1]
			
			CPU.Registers[reg1] = CPU.Registers[reg2]
			
			CPU.Registers[reg2] = temp
			
		elseif cmd == "NEG" then
			
			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			local inverted = ALU.BitNOT(CPU.Registers[reg])
			
			local result = ALU.Add(inverted, 1)
			
			CPU.Registers[reg] = result.Result
			
			UpdateFlags(result.Result)
			
		elseif cmd == "TEST" then
			
			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			local value = ResolveValue(args[2])
			
			local result = ALU.BitAND(CPU.Registers[reg], value)
			
			UpdateFlags(result)
			
		elseif cmd == "LEA" then
			
			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			local address = ResolveValue(args[2]) or 0
			
			CPU.Registers[reg] = address % 65536
			
			UpdateFlags(CPU.Registers[reg])
		
		elseif cmd == "ROL" then
			
			local reg = args[1]
			
			if not AssertRegister(reg) then
				break
			end
			
			local result = ALU.ROL(CPU.Registers[reg])
			
			CPU.Registers[reg] = result.Result
			CPU.Flags.Carry = result.Carry
			
			UpdateFlags(result.Result)
			
		elseif cmd == "ROR" then
			
			local reg = args[1]

			if not AssertRegister(reg) then
				break
			end

			local result = ALU.ROR(CPU.Registers[reg])

			CPU.Registers[reg] = result.Result
			CPU.Flags.Carry = result.Carry

			UpdateFlags(result.Result)
		
		end
		
		updateEvent:FireAllClients({
			Registers = CPU.Registers,
			Flags = CPU.Flags,
			PC = CPU.PC,
			Memory = CPU.Memory
		})
		
		CPU.PC += 1
		
		task.wait(0.05)
	end
end

return Interpreter
