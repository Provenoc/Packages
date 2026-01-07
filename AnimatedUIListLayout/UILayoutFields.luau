--!strict
--[[ 
    UILayoutFields.lua
]]
local AnimNation = require(script.Parent.Parent.AnimNation)

local UILayoutFields = {}

--// SORTING TYPES
UILayoutFields.SortOrder = {
	LayoutOrder = function(a: GuiObject, b: GuiObject)
		return (a.LayoutOrder or 0) < (b.LayoutOrder or 0)
	end,

	Alphabetical = function(a: GuiObject, b: GuiObject)
		return (a.Name or "") < (b.Name or "")
	end;
	Age = function(a: GuiObject, b: GuiObject)
		return (a:GetAttribute("Age") < b:GetAttribute("Age"))
	end,
}

UILayoutFields.EntryType = {
	Default = function(GUI_OBJECT : GuiObject, Position : UDim2)
		AnimNation.target(GUI_OBJECT, { s = 20, d = 1 }, {
			Position = Position
		})
		return true
	end,
	HorizontalEntry = function(GUI_OBJECT : GuiObject, Position)
		GUI_OBJECT.Position = UDim2.new(GUI_OBJECT.Position.X.Scale, GUI_OBJECT.Position.X.Offset, Position.Y.Scale, Position.Y.Offset)
		AnimNation.target(GUI_OBJECT, {s = 20,d = 1},{
			Position = Position
		})
	end,
}
--// CELL TYPE
UILayoutFields.CellType = {
	Explicit = "Explicit",   -- uses LayoutRules.CellSize
	Automatic = "Automatic", -- uses object's size
}

--// TYPE DEFINITIONS (not enforced at runtime, just for clarity)
export type LayoutRules = {
	SortDirection : Enum.SortDirection;
	FillDirection: Enum.FillDirection,
	HorizontalAlignment: Enum.HorizontalAlignment,
	BorderPadding: Vector2,
	ObjectPadding: Vector2,
	Wraps: boolean,

	SortFunction: (GuiObject, GuiObject) -> boolean,

	CellType: string,
	CellSize: UDim2?,
	EntryType : (GuiObject, Position : UDim2) -> boolean;
	AutoSort: boolean,

	HorizontalFlex: Enum.UIFlexAlignment,
	VerticalFlex: Enum.UIFlexAlignment,

	ANIMATION_THRESHOLD: number,
}

return UILayoutFields
