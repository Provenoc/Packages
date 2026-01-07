--[[
	Name: LazyPane.lua
	Author: Provenoc
	Created: 3/29/25
	Description: Basically simplifies the constant typing of acquiring UI Descendants, returns only the once specified allowing for easy use.
	COMPATIBLE WITH UI-LABS
	Example:
		local UIHandler : LazyPane.LazyPaneObject = LazyPane.new(ScreenGui, {
			"ExitButton";
			"OpenButton"
		})
		UIHandler.ExitButton.Activated:Once(Quit)
		UIHandler.OpenButton.Activated:Once(Open)
	Functions:
		- .new(UI_TEMPLATE : GuiObject, Instances : {[number] : string}) 
			-> Returns a LazyPaneObject.
]]

--[[ Services ]]
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[[ Assets ]]
local Packages = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages")

--[[ Dependencies ]]
local Signal = require(Packages:WaitForChild("Signal"))
local Trove = require(Packages:WaitForChild("Trove"))

--[[ Types ]] 
export type LazyPaneObject<T> = {
	Gui : GuiObject,
	_trove : Trove.Trove,
} & T

--[[ LazyPane ]]
local LazyPane = {}
LazyPane.__index = LazyPane
LazyPane.ClassName = "LazyPane"

--[[
	Constructor
	@summary Returns a new LazyPane Object
	@param UI_Template(GuiObject) - The UI to link to.
	@param Instances({[number] : string}) - A table of the descendants to use.
	@returns LazyPane Object
]]
function LazyPane.new<T>(UI_Template : GuiObject, Instances : {[number] : string}) : LazyPaneObject<T>
	assert(UI_Template, `LazyPane - Cannot have a empty UI_Template`)
	local self = setmetatable({},LazyPane) :: LazyPaneObject<T>
	
	-- Acquire the GUI
	self.Gui = UI_Template
	
	-- Acquire the Descendants to use.
	for _, Descendant : GuiObject in self.Gui:GetDescendants() do
		if table.find(Instances,Descendant.Name) then
			self[Descendant.Name] = Descendant
		end
	end
	
	-- Setup Trove 
	self._trove = Trove.new()
	self._trove:Add(self.Gui)

	return self
end


return LazyPane 