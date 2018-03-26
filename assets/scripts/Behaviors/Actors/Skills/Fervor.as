namespace Skills
{
	class FervorTrigger : Modifiers::Modifier
	{
		Fervor@ m_skill;
	
		FervorTrigger(Fervor@ skill)
		{
			@m_skill = skill;
		}	

		void TriggerEffects(PlayerBase@ player, Actor@ enemy, Modifiers::EffectTrigger trigger) override
		{ 
			if (trigger == Modifiers::EffectTrigger::Kill)
				m_skill.OnKill();
		}
		
		bool Evasion(PlayerBase@ player, Actor@ enemy) override { return (randf() <= (m_skill.m_stackEvasion * m_skill.m_count)); }
	}

	class Fervor : Skill
	{
		array<Modifiers::Modifier@> m_modifiers;
		
		int m_timerC;
		int m_timer;
		
		int m_maxCount;
		int m_count;
		
		float m_stackSpeed;
		float m_stackEvasion;
		
	
		Fervor(UnitPtr unit, SValue& params)
		{
			super(unit);
			
			m_timer = GetParamInt(unit, params, "duration");
			m_maxCount = GetParamInt(unit, params, "max-stacks");
			m_stackSpeed = GetParamFloat(unit, params, "stack-speed");
			m_stackEvasion = GetParamFloat(unit, params, "stack-evasion");
			
			m_modifiers.insertLast(FervorTrigger(this));
		}
		
		void RefreshCount()
		{
			cast<ActiveSkill>(cast<PlayerBase>(m_owner).m_skills[0]).m_timeScale = (1.0f + m_stackSpeed * m_count);
		}
		
		void OnKill()
		{
			m_timerC = m_timer;
			m_count = min(m_maxCount, m_count + 1);
			
			RefreshCount();
		}

		array<Modifiers::Modifier@>@ GetModifiers() override
		{
			return m_modifiers;
		}
		
		void Update(int dt, bool walking) override
		{
			if (m_count > 0)
			{
				m_timerC -= dt;
				if (m_timerC < 0)
				{
					m_count--;
					m_timerC += m_timer;
					RefreshCount();
				}			
			}
		}
	}	
}