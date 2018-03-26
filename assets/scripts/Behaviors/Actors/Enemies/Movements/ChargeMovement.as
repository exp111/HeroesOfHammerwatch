class ChargeMovement : ActorMovement
{
	AnimString@ m_idleAnim;
	AnimString@ m_walkAnim;

	float m_fSpeed;
	float m_fAcceleration;
	float m_fDeceleration;
	float m_fTurnSpeed;
	float m_fCurrentSpeed;

	float m_fCrashAngle;

	int m_iWaitAfterSight;
	int m_iWaitAfterLost;

	bool m_bVisible;
	int m_iVisibleWait;
	int m_iCheckTime;

	bool m_bCharging;
	bool m_immortalCharge;
	
	bool m_bBraking;
	int m_iBreakTime;

	ActorFootsteps@ m_footsteps;

	ChargeMovement(UnitPtr unit, SValue& params)
	{
		super(unit, params);

		@m_idleAnim = AnimString(GetParamString(unit, params, "anim-idle"));
		@m_walkAnim = AnimString(GetParamString(unit, params, "anim-walk"));

		m_fSpeed = GetParamFloat(unit, params, "speed");
		m_fAcceleration = GetParamFloat(unit, params, "acceleration");
		m_fDeceleration = GetParamFloat(unit, params, "deceleration");
		m_fTurnSpeed = GetParamFloat(unit, params, "turnspeed", false, 0);
		m_fCurrentSpeed = m_fSpeed;

		m_fCrashAngle = GetParamFloat(unit, params, "crashangle", false, 1.0);

		m_iWaitAfterSight = GetParamInt(unit, params, "wait-sight-time", false, 1000);
		m_iWaitAfterLost = GetParamInt(unit, params, "wait-after-lost", false, 1000);
		
		m_immortalCharge = GetParamBool(unit, params, "immortal-while-charging", false, false);

		m_bVisible = false;
		m_iVisibleWait = 0;
		m_iCheckTime = 0;

		m_bCharging = false;
		
%if GFX_VFX_HIGH
		auto svFootsteps = GetParamDictionary(unit, params, "footsteps", false);
		if (svFootsteps !is null)
			@m_footsteps = ActorFootsteps(unit, svFootsteps);
%endif
	}

	void BeginCharging()
	{
		m_bCharging = true;
		m_fCurrentSpeed = m_fAcceleration;

		if (Network::IsServer())
			(Network::Message("UnitMovementChargeBegin") << m_unit << xy(m_unit.GetPosition()) << m_dir).SendToAll();
	}

	void BeginLooking()
	{
		m_bCharging = false;
		m_bBraking = false;
		m_bVisible = false;
		m_iVisibleWait = 0;

		if (Network::IsServer())
			(Network::Message("UnitMovementChargeLook") << m_unit << xy(m_unit.GetPosition())).SendToAll();
	}
	
	void OnCollide(UnitPtr unit, vec2 pos, vec2 normal, Fixture@ fxSelf, Fixture@ fxOther) override
	{
		auto behavior = unit.GetScriptBehavior();

		Actor@ actor = cast<Actor>(behavior);
		Breakable@ breakable = cast<Breakable>(behavior);

		if (breakable is null && (actor is null || actor.Impenetrable()) && !fxOther.IsSensor())
		{
			auto body = m_unit.GetPhysicsBody();
			vec2 vel = body.GetLinearVelocity();
			if (abs(vel.x * normal.y - normal.x * vel.y) < m_fCrashAngle)
			{
				body.SetLinearVelocity(0, 0);
				BeginLooking();
			}
		}
		else if (breakable !is null)
		{
			breakable.Damage(DamageInfo(uint8(DamageType::BLUNT), m_behavior, 35, true, true, 0), pos, normal);
		}
	}
	
	void ClientUpdate(int dt, vec2 dir)
	{
		auto body = m_unit.GetPhysicsBody();
		body.SetLinearVelocity(0, 0);
		body.SetStatic(true);

		if (m_immortalCharge)
			m_behavior.SetImmortal(lengthsq(dir) > 0.01);
		
		if (dir.x != 0 || dir.y != 0)
		{
			dir = normalize(dir);
			m_dir = atan(dir.y, dir.x);
		}
		
		SetWalkingAnimation();
		
		if (m_footsteps !is null)
		{
			m_footsteps.m_facingDirection = m_dir;
			m_footsteps.Update(dt);
		}
	}
	

	void Update(int dt, bool isCasting) override
	{
		if (!m_enabled)
			return;
		
		if (!Network::IsServer())
		{
			ClientUpdate(dt, m_unit.GetMoveDir());
			return;
		}
		
		if (m_behavior.m_target is null)
		{
			m_unit.GetPhysicsBody().SetLinearVelocity(0, 0);
			m_unit.SetUnitScene(m_idleAnim.GetSceneName(m_dir), false);
			return;
		}

		vec2 upos = xy(m_behavior.m_target.m_unit.GetPosition());
		vec2 mypos = xy(m_unit.GetPosition());
		vec2 diff = upos - mypos;
		vec2 dir = normalize(diff);

		auto body = m_unit.GetPhysicsBody();
		if (m_bCharging)
		{
			vec2 godir = vec2(cos(m_dir), sin(m_dir));
			body.SetLinearVelocity(godir * m_fCurrentSpeed * m_behavior.m_buffs.MoveSpeedMul());

			float angle = godir.x * dir.y - dir.x * godir.y;
			float add = angle * (m_fTurnSpeed / 100.0) * (m_fCurrentSpeed / m_fSpeed);
			m_dir += add;

			if (dot(godir, dir) < 0)
			{
				if (!m_bBraking)
				{
					m_bBraking = true;
					m_iBreakTime = 0;
				}

				m_iBreakTime += dt;

				m_fCurrentSpeed -= m_fDeceleration;
				if (m_fCurrentSpeed < 0)
					m_fCurrentSpeed = 0;

				if (m_iBreakTime >= m_iWaitAfterLost)
					BeginLooking();

				m_bVisible = false;
			}
			else
			{
				m_fCurrentSpeed += m_fAcceleration;
				if (m_fCurrentSpeed > m_fSpeed)
					m_fCurrentSpeed = m_fSpeed;
			}
		}
		else
		{
			body.SetLinearVelocity(0, 0);

			if (m_bVisible)
				m_iVisibleWait += dt;

			// Target must be in a clear range
			m_iCheckTime += dt;
			if (m_iCheckTime >= 100)
			{
				m_iCheckTime = 0;

				bool visible = true;
				array<RaycastResult>@ rayResults = g_scene.Raycast(mypos, upos, ~0, RaycastType::Aim);
				for (uint i = 0; i < rayResults.length(); i++)
				{
					UnitPtr ray_unit = rayResults[i].FetchUnit(g_scene);
					if (!ray_unit.IsValid())
						continue;
					Actor@ a = cast<Actor>(ray_unit.GetScriptBehavior());
					if (a is null or a.Impenetrable())
					{
						visible = false;
						break;
					}
				}

				if (visible)
				{
					// Maybe begin charging after a little bit
					m_dir = atan(dir.y, dir.x);
					if (!m_bVisible)
					{
						m_bVisible = true;
						m_iVisibleWait = 0;
					}
					else if (m_iVisibleWait >= m_iWaitAfterSight)
						BeginCharging();
				}
				else
					m_bVisible = false;
			}
		}

		// Workaround for issue 1370
		if (m_immortalCharge)
			m_behavior.SetImmortal(lengthsq(m_unit.GetMoveDir()) > 0.01);

		SetWalkingAnimation();

		if (m_footsteps !is null)
		{
			m_footsteps.m_facingDirection = m_dir;
			m_footsteps.Update(dt);
		}
	}
	
	void SetWalkingAnimation()
	{
		bool walking = (lengthsq(m_unit.GetMoveDir()) > 0.01);
		string scene = walking ? m_walkAnim.GetSceneName(m_dir) : m_idleAnim.GetSceneName(m_dir);
		m_unit.SetUnitScene(scene, false);
	}
}
