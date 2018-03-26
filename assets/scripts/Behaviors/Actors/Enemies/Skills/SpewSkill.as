class SpewSkill : ICompositeActorSkill
{
	UnitPtr m_unit;
	CompositeActorBehavior@ m_behavior;
	int m_id;

	AnimString@ m_anim;

	int m_cooldown;
	int m_cooldownC;
	int m_castpoint;
	int m_duration;
	int m_durationC;

	int m_rangeSq;
	int m_minRangeSq;

	float m_spread;

	int m_spawnRate;
	int m_spawnRateC;
	
	SoundEvent@ m_sound;
	SoundInstance@ m_soundI;
	SoundEvent@ m_stopSound;

	UnitProducer@ m_projProd;
	string m_offset;
	
	array<ISkillConditional@>@ m_conditionals;
	
	bool m_holdDir;
	vec2 m_dir;
	bool m_mustSee;
	bool m_ignoreIsCasting;
	

	SpewSkill(UnitPtr unit, SValue& params)
	{
		@m_anim = AnimString(GetParamString(unit, params, "anim"));

		m_rangeSq = GetParamInt(unit, params, "range");
		m_rangeSq = m_rangeSq * m_rangeSq;
		
		m_minRangeSq = GetParamInt(unit, params, "min-range", false, 0);
		m_minRangeSq = m_minRangeSq * m_minRangeSq;

		m_cooldown = GetParamInt(unit, params, "cooldown", false);
		m_castpoint = GetParamInt(unit, params, "castpoint", false);
		m_duration = GetParamInt(unit, params, "duration");

		@m_projProd = Resources::GetUnitProducer(GetParamString(unit, params, "projectile"));
		m_offset = GetParamString(unit, params, "offset", false);
		
		@m_sound = Resources::GetSoundEvent(GetParamString(unit, params, "snd", false));
		@m_stopSound = Resources::GetSoundEvent(GetParamString(unit, params, "stop-snd", false));

		m_spread = GetParamInt(unit, params, "spread", false) * PI / 180.0;
		m_spawnRateC = m_spawnRate = GetParamInt(unit, params, "rate", false, 33);
		
		m_holdDir = GetParamBool(unit, params, "hold-dir", false, false);
		m_mustSee = GetParamBool(unit, params, "must-see", false, true);
		m_ignoreIsCasting = GetParamBool(unit, params, "ignore-is-casting", false, false);
		
		@m_conditionals = LoadSkillConditionals(unit, params);
	}

	void Initialize(UnitPtr unit, CompositeActorBehavior& behavior, int id)
	{
		m_unit = unit;
		@m_behavior = behavior;
		m_id = id;
	}
	
	void Destroyed()
	{
		if (m_soundI !is null)
		{
			m_soundI.Stop();
			@m_soundI = null;
		}
	}
	
	void StartLoopingSound()
	{
		if (m_sound !is null)
		{
			if (m_soundI !is null)
				m_soundI.Stop();
				
			@m_soundI = m_sound.PlayTracked(m_unit.GetPosition());
		}
	}
	
	void StopLoopingSound()
	{
		if (m_soundI !is null)
		{
			m_soundI.Stop();
			@m_soundI = null;
			
			if (m_stopSound !is null)
				PlaySound3D(m_stopSound, m_unit.GetPosition());
		}
	}

	void NetUseSkill(int stage, SValue@ param) 
	{
		m_cooldownC = 0;
		m_durationC = m_duration + m_castpoint;
		m_spawnRateC = m_castpoint;
		m_dir = normalize(xy(m_behavior.m_target.m_unit.GetPosition() - m_unit.GetPosition()));
		StartLoopingSound();
	}
	
	void Update(int dt, bool isCasting)
	{
		if (m_behavior.m_target is null)
			return;

		if (Network::IsServer())
		{
			if (m_cooldownC > 0)
			{
				m_cooldownC -= dt;
				return;
			}

			vec3 posTarget = m_behavior.m_target.m_unit.GetPosition();
			vec3 posMe = m_unit.GetPosition();

			if (m_durationC <= 0 && !isCasting)
			{
				float distance = distsq(posMe, posTarget);
				if (IsAvailable() && (!m_mustSee || CanSee(m_behavior.m_target.m_unit)))
				{
					NetUseSkill(0, null);
					UnitHandler::NetSendUnitUseSkill(m_unit, m_id, 0);
					return;
				}
			}
		}

		if (m_durationC <= 0)
			return;
		
		if (!m_holdDir)
			m_dir = normalize(xy(m_behavior.m_target.m_unit.GetPosition() - m_unit.GetPosition()));
		
		m_behavior.m_movement.m_dir = atan(m_dir.y, m_dir.x);
		m_behavior.SetUnitScene(m_anim.GetSceneName(atan(m_dir.y, m_dir.x)), false);

		auto body = m_unit.GetPhysicsBody();
		if (body !is null)
			body.SetLinearVelocity(0, 0);

		m_spawnRateC -= dt;
		while (m_spawnRateC <= 0)
		{
			vec2 shootDir = addrot(m_dir, randfn() * m_spread);

			vec3 pos = xyz(FetchOffsetPos(m_unit, m_offset));
			pos += xyz(shootDir * 3.0);
			
			UnitPtr unitProj = m_projProd.Produce(g_scene, pos);
			if (unitProj.IsValid())
			{
				IProjectile@ p = cast<IProjectile>(unitProj.GetScriptBehavior());
				if (p !is null)
					p.Initialize(m_behavior, shootDir, 1.0, false, m_behavior.m_target, 0);
			}

			m_spawnRateC += m_spawnRate;
		}

		m_durationC -= dt;
		if (m_durationC <= 0)
		{
			m_cooldownC = m_cooldown;
			StopLoopingSound();
		}
	}

	bool IsCasting()
	{
		//TODO: Movement should think while this skill is cast (as in Hammerwatch [which is actually a bug?]), but other skills may not be cast.
		return !m_ignoreIsCasting && m_durationC > 0;
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
	
	bool IsAvailable()
	{
		int distSq = distsq(m_unit, m_behavior.m_target);
	
		if (distSq > m_rangeSq)
			return false;
			
		if (distSq < m_minRangeSq)
			return false;
			
		if (m_behavior.m_buffs.Disarm())
			return false;
			
		return CheckConditionals(m_conditionals, m_behavior);
	}

	void OnDamaged() { }
	void OnDeath() { }
	void OnCollide(UnitPtr unit, vec2 normal) { }
}
