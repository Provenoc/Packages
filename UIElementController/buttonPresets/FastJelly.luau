--[[
	Name: JellyBtn.lua
	Description: not finished yet/cleaned
]]
--[[ Services ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[[ Assets ]]
local Packages = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages")
--[[ Dependencies ]]
local AnimNation = require(Packages:WaitForChild("AnimNation"))

-- Track hover state
local hoverStates = setmetatable({}, { __mode = "k" })

return {
	Connections = {
		MouseEnter = function(buttonInstance : GuiButton, ScaleOriginal : number, ScaleChange : number)

			assert(buttonInstance:FindFirstChildOfClass("UIScale"), `{buttonInstance.Name} is missing a UIScale Instance.`)
			hoverStates[buttonInstance] = true
			AnimNation.target(buttonInstance:FindFirstChildOfClass("UIScale"), {s = 32, d = .8}, {Scale = ScaleOriginal + ScaleChange})

		end,

		MouseLeave = function(buttonInstance : GuiButton, ScaleOriginal : number, ScaleChange : number)
			assert(buttonInstance:FindFirstChildOfClass("UIScale"), `{buttonInstance.Name} is missing a UIScale Instance.`)
			hoverStates[buttonInstance] = false
			AnimNation.target(buttonInstance:FindFirstChildOfClass("UIScale"), {s = 32, d = .8}, {Scale = ScaleOriginal})
		end,

		MouseButton1Down = function(buttonInstance : GuiButton, ScaleOriginal : number, ScaleChange : number)
			assert(buttonInstance:FindFirstChildOfClass("UIScale"), `{buttonInstance.Name} is missing a UIScale Instance.`)
			AnimNation.target(buttonInstance:FindFirstChildOfClass("UIScale"), {s = 32, d = .8}, {Scale = ScaleOriginal - (ScaleChange/2)})
		
		end,

		MouseButton1Up = function(buttonInstance : GuiButton, ScaleOriginal : number, ScaleChange : number)
			assert(buttonInstance:FindFirstChildOfClass("UIScale"), `{buttonInstance.Name} is missing a UIScale Instance.`)

			local isHovered = hoverStates[buttonInstance]
			local targetScale = isHovered and (ScaleOriginal + ScaleChange) or ScaleOriginal
			
			AnimNation.target(buttonInstance:FindFirstChildOfClass("UIScale"), {s = 32, d = .8}, {Scale = targetScale})
		end,
		Activated = function()
			return true
		end
	}
}
