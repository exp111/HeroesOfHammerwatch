class PlayerPush : IEffect
{
	float m_force;

	PlayerPush(UnitPtr unit, SValue& params)
	{
		m_force = GetParamFloat(unit, params, "force", false, 1.0f);
	}

	void SetWeaponInformation(uint weapon) {}
	
	bool Apply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity, bool husk)
	{
		if (!CanApply(owner, target, pos, dir, intensity))
			return false;

		Player@ plr = cast<Player>(target.GetScriptBehavior());
		plr.Jump(dir * m_force);
		return true;
	}

	bool CanApply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity) override
	{
		if (!target.IsValid())
			return false;
	
		Player@ plr = cast<Player>(target.GetScriptBehavior());

		if (plr is null)
			return false;
			
		return true;
	}

	bool NeedsFilter()
	{
		return false;
	}
}