--!strict
--[[ File Info
	Author: Provenoc
	Name: AnimatedUIListLayout.lua
	
	
	A direct copy of the Roblox UIListLayout, 
	but animated.
	
	Types:
		- NOTE: AFTER A VALUE IS MANUALLY CHANGED, BE SURE TO CALL :Sort()
		LayoutRules (table) - Rules that define the UIListLayout.
			.FillDirection (Enum.FillDirection) - Direction the layout should fill.
			.HorizontalAlignment (Enum.HorizontalAlignment) - Horizontal alignment of the layout. (.Left, .Center, .Right)
			.BorderPadding (Vector2) - Padding applied between top-left and bottom-right corners.
			.Wraps (boolean) - Whether the layout should wrap onto the next column/row, or continue in the direction.
			.SortFunction (fn) - The function to use to sort the objects in the layout (SortType.LayoutOrder, SortType.Alphabetical, or your own).
			.ObjectPadding (Vector2) - Padding applied between each object in the layout.
			.AutoSort (boolean) - Whether the AnimatedUIListLayout should call :Sort when a child is removed/added.
			.HorizonalFlex (Enum.UIFlexAlignment) - How extra space is distributed HORIZONTALLY.
			.VerticalFlex (Enum.UIFlexAlignment) - How extra space is distributed VERTICALLY.
			.ANIMATION_THRESHOLD (number) - The max amount of animations to run in a given sort, if over threshold GuiObjects will just be positioned and not lerped.
	
	API:
		.new(GUI_OBJECT : GuiObject, LAYOUT_PROPERTIES : LayoutRules)
			> Creates and returns a new AnimatedUIListLayout object.
			
		:Sort()
			> Re-sorts the layout.
]]

--// Dependencies
local Signal = require(script.Parent.Signal) --@module Signal
local AnimNation = require(script.Parent.AnimNation) --@module AnimNation
local UILayoutFields  = require(script.UILayoutFields) --@module UILayoutProperties
local Trove = require(script.Parent.Trove)
--// Types
type AnimatedUIListLayout = {
	new : (GUI_OBJECT : GuiObject, OVERRIDE_PROPERTIES : UILayoutFields.LayoutRules?) -> (AnimatedUIListLayout);
	Sort : ()-> ();
}
--// Constants 
local DEFAULT_PROPERTIES : UILayoutFields.LayoutRules  = {
	SortDirection = Enum.SortDirection.Descending;
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,

	BorderPadding = UDim2.new(0.02, 0, 0.02, 0), -- use Scale by default (2% of parent)
	ObjectPadding = UDim2.new(0.02, 0, 0.02, 0), -- spacing as scale of parent size
	Wraps = true,
	SortFunction = UILayoutFields.SortOrder.Alphabetical,
	EntryType = UILayoutFields.EntryType.Default;
	

	CellType = UILayoutFields.CellType.Explicit,
	
	AutoSort = true,
	

	HorizontalFlex = Enum.UIFlexAlignment.None,
	VerticalFlex = Enum.UIFlexAlignment.None,

	ANIMATION_THRESHOLD = 30;
}

--// Helper Functions
function OffsetToScale(udim2Offset: UDim2, parentSize: Vector2): UDim2
	local scaleX = udim2Offset.X.Offset / parentSize.X
	local scaleY = udim2Offset.Y.Offset / parentSize.Y
	return UDim2.new(scaleX, 0, scaleY, 0)
end


--// AnimatedUIListLayout Declaration
local AnimatedUIListLayout = {
	UILayoutFields = UILayoutFields
}

AnimatedUIListLayout.__index = AnimatedUIListLayout

function AnimatedUIListLayout.new(GUI_OBJECT : GuiObject, OVERRIDE_PROPERTIES : UILayoutFields.LayoutRules?)
	local self = setmetatable({}, AnimatedUIListLayout)

	self.ChildRemoved = Signal.new()
	self.ChildAdded = Signal.new()
	
	self.GUI_OBJECT_PARENT = GUI_OBJECT :: GuiObject
	self._trove = Trove.new()
	self.Cache = {}
	self.Instances = {} 
	
	self._trove:Add(self.ChildAdded)
	self._trove:Add(self.ChildRemoved)
	
	self.LayoutRules = OVERRIDE_PROPERTIES and table.clone(OVERRIDE_PROPERTIES) or table.clone(DEFAULT_PROPERTIES)

	if self.LayoutRules.AutoSort then
		self:Sort()
		self._trove:Add(self.GUI_OBJECT_PARENT.ChildAdded:Connect(function(Child)
			self:INSTANCE_ADDED(Child)
		end))
		self._trove:Add(self.GUI_OBJECT_PARENT.ChildRemoved:Connect(function(Child)
			self:INSTANCE_REMOVED(Child)
		end))
	end
	return self
