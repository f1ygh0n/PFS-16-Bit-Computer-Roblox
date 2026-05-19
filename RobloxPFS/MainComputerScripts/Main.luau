local OutputEvent = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("Computer"):WaitForChild("Output")
local InputEvent = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("Computer"):WaitForChild("Input")
local ModeEvent = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("Computer"):WaitForChild("ToggleMode")

local moduleScripts = script.Parent.Modules
local aluMS = require(moduleScripts.ALU)
local parserMS = require(moduleScripts.Parser)
local interpreterMS = require(moduleScripts.Interpreter)

local CPU = require(moduleScripts.CPU_State)

InputEvent.OnServerEvent:Connect(function(plr, text)
	local program, labelsOrError = parserMS.Parse(text)
	
	if not program then
		warn(labelsOrError)
		return
	end
	
	local labels = labelsOrError 
	
	interpreterMS.Run(program, labels)
end)

ModeEvent.OnServerEvent:Connect(function(plr, mode)
	print("Switched to " .. mode .. " mode")
	
	CPU.Mode = mode
end)