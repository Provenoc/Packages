--[[ Types ]]
local Types = require(script.Parent.Types)

export type Particle = {
	Object : GuiObject;
	Properties : Types.ParticleData;
	
	update : (self : Particle, dt : number) -> ();
	new : (ParticleTemplate : GuiObject, ParticleProperties : Types.ParticleData) -> (Particle)
}

--[[ Helper Functions ]]
local function lerp(a,b,t)
	return a + (b-a)*t
end
--[[ Particle ]]
local Particle : Particle = {}
Particle.__index = Particle


function Particle.new(ParticleTemplate : GuiObject, Properties : Types.ParticleData)
	local self = setmetatable({}, Particle)
	
	self.Object = ParticleTemplate:Clone()
	self.Properties = Properties
	self._init = os.clock()
	self._currentLife = os.clock()-self._init
	return self
end

function Particle:update(dt : number)
	-- Set Lifetime
	self._currentLife = os.clock()-self._init
	
	-- Update Physical Properties
	self.Properties.Rotation += self.Properties.RotationSpeed*dt
	self.Properties.Velocity += self.Properties.Acceleration * dt

	-- extract current offset
	local x = self.Properties.Position.X.Offset
	local y = self.Properties.Position.Y.Offset

	-- integrate position
	x += self.Properties.Velocity.X * dt
	y += self.Properties.Velocity.Y * dt

	-- write back (scale unchanged)
	self.Properties.Position = UDim2.new(
		self.Properties.Position.X.Scale,
		x,
		self.Properties.Position.Y.Scale,
		y
	)
	
	-- Set Position & Rotation
	self.Object.Rotation = self.Properties.Rotation
	self.Object.Position = self.Properties.Position
	
	-- Update lifetime
	self.Object.Transparency = lerp(self.Properties.Transparency.Min, self.Properties.Transparency.Max, self._currentLife)
	self.Object.Size = self.Properties.Size.Initial:Lerp(self.Properties.Size.Final, self._currentLife)
end

function Particle:Destroy()
	setmetatable(self, nil)
end

return Particle
