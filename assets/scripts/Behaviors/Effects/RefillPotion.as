class RefillPotion : IEffect
{
	int m_charges;

	RefillPotion(UnitPtr unit, SValue& params)
	{
		m_charges = GetParamInt(unit, params, "charges", false, 1);
	}
	
	void SetWeaponInformation(uint weapon) {}
	
	bool Apply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity, bool husk)
	{
		if (!CanApply(owner, target, pos, dir, intensity))
			return false;
		
		auto player = cast<Player>(target.GetScriptBehavior());
		if (player is null)
			return false;
		
		player.m_record.potionChargesUsed = max(0, player.m_record.potionChargesUsed - m_charges);
		return true;
	}

	bool CanApply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity) override
	{
		if (!target.IsValid())
			return false;
			
		auto player = cast<Player>(target.GetScriptBehavior());
		if (player is null)
			return false;
		
		return player.m_record.potionChargesUsed > 0;
	}

	bool NeedsFilter()
	{
		return false;
	}
}