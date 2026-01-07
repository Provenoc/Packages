--[[
	Name: AdventBtn.lua
	Description: not finished yet/cleaned
]]
--[[ Services ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[[ Assets ]]
local Packages = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages")

--[[ Dependencies ]]
local AnimNation = require(Packages:WaitForChild("AnimNation"))
local Spring = {s = 32, d = .8}
-- Track hover state
local hoverStates = setmetatable({}, { __mode = "k" })

return {
	Connections = {
		MouseEnter = function(buttonInstance : GuiButton, ScaleOriginal : UDim2, ScaleChange : number)
			script.Parent.Parent.Sounds.Viewing:Play() -- temporary
			hoverStates[buttonInstance] = true
			
			AnimNation.target(buttonInstance, Spring, {Size = UDim2.fromScale(ScaleOriginal.X.Scale*ScaleChange,ScaleOriginal.Y.Scale*ScaleChange)})
			AnimNation.target(buttonInstance.Blur, {s = 20,d = 1},{ImageTransparency = 0.5})
			return true, "Hovered"
		end,

		MouseLeave = function(buttonInstance : GuiButton, ScaleOriginal : UDim2, ScaleChange : number)
			hoverStates[buttonInstance] = false
			AnimNation.target(buttonInstance, Spring, {Size = ScaleOriginal})
			AnimNation.target(buttonInstance.Blur, {s = 20,d = 1},{ImageTransparency = 1})
			return true, "HoverEnded"
		end,

		MouseButton1Down = function(buttonInstance : GuiButton, ScaleOriginal : number, ScaleChange : number)
			AnimNation.target(buttonInstance, Spring, {Size = UDim2.fromScale(ScaleOriginal.X.Scale*(ScaleChange/1.2),ScaleOriginal.Y.Scale*(ScaleChange/1.2))})
		end,

		MouseButton1Up = function(buttonInstance : GuiButton, ScaleOriginal : UDim2, ScaleChange : number)
			local isHovered = hoverStates[buttonInstance]
			local targetScale = isHovered and (ScaleChange) or 1

			AnimNation.target(buttonInstance, Spring, {Size = UDim2.fromScale(ScaleOriginal.X.Scale*targetScale,ScaleOriginal.Y.Scale*targetScale)})
		end,
		Activated = function()
			script.Parent.Parent.Sounds.Click:Play() -- temporary
	
			return true, "Activated"
		end
	}
}
