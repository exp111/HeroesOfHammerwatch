class WhirlNovaSkill : ICompositeActorSkill
{
	UnitPtr m_unit;
	CompositeActorBehavior@ m_behavior;
	int m_id;

	AnimString@ m_anim;

	int m_cooldown;
	int m_cooldownC;

	int m_castpoint;
	int m_castpointC;

	int m_minRangeSq;
	int m_rangeSq;

	int m_duration;
	int m_durationC;

	int m_animationC;

	UnitProducer@ m_projProd;

	SoundEvent@ m_startSnd;
	SoundEvent@ m_fireSnd;
	
	string m_offset;
	array<ISkillConditional@>@ m_conditionals;

	float m_projDist;
	int m_projDelay;
	int m_perRev;
	

	WhirlNovaSkill(UnitPtr unit, SValue& params)
	{
		@m_anim = AnimString(GetParamString(unit, params, "anim"));

		m_cooldown = GetParamInt(unit, params, "cooldown", false);
		m_cooldownC = randi(m_cooldown);

		m_minRangeSq = GetParamInt(unit, params, "min-range");
		m_minRangeSq = m_minRangeSq * m_minRangeSq;

		m_castpoint = GetParamInt(unit, params, "castpoint");

		m_rangeSq = GetParamInt(unit, params, "range");
		m_rangeSq = m_rangeSq * m_rangeSq;

		m_duration = GetParamInt(unit, params, "duration", false, 1000);
		@m_projProd = Resources::GetUnitProducer(GetParamString(unit, params, "projectile"));

		@m_startSnd = Resources::GetSoundEvent(GetParamString(unit, params, "start-snd", false));
		@m_fireSnd = Resources::GetSoundEvent(GetParamString(unit, params, "fire-snd", false));

		m_projDist = GetParamFloat(unit, params, "proj-dist", false);
		m_projDelay = GetParamInt(unit, params, "proj-delay", false, 33);
		m_perRev = GetParamInt(unit, params, "per-revolution", false, 1);
		
		m_offset = GetParamString(unit, params, "offset", false, "");
		
		@m_conditionals = LoadSkillConditionals(unit, params);
	}

	void Initialize(UnitPtr unit, CompositeActorBehavior& behavior, int id)
	{
		m_unit = unit;
		@m_behavior = behavior;
		m_id = id;
	}

	void Update(int dt, bool isCasting)
	{
		if (IsCasting())
			m_unit.GetPhysicsBody().SetLinearVelocity(0, 0);

		if (m_animationC > 0)
			m_animationC -= dt;

		if (m_cooldownC > 0)
		{
			m_cooldownC -= dt;
			return;
		}

		if (!isCasting)
		{
			int distSq = distsq(m_unit, m_behavior.m_target);
			if (distSq > m_rangeSq || distSq < m_minRangeSq)
				return;

			if (Network::IsServer() && CheckConditionals(m_conditionals, m_behavior))
			{
				NetUseSkill(0, null);
				UnitHandler::NetSendUnitUseSkill(m_unit, m_id);
			}
		}

		if (m_castpointC > 0)
		{
			m_castpointC -= dt;
			if (m_castpointC <= 0)
				m_durationC = m_duration;
		}

		if (m_durationC > 0)
		{
			if (m_durationC % m_projDelay < dt)
			{
				int i = m_durationC / m_projDelay;
				float angle = ((2 * PI / m_perRev) * i);
				vec2 shootDir = vec2(cos(angle), sin(angle));
				vec3 projPos = xyz(FetchOffsetPos(m_unit, m_offset) + shootDir * m_projDist);
				UnitPtr proj = m_projProd.Produce(g_scene, projPos);
				if (proj.IsValid())
				{
					IProjectile@ p = cast<IProjectile>(proj.GetScriptBehavior());
					if (p !is null)
						p.Initialize(m_behavior, shootDir, 1.0, false, null, 0);
					PlaySound3D(m_fireSnd, projPos);
				}
			}
			m_durationC -= dt;
			if (m_durationC <= 0)
				m_cooldownC = m_cooldown;
		}
	}

	bool IsCasting()
	{
		return m_durationC > 0 || m_castpointC > 0 || m_animationC > 0;
	}

	void OnDamaged() { }
	void OnDeath() { }
	void Destroyed() { }
	void OnCollide(UnitPtr unit, vec2 normal) { }

	void NetUseSkill(int stage, SValue@ param)
	{
		if (m_castpoint > 0)
			m_castpointC = m_castpoint;
		else
			m_durationC = m_duration;
		m_cooldownC = 0;

		m_animationC = m_behavior.SetUnitScene(m_anim.GetSceneName(m_behavior.m_movement.m_dir), true);
		PlaySound3D(m_startSnd, m_unit.GetPosition());
	}
}
