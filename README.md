**LazyPane** is a utility module for UI Development mainly. Instead of calling :FindFirstChild or :WaitForChild, you only need to declare the given specific elements with the specific name. It's mainly targetted to avoid the repetition of constantly declaring objects in variables.
  
  Example:
  ```lua
  local UIHandler = LazyPane.new(ScreenGui, {
    "ExitButton",
    "OpenButton",
})

UIHandler.ExitButton.Activated:Once(Quit)
UIHandler.OpenButton.Activated:Once(Open)
```
**AnimatedUIPageLayout** is another utility module I made which is the same as the instance based UIPageLayout, but its mainly designed to be accessible through code. It also has options for customized sorting, or specific animations

Example:
```lua
local PageLayout = AnimatedUIPageLayout.new(
    Container,
    UDim2.fromScale(1, 0),   -- Initial (off-screen)
    UDim2.fromScale(0, 0),   -- Center
    UDim2.fromScale(-1, 0)   -- Exited
)

PageLayout:Next()
PageLayout:GoToIndex(3)
```
**AnimatedUIListLayout** is another utility module I made which is the same as the instance based UIListLayout, but it allows for animated layout ordering, instead of static movement of objects changing in a UI-Container; they self-move to their new position.
Note: It's still a work in progress and it is **NOT** done.

**UIElementController** is ANOTHER utility module designed to target buttons. I created it to avoid the need of constantly hard coding the animations for buttons. This does the work instead when you provide the given option.
Note: This is going under a rework as I did incorporate different types like .newButton, .newSelector, .newSwitch which will soon be declared into its own module to make it scalable and allow for different types

API:
```lua
.newButton(guiBase : GuiObject, elementType : string, ... : any)
  Example: Simple button with .Activated, .Hovered, .HoverEnded Connections.
.newSelector(Options : {GuiObject}, Switch : GuiBase, buttonType : string, UPDATE_DELAY : number)
  Example: A set of options that can be selected. Does support re-selecting an option and toggling it OFF.
.newSwitch(Btn : GuiButton, Switch : GuiBase, DEFAULT_STATE : boolean, STATES) 
  Example: A lightswitch
```
**In the Works:**
UIParticleEmitter: Still working on it; its basically ParticleEmitters but targetted towards UI Development; hopefully once done I'll be integrating it into my game.
  
