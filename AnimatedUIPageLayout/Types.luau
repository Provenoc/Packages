local AnimNation = require(script.Parent.Parent.AnimNation)
local Promise = require(script.Parent.Parent.Promise)
local Signal = require(script.Parent.Parent.Signal)

local Types = {
	SortOrder = {
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
}

export type SortOrder = "Age" | "Alphabetical" | "LayoutOrder"
export type AnimatedPage = {
	-- Core Container
	Pages : {[number] : GuiObject};

	-- Events
	OnPageEntered : Signal.Signal<GuiObject>;
	OnPageExited : Signal.Signal<GuiObject>;

	-- Properties
	CanSwitch : boolean;
	CurrentPage : GuiObject | nil;
	CurrentIndex : number | nil;
	Animated : boolean;
	AnimationConfiguration : AnimNation.SpringInfo;

	PAGE_INITIAL_POSITION : UDim2;
	PAGE_CENTER_POSITION : UDim2;
	PAGE_EXITED_POSITION : UDim2;
	SortOrder : SortOrder;

	-- Methods
	Next : (self : AnimatedPage, Increment : number | nil) -> (Promise.Promise<>);
	GoToIndex : (self : AnimatedPage, Index : number) -> (Promise.Promise<>);
	GoToPage : (self : AnimatedPage, Page : GuiObject) -> (Promise.Promise<>);
	Previous : (self : AnimatedPage, Increment : number | nil) -> (Promise.Promise<>);
	Destroy : (self : AnimatedPage) -> ();
	
	-- Privates
	new : (Container : GuiObject, PAGE_INITIAL_POSITION : UDim2, PAGE_CENTER_POSITION : UDim2, PAGE_EXITED_POSITION : UDim2) -> (AnimatedPage);
	_animatePage : (self : AnimatedPage) -> (unknown);
}




return Types
