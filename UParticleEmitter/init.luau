--[[
	Name: UIParticleEmitter.lua
	Description; A Particle Emitter but UI based.
	Author: Provenoc
	Date: 1/4/26
]]
--[[ Services ]]
local RunService = game:GetService("RunService")
local HTTPService = game:GetService("HttpService")

--[[ Dependencies ]]
local Promise = require(script.Promise)
local Particle = require(script.Particle)
local Types = require(script.Types)

local UIParticleEmitter = {
	Particles = {}
} :: Types.ParticleEmitter
UIParticleEmitter.__index = UIParticleEmitter

function UIParticleEmitter.new(Parent : GuiObject, Template : GuiObject | nil, ParticleData : Types.ParticleData)
	local self = setmetatable({}, UIParticleEmitter)
	
	self.Properties = table.clone(ParticleData)
	self.ParticleContainer = Parent
	self.ParticleTemplate = Template or script.Frame:Clone()
	self.RenderKey = HTTPService:GenerateGUID(false)
	self.Rate = 1
	
	return self
end

function UIParticleEmitter:SetAutoEmit(isEnabled : boolean)
	return Promise.new(function(resolve)
		if not self.AutoEmit and isEnabled then
			self.LastAutoEmitted = os.clock()
			RunService:BindToRenderStep(self.RenderKey, Enum.RenderPriority.Last.Value, function(dt : number)
				self:Render(dt)
			end)
		elseif self.AutoEmit and not isEnabled then
			RunService:UnbindFromRenderStep(self.RenderKey)
		end

		self.AutoEmit = isEnabled
		resolve()
	end)
end

function UIParticleEmitter:Render(dt : number)
	local EmitDiff = os.clock()-self.LastAutoEmitted
	
	-- Emit as we crossed the threshold
	if EmitDiff >=self.Rate then
		self:Emit()
		self.LastAutoEmitted = os.clock()
	end
	
	for Particle, _ in self.Particles do
		if Particle == nil then continue end
		-- Lifetime Prop
		if  Particle._currentLife >= Particle.Properties.Lifetime.Min then
			Particle:Destroy()
			self.Particles[Particle] = nil
			continue
		end
		Particle:update(dt)
	end
end

function UIParticleEmitter:Emit()
	return Promise.new(function(resolve)
		local Particle = Particle.new(self.ParticleTemplate:Clone(), table.clone(Types.DefaultParticleData))
		Particle.Object.Parent = self.ParticleContainer
		self.Particles[Particle] = true
		resolve()
	end)
end

return UIParticleEmitter
