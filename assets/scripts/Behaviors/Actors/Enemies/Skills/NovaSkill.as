class NovaSkill : ICompositeActorSkill
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
	
	bool m_mustSee;
	int m_charges;

	int m_animationC;

	UnitProducer@ m_projProd;

	SoundEvent@ m_fireSnd;

	float m_projDist;
	int m_projCount;
	
	array<ISkillConditional@>@ m_conditionals;
	

	NovaSkill(UnitPtr unit, SValue& params)
	{
		@m_anim = AnimString(GetParamString(unit, params, "anim"));

		m_cooldown = GetParamInt(unit, params, "cooldown", false);
		m_cooldownC = randi(m_cooldown);

		m_minRangeSq = GetParamInt(unit, params, "min-range", false, 0);
		m_minRangeSq = m_minRangeSq * m_minRangeSq;
		
		m_mustSee = GetParamBool(unit, params, "must-see", false, true);

		m_castpoint = GetParamInt(unit, params, "castpoint", false, unit.GetUnitScene(m_anim.GetSceneName(0)).Length());

		m_rangeSq = GetParamInt(unit, params, "range");
		m_rangeSq = m_rangeSq * m_rangeSq;

		@m_projProd = Resources::GetUnitProducer(GetParamString(unit, params, "projectile"));

		@m_fireSnd = Resources::GetSoundEvent(GetParamString(unit, params, "fire-snd", false));

		m_projDist = GetParamFloat(unit, params, "proj-dist", false);
		m_projCount = GetParamInt(unit, params, "proj-count", false, 8);
		
		m_charges = GetParamInt(unit, params, "charges", false, -1);
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
			if (!IsAvailable())
				return;
				
			if (m_mustSee && !CanSee(m_behavior.m_target.m_unit))
				return;

			if (Network::IsServer())
			{
				NetUseSkill(0, null);
				UnitHandler::NetSendUnitUseSkill(m_unit, m_id, 0);
			}
		}

		if (Network::IsServer() && m_castpointC > 0)
		{
			m_castpointC -= dt;
			if (m_castpointC <= 0)
			{
				NetUseSkill(1, null);
				UnitHandler::NetSendUnitUseSkill(m_unit, m_id, 1);
			}
		}
	}
	
	bool CanSee(UnitPtr unit)
	{
		if (!unit.IsValid())
			return false;
	
		RaycastResult res = g_scene.RaycastClosest(xy(m_unit.GetPosition()), xy(unit.GetPosition()), ~0, RaycastType::Aim);
		UnitPtr res_unit = res.FetchUnit(g_scene);
		
		if (!res_unit.IsValid())
			return true;
		
		return (res_unit == unit);
	}

	void FireProjectiles()
	{
		for (int i = 0; i < m_projCount; i++)
		{
			float angle = (2 * PI / m_projCount) * i;
			vec2 shootDir = vec2(cos(angle), sin(angle));
			vec3 projPos = xyz(xy(m_unit.GetPosition()) + shootDir * m_projDist);
			UnitPtr proj = m_projProd.Produce(g_scene, projPos);
			if (proj.IsValid())
			{
				IProjectile@ p = cast<IProjectile>(proj.GetScriptBehavior());
				if (p !is null)
					p.Initialize(m_behavior, shootDir, 1.0, false, m_behavior.m_target, 0);
			}
			m_cooldownC = m_cooldown;
		}
		PlaySound3D(m_fireSnd, m_unit.GetPosition());
		
		if (m_charges > 0)
			m_charges--;
	}

	bool IsCasting()
	{
		return m_castpointC > 0 || m_animationC > 0;
	}
	
	bool IsAvailable()
	{
		if (m_charges == 0)
			return false;
			
		if (m_behavior.m_target is null)
			return false;
	
		int distSq = distsq(m_unit, m_behavior.m_target);
	
		if (distSq > m_rangeSq)
			return false;
			
		if (distSq < m_minRangeSq)
			return false;
			
		if (m_behavior.m_buffs.Disarm())
			return false;
		
		return CheckConditionals(m_conditionals, m_behavior);
	}

	void Destroyed() { }
	void OnDamaged() { }
	void OnDeath() { }
	void OnCollide(UnitPtr unit, vec2 normal) { }

	void NetUseSkill(int stage, SValue@ param)
	{
		if (stage == 0)
		{
			if (m_castpoint > 0)
				m_castpointC = m_castpoint;
			else
				FireProjectiles();

			m_animationC = m_behavior.SetUnitScene(m_anim.GetSceneName(m_behavior.m_movement.m_dir), true);
		}
		else if (stage == 1)
			FireProjectiles();
	}
}
