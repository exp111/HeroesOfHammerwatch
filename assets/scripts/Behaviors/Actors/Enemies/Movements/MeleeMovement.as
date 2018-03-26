class MeleeMovement : ActorMovement
{
	AnimString@ m_idleAnim;
	AnimString@ m_walkAnim;
	
	float m_speed;
	int m_standDist;
	int m_minDist;
	bool m_flying;
	
	int m_stagger;
	int m_staggerThreshold;
	
	PathFollower m_pathFollower;

	ActorFootsteps@ m_footsteps;
	
	vec2 m_origPos;
	vec2 m_idleTarget;
	int m_newIdleTargetC;
	float m_roaming;
	
	
	MeleeMovement(UnitPtr unit, SValue& params)
	{
		super(unit, params);
	
		@m_idleAnim = AnimString(GetParamString(unit, params, "anim-idle"));
		@m_walkAnim = AnimString(GetParamString(unit, params, "anim-walk"));
		
		m_staggerThreshold = GetParamInt(unit, params, "stagger-threshold", false, 1);
		m_speed = max(0.0, GetParamFloat(unit, params, "speed", true));
		
		m_standDist = GetParamInt(unit, params, "dist", false, 0);
		m_minDist = GetParamInt(unit, params, "min-dist", false, int(m_standDist * 0.1));
		m_flying = GetParamBool(unit, params, "flying", false, false);
		m_roaming = GetParamFloat(unit, params, "roaming", false, 0.25f);
		
		m_stagger = 0;

%if GFX_VFX_HIGH
		auto svFootsteps = GetParamDictionary(unit, params, "footsteps", false);
		if (svFootsteps !is null)
			@m_footsteps = ActorFootsteps(unit, svFootsteps);
%endif

		m_origPos = xy(unit.GetPosition());
		m_idleTarget = m_origPos;
		m_newIdleTargetC = randi(3000);
	}
	
	void Initialize(UnitPtr unit, CompositeActorBehavior& behavior) override
	{
		ActorMovement::Initialize(unit, behavior);
		m_pathFollower.Initialize(unit, m_behavior.m_maxRange, m_flying);
		
		if (m_standDist <= 0)
			m_standDist = m_pathFollower.m_unitRadius + 10;
		
		m_unit.SetUnitScene(m_idleAnim.GetSceneName(m_dir), false);
	}
	
	void MakeAggro() override
	{
		m_pathFollower.m_maxRange = m_behavior.m_maxRange;
	}
	
	void QueuedPathfind(array<vec2>@ path) override
	{
		m_pathFollower.QueuedPathfind(path);
	}
	
	void OnDamaged(DamageInfo dmg) override
	{
		if (m_staggerThreshold > 0 && dmg.Melee && dmg.Damage >= m_staggerThreshold)
		{
			m_stagger = 600;
			//m_unit.SetUnitSceneTime(0);
		}
	}
	
	void ClientUpdate(int dt, bool isCasting, vec2 dir)
	{
		if (isCasting)
			return;
	
		auto body = m_unit.GetPhysicsBody();
		body.SetLinearVelocity(0, 0);
		body.SetStatic(true);
		
		if (dir.x != 0 || dir.y != 0)
		{
			if (m_minDist > 0 && m_behavior.m_target !is null)
			{
				auto td = xy(m_behavior.m_target.m_unit.GetPosition() - m_unit.GetPosition());
				float distSq = lengthsq(td);
				if (distSq < m_minDist * m_minDist)
					dir = td;
			}

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
	
	bool IdleUpdate(int dt, float speed)
	{
		bool noTarget = m_behavior.m_target is null;

		if (speed == 0 || (noTarget && m_roaming <= 0))
		{
			m_unit.GetPhysicsBody().SetLinearVelocity(0, 0);
			m_unit.SetUnitScene(m_idleAnim.GetSceneName(m_dir), false);
			return true;
		}
	
		if (noTarget)
		{
			m_newIdleTargetC -= dt;
			if (m_newIdleTargetC <= 0)
			{
				float len = randf() * 100 * m_roaming;
				vec2 dr = randdir();

				m_idleTarget = m_origPos + vec2(dr.x * len, (dr.y * 0.66 - 0.33) * len);
				m_newIdleTargetC = 2000 + randi(2000 + int(max(0.0f, 1.0f - m_roaming) * 12000));
			}
			
			float dist = distsq(m_idleTarget, xy(m_unit.GetPosition()));
			if (dist <= 3 * 3)
			{
				m_unit.GetPhysicsBody().SetLinearVelocity(0, 0);
				m_unit.SetUnitScene(m_idleAnim.GetSceneName(m_dir), false);
				return true;
			}
			else if (dist >= 100 * m_roaming * 100 * m_roaming)
			{
				m_origPos = xy(m_unit.GetPosition());
				m_newIdleTargetC = 0;
			}
			
			vec2 dir = normalize(m_idleTarget - xy(m_unit.GetPosition())) * speed * m_roaming;
			m_dir = atan(dir.y, dir.x);
			m_unit.GetPhysicsBody().SetLinearVelocity(dir);
			SetWalkingAnimation();
			
			if (m_footsteps !is null)
			{
				m_footsteps.m_facingDirection = m_dir;
				m_footsteps.Update(dt);
			}
			
			return true;
		}
		
		return false;
	}
	
	float CalcDirSpeed()
	{
		float diff = pow(1.0f - abs(angdiff(m_dir, m_pathFollower.m_visualDir) / PI), 3.0f);
		diff = clamp(diff * 1.75 - 0.75, 0.0f, 1.0f);
		return lerp(0.1f, 1.0f, diff);
	}
	
	void Update(int dt, bool isCasting) override
	{
		if (!m_enabled || isCasting)
			return;
			
		ActorMovement::Update(dt, isCasting);
	
		if (!Network::IsServer())
		{
			ClientUpdate(dt, isCasting, m_unit.GetMoveDir());
			return;
		}
		
		float speed = m_speed + g_ngp * 0.1f;
	
		if (m_stagger > 0)
		{
			m_stagger -= dt;
			speed *= 0.5;
		}
		speed *= m_behavior.m_buffs.MoveSpeedMul();
		
		if (MeleeMovement::IdleUpdate(dt, speed))
			return;

		vec3 posTarget = m_behavior.m_target.m_unit.GetPosition();
		vec3 posMe = m_unit.GetPosition();
		
		auto body = m_unit.GetPhysicsBody();

		float distSq = lengthsq(posMe - posTarget);
		vec2 dir = normalize(xy(posTarget - posMe));
		auto origDir = dir;
		
		bool fleeing = false;
		if (distSq < m_minDist * m_minDist)
		{
			posTarget = posMe - xyz(dir * m_standDist);
			fleeing = true;
		}
		else if (distSq <= m_standDist * m_standDist)
		{
			m_dir = atan(dir.y, dir.x);
			
			body.SetLinearVelocity(0, 0);
			m_unit.SetUnitScene(m_idleAnim.GetSceneName(m_dir), false);
			
			body.SetStatic(true);
			return;
		}

		body.SetStatic(false);
		dir = m_pathFollower.FollowPath(xy(posMe), xy(posTarget)) * speed * CalcDirSpeed();
		
		if (m_behavior.m_buffs.Confuse())
		{
			dir = GetConfuseDir(dir, speed);
			m_dir = atan(dir.y, dir.x);
		}
		else if (fleeing)
			m_dir = atan(origDir.y, origDir.x);
		else
			m_dir = m_pathFollower.m_visualDir;
			
		body.SetLinearVelocity(dir);
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