end

function AnimatedUIListLayout:organizeInstances()
	table.sort(self.Instances,self.LayoutRules.SortFunction)
end

function AnimatedUIListLayout:Sort()
	self:organizeInstances()

	local parentSize : Vector2 = self.GUI_OBJECT_PARENT.AbsoluteSize

	-- Compute pixel paddings from UDim2 (supports both Scale and Offset)
	local BORDER_PADDING_PIXELS : Vector2 = Vector2.new(
		(self.LayoutRules.BorderPadding.X.Scale * parentSize.X) + self.LayoutRules.BorderPadding.X.Offset,
		(self.LayoutRules.BorderPadding.Y.Scale * parentSize.Y) + self.LayoutRules.BorderPadding.Y.Offset
	)

	local OBJECT_PADDING_PIXELS : Vector2 = Vector2.new(
		(self.LayoutRules.ObjectPadding.X.Scale * parentSize.X) + self.LayoutRules.ObjectPadding.X.Offset,
		(self.LayoutRules.ObjectPadding.Y.Scale * parentSize.Y) + self.LayoutRules.ObjectPadding.Y.Offset
	)
	local GUI_OBJECT_PARENT_CORNER_TOP_LEFT : Vector2 = self.GUI_OBJECT_PARENT.AbsolutePosition :: Vector2
	local GUI_OBJECT_PARENT_CORNER_TOP_LEFT_BORDER_PADDING : Vector2 = GUI_OBJECT_PARENT_CORNER_TOP_LEFT + BORDER_PADDING_PIXELS
	local GUI_OBJECT_PARENT_CORNER_BOTTOM_RIGHT : Vector2 = GUI_OBJECT_PARENT_CORNER_TOP_LEFT + self.GUI_OBJECT_PARENT.AbsoluteSize
	local GUI_OBJECT_PARENT_CORNER_BOTTOM_RIGHT_BORDER_PADDING : Vector2 = GUI_OBJECT_PARENT_CORNER_BOTTOM_RIGHT - BORDER_PADDING_PIXELS
	local GUI_OBJECT_PARENT_CENTER_BORDER_PADDING : Vector2 = (GUI_OBJECT_PARENT_CORNER_TOP_LEFT_BORDER_PADDING+GUI_OBJECT_PARENT_CORNER_BOTTOM_RIGHT_BORDER_PADDING)/2

	local ROW : number = 0
	local COLUMN : number = 0

	local OBJECTS_IN_ROW = {}
	local OBJECTS_IN_COLUMN = {}

	for i = 1, #self.Instances do

		local DESCENDANT_GUI_OBJECT : GuiObject = self.Instances[i]
		local DESCENDANT_GUI_OBJECT_SIZE : Vector2 = DESCENDANT_GUI_OBJECT.AbsoluteSize
		local OFFSET_VECTOR : Vector2 = Vector2.new(0,0)


		-- Wrapping logic
		if self.LayoutRules.Wraps then
			-- Horizontal Wrapping
			if self.LayoutRules.FillDirection == Enum.FillDirection.Horizontal then
				local FUTURE_X = GUI_OBJECT_PARENT_CORNER_TOP_LEFT_BORDER_PADDING.X +
					(DESCENDANT_GUI_OBJECT_SIZE.X + OBJECT_PADDING_PIXELS.X) * COLUMN +
					DESCENDANT_GUI_OBJECT_SIZE.X

				if FUTURE_X > GUI_OBJECT_PARENT_CORNER_BOTTOM_RIGHT_BORDER_PADDING.X then
					COLUMN = 0
					ROW += 1
					OBJECTS_IN_ROW = {}
					OBJECTS_IN_COLUMN = {}
				end

				-- Vertical Wrapping
			elseif self.LayoutRules.FillDirection == Enum.FillDirection.Vertical then

				local FUTURE_Y = GUI_OBJECT_PARENT_CORNER_TOP_LEFT_BORDER_PADDING.Y +
					(DESCENDANT_GUI_OBJECT_SIZE.Y + OBJECT_PADDING_PIXELS.Y) * ROW +
					DESCENDANT_GUI_OBJECT_SIZE.Y	
				if FUTURE_Y > GUI_OBJECT_PARENT_CORNER_BOTTOM_RIGHT_BORDER_PADDING.Y then

					ROW = 0
					COLUMN += 1

					OBJECTS_IN_ROW = {}
					OBJECTS_IN_COLUMN = {}
				end
			end
		end

		-- Compute global top-left for this descendant.
		local xPos = GUI_OBJECT_PARENT_CORNER_TOP_LEFT_BORDER_PADDING.X + (DESCENDANT_GUI_OBJECT_SIZE.X + OBJECT_PADDING_PIXELS.X) * COLUMN
		local yPos
		-- If filling vertically and SortDirection is Descending, start from bottom and move upward
		if self.LayoutRules.FillDirection == Enum.FillDirection.Vertical and self.LayoutRules.SortDirection == Enum.SortDirection.Descending then
			local startBottom = GUI_OBJECT_PARENT_CORNER_BOTTOM_RIGHT_BORDER_PADDING.Y - DESCENDANT_GUI_OBJECT_SIZE.Y
			yPos = startBottom - (DESCENDANT_GUI_OBJECT_SIZE.Y + OBJECT_PADDING_PIXELS.Y) * ROW
		else
			yPos = GUI_OBJECT_PARENT_CORNER_TOP_LEFT_BORDER_PADDING.Y + (DESCENDANT_GUI_OBJECT_SIZE.Y + OBJECT_PADDING_PIXELS.Y) * ROW
		end

		local DESCENDANT_GUI_OBJECT_GLOBAL_TOP_LEFT_CORNER : Vector2 = Vector2.new(xPos, yPos) + OFFSET_VECTOR

		if self.LayoutRules.FillDirection == Enum.FillDirection.Horizontal then
			COLUMN += 1
			OBJECTS_IN_COLUMN = {}
			table.insert(OBJECTS_IN_ROW,DESCENDANT_GUI_OBJECT)
		else
			ROW += 1
			OBJECTS_IN_ROW = {}
			table.insert(OBJECTS_IN_COLUMN,DESCENDANT_GUI_OBJECT)
		end

		-- Positioning
		local TARGET_ABSOLUTE_POSITION : Vector2 = DESCENDANT_GUI_OBJECT_GLOBAL_TOP_LEFT_CORNER
		local TARGET_RELATIVE_POSITION : Vector2 = TARGET_ABSOLUTE_POSITION - GUI_OBJECT_PARENT_CORNER_TOP_LEFT
		
		local ChildAge = tick() - DESCENDANT_GUI_OBJECT:GetAttribute("Age")
		if DESCENDANT_GUI_OBJECT.AbsolutePosition ~= TARGET_ABSOLUTE_POSITION then
			if ChildAge < .5 then
				self.LayoutRules.EntryType(DESCENDANT_GUI_OBJECT, UDim2.new(0, TARGET_RELATIVE_POSITION.X, 0, TARGET_RELATIVE_POSITION.Y) )
			else
				AnimNation.target(DESCENDANT_GUI_OBJECT, {s = 20,d = 1},{Position = UDim2.new(0, TARGET_RELATIVE_POSITION.X, 0, TARGET_RELATIVE_POSITION.Y)})
			end
			
		end
	end

end


function AnimatedUIListLayout:INSTANCE_ADDED(Child : Instance)
	if not Child:IsA("GuiObject") then return end

	self.ChildAdded:Fire(Child)
	Child:SetAttribute("Age",tick())
	Child.Size = (self.LayoutRules.CellType == UILayoutFields.CellType.Explicit and self.LayoutRules.CellSize) or Child.Size
	table.insert(self.Instances,Child)
	if self.LayoutRules.AutoSort then
		self:Sort()
	end
end

function AnimatedUIListLayout:INSTANCE_REMOVED(Child : Instance)
	if not Child:IsA("GuiObject") then return end

	local Identifier : number? = table.find(self.Instances,Child)
	self.ChildRemoved:Fire(Child)
	table.remove(self.Instances,Identifier)


	if self.LayoutRules.AutoSort then
		self:Sort()
	end
end

function AnimatedUIListLayout:Destroy()
	self._trove:Destroy()
	setmetatable(self, nil)
end

return AnimatedUIListLayout
