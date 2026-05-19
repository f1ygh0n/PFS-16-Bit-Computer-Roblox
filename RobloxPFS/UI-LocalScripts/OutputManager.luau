local outputPanel = script.Parent.Main.OutputPanel.ScrollingFrame.TextLabel
local outputEvent = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("Computer"):WaitForChild("Output")

local outputLines = {}

outputEvent.OnClientEvent:Connect(function(output, lineNumber, reset)
	if reset == true then
		outputLines = {}
		outputPanel.Text = ""
		return
	end
	
	
	table.insert(outputLines, {output, lineNumber})
	
	local finalText = ""
	
	for _, output in ipairs(outputLines) do
		local formatted = output[1]
		local lineNo = output[2]
		
		if string.find(formatted, "Warning") then
			formatted = "<font color='rgb(255, 123, 0)'>" .. formatted .. "</font> "
		elseif string.find(formatted, "Error") then
			formatted = "<font color='rgb(255, 0, 0)'>" .. formatted .. "</font> "
		end
		
		finalText ..= "Line " .. tostring(lineNo) .. ": " .. formatted .. "\n"
	end
	
	outputPanel.Text = finalText
end)
