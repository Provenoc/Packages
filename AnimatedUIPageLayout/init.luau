--[[
	Name: AnimatedUIPageLayout.lua
	Description: A modular, animated replacement for UIPageLayout
	Author: Provenoc
	Date: 1/6/26

	API:

	AnimatedUIPageLayout.new(
		Container : GuiObject,
		PAGE_INITIAL_POSITION : UDim2,
		PAGE_CENTER_POSITION : UDim2,
		PAGE_EXITED_POSITION : UDim2
	) -> AnimatedUIPageLayout
		Creates and returns a new AnimatedUIPageLayout instance.
		All GuiObjects inside Container are treated as pages.

	Methods:

	:Next(Increment : number?) -> Promise
		Advances forward by Increment pages (default = 1).
		Wraps around when exceeding bounds.
		Returns a Promise that resolves once animation finishes.

	:Previous(Increment : number?) -> Promise
		Moves backward by Increment pages (default = -1).
		Wraps around when exceeding bounds.
		Returns a Promise that resolves once animation finishes.

	:GoToPage(Page : GuiObject) -> Promise
		Navigates to a specific page instance.
		Automatically determines direction.
		Returns a Promise.

	:GoToIndex(Index : number) -> Promise
		Navigates to a page by index.
		Automatically determines direction.
		Returns a Promise.

	:Destroy()
		Cleans up signals and removes the instance.

	Signals:

	.OnPageEntered(Page : GuiObject)
		Fires when a page begins entering the center position.

	.OnPageExited(Page : GuiObject)
		Fires when a page exits the center position.

	Properties:

	.Pages : {GuiObject}
		Ordered list of pages.

	.CurrentPage : GuiObject?
		The currently active page.

	.CurrentIndex : number
		Index of the current page.

	.CanSwitch : boolean
		Prevents overlapping page transitions.

	.Animated : boolean
		Toggles animated vs instant transitions.

	.AnimationConfiguration : table
		Passed directly into AnimNation.target.

	.SortOrder : string
		Sorting method for pages (default = "LayoutOrder").
]]


--[[ Dependencies ]]
local AnimNation = require(script.Parent.AnimNation)
local Promise = require(script.Parent.Promise)
local Signal = require(script.Parent.Signal)
local Types = require(script.Types)

--[[ Local Functions ]]
local function wrapNumber(current : number, Increment : number, Max : number) : number
	current+=Increment	
	if current > Max then
		return 1
	elseif current <= 0 then
		return Max
	end
	return current
end

--[[ AnimatedUIPageLayout ]]
local AnimatedUIPageLayout : Types.AnimatedPage = {}
AnimatedUIPageLayout.__index = AnimatedUIPageLayout

--[[ Privates ]]
--[[
	@summary Animates a page to a target position and fires enter/exit signals.
	@param Page GuiObject -- The page being animated
	@param TargetPosition UDim2 -- The position the page should move to
	@returns Promise? -- Returns an animation promise if animated, otherwise nil
]]
function AnimatedUIPageLayout:_animatePage(Page : GuiObject, TargetPosition : UDim2)
	-- Signal Events
	if TargetPosition == self.PAGE_INITIAL_POSITION then
		self.OnPageEntered:Fire(Page)
	else
		self.OnPageExited:Fire(Page)
	end
	
	if self.Animated then
		return AnimNation.target(Page, self.AnimationConfiguration, {Position = TargetPosition})
	else
		Page.Position = TargetPosition
	end
	
end

