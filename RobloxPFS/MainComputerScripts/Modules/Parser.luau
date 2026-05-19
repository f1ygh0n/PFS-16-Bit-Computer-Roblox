local parser = {}

local outputEvent = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("Computer"):WaitForChild("Output")

function parser.Parse(text)
	local program = {}
	local labels = {}
	local lines = text:split("\n")
	
	local validCommands = {
		LOAD = true,
		ADD = true,
		SUB = true,
		PRINT = true,
		JMP = true,
		HLT = true,
		JZ = true,
		JNZ = true,
		MOV = true,
		CMP = true,
		AND = true,
		OR = true,
		XOR = true,
		NOT = true,
		NAND = true,
		NOR = true,
		XNOR = true,
		SHL = true,
		SHR = true,
		STORE = true,
		LOADM = true, 
		PUSH = true,
		POP = true,
		CALL = true,
		RET = true, 
		MUL = true,
		DIV = true,
		MOD = true,
		INC = true,
		DEC = true,
		NOP = true, 
		JE = true,
		JNE = true,
		JL = true,
		JG = true,
		PEEK = true,
		SWAP = true,
		ROL = true,
		ROR = true,
		NEG = true,
		TEST = true,
		LEA = true -- 42 commands
	}
	
	for lineNumber, line in ipairs(lines) do
		line = line:match("^%s*(.-)%s*$")
		
		if line == "" then continue end
		
		if line:sub(-1) == ":" then
			local labelName = line:sub(1, -2):upper()
			
			if labels[labelName] then
				outputEvent:FireAllClients("Error: " .. labelName .. " already exists", lineNumber)
				return nil
			end
			
			labels[labelName] = #program + 1
			continue
		end
		
		local parts = {}
		
		for token in string.gmatch(line, "%S+") do
			table.insert(parts, token)
		end
		
		local cmd = parts[1]:upper()
		
		if not validCommands[cmd] then
			outputEvent:FireAllClients("Error: Unknown command " .. cmd .. ", either the command has not been added yet or invalid command", lineNumber)
			return nil
		end
		
		local args = {}
		
		local i =2 
		while i <= #parts do
			local part = parts[i]

			if part:sub(1,1) == "[" then

				local full = part

				while not full:find("]") and i < #parts do
					i += 1
					full = full .. " " .. parts[i]
				end

				table.insert(args, full)
			else
				local num = tonumber(part)
				table.insert(args, num or part)
			end

			i += 1
		end
		
		table.insert(program, {
			cmd = cmd,
			args = args,
			line = lineNumber
		})
	end
	
	return program, labels
end

return parser
