enum SkillTrigger
{
	None,
	OnDeath,
	OnDamaged,
	OnCollide,
	OnSpawn,
	OnMove,
	OnTime
}

class CompositeActorTriggeredSkill : ICompositeActorSkill
{
	SkillTrigger m_trigger;
	bool m_targetSelf;

	AnimString@ m_anim;

	int m_castPoint;
	int m_castPointC;
	vec2 m_castDir;
	vec2 m_castPos;
	UnitPtr m_castTarget;
	
	UnitPtr m_unit;
	CompositeActorBehavior@ m_behavior;
	int m_id;
	
	array<IAction@>@ m_actions;
	array<IEffect@>@ m_effects;

	array<ISkillConditional@>@ m_conditionals;
	
	bool m_spawned;
	int m_animTimeC;
	uint m_cooldown;
	uint m_lastHitTime;
	
	
	CompositeActorTriggeredSkill(UnitPtr unit, SValue& params)
	{
		m_trigger = SkillTrigger::None;
		string trigger = GetParamString(unit, params, "trigger");

		if (trigger == "OnDeath")
			m_trigger = SkillTrigger::OnDeath;
		else if (trigger == "OnDamaged")
			m_trigger = SkillTrigger::OnDamaged;
		else if (trigger == "OnCollide")
			m_trigger = SkillTrigger::OnCollide;
		else if (trigger == "OnSpawn")
			m_trigger = SkillTrigger::OnSpawn;

		
		@m_actions = LoadActions(unit, params);
		@m_effects = LoadEffects(unit, params);

		m_targetSelf = GetParamBool(unit, params, "targetself", false, true);
		
		@m_conditionals = LoadSkillConditionals(unit, params);

		string strAnim = GetParamString(unit, params, "anim", false);
		if (strAnim != "")
			@m_anim = AnimString(strAnim);

		m_castPoint = GetParamInt(unit, params, "castpoint", false);
		m_cooldown = GetParamInt(unit, params, "cooldown", false, 0);
	}
	
	void Initialize(UnitPtr unit, CompositeActorBehavior& behavior, int id)
	{
		m_unit = unit;
		@m_behavior = behavior;
		m_id = id;
	}
	
	bool IsAvailable()
	{
		return CheckConditionals(m_conditionals, m_behavior);
	}
	
	void Update(int dt, bool isCasting)
	{
		if (m_castPointC > 0)
		{
			m_castPointC -= dt;
			if (m_castPointC <= 0)
				CastTrigger();
		}

		if (m_animTimeC > 0)
			m_animTimeC -= dt;

		if (!m_spawned)
		{
			m_spawned = true; // TODO: Save flag
			OnSpawn();
		}
		for (uint i = 0; i < m_actions.length(); i++)
			m_actions[i].Update(dt, 0);
	}
	
	void OnDamaged() 
	{
		if (m_trigger != SkillTrigger::OnDamaged)
			return;
			
		if (!IsAvailable())
			return;

		UnitPtr target;
		if (m_targetSelf)
			target = m_unit;

		Trigger(target);
	}
	
	void OnDeath()
	{
		if (m_trigger != SkillTrigger::OnDeath)
			return;
			
		if (!Network::IsServer())
			return;
			
		if (!IsAvailable())
			return;

		UnitPtr target;
		if (m_targetSelf)
			target = m_unit;

		Trigger(target);
	}
	
	void OnCollide(UnitPtr unit, vec2 normal) 
	{
		if (m_trigger != SkillTrigger::OnCollide)
			return;
			
		if (!IsAvailable())
			return;

		UnitPtr target;
		if (m_targetSelf)
			target = m_unit;
		else
			target = unit;

		Trigger(target);
	}

	void OnSpawn()
	{
		if (m_trigger != SkillTrigger::OnSpawn)
			return;
			
		if (!IsAvailable())
			return;

		UnitPtr target;
		if (m_targetSelf)
			target = m_unit;

		Trigger(target);
	}
	
	bool IsCasting()
	{
		return m_animTimeC > 0;
	}
	
	void NetUseSkill(int stage, SValue@ param)
	{
		if (stage == 0)
			NetTrigger();
		else if (stage == 1)
		{
			vec2 dir = m_behavior.GetCastDirection();
			vec2 pos = xy(m_unit.GetPosition());

			NetDoActions(m_actions, param, m_behavior, pos, dir);
			if (m_castTarget.IsValid())
			{
				auto b = cast<Actor>(m_castTarget.GetScriptBehavior());
				if (b !is null and !b.IsTargetable())
					return;
				
				ApplyEffects(m_effects, m_behavior, m_castTarget, pos, dir, m_behavior.m_buffs.DamageMul(), !Network::IsServer());
			}
		}
	}

	void Trigger(UnitPtr target)
	{
		auto nowT = g_scene.GetTime();
		if ((m_lastHitTime + m_cooldown) > nowT)
			return;
		
		m_lastHitTime = nowT;
	
	
		m_castDir = m_behavior.GetCastDirection();
		m_castPos = xy(m_unit.GetPosition());

		if (m_anim !is null)
		{
			m_unit.SetUnitScene(m_anim.GetSceneName(atan(m_castDir.y, m_castDir.x)), true);
			m_animTimeC = m_unit.GetCurrentUnitScene().Length();
		}

		UnitHandler::NetSendUnitUseSkill(m_unit, m_id, 0, null);

		m_castPointC = m_castPoint;
		m_castTarget = target;

		if (m_castPointC <= 0)
			CastTrigger();
	}

	void NetTrigger()
	{
		if (m_anim !is null)
		{
			vec2 dir = m_behavior.GetCastDirection();
			m_unit.SetUnitScene(m_anim.GetSceneName(atan(dir.y, dir.x)), true);
			m_animTimeC = m_unit.GetCurrentUnitScene().Length();
		}
	}

	void CastTrigger()
	{
		SValue@ param = DoActions(m_actions, m_behavior, m_behavior.m_target, m_castPos, m_castDir, m_behavior.m_buffs.DamageMul());
		UnitHandler::NetSendUnitUseSkill(m_unit, m_id, 1, param);
		
		if (m_castTarget.IsValid())
		{
			auto b = cast<Actor>(m_castTarget.GetScriptBehavior());
			if (b !is null and !b.IsTargetable())
				return;
			
			ApplyEffects(m_effects, m_behavior, m_castTarget, m_castPos, m_castDir, m_behavior.m_buffs.DamageMul(), !Network::IsServer());
		}
	}
	
	void Destroyed() { }
}
