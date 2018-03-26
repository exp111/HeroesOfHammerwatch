class ActorMovement
{
	UnitPtr m_unit;
	CompositeActorBehavior@ m_behavior;

	float m_dir;
	bool m_enabled;

	float m_confuseAngle;
	
	
	ActorMovement(UnitPtr unit, SValue& params)
	{
		m_dir = randf() * PI * 2;
		m_enabled = true;
	}
	
	void Initialize(UnitPtr unit, CompositeActorBehavior& behavior)
	{
		m_unit = unit;
		@m_behavior = behavior;
		
		//m_unit.SetShouldCollideWithSame(false);
		
		
		auto body = m_unit.GetPhysicsBody();
		if (body !is null and !body.IsStatic())
		{
			vec3 pos = unit.GetPosition();
			pos.x += randf() / 100.0;
			pos.y += randf() / 100.0;
			unit.SetPosition(pos);
		}
	}
	
	void MakeAggro() {}
	void OnDamaged(int dmg) {}
	void QueuedPathfind(array<vec2>@ path) {}
	
	void OnCollide(UnitPtr unit, vec2 pos, vec2 normal, Fixture@ fxSelf, Fixture@ fxOther) {}
	
	void Update(int dt, bool isCasting) {}

	vec2 GetConfuseDir(vec2 dir, float speed)
	{
		m_confuseAngle += 0.025;
		return addrot(dir, sin(m_confuseAngle) * 1.5) * speed * 0.8;
	}
}
