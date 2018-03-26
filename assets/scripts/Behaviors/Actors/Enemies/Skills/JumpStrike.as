class JumpStrike : ICompositeActorSkill
{
	AnimString@ m_anim;
	
	UnitPtr m_unit;
	int m_id;
	CompositeActorBehavior@ m_behavior;
	
	int m_cooldown;
	int m_cooldownC;
	
	int m_holdFrame;
	int m_preCastC;
	int m_postCastC;
	int m_castingC;
	
	int m_rangeSq;
	int m_minRangeSq;
	
	bool m_mustSee;
	
	SoundEvent@ m_sound;
	
	array<IEffect@>@ m_effects;
	
	array<ISkillConditional@>@ m_conditionals;
	
	vec2 m_dir;
	string m_currAnim;
	float m_speed;
	int m_airTime;
	int m_jumpHeight;
	bool m_glide;
	
	
	JumpStrike(UnitPtr unit, SValue& params)
	{
		@m_anim = AnimString(GetParamString(unit, params, "anim"));
		
		m_cooldown = GetParamInt(unit, params, "cooldown");
		m_cooldownC = randi(m_cooldown);
		m_holdFrame = max(1, GetParamInt(unit, params, "hold-frame", false, 1));
		
		m_rangeSq = GetParamInt(unit, params, "range");
		m_rangeSq = m_rangeSq * m_rangeSq;
		
		m_minRangeSq = GetParamInt(unit, params, "min-range", false, 0);
		m_minRangeSq = m_minRangeSq * m_minRangeSq;
		
		m_mustSee = GetParamBool(unit, params, "must-see", false, true);
		
		@m_sound = Resources::GetSoundEvent(GetParamString(unit, params, "snd", false));
		
		
		@m_conditionals = LoadSkillConditionals(unit, params);
		
		
		m_speed = GetParamFloat(unit, params, "speed");
		m_airTime = GetParamInt(unit, params, "air-time");
		m_jumpHeight = GetParamInt(unit, params, "jump-height");
		m_glide = GetParamBool(unit, params, "glide", false, false);
		
		@m_effects = LoadEffects(unit, params);
	}
	
	void Initialize(UnitPtr unit, CompositeActorBehavior& behavior, int id)
	{
		m_unit = unit;
		@m_behavior = behavior;
		m_id = id;
	}
	
	void OnDamaged() {}
	void OnDeath() {}
	
	void Destroyed()
	{
		m_unit.SetPositionZ(0);
	}
	
	void OnCollide(UnitPtr unit, vec2 normal)
	{
		if (m_castingC <= 0)
			return;

		if (cast<Pickup>(unit.GetScriptBehavior()) !is null)
			return;
	
		vec2 dir = m_behavior.GetDirection();
		vec2 pos = xy(m_unit.GetPosition());
		
		ApplyEffects(m_effects, m_behavior, unit, pos, dir, m_behavior.m_buffs.DamageMul(), !Network::IsServer(), 0, 0);
		
		if (unit.GetUnitProducer() !is m_unit.GetUnitProducer())
			CancelSkill();
	}
	
	void CancelSkill()
	{
		m_cooldownC = m_cooldown;
		m_preCastC = 0;
		m_castingC = 0;
		m_postCastC = 0;
		m_unit.SetPositionZ(0);
		
		//m_behavior.m_movement.m_collideWithFriends = true;
		m_unit.SetShouldCollideWithSame(true);
		
		if (Network::IsServer())
			(Network::Message("UnitUseSSkill") << m_unit << m_id << 1 << xy(m_unit.GetPosition())).SendToAll();
	}
	
	void NetUseSkill(int stage, SValue@ param) 
	{
		if (stage == 1)
			CancelSkill();
	}
	
	void Update(int dt, bool isCasting)
	{
		if (m_cooldownC > 0)
		{
			m_cooldownC -= dt;
			return;
		}
		
		if (m_cooldownC <= 0  && !isCasting && !IsCasting() && IsAvailable())
		{
			if (!m_mustSee || CanSee(m_behavior.m_target.m_unit))
			{
				m_cooldownC = 0;
				m_preCastC = m_holdFrame;
				
				m_dir = normalize(xy(m_behavior.m_target.m_unit.GetPosition() - m_unit.GetPosition()));
				if (m_behavior.m_buffs.Confuse())
					m_dir = addrot(m_dir, randfn() * (PI / 4));
				float dir = atan(m_dir.y, m_dir.x);
				m_currAnim = m_anim.GetSceneName(dir);
				
				m_postCastC = m_behavior.SetUnitScene(m_currAnim, true) - m_holdFrame;

				//m_behavior.m_movement.m_collideWithFriends = false;
				m_unit.SetShouldCollideWithSame(false);
				return;
			}
			else
				m_cooldownC = m_cooldown;
		}
		
		
		if (!IsCasting())
			return;
		
		m_behavior.SetUnitScene(m_currAnim, false);
		
		vec2 vel;
		if (m_preCastC > 0)
		{
			m_preCastC -= dt;
			if (m_preCastC <= 0)
			{
				//if (IsAvailable())
				{
					m_castingC = m_airTime;
					PlaySound3D(m_sound, m_unit);
				}
			}
		}
		else if(m_castingC > 0)
		{
			m_unit.SetUnitSceneTime(m_holdFrame);
			vel = m_dir * m_speed;
			
			if (Network::IsServer() && m_jumpHeight > 0)
			{
				float h = (sin(m_castingC * PI / m_airTime)) * m_jumpHeight;
				m_unit.SetPositionZ(h, true);
			}
			
			m_castingC -= dt;
		}		
		else if (m_postCastC > 0)
		{
			if (m_glide)
				vel = m_dir * m_speed * (m_postCastC / float(m_unit.GetCurrentUnitScene().Length() - m_holdFrame));
		
			m_postCastC -= dt;
			if (m_postCastC <= 0)
				CancelSkill();
		}
		
		if (Network::IsServer())
			m_unit.GetPhysicsBody().SetLinearVelocity(vel);
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
	
	bool IsCasting()
	{
		return m_preCastC > 0 || m_castingC > 0 || m_postCastC > 0;
	}
	
	bool IsAvailable()
	{
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
}