class CirclingMovement : MeleeMovement
{
	int m_circleDist;
	int m_circleDir;
	int m_tmDistCheck;
	bool m_lastCanSee;

	CirclingMovement(UnitPtr unit, SValue& params)
	{
		super(unit, params);

		m_circleDist = GetParamInt(unit, params, "circle-dist", false, 0);
	}

	void Initialize(UnitPtr unit, CompositeActorBehavior& behavior) override
	{
		MeleeMovement::Initialize(unit, behavior);

		if (m_circleDist <= 0)
			m_circleDist = int(m_standDist * 5);
	}

	vec2 GetMoveDir(float dirAngle)
	{
		float moveToDir = dirAngle + m_circleDir * (PI/4.0);
		vec2 posMe = xy(m_unit.GetPosition());
		return vec2(cos(moveToDir), sin(moveToDir));
	}

	void Update(int dt, bool isCasting) override
	{
		if (!m_enabled)
			return;
	
		if (!Network::IsServer())
		{
			ClientUpdate(dt, isCasting, m_unit.GetMoveDir());
			return;
		}
		
	
		float speed = m_speed;
	
		if (m_stagger > 0)
		{
			m_stagger -= dt;
			speed *= 0.5;
		}
		speed *= m_behavior.m_buffs.MoveSpeedMul();
		
		if (isCasting)
			return;

		if (m_behavior.m_target is null || speed == 0)
		{
			m_unit.GetPhysicsBody().SetLinearVelocity(0, 0);
			m_unit.SetUnitScene(m_idleAnim.GetSceneName(m_dir), false);
			return;
		}

		vec3 posTarget = m_behavior.m_target.m_unit.GetPosition();
		vec3 posMe = m_unit.GetPosition();

		if (!m_lastCanSee)
		{
			if (m_tmDistCheck <= 0)
			{
				if (rayCanSee(m_unit, m_behavior.m_target.m_unit))
					m_lastCanSee = true;
				m_tmDistCheck = 100;
			}
			else
				m_tmDistCheck -= dt;
		}

		auto body = m_unit.GetPhysicsBody();
		
		float distSq = lengthsq(posMe - posTarget);
		if (distSq <= m_standDist * m_standDist)
		{
			vec2 dir = normalize(xy(posTarget - posMe));
			m_dir = atan(dir.y, dir.x);
			
			body.SetLinearVelocity(0, 0);
			body.SetStatic(true);
			
			m_unit.SetUnitScene(m_idleAnim.GetSceneName(m_dir), false);
			
			return;
		}
		else if (m_lastCanSee && distSq <= m_circleDist * m_circleDist && !m_behavior.m_buffs.Confuse())
		{
			body.SetStatic(false);

			vec2 dir = normalize(xy(posTarget - posMe));
			float dirAngle = atan(dir.y, dir.x);

			if (m_circleDir == 0 && Network::IsServer())
			{
				m_circleDir = (randi(2) == 0 ? -1 : 1);
				//(Network::Message("UnitMovementCircleDir") << m_unit << m_circleDir << xy(posMe)).SendToAll();
			}

			vec2 moveDir = GetMoveDir(dirAngle);

			m_lastCanSee = true;

			if (m_tmDistCheck <= 0)
			{
				if (rayQuickFromUnit(m_unit, xy(posMe) + moveDir * 10, ~0, RaycastType::Shot))
				{
					m_circleDir *= -1;
					moveDir = GetMoveDir(dirAngle);
				}
				
				if (!rayCanSee(m_unit, m_behavior.m_target.m_unit))
					m_lastCanSee = false;
					
				m_tmDistCheck = 100;
			}
			else
				m_tmDistCheck -= dt;

			body.SetLinearVelocity(moveDir * speed);
			m_dir = atan(moveDir.y, moveDir.x);

			SetWalkingAnimation();

			if (m_footsteps !is null)
			{
				m_footsteps.m_facingDirection = m_dir;
				m_footsteps.Update(dt);
			}

			if (m_lastCanSee)
				return;
		}
		m_circleDir = 0;

		body.SetStatic(false);
	
		vec2 dir = m_pathFollower.FollowPath(xy(posMe), xy(posTarget)) * speed;
		if (m_behavior.m_buffs.Confuse())
			dir = GetConfuseDir(dir, speed);
		if (dir.x != 0 || dir.y != 0)
		{
			body.SetLinearVelocity(dir);
			m_dir = atan(dir.y, dir.x);
		}
		
		SetWalkingAnimation();
		
		if (m_footsteps !is null)
		{
			m_footsteps.m_facingDirection = m_dir;
			m_footsteps.Update(dt);
		}
	}
}
