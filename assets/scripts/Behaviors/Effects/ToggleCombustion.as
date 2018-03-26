class ToggleCombustion : IEffect
{
	bool m_enable;

	ToggleCombustion(UnitPtr unit, SValue& params)
	{
		m_enable = GetParamBool(unit, params, "enable");
	}
	
	void SetWeaponInformation(uint weapon) {}
	bool CanApply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity) override { return true; }

	bool Apply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity, bool husk)
	{
		auto player = cast<Player>(owner);
		if (player !is null)
		{
			auto combust = cast<Skills::PassiveSkill>(player.m_skills[4]);
			if (combust is null)
				return false;
		
			for (uint i = 0; i < combust.m_modifiers.length(); i++)
			{
				auto trigEffect = cast<Modifiers::TriggerEffect>(combust.m_modifiers[i]);
				if (trigEffect is null)
					continue;
				
				trigEffect.m_enabled = m_enable;
			}
		}

		return true;
	}

	bool NeedsFilter()
	{
		return true;
	}
}