--[[ Global Methods ]]
--[[
	@summary Advances to the next page in the layout.
	@param Increment number? -- How many pages to move forward (default = 1)
	@returns Promise -- Resolves once the page transition finishes
]]
function AnimatedUIPageLayout:Next(Increment : number | nil)
	return Promise.new(function(resolve)
		-- Cooldown
		if not self.CanSwitch then 
			resolve() 
			return
		end
		
		self.CanSwitch = false
		self.CurrentIndex = wrapNumber(self.CurrentIndex, Increment or 1, #self.Pages)
		
		-- Animate Prev Page if any
		if self.CurrentPage ~= nil then
			self:_animatePage(self.CurrentPage, self.PAGE_EXITED_POSITION)
		end
		
		self.CurrentPage = self.Pages[self.CurrentIndex]
		self.CurrentPage.Position = self.PAGE_INITIAL_POSITION
		self:_animatePage(self.CurrentPage, self.PAGE_CENTER_POSITION):Await()
		self.CanSwitch = true
		resolve()
	end)
end

--[[
	@summary Moves to the previous page in the layout.
	@param Increment number? -- How many pages to move backward (default = -1)
	@returns Promise -- Resolves once the page transition finishes
]]
function AnimatedUIPageLayout:Previous(Increment : number | nil)
	return Promise.new(function(resolve)
		-- Cooldown
		if not self.CanSwitch then 
			resolve() 
			return
		end

		self.CanSwitch = false
		self.CurrentIndex = wrapNumber(self.CurrentIndex, Increment or -1, #self.Pages)
		
		-- Animate Prev Page if any
		if self.CurrentPage ~= nil then
			self:_animatePage(self.CurrentPage, self.PAGE_INITIAL_POSITION)
		end
		
		self.CurrentPage = self.Pages[self.CurrentIndex]
		self.CurrentPage.Position = self.PAGE_EXITED_POSITION
		self:_animatePage(self.CurrentPage, self.PAGE_CENTER_POSITION):Await()
		self.CanSwitch = true
		resolve()
	end)
end

--[[
	@summary Navigates to a specific page instance.
	@param Page GuiObject -- The page to navigate to
	@returns Promise -- Resolves after navigation is triggered
]]
function AnimatedUIPageLayout:GoToPage(Page : GuiObject)
	return Promise.new(function(resolve)
		local TargetIndex : number = table.find(self.Pages, Page)
		
		-- We are going backwards
		if self.CurrentIndex > TargetIndex then
			self:Previous(self.CurrentIndex-TargetIndex)
		-- We are going forwards
		elseif self.CurrentIndex < TargetIndex then
			self:Next(TargetIndex-self.CurrentIndex)
		end
		resolve()
	end)
end

--[[
	@summary Navigates to a page by index.
	@param Index number -- Target page index
	@returns Promise -- Resolves after navigation is triggered
]]
function AnimatedUIPageLayout:GoToIndex(Index : number)
	return Promise.new(function(resolve)
		-- We are going backwards
		if self.CurrentIndex > Index then
			self:Previous(self.CurrentIndex-Index)
			-- We are going forwards
		elseif self.CurrentIndex < Index then
			self:Next(Index-self.CurrentIndex)
		end
		resolve()
	end)
end

--[[ Initializers ]]
--[[
	@summary Creates a new AnimatedUIPageLayout instance.
	@param Container GuiObject -- Parent containing all page GuiObjects
	@param PAGE_INITIAL_POSITION UDim2 -- Starting position for entering pages
	@param PAGE_CENTER_POSITION UDim2 -- Center (active) position
	@param PAGE_EXITED_POSITION UDim2 -- Off-screen exit position
	@returns AnimatedUIPageLayout -- The created layout instance
]]
function AnimatedUIPageLayout.new(
	Container : GuiObject, 
	PAGE_INITIAL_POSITION : UDim2, 
	PAGE_CENTER_POSITION : UDim2, 
	PAGE_EXITED_POSITION : UDim2
) : Types.AnimatedPage

	-- Asserts
	assert(Container, `AnimatedUIIPageLayout -> Missing the specified container.`)
	assert(PAGE_INITIAL_POSITION or PAGE_CENTER_POSITION or PAGE_EXITED_POSITION, `AnimatedUIPageLayout -> Missing either specified target positions`);
	
	local self = setmetatable({}, AnimatedUIPageLayout)
	
	self.Pages = {}
	
	-- Signals
	self.OnPageEntered = Signal.new()
	self.OnPageExited = Signal.new()
	
	-- Properties
	self.CanSwitch = true
	self.CurrentPage = nil
	self.CurrentIndex = 0
	self.Animated = true
	self.AnimationConfiguration = {s = 20, d = 1};

	self.PAGE_INITIAL_POSITION = PAGE_INITIAL_POSITION
	self.PAGE_CENTER_POSITION = PAGE_CENTER_POSITION
	self.PAGE_EXITED_POSITION = PAGE_EXITED_POSITION;
	self.SortOrder = "LayoutOrder"
	
	-- Add Children & Sort
	for _, Page in Container:GetChildren() do
		if Page:IsA("GuiObject") then
			table.insert(self.Pages, Page)
		end
	end
	
	table.sort(self.Pages, Types.SortOrder[self.SortOrder])
	
	return self
end

--[[
	@summary Destroys the layout and cleans up signals.
	@returns nil
]]
function AnimatedUIPageLayout:Destroy()
	self.OnPageEntered:Destroy()
	self.OnPageExited:Destroy()
	setmetatable(self, nil)
end

return AnimatedUIPageLayout
