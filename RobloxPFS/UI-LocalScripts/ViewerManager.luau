local viewerPanel = script.Parent.Main.ViewerPanel

local topButtons = viewerPanel.TopButtons
local registerButton = topButtons.Registers
local flagsButton = topButtons.Flags
local PCButton = topButtons.ProgramCounter
local RAMbutton = topButtons.RAM

local updateEvent = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("Computer"):WaitForChild("CpuUpdate")

local selectedColor = Color3.fromRGB(0, 0, 255)
local unselectedColor = Color3.fromRGB(255, 255, 255)

local labels = viewerPanel.ScrollingFrames
local registerLabel = labels.RegistersSF.RegistersLabel
local flagsLabel = labels.FlagsSF.FlagsLabel
local PCLabel = labels.ProgramCounterSF.PCLabel
local ramLabel = labels.RamSF.RAMLabel

local registerSF = labels.RegistersSF
local flagsSF = labels.FlagsSF
local PCSF = labels.ProgramCounterSF
local ramSF = labels.RamSF

local registers = {}
local flags = {}
local pc = {}
local ram = {}

updateEvent.OnClientEvent:Connect(function(info)
	registers = info.Registers
	flags = info.Flags
	pc = info.PC
	ram = info.Memory
	
	local registersText = ""
	local flagsText = ""
	local pcText = ""
	local ramText = ""
	
	for reg, value in pairs(registers) do
		local line = reg .. ": " .. tostring(value)
		
		if value ~= 0 then
			line = "<font color='rgb(0,255,0)'>" .. line .. "</font>"
		end
		
		registersText ..= line .. "\n"
	end
	
	for flag, value in pairs(flags) do
		flagsText ..= flag .. ": " .. tostring(value) .. "\n"
	end
	
	pcText = "PC: " .. tostring(pc)
	
	for i = 0, 2047 do
		local value = ram[i]
		
		local line = i .. ": " .. tostring(value)
		
		if value ~= 0 then
			line = "<font color='rgb(0,255,0)'>" .. line .. "</font>"
		end
		
		ramText ..= line .. "\n"
	end
	
	registerLabel.Text = registersText
	flagsLabel.Text = flagsText
	PCLabel.Text = pcText
	ramLabel.Text = ramText
end)

registerButton.MouseButton1Click:Connect(function()
	registerButton.UIStroke.Color = selectedColor
	flagsButton.UIStroke.Color = unselectedColor
	PCButton.UIStroke.Color = unselectedColor
	RAMbutton.UIStroke.Color = unselectedColor
	
	registerSF.Visible = true
	flagsSF.Visible = false
	PCSF.Visible = false
	ramSF.Visible = false
end)

flagsButton.MouseButton1Click:Connect(function()
	registerButton.UIStroke.Color = unselectedColor
	flagsButton.UIStroke.Color = selectedColor
	PCButton.UIStroke.Color = unselectedColor
	RAMbutton.UIStroke.Color = unselectedColor
	
	registerSF.Visible = false
	flagsSF.Visible = true
	PCSF.Visible = false
	ramSF.Visible = false
end)

PCButton.MouseButton1Click:Connect(function()
	registerButton.UIStroke.Color = unselectedColor
	flagsButton.UIStroke.Color = unselectedColor
	PCButton.UIStroke.Color = selectedColor
	RAMbutton.UIStroke.Color = unselectedColor
	
	registerSF.Visible = false
	flagsSF.Visible = false
	PCSF.Visible = true
	ramSF.Visible = false
end)

RAMbutton.MouseButton1Click:Connect(function()
	registerButton.UIStroke.Color = unselectedColor
	flagsButton.UIStroke.Color = unselectedColor
	PCButton.UIStroke.Color = unselectedColor
	RAMbutton.UIStroke.Color = selectedColor
	
	registerSF.Visible = false
	flagsSF.Visible = false
	PCSF.Visible = false
	ramSF.Visible = true
end)

