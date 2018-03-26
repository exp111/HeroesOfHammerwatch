class SpawnEffect : IEffect, IAction
{
	UnitScene@ m_effect;

	SpawnEffect(UnitPtr unit, SValue& params)
	{
		@m_effect = Resources::GetEffect(GetParamString(unit, params, "effect"));
	}

	bool NeedNetParams() { return false; }
	void SetWeaponInformation(uint weapon) {}
	
	bool DoAction(SValueBuilder@ builder, Actor@ owner, Actor@ target, vec2 pos, vec2 dir, float intensity)
	{
		Do(pos);
		return true;
	}
	
	bool NetDoAction(SValue@ param, Actor@ owner, vec2 pos, vec2 dir)
	{
		Do(pos);
		return true;
	}
	
	bool Apply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity, bool husk)
	{
		Do(pos);
		return true;
	}

	bool CanApply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity) override
	{
		return true;
	}
	
	void Do(vec2 pos)
	{
		PlayEffect(m_effect, pos);
	}
	
	
	
	void Update(int dt, int cooldown)
	{
	}

	bool NeedsFilter()
	{
		return true;
	}
}