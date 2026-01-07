--[[
	Name: ElementController.lua
	Author: Provenoc
	Description: An element based controller, useful for animating any button with a valid preset (if defined).
	Created: 3/30/25
	Updated: 
		11/21/25 - Reworked the way .Button is handled
	Methods:
		.newButton(guiBase : GuiObject, elementType : string, ... : any)
			Example: Simple button with .Activated, .Hovered, .HoverEnded Connections.
		.newSelector(Options : {GuiObject}, Switch : GuiBase, buttonType : string, UPDATE_DELAY : number)
			Example: A set of options that can be selected. Does support re-selecting an option and toggling it OFF.
		.newSwitch(Btn : GuiButton, Switch : GuiBase, DEFAULT_STATE : boolean, STATES) 
			Example: A lightswitch
		
]]

--[[ Services ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[[ Assets ]]
local Packages = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages")

--[[ Dependencies ]]
local AnimNation = require(Packages:WaitForChild("AnimNation"))
local Signal = require(Packages:WaitForChild("Signal"))
local Trove = require(Packages:WaitForChild("Trove"))

--[[ Types ]]
type Signal = Signal.Signal<>

export type UIElementPreset = {
	Connections : {[string] : (...any) -> (boolean?)}
}

export type Button = {
	Activated : Signal,
	Hovered : Signal,
	HoverEnded : Signal,
	GuiBase : GuiObject,
	__trove : Trove.Trove,
	Type : string
}

export type Selector = {
	OnOptionSelected : Signal;
	Options : {[GuiButton] : Button}
}

export type Switch = {
	State : boolean,
	OnSwitchStateChanged : Signal;
	__trove : Trove.Trove
}

--[[ UIElementController ]]
local UIElementController = {}
UIElementController.__index = UIElementController

--[[
	Constructor
	@param guiBase : GuiObject - The base GUI object to attach the controller to.
	@param elementType : string - The type of preset to use.
	@param ... : any - Any extra data to pass to the element's connection functions.

]]
function UIElementController.newButton(guiBase : GuiObject, elementType : string, ... : any) : Button
	assert(script.buttonPresets:FindFirstChild(elementType),`ElementController: Could not find {elementType}`)

	local elementInfo = require(script.buttonPresets[elementType]) :: UIElementPreset
	
	local self = {
		Activated = Signal.new(),
		Hovered = Signal.new();
		HoverEnded = Signal.new();
		Type = elementType,
		GuiBase = guiBase,
		__trove = Trove.new();
		__originalColor = guiBase.BackgroundColor3;
		__originalSize = guiBase.Size
	}
	local extraData = {...}

	setmetatable(self, UIElementController)
	
	self.__trove:Add(self.Activated)
	self.__trove:Add(self.Hovered)
	self.__trove:Add(self.HoverEnded)
	
	for EventName : string, Func in elementInfo.Connections do
		self.__trove:Add(guiBase[EventName]:Connect(function()
			local invokeCallback, EventType : string, data = Func(guiBase,table.unpack(extraData))
			if invokeCallback then
				self[EventType]:Fire(data)
			end
		end))
	end

	self.__trove:Add(guiBase.Destroying:Once(function()
		if self and self["Destroy"] then
			self:Destroy()
		end
	end))

	return self
end

--[[
	Constructor
	@param Options : {GuiObject} - The available options to chose from.
	@param Switch : GuiBase - The frame that travels based on the chosen option.
	@param buttonType : string - The type of button to use for the options.
	@param UPDATE_DELAY : number - The delay between switching options.
]]

function UIElementController.newSelector(Options : {GuiObject}, Switch : GuiBase, buttonType : string, UPDATE_DELAY : number)
	local self = setmetatable({
		__trove = Trove.new()	
	},UIElementController)
	
	UPDATE_DELAY = UPDATE_DELAY or .5
	
	self.OnOptionSelected = Signal.new()
	self.Options = {}
	self.UPDATE_TICK = tick()
	self.__trove:Add(self.OnOptionSelected)
	for _, Option : GuiButton in Options do
		if Option:IsA("GuiButton") then
			local animatedOption = UIElementController.newButton(Option, buttonType, 1, .1)
			self.Options[Option] = animatedOption

			animatedOption.Activated:Connect(function()
				if tick()-self.UPDATE_TICK < UPDATE_DELAY then return end

				if Switch then
					AnimNation.target(Switch,{s = 20,d = .8}, {Position = Option.Position})
				end
				
				self.OnOptionSelected:Fire(Option.Name)
				self.UPDATE_TICK = tick()
			end)

			self.__trove:Add(animatedOption)
		end
	end
	
	function self:TriggerSwitch(TargetOption : GuiButton)
		if self.Options[TargetOption] then
			self.Options[TargetOption].Activated:Fire()
		end
	end
	
	return self
end

--[[
	Constructor
	@param Btn : GuiObject} - The button whitch acts like a switch.
	@param Switch : GuiBase - The frame that travels based on the chosen option.
	@param DEFAULT_STATE : boolean - The starting state of the Button.
	@param STATES : StateData - The On/Off Data for the switch.
]]

function UIElementController.newSwitch(Btn : GuiButton, Switch : GuiBase, DEFAULT_STATE : boolean,
	States : {
		On : {
			Position : UDim2,
			Color : Color3
		},
		
		Off : {
			Position : UDim2,
			Color : Color3
		},
		
	}
)
	
	local self = setmetatable({
		__trove = Trove.new()	
	},UIElementController)

	self.UPDATE_TICK = tick()
	self.OnSwitchStateChanged = Signal.new()
	self.State = DEFAULT_STATE or "On"
	
	self.__trove:Add(Btn.Activated:Connect(function()
		if tick()-self.UPDATE_TICK < .1 then return end
		
		self.State = self.State == "On" and "Off" or "On"
		
		AnimNation.target(Btn, {s = 20, d = .8}, {BackgroundColor3 = States[self.State].Color})
		AnimNation.target(Switch, {s = 20,d = .8},{Position = States[self.State].Position})
		
		self.OnSwitchStateChanged:Fire(self.State)
		self.UPDATE_TICK = tick()
	end))
	
	function self:SetState(newState : string)
		self.State = self.State == "On" and "Off" or "On"

		AnimNation.target(Btn, {s = 20, d = .8}, {BackgroundColor3 = States[self.State].Color})
		AnimNation.target(Switch, {s = 20,d = .8},{Position = States[self.State].Position})
	end
	
	self.__trove:Add(self.OnSwitchStateChanged)
	
	return self
end

--@ Method which cleans up the controller and its connections.
function UIElementController:Destroy()
	self.__trove:Destroy()
	if self.Activated then
		self.Activated:Destroy()
	end
	setmetatable(self,nil)
end

return UIElementController
