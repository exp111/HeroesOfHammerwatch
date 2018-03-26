class GivePerk : IEffect
{
	string m_perk;

	GivePerk(UnitPtr unit, SValue& params)
	{
		m_perk = GetParamString(unit, params, "perk");
	}

	void SetWeaponInformation(uint weapon) {}
	
	bool Apply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity, bool husk)
	{
		if (!CanApply(owner, target, pos, dir, intensity))
			return false;

		Player@ plr = cast<Player>(target.GetScriptBehavior());
		plr.m_record.GivePerk(m_perk);
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