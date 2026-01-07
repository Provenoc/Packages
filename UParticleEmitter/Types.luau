export type ParticleData = {
	Velocity : Vector2;
	Transparency : NumberRange;
	Position : UDim2;
	Rotation : number;
	RotationSpeed : number;
	Acceleration : Vector2;
	SpreadAngle : Vector2;
	LifeTime : NumberRange;
	Size : {
		Initial : UDim2;
		Final : UDim2
	}
}

export type ParticleEmitter = {
	Particles : {};
	ParticleContainer : GuiObject;
	ParticleTemplate : GuiObject;
	
	AutoEmit : boolean;
	RenderKey : string;
	MaxParticles : number;
	LastAutoEmitted : number;
	Rate : number; --Particles / Second
	
	Emit : (self : ParticleEmitter) -> ();
	SetAutoEmit : (self : ParticleEmitter, isEnabled : boolean) -> ();
	
	Render : (self : ParticleEmitter, dt : number) -> ();
	
	new : (Parent : GuiObject, Template : GuiObject | nil, ParticleData : ParticleData) -> (ParticleEmitter)
}

local Types = {
	DefaultParticleData  = {
		Position = UDim2.new(.388,0,.313,0);
		Velocity = Vector2.new(0,50);
		Acceleration = Vector2.new(0,50);
		Rotation = 0;
		RotationSpeed = 200;
		Size = {
			Initial = UDim2.fromOffset(86,64);
			Final = UDim2.fromOffset(41,33)
		};
		Transparency = NumberRange.new(0,1);
		SpreadAngle = Vector2.new(30,30);
		Lifetime = NumberRange.new(3,8);
	} :: ParticleData
}

return Types
