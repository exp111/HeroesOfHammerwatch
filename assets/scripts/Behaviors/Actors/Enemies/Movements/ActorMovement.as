class ActorMovement
{
	UnitPtr m_unit;
	CompositeActorBehavior@ m_behavior;

	bool m_enabled;
	float m_confuseAngle;
	
	
	float m_rotSpeed;
	private float m_dirCurr;
	private float m_dirTarget;
	float m_dir
	{
		get { return m_dirCurr; }
		set 
		{ 
			m_dirTarget = value;
			if (m_rotSpeed >= 95)
				m_dirCurr = value;
		}
	}
	
	ActorMovement(UnitPtr unit, SValue& params)
	{
		//m_rotSpeed = GetParamFloat(unit, params, "rot-speed", false, 12);
		m_rotSpeed = 100;
		m_dirCurr = m_dirTarget = randf() * PI * 2;
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
	void OnDamaged(DamageInfo dmg) {}
	void QueuedPathfind(array<vec2>@ path) {}
	
	void OnCollide(UnitPtr unit, vec2 pos, vec2 normal, Fixture@ fxSelf, Fixture@ fxOther) {}
	
	void Update(int dt, bool isCasting)
	{
		if (!isCasting)
		{
			if (m_dirCurr != m_dirTarget)
				m_dirCurr = rottowards(m_dirCurr, m_dirTarget, m_rotSpeed * dt / 1000.0f);
		}
	}
	
	vec2 GetConfuseDir(vec2 dir, float speed)
	{
		m_confuseAngle += 0.025;
		return addrot(dir, sin(m_confuseAngle) * 1.5) * speed * 0.8;
	}
}
