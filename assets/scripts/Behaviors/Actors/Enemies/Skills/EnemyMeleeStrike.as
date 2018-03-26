class EnemyMeleeStrike : ICompositeActorSkill
{
	AnimString@ m_anim;
	
	UnitPtr m_unit;
	CompositeActorBehavior@ m_behavior;
	int m_id;
	
	int m_cooldown;
	int m_cooldownC;
	
	int m_castPoint;
	int m_castPointC;
	int m_castC;
	
	int m_rangeSq;
	int m_minRangeSq;
	float m_arc;
	
	string m_offset;
	
	SoundEvent@ m_sound;	
	array<IEffect@>@ m_effects;
	
	array<ISkillConditional@>@ m_conditionals;
	
	
	
	EnemyMeleeStrike(UnitPtr unit, SValue& params)
	{
		@m_anim = AnimString(GetParamString(unit, params, "anim"));
		
		m_cooldown = GetParamInt(unit, params, "cooldown");
		m_cooldownC = randi(m_cooldown);
		m_castPoint = max(1, GetParamInt(unit, params, "castpoint", false, 1));
		
		m_offset = GetParamString(unit, params, "offset", false, "");
		
		m_rangeSq = GetParamInt(unit, params, "range");
		m_rangeSq = m_rangeSq * m_rangeSq;
		
		m_arc = GetParamInt(unit, params, "arc", false, 90) * PI / 180;
		
		m_minRangeSq = GetParamInt(unit, params, "min-range", false, 0);
		m_minRangeSq = m_minRangeSq * m_minRangeSq;
		
		@m_sound = Resources::GetSoundEvent(GetParamString(unit, params, "snd", false));
		
		@m_effects = LoadEffects(unit, params);
		
		@m_conditionals = LoadSkillConditionals(unit, params);
	}
	
	void Initialize(UnitPtr unit, CompositeActorBehavior& behavior, int id)
	{
		m_unit = unit;
		@m_behavior = behavior;
		m_id = id;
	}
	
	void OnDamaged() {}
	void OnDeath() {}
	void Destroyed() {}
	void OnCollide(UnitPtr unit, vec2 normal) {}
	
	void NetUseSkill(int stage, SValue@ param)
	{
		m_cooldownC = 0;
		m_castPointC = m_castPoint;
		
		m_castC = m_behavior.SetUnitScene(m_anim.GetSceneName(m_behavior.m_movement.m_dir), true);
		
		if (m_behavior.m_target !is null)
		{
			vec2 dir = xy(m_behavior.m_target.m_unit.GetPosition() - m_unit.GetPosition());
			if (dir.x != 0 || dir.y != 0)
				m_behavior.m_movement.m_dir = atan(dir.y, dir.x);
		}
	}
	
	void Update(int dt, bool isCasting)
	{
		if (m_castC > 0)
		{
			if (m_castPointC <= 0)
			{
				vec2 dir = normalize(xy(m_behavior.m_target.m_unit.GetPosition() - m_unit.GetPosition()));
				m_behavior.m_movement.m_dir = atan(dir.y, dir.x);
			}
		
			m_unit.GetPhysicsBody().SetLinearVelocity(0, 0);
		
			m_castC -= dt;
			if (m_castC <= 0)
				m_cooldownC = m_cooldown;
		}
		
		if (m_cooldownC > 0)
		{
			m_cooldownC -= dt;
			return;
		}
		
		if (m_cooldownC <= 0 && !isCasting && !IsCasting() && IsAvailable() && Network::IsServer())
		{
			NetUseSkill(0, null);
			UnitHandler::NetSendUnitUseSkill(m_unit, m_id);
		}
		
		if (m_castPointC <= 0)
			return;
			
		m_castPointC -= dt;
		
		if (m_castPointC <= 0)
		{
			PlaySound3D(m_sound, m_unit.GetPosition());
		
			//if (!Network::IsServer())
			//	return;
		
			if (!IsAvailable())
				return;

			vec2 dir = normalize(xy(m_behavior.m_target.m_unit.GetPosition() - m_unit.GetPosition()));
			float angle = m_behavior.m_movement.m_dir - atan(dir.y, dir.x);
			angle += (angle > PI) ? -TwoPI : (angle < -PI) ? TwoPI : 0;

			if (abs(angle) <= m_arc / 2)
			{
				vec2 pos = FetchOffsetPos(m_unit, m_offset);
				auto results = g_scene.Raycast(pos, xy(m_behavior.m_target.m_unit.GetPosition()), ~0, RaycastType::Shot);
				for (uint i = 0; i < results.length(); i++)
				{
					UnitPtr res_unit = results[i].FetchUnit(g_scene);
					if (!res_unit.IsValid())
						continue;
						
					auto b = res_unit.GetScriptBehavior();
					if (b is m_behavior.m_target)
					{
						ApplyEffects(m_effects, m_behavior, m_behavior.m_target.m_unit, results[i].point, dir, m_behavior.m_buffs.DamageMul(), !Network::IsServer(), 0, 0);
						break;
					}
					
					auto d = cast<IDamageTaker>(b);
					if (d is null or d.Impenetrable())
						break;
				}
			}
		}
	}
	
	bool IsCasting()
	{
		return m_castC > 0;
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